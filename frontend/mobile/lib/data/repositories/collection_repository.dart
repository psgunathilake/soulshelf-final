import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/collection_model.dart';
import '../services/api_collection_service.dart';
import '../services/pending_writes_box.dart';

/// Cache + API + offline-queue shape for collections. Mirrors
/// MediaRepository: local-uuid id while a row is unsynced, swapped to
/// the server's `<id>` once POST succeeds.
///
/// Phase 4 ships the collections UI; the pivot methods (attachMedia /
/// detachMedia) and `getCollectionWithMembers` are live now so 3.8's
/// queue drainer has a complete repertoire.
class CollectionRepository {
  final ApiCollectionService _api;
  final PendingWritesBox _queue;
  bool _refreshed = false;

  CollectionRepository(this._api, this._queue);

  Box get _box => Hive.box('collectionsBox');

  /// Saves a new collection. Returns the persisted model — server-id row
  /// when online, local-uuid row when offline (caller can detect the
  /// `local-` prefix to skip server-only follow-ups like cover upload).
  Future<CollectionModel> addCollection(CollectionModel c) async {
    final local = c.copyWith(id: 'local-${const Uuid().v4()}');
    await _box.put(local.id, local.toHive());

    try {
      final server = await _api.create(c);
      await _box.delete(local.id);
      await _box.put(server.id, server.toHive());
      return server;
    } on DioException catch (e) {
      if (!_isOffline(e)) rethrow;
      await _queue.enqueue('create.collection', {
        'localId': local.id,
        'serverId': null,
        'body': c.toApi(),
      });
      return local;
    }
  }

  Future<void> updateCollection(CollectionModel c) async {
    final bumped = c.copyWith(updatedAt: DateTime.now());
    await _box.put(bumped.id, bumped.toHive());

    if (bumped.id.startsWith('local-')) return;
    final serverId = int.tryParse(bumped.id);
    if (serverId == null) return;

    try {
      final server = await _api.update(serverId, bumped);
      // Preserve mediaIds — server PUT response doesn't eager-load `media`.
      final merged = Map<String, dynamic>.from(server.toHive());
      merged['mediaIds'] = bumped.mediaIds;
      await _box.put(server.id, merged);
    } on DioException catch (e) {
      if (!_isOffline(e)) rethrow;
      await _queue.enqueue('update.collection', {
        'localId': bumped.id,
        'serverId': serverId,
        'body': bumped.toApi(),
      });
    }
  }

  CollectionModel? getCollection(String id) {
    final raw = _box.get(id);
    return raw == null ? null : CollectionModel.fromHive(raw as Map);
  }

  /// Forces a `GET /api/collections/{id}` to pull the eager-loaded `media`
  /// array. Used by detail screens that need accurate membership.
  Future<CollectionModel?> getCollectionWithMembers(String id) async {
    if (id.startsWith('local-')) return getCollection(id);
    final serverId = int.tryParse(id);
    if (serverId == null) return getCollection(id);

    try {
      final server = await _api.show(serverId);
      await _box.put(server.id, server.toHive());
      return server;
    } on DioException {
      return getCollection(id);
    }
  }

  List<CollectionModel> getAllCollections() => _box.values
      .map((e) => CollectionModel.fromHive(e as Map))
      .toList(growable: false);

  Stream<List<CollectionModel>> watchAllCollections() async* {
    _refreshOnce();
    yield getAllCollections();
    await for (final _ in _box.watch()) {
      yield getAllCollections();
    }
  }

  Future<void> deleteCollection(String id) async {
    await _box.delete(id);

    if (id.startsWith('local-')) return;
    final serverId = int.tryParse(id);
    if (serverId == null) return;

    try {
      await _api.destroy(serverId);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return;
      if (!_isOffline(e)) rethrow;
      await _queue.enqueue('delete.collection', {
        'localId': id,
        'serverId': serverId,
      });
    }
  }

  /// Adds a media row to a collection. Updates the local cache's
  /// `mediaIds` immediately; server pivot is best-effort.
  Future<void> attachMedia(String collectionId, String mediaId) async {
    final raw = _box.get(collectionId);
    if (raw is Map) {
      final c = CollectionModel.fromHive(raw);
      if (!c.mediaIds.contains(mediaId)) {
        await _box.put(
          collectionId,
          c
              .copyWith(mediaIds: [...c.mediaIds, mediaId])
              .toHive(),
        );
      }
    }

    if (collectionId.startsWith('local-') || mediaId.startsWith('local-')) {
      // Both must be server-side before the pivot makes sense.
      // 3.8's drainer will retry once both ids are real.
      await _queue.enqueue('attach.collection_media', {
        'collectionId': collectionId,
        'mediaId': mediaId,
      });
      return;
    }

    final cId = int.tryParse(collectionId);
    final mId = int.tryParse(mediaId);
    if (cId == null || mId == null) return;

    try {
      await _api.attachMedia(cId, mId);
    } on DioException catch (e) {
      if (!_isOffline(e)) rethrow;
      await _queue.enqueue('attach.collection_media', {
        'collectionId': collectionId,
        'mediaId': mediaId,
      });
    }
  }

  /// Uploads a cover for an existing collection. Returns the refreshed
  /// model with `coverUrl` populated, or `null` if the row hasn't been
  /// synced yet (`local-` prefix). Network-class failures return null;
  /// HTTP errors rethrow. Mirrors `MediaRepository.uploadCover`.
  Future<CollectionModel?> uploadCover(String id, File file) async {
    if (id.startsWith('local-')) return null;
    final serverId = int.tryParse(id);
    if (serverId == null) return null;

    try {
      final updated = await _api.uploadCover(serverId, file);
      // Preserve local mediaIds — uploadCover response doesn't eager-load `media`.
      final raw = _box.get(id);
      final localMediaIds = raw is Map
          ? ((raw['mediaIds'] as List?)?.cast<String>())
          : null;
      final merged = Map<String, dynamic>.from(updated.toHive());
      if (localMediaIds != null && localMediaIds.isNotEmpty) {
        merged['mediaIds'] = localMediaIds;
      }
      await _box.put(updated.id, merged);
      return updated;
    } on DioException catch (e) {
      if (_isOffline(e)) return null;
      rethrow;
    }
  }

  Future<void> detachMedia(String collectionId, String mediaId) async {
    final raw = _box.get(collectionId);
    if (raw is Map) {
      final c = CollectionModel.fromHive(raw);
      if (c.mediaIds.contains(mediaId)) {
        await _box.put(
          collectionId,
          c
              .copyWith(
                mediaIds: c.mediaIds.where((id) => id != mediaId).toList(),
              )
              .toHive(),
        );
      }
    }

    if (collectionId.startsWith('local-') || mediaId.startsWith('local-')) {
      return;
    }

    final cId = int.tryParse(collectionId);
    final mId = int.tryParse(mediaId);
    if (cId == null || mId == null) return;

    try {
      await _api.detachMedia(cId, mId);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return;
      if (!_isOffline(e)) rethrow;
      await _queue.enqueue('detach.collection_media', {
        'collectionId': collectionId,
        'mediaId': mediaId,
      });
    }
  }

  // ------- Internals -------

  void _refreshOnce() {
    if (_refreshed) return;
    _refreshed = true;
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final serverItems = await _api.list();
      final serverIds = serverItems.map((c) => c.id).toSet();

      for (final item in serverItems) {
        // Preserve cache-side mediaIds — list response doesn't include
        // membership, only `show` does.
        final raw = _box.get(item.id);
        final localMediaIds = raw is Map
            ? ((raw['mediaIds'] as List?)?.cast<String>())
            : null;
        final merged = Map<String, dynamic>.from(item.toHive());
        if (localMediaIds != null && localMediaIds.isNotEmpty) {
          merged['mediaIds'] = localMediaIds;
        }
        await _box.put(item.id, merged);
      }

      // Drop server-id rows the server didn't return; keep `local-` rows.
      final stale = _box.keys.where((k) {
        final keyStr = k as String;
        return !keyStr.startsWith('local-') && !serverIds.contains(keyStr);
      }).toList();
      for (final k in stale) {
        await _box.delete(k);
      }
    } on DioException {
      // Offline / server error — cache stays as-is.
    }
  }

  static bool _isOffline(DioException e) =>
      e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.sendTimeout;
}

final collectionRepositoryProvider = Provider<CollectionRepository>((ref) {
  final api = ref.watch(apiCollectionServiceProvider);
  final queue = ref.watch(pendingWritesBoxProvider);
  return CollectionRepository(api, queue);
});
