import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

import '../models/planner_model.dart';
import '../services/api_planner_service.dart';
import '../services/pending_writes_box.dart';

/// Daily planner entries keyed by `yyyy-MM-dd`. Same cache+API+queue shape
/// as JournalRepository.
class PlannerRepository {
  static final _keyFormat = DateFormat('yyyy-MM-dd');

  final ApiPlannerService _api;
  final PendingWritesBox _queue;
  bool _refreshed = false;

  PlannerRepository(this._api, this._queue);

  Box get _box => Hive.box('plannerBox');

  String keyFor(DateTime d) => _keyFormat.format(d);

  Future<void> savePlan(DateTime date, PlannerModel plan) async {
    final key = keyFor(date);
    await _box.put(key, plan.toHive());

    try {
      final server = await _api.upsert(key, plan);
      await _box.put(key, server.toHive());
    } on DioException catch (e) {
      if (!_isOffline(e)) rethrow;
      await _queue.enqueue('upsert.planner', {
        'date': key,
        'body': plan.toApi(),
      });
    }
  }

  PlannerModel? getPlan(DateTime date) {
    final raw = _box.get(keyFor(date));
    return raw == null ? null : PlannerModel.fromHive(raw as Map);
  }

  List<MapEntry<String, PlannerModel>> getAllPlans() {
    final entries = <MapEntry<String, PlannerModel>>[];
    for (final k in _box.keys) {
      final raw = _box.get(k);
      if (raw is Map) {
        entries.add(MapEntry(k as String, PlannerModel.fromHive(raw)));
      }
    }
    return entries;
  }

  Stream<List<MapEntry<String, PlannerModel>>> watchAllPlans() async* {
    _refreshOnce();
    yield getAllPlans();
    await for (final _ in _box.watch()) {
      yield getAllPlans();
    }
  }

  Future<void> deletePlan(DateTime date) async {
    final key = keyFor(date);
    await _box.delete(key);

    try {
      await _api.destroy(key);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return;
      if (!_isOffline(e)) rethrow;
      await _queue.enqueue('delete.planner', {'date': key});
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
      final serverEntries = await _api.list();
      for (final e in serverEntries) {
        await _box.put(e.key, e.value.toHive());
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

final plannerRepositoryProvider = Provider<PlannerRepository>((ref) {
  final api = ref.watch(apiPlannerServiceProvider);
  final queue = ref.watch(pendingWritesBoxProvider);
  return PlannerRepository(api, queue);
});
