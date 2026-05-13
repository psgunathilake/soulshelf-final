import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

import '../models/journal_model.dart';
import '../services/api_journal_service.dart';
import '../services/pending_writes_box.dart';

/// Journal entries are keyed by `yyyy-MM-dd` so at most one entry exists
/// per calendar day. As of Phase 3 the Laravel API is the source of truth;
/// `journalBox` is a cache + offline-write queue source.
///
/// Public surface unchanged from Phase 1 — `saveEntry`/`getEntry`/etc.
/// keep their signatures.
///
/// `shortNote` is a Phase-1 cache-only field (no schema column). The
/// merge in `_refresh` preserves it across refresh cycles.
class JournalRepository {
  static final _keyFormat = DateFormat('yyyy-MM-dd');

  final ApiJournalService _api;
  final PendingWritesBox _queue;
  bool _refreshed = false;

  JournalRepository(this._api, this._queue);

  Box get _box => Hive.box('journalBox');

  String keyFor(DateTime d) => _keyFormat.format(d);

  Future<void> saveEntry(DateTime date, JournalModel entry) async {
    final key = keyFor(date);
    await _box.put(key, entry.toHive());

    try {
      final server = await _api.upsert(key, entry);
      // Preserve cache-only shortNote across the server roundtrip.
      final merged = Map<String, dynamic>.from(server.toHive());
      if (entry.shortNote != null) merged['shortNote'] = entry.shortNote;
      await _box.put(key, merged);
    } on DioException catch (e) {
      if (!_isOffline(e)) rethrow;
      await _queue.enqueue('upsert.journal', {
        'date': key,
        'body': entry.toApi(),
      });
    }
  }

  JournalModel? getEntry(DateTime date) {
    final raw = _box.get(keyFor(date));
    return raw == null ? null : JournalModel.fromHive(raw as Map);
  }

  List<MapEntry<String, JournalModel>> getAllEntries() {
    final entries = <MapEntry<String, JournalModel>>[];
    for (final k in _box.keys) {
      final raw = _box.get(k);
      if (raw is Map) {
        entries.add(MapEntry(k as String, JournalModel.fromHive(raw)));
      }
    }
    return entries;
  }

  Stream<List<MapEntry<String, JournalModel>>> watchAllEntries() async* {
    _refreshOnce();
    yield getAllEntries();
    await for (final _ in _box.watch()) {
      yield getAllEntries();
    }
  }

  Future<void> deleteEntry(DateTime date) async {
    final key = keyFor(date);
    await _box.delete(key);

    try {
      await _api.destroy(key);
    } on DioException catch (e) {
      // 404 on delete = already gone server-side; treat as success.
      if (e.response?.statusCode == 404) return;
      if (!_isOffline(e)) rethrow;
      await _queue.enqueue('delete.journal', {'date': key});
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
      // Default: most recent 31 entries (server's default per_page).
      // Older entries stay in cache; we don't reconcile-delete here
      // because partial windows can't tell "missing" from "out of range".
      final serverEntries = await _api.list();
      for (final e in serverEntries) {
        final raw = _box.get(e.key);
        final localShortNote =
            raw is Map ? (raw['shortNote'] as String?) : null;
        final merged = Map<String, dynamic>.from(e.value.toHive());
        if (localShortNote != null) merged['shortNote'] = localShortNote;
        await _box.put(e.key, merged);
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

final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  final api = ref.watch(apiJournalServiceProvider);
  final queue = ref.watch(pendingWritesBoxProvider);
  return JournalRepository(api, queue);
});
