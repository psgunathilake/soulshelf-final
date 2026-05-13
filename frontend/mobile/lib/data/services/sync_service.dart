import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../core/messenger.dart';
import '../models/book_model.dart';
import '../models/collection_model.dart';
import '../models/journal_model.dart';
import '../models/planner_model.dart';
import '../models/show_model.dart';
import '../models/song_model.dart';
import '../models/user_model.dart';
import 'api_client.dart';
import 'connectivity_service.dart';
import 'pending_writes_box.dart';

/// Drains `pendingWritesBox` against the Laravel API. Triggered by:
///
/// 1. App start (cold-start recovery if online and queue non-empty)
/// 2. Connectivity transitioning false → true
/// 3. Manual [sync] call (for a future "Sync now" button)
///
/// Drain is FIFO. Halts on auth failure (token already wiped by the 401
/// interceptor) or transient network error. Permanently-failed envelopes
/// (4xx/422) are dropped so the queue can advance. Cache fixup runs
/// alongside each successful replay so the UI reflects server-canonical
/// ids without waiting for the next refresh.
class SyncService {
  final ApiClient _api;
  final ConnectivityService _connectivity;
  final PendingWritesBox _queue;

  StreamSubscription<bool>? _sub;
  bool _online = false;
  bool _draining = false;
  bool _started = false;

  SyncService(this._api, this._connectivity, this._queue);

  /// Wires up connectivity listening + does a cold-start drain check.
  /// Idempotent — repeated calls are no-ops.
  Future<void> start() async {
    if (_started) return;
    _started = true;

    _online = await _connectivity.isOnline();

    _sub = _connectivity.onlineStream.listen((isOnline) {
      final wasOffline = !_online;
      _online = isOnline;
      if (isOnline && wasOffline) {
        _drain();
      }
    });

    if (_online && _queue.pendingCount > 0) {
      _drain();
    }
  }

  /// Manual trigger (for a "Sync now" UI button later).
  Future<void> sync() => _drain();

  Future<void> dispose() async {
    await _sub?.cancel();
  }

  // ---- drain loop ----

  Future<void> _drain() async {
    if (_draining) return;
    _draining = true;

    final startCount = _queue.pendingCount;
    if (startCount > 0) {
      _showSnackbar('Syncing $startCount pending write${startCount == 1 ? '' : 's'}…');
    }

    var halted = false;
    try {
      while (_queue.pendingCount > 0) {
        final outcome = await _processOldest();
        if (outcome == _DrainOutcome.halt) {
          halted = true;
          break;
        }
      }
    } finally {
      _draining = false;
    }

    if (startCount > 0 && !halted) {
      _showSnackbar('Synced');
    }
  }

  Future<_DrainOutcome> _processOldest() async {
    final box = Hive.box('pendingWritesBox');
    final keys = box.keys.toList();
    if (keys.isEmpty) return _DrainOutcome.processed;

    final key = keys.first;
    final raw = box.get(key);
    if (raw is! Map) {
      // Malformed envelope — drop it and continue.
      await box.delete(key);
      return _DrainOutcome.processed;
    }

    final envelope = Map<String, dynamic>.from(raw);
    final op = envelope['op'] as String? ?? '';
    final payload = Map<String, dynamic>.from(
      (envelope['payload'] as Map?) ?? const {},
    );

    // Cross-user safety: an envelope queued under user A must never replay
    // under user B's token. Legacy envelopes (pre-3.11, no `userId` field)
    // are also dropped — they predate the stamp and we can't safely tell
    // who owns them.
    final envelopeUserId = envelope['userId'] as String?;
    final currentUserId = _currentUserId();
    if (envelopeUserId == null || envelopeUserId != currentUserId) {
      debugPrint(
          '[SyncService] dropping op=$op: envelope user=$envelopeUserId, current=$currentUserId');
      await box.delete(key);
      return _DrainOutcome.processed;
    }

    try {
      await _dispatch(op, payload);
      await box.delete(key);
      return _DrainOutcome.processed;
    } on DioException catch (e) {
      final status = e.response?.statusCode;

      if (status == 401) {
        // Auth failure — interceptor already wiped the token; auth-state
        // listener will route to login. Stop draining so we don't replay
        // queued writes under a different identity after re-login.
        debugPrint('[SyncService] drain halted: 401 on op=$op');
        return _DrainOutcome.halt;
      }

      if (status != null &&
          status >= 400 &&
          status < 500 &&
          status != 429) {
        // Permanent failure (422 validation, 403 forbidden, 404 missing).
        // The op will never succeed; drop it so the queue can advance.
        debugPrint('[SyncService] dropping op=$op after $status: ${e.response?.data}');
        await box.delete(key);
        return _DrainOutcome.processed;
      }

      // Transient network or 5xx — halt; will retry on next online transition.
      debugPrint('[SyncService] drain halted: ${e.type} ${status ?? ''} on op=$op');
      return _DrainOutcome.halt;
    } catch (e, st) {
      // Unknown failure — drop the envelope so the queue doesn't stall
      // forever on a malformed payload.
      debugPrint('[SyncService] dropping op=$op after unexpected error: $e\n$st');
      await box.delete(key);
      return _DrainOutcome.processed;
    }
  }

  // ---- per-op handlers ----

  Future<void> _dispatch(String op, Map<String, dynamic> payload) async {
    switch (op) {
      case 'create.media':
        await _replayCreateMedia(payload);
        break;
      case 'update.media':
        await _replayUpdateMedia(payload);
        break;
      case 'delete.media':
        await _replayDeleteMedia(payload);
        break;
      case 'upsert.journal':
        await _replayUpsertJournal(payload);
        break;
      case 'delete.journal':
        await _replayDeleteJournal(payload);
        break;
      case 'upsert.planner':
        await _replayUpsertPlanner(payload);
        break;
      case 'delete.planner':
        await _replayDeletePlanner(payload);
        break;
      case 'create.collection':
        await _replayCreateCollection(payload);
        break;
      case 'update.collection':
        await _replayUpdateCollection(payload);
        break;
      case 'delete.collection':
        await _replayDeleteCollection(payload);
        break;
      case 'attach.collection_media':
        await _replayAttachMedia(payload);
        break;
      case 'detach.collection_media':
        await _replayDetachMedia(payload);
        break;
      case 'update.user':
        await _replayUpdateUser(payload);
        break;
      case 'set.pin':
        await _replaySetPin(payload);
        break;
      default:
        debugPrint('[SyncService] unknown op=$op; dropping');
        return; // caller will delete the envelope
    }
  }

  Future<void> _replayCreateMedia(Map<String, dynamic> p) async {
    final body = Map<String, dynamic>.from(p['body'] as Map);
    final localId = p['localId'] as String;
    final category = p['category'] as String;

    final res = await _api.dio.post('/media', data: body);
    final j = (res.data as Map).cast<String, dynamic>();
    final serverId = j['id'].toString();

    final box = _mediaBoxFor(category);
    final hiveShape = _mediaToHive(j, category);

    await box.delete(localId);
    await box.put(serverId, hiveShape);
  }

  Future<void> _replayUpdateMedia(Map<String, dynamic> p) async {
    final body = Map<String, dynamic>.from(p['body'] as Map);
    final serverId = p['serverId'] as int;
    final category = p['category'] as String;

    final res = await _api.dio.put('/media/$serverId', data: body);
    final j = (res.data as Map).cast<String, dynamic>();

    await _mediaBoxFor(category).put(
      serverId.toString(),
      _mediaToHive(j, category),
    );
  }

  Future<void> _replayDeleteMedia(Map<String, dynamic> p) async {
    final serverId = p['serverId'] as int;
    try {
      await _api.dio.delete('/media/$serverId');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return; // already gone
      rethrow;
    }
  }

  Future<void> _replayUpsertJournal(Map<String, dynamic> p) async {
    final date = p['date'] as String;
    final body = Map<String, dynamic>.from(p['body'] as Map);

    final res = await _api.dio.put('/journals/$date', data: body);
    final j = (res.data as Map).cast<String, dynamic>();
    final entry = JournalModel.fromApi(j);

    final box = Hive.box('journalBox');
    final raw = box.get(date);
    final localShortNote = raw is Map ? (raw['shortNote'] as String?) : null;
    final merged = Map<String, dynamic>.from(entry.toHive());
    if (localShortNote != null) merged['shortNote'] = localShortNote;
    await box.put(date, merged);
  }

  Future<void> _replayDeleteJournal(Map<String, dynamic> p) async {
    final date = p['date'] as String;
    try {
      await _api.dio.delete('/journals/$date');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return;
      rethrow;
    }
  }

  Future<void> _replayUpsertPlanner(Map<String, dynamic> p) async {
    final date = p['date'] as String;
    final body = Map<String, dynamic>.from(p['body'] as Map);

    final res = await _api.dio.put('/planners/$date', data: body);
    final j = (res.data as Map).cast<String, dynamic>();
    final plan = PlannerModel.fromApi(j);

    await Hive.box('plannerBox').put(date, plan.toHive());
  }

  Future<void> _replayDeletePlanner(Map<String, dynamic> p) async {
    final date = p['date'] as String;
    try {
      await _api.dio.delete('/planners/$date');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return;
      rethrow;
    }
  }

  Future<void> _replayCreateCollection(Map<String, dynamic> p) async {
    final body = Map<String, dynamic>.from(p['body'] as Map);
    final localId = p['localId'] as String;

    final res = await _api.dio.post('/collections', data: body);
    final j = (res.data as Map).cast<String, dynamic>();
    final serverId = j['id'].toString();

    final box = Hive.box('collectionsBox');
    final raw = box.get(localId);
    final localMediaIds = raw is Map
        ? ((raw['mediaIds'] as List?)?.cast<String>())
        : null;
    final merged =
        Map<String, dynamic>.from(CollectionModel.fromApi(j).toHive());
    if (localMediaIds != null && localMediaIds.isNotEmpty) {
      merged['mediaIds'] = localMediaIds;
    }

    await box.delete(localId);
    await box.put(serverId, merged);
  }

  Future<void> _replayUpdateCollection(Map<String, dynamic> p) async {
    final body = Map<String, dynamic>.from(p['body'] as Map);
    final serverId = p['serverId'] as int;

    final res = await _api.dio.put('/collections/$serverId', data: body);
    final j = (res.data as Map).cast<String, dynamic>();

    final box = Hive.box('collectionsBox');
    final raw = box.get(serverId.toString());
    final localMediaIds = raw is Map
        ? ((raw['mediaIds'] as List?)?.cast<String>())
        : null;
    final merged =
        Map<String, dynamic>.from(CollectionModel.fromApi(j).toHive());
    if (localMediaIds != null && localMediaIds.isNotEmpty) {
      merged['mediaIds'] = localMediaIds;
    }
    await box.put(serverId.toString(), merged);
  }

  Future<void> _replayDeleteCollection(Map<String, dynamic> p) async {
    final serverId = p['serverId'] as int;
    try {
      await _api.dio.delete('/collections/$serverId');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return;
      rethrow;
    }
  }

  Future<void> _replayAttachMedia(Map<String, dynamic> p) async {
    final cId = p['collectionId'] as String;
    final mId = p['mediaId'] as String;

    if (cId.startsWith('local-') || mId.startsWith('local-')) {
      // Drain reordering / lost create — drop. Cache state still reflects
      // the user's intent; they can re-add via UI.
      debugPrint(
          '[SyncService] attach.collection_media: unresolved local id (cId=$cId mId=$mId); dropping');
      return;
    }

    final cIdInt = int.tryParse(cId);
    final mIdInt = int.tryParse(mId);
    if (cIdInt == null || mIdInt == null) return;

    await _api.dio.post(
      '/collections/$cIdInt/media',
      data: {'media_id': mIdInt},
    );
  }

  Future<void> _replayDetachMedia(Map<String, dynamic> p) async {
    final cId = p['collectionId'] as String;
    final mId = p['mediaId'] as String;

    if (cId.startsWith('local-') || mId.startsWith('local-')) return;

    final cIdInt = int.tryParse(cId);
    final mIdInt = int.tryParse(mId);
    if (cIdInt == null || mIdInt == null) return;

    try {
      await _api.dio.delete('/collections/$cIdInt/media/$mIdInt');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return;
      rethrow;
    }
  }

  Future<void> _replaySetPin(Map<String, dynamic> p) async {
    final hash = p['pin_hash'] as String;
    await _api.dio.put('/user/pin', data: {'pin_hash': hash});
    // No cache fixup — the optimistic write in UserRepository.setPin
    // already mirrored the hash to profileBox['profile']['pinHash'].
  }

  Future<void> _replayUpdateUser(Map<String, dynamic> p) async {
    final body = Map<String, dynamic>.from(p['body'] as Map);

    final res = await _api.dio.put('/user', data: body);
    final j = (res.data as Map).cast<String, dynamic>();

    final box = Hive.box('profileBox');
    final raw = box.get('profile');
    final localPinHash = raw is Map ? (raw['pinHash'] as String?) : null;
    final merged = Map<String, dynamic>.from(UserModel.fromApi(j).toHive());
    if (localPinHash != null) merged['pinHash'] = localPinHash;
    await box.put('profile', merged);
  }

  // ---- helpers ----

  /// Reads the active user's id from the cached profile (same source as
  /// PendingWritesBox._currentUserId). Returns null if no profile is
  /// loaded; in that state every envelope is treated as a mismatch.
  String? _currentUserId() {
    final profile = Hive.box('profileBox').get('profile');
    if (profile is! Map) return null;
    return profile['uid'] as String?;
  }

  Box _mediaBoxFor(String category) => switch (category) {
        'book' => Hive.box('booksBox'),
        'song' => Hive.box('songsBox'),
        'show' => Hive.box('showsBox'),
        _ => throw ArgumentError('unknown media category: $category'),
      };

  Map<String, dynamic> _mediaToHive(Map<String, dynamic> j, String category) =>
      switch (category) {
        'book' => BookModel.fromApi(j).toHive(),
        'song' => SongModel.fromApi(j).toHive(),
        'show' => ShowModel.fromApi(j).toHive(),
        _ => throw ArgumentError('unknown media category: $category'),
      };

  void _showSnackbar(String message) {
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 1500),
      ),
    );
  }
}

enum _DrainOutcome { processed, halt }

final syncServiceProvider = Provider<SyncService>((ref) {
  final api = ref.watch(apiClientProvider);
  final connectivity = ref.watch(connectivityServiceProvider);
  final queue = ref.watch(pendingWritesBoxProvider);
  final service = SyncService(api, connectivity, queue);
  ref.onDispose(service.dispose);
  return service;
});
