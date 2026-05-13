import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/book_model.dart';
import '../models/media_model.dart';
import '../models/show_model.dart';
import '../models/song_model.dart';
import '../services/api_media_service.dart';
import '../services/pending_writes_box.dart';

/// Single repository for Books / Songs / Shows. As of Phase 3 the Laravel
/// API is the source of truth; the three Hive boxes (booksBox · songsBox ·
/// showsBox) are caches keyed by the row's id (`local-{uuid}` for un-synced
/// offline writes, `'<serverId>'` once the server has assigned one).
///
/// Public surface is unchanged from Phase 1 — `addBook`/`watchAllBooks`/etc.
/// keep their signatures so the existing UI doesn't have to move.
///
/// Offline writes are enqueued in `pendingWritesBox`. Task 3.8 ships the
/// connectivity-driven drainer; in 3.6 the queue only fills.
class MediaRepository {
  final ApiMediaService _api;
  final PendingWritesBox _queue;
  final Set<MediaCategory> _refreshed = {};

  MediaRepository(this._api, this._queue);

  Box get _booksBox => Hive.box('booksBox');
  Box get _songsBox => Hive.box('songsBox');
  Box get _showsBox => Hive.box('showsBox');

  Box _boxFor(MediaCategory cat) => switch (cat) {
        MediaCategory.book => _booksBox,
        MediaCategory.song => _songsBox,
        MediaCategory.show => _showsBox,
      };

  // ------- Books -------
  Future<BookModel> addBook(BookModel b) async =>
      (await _addMedia(b, _booksBox)) as BookModel;

  Future<void> updateBook(BookModel b) => _updateMedia(
        b.copyWith(updatedAt: DateTime.now()),
        _booksBox,
      );

  List<BookModel> getAllBooks() => _booksBox.values
      .map((e) => BookModel.fromHive(e as Map))
      .toList(growable: false);

  BookModel? getBook(String id) {
    final raw = _booksBox.get(id);
    return raw == null ? null : BookModel.fromHive(raw as Map);
  }

  Stream<List<BookModel>> watchAllBooks() async* {
    _refreshOnce(MediaCategory.book);
    yield getAllBooks();
    await for (final _ in _booksBox.watch()) {
      yield getAllBooks();
    }
  }

  // ------- Songs -------
  Future<SongModel> addSong(SongModel s) async =>
      (await _addMedia(s, _songsBox)) as SongModel;

  Future<void> updateSong(SongModel s) => _updateMedia(
        s.copyWith(updatedAt: DateTime.now()),
        _songsBox,
      );

  List<SongModel> getAllSongs() => _songsBox.values
      .map((e) => SongModel.fromHive(e as Map))
      .toList(growable: false);

  SongModel? getSong(String id) {
    final raw = _songsBox.get(id);
    return raw == null ? null : SongModel.fromHive(raw as Map);
  }

  Stream<List<SongModel>> watchAllSongs() async* {
    _refreshOnce(MediaCategory.song);
    yield getAllSongs();
    await for (final _ in _songsBox.watch()) {
      yield getAllSongs();
    }
  }

  // ------- Shows -------
  Future<ShowModel> addShow(ShowModel s) async =>
      (await _addMedia(s, _showsBox)) as ShowModel;

  Future<void> updateShow(ShowModel s) => _updateMedia(
        s.copyWith(updatedAt: DateTime.now()),
        _showsBox,
      );

  List<ShowModel> getAllShows() => _showsBox.values
      .map((e) => ShowModel.fromHive(e as Map))
      .toList(growable: false);

  ShowModel? getShow(String id) {
    final raw = _showsBox.get(id);
    return raw == null ? null : ShowModel.fromHive(raw as Map);
  }

  Stream<List<ShowModel>> watchAllShows() async* {
    _refreshOnce(MediaCategory.show);
    yield getAllShows();
    await for (final _ in _showsBox.watch()) {
      yield getAllShows();
    }
  }

  /// Cross-category lookup. Returns the cached row regardless of which
  /// box it's in (book/song/show), or null if the id is unknown locally.
  /// Used by the collection view to resolve mixed-category members.
  MediaModel? findMediaById(String id) {
    final raw = _booksBox.get(id) ?? _songsBox.get(id) ?? _showsBox.get(id);
    if (raw is! Map) return null;
    final cat = raw['category'] as String?;
    return switch (cat) {
      'book' => BookModel.fromHive(raw),
      'song' => SongModel.fromHive(raw),
      'show' => ShowModel.fromHive(raw),
      _ => null,
    };
  }

  // ------- Generic delete -------
  Future<void> deleteMedia(MediaCategory cat, String id) async {
    final box = _boxFor(cat);
    await box.delete(id);

    // Un-synced row — never reached the server, nothing to call.
    // Known correctness gap: a queued create.media for this id will still
    // fire when 3.8 drains, leaving an orphan server row. 3.8 must scrub
    // pending creates whose localId no longer exists in cache.
    if (id.startsWith('local-')) return;

    final serverId = int.tryParse(id);
    if (serverId == null) return;

    try {
      await _api.destroy(serverId);
    } on DioException catch (e) {
      if (!_isOffline(e)) rethrow;
      await _queue.enqueue('delete.media', {
        'category': cat.name,
        'localId': id,
        'serverId': serverId,
      });
    }
  }

  /// Uploads a cover for an existing media row. Returns the refreshed
  /// model with `coverUrl` populated, or `null` if the row hasn't been
  /// synced yet (`local-` prefix) — covers can't queue, per architectural
  /// decision in the integration doc. Network-class failures return null;
  /// HTTP errors rethrow.
  Future<MediaModel?> uploadCover(
    MediaCategory cat,
    String id,
    File file,
  ) async {
    if (id.startsWith('local-')) return null;
    final serverId = int.tryParse(id);
    if (serverId == null) return null;

    try {
      final updated = await _api.uploadCover(serverId, file);
      await _boxFor(cat).put(updated.id, updated.toHive());
      return updated;
    } on DioException catch (e) {
      if (_isOffline(e)) return null;
      rethrow;
    }
  }

  // ------- Internals -------

  /// Returns the model whose id is whatever ended up in cache: server id
  /// on success, `local-{uuid}` if we went offline. Callers can detect
  /// the offline path via `result.id.startsWith('local-')`.
  Future<MediaModel> _addMedia(MediaModel m, Box box) async {
    final local = _withLocalId(m);
    await box.put(local.id, local.toHive());

    try {
      final server = await _api.create(m);
      await box.delete(local.id);
      await box.put(server.id, server.toHive());
      return server;
    } on DioException catch (e) {
      if (!_isOffline(e)) rethrow;
      await _queue.enqueue('create.media', {
        'category': m.category.name,
        'localId': local.id,
        'serverId': null,
        'body': _toApi(m),
      });
      return local;
    }
  }

  Future<void> _updateMedia(MediaModel m, Box box) async {
    await box.put(m.id, m.toHive());

    // Un-synced row — the queued create.media already carries the latest
    // body when it gets drained (drainer reads from cache, not the queue
    // payload). Nothing else to do here.
    if (m.id.startsWith('local-')) return;

    final serverId = int.tryParse(m.id);
    if (serverId == null) return;

    try {
      final server = await _api.update(serverId, m);
      await box.put(server.id, server.toHive());
    } on DioException catch (e) {
      if (!_isOffline(e)) rethrow;
      await _queue.enqueue('update.media', {
        'category': m.category.name,
        'localId': m.id,
        'serverId': serverId,
        'body': _toApi(m),
      });
    }
  }

  /// Only network-class failures should enqueue. HTTP errors (401/403/422/5xx)
  /// would either replay forever or fire under a different user's token after
  /// re-login. Same classification used by `auth_repository.dart:103-106`.
  static bool _isOffline(DioException e) =>
      e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.sendTimeout;

  void _refreshOnce(MediaCategory cat) {
    if (_refreshed.contains(cat)) return;
    _refreshed.add(cat);
    // Fire-and-forget; errors swallowed (offline → cache continues to serve).
    _refresh(cat);
  }

  Future<void> _refresh(MediaCategory cat) async {
    try {
      final serverItems = await _api.list(category: cat);
      final box = _boxFor(cat);
      final serverIds = serverItems.map((m) => m.id).toSet();

      for (final item in serverItems) {
        await box.put(item.id, item.toHive());
      }

      // Drop server-id rows the server didn't return (deleted elsewhere).
      // Keep `local-` rows — those are un-synced offline writes.
      final stale = box.keys.where((k) {
        final keyStr = k as String;
        return !keyStr.startsWith('local-') && !serverIds.contains(keyStr);
      }).toList();
      for (final k in stale) {
        await box.delete(k);
      }
    } on DioException {
      // Offline / server error — cache stays as-is.
    }
  }

  static MediaModel _withLocalId(MediaModel m) {
    final localId = 'local-${const Uuid().v4()}';
    return switch (m) {
      BookModel b => b.copyWith(id: localId),
      SongModel s => s.copyWith(id: localId),
      ShowModel s => s.copyWith(id: localId),
      _ => throw ArgumentError('Unknown MediaModel subtype: ${m.runtimeType}'),
    };
  }

  static Map<String, dynamic> _toApi(MediaModel m) => switch (m) {
        BookModel b => b.toApi(),
        SongModel s => s.toApi(),
        ShowModel s => s.toApi(),
        _ => throw ArgumentError('Unknown MediaModel subtype: ${m.runtimeType}'),
      };
}

final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  final api = ref.watch(apiMediaServiceProvider);
  final queue = ref.watch(pendingWritesBoxProvider);
  return MediaRepository(api, queue);
});

/// Live list of all saved books. Auto-refreshes when any book is added,
/// updated, or deleted. Consumed by the Books list screen.
final booksStreamProvider = StreamProvider.autoDispose<List<BookModel>>(
  (ref) => ref.watch(mediaRepositoryProvider).watchAllBooks(),
);

final songsStreamProvider = StreamProvider.autoDispose<List<SongModel>>(
  (ref) => ref.watch(mediaRepositoryProvider).watchAllSongs(),
);

final showsStreamProvider = StreamProvider.autoDispose<List<ShowModel>>(
  (ref) => ref.watch(mediaRepositoryProvider).watchAllShows(),
);
