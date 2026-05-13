import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../services/api_stats_service.dart';

/// Reads the `users.stats` denormalized counters from cache and refreshes
/// them from the API. Stats are read-only on the client — there is no
/// enqueue path; offline simply returns the last cached blob.
///
/// Cache shape: stored as a JSON string under `profileBox['stats']` so
/// nested maps (mediaByCategory, mediaByStatus) round-trip with clean
/// `Map<String, dynamic>` typing on every read.
class StatsRepository {
  static const _statsKey = 'stats';

  final ApiStatsService _api;

  StatsRepository(this._api);

  Box get _box => Hive.box('profileBox');

  /// Synchronous cache read. Returns null if no fetch has succeeded yet.
  Map<String, dynamic>? getStats() {
    final raw = _box.get(_statsKey);
    if (raw is! String || raw.isEmpty) return null;
    return (jsonDecode(raw) as Map).cast<String, dynamic>();
  }

  /// Hits the API, mirrors the response to cache, returns the fresh blob.
  /// Offline → returns the cached blob (may be null) without throwing, so
  /// the dashboard can render whatever it last saw.
  Future<Map<String, dynamic>?> refresh() async {
    try {
      final blob = await _api.fetch();
      await _box.put(_statsKey, jsonEncode(blob));
      return blob;
    } on DioException catch (e) {
      if (_isOffline(e)) return getStats();
      rethrow;
    }
  }

  static bool _isOffline(DioException e) =>
      e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.sendTimeout;
}

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  return StatsRepository(ref.watch(apiStatsServiceProvider));
});

/// Stale-while-revalidate stats stream: emits the cached blob immediately
/// (so UI renders without flicker), then emits the freshly-fetched blob
/// from the server. Pull-to-refresh invalidates the provider, which re-runs
/// the same two-phase emit. Both emits may be null on a fresh user with
/// no cache + offline; UI handles null as empty state.
final statsStreamProvider =
    StreamProvider.autoDispose<Map<String, dynamic>?>((ref) async* {
  final repo = ref.watch(statsRepositoryProvider);
  yield repo.getStats();
  yield await repo.refresh();
});
