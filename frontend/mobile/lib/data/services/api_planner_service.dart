import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/planner_model.dart';
import 'api_client.dart';

/// Thin dio wrapper over `/api/planners/*`. Same date-keyed upsert shape
/// as journals.
class ApiPlannerService {
  static final _df = DateFormat('yyyy-MM-dd');

  final ApiClient _api;

  ApiPlannerService(this._api);

  Future<List<MapEntry<String, PlannerModel>>> list({
    DateTime? from,
    DateTime? to,
  }) async {
    final params = <String, dynamic>{'per_page': 100};
    if (from != null) params['from'] = _df.format(from);
    if (to != null) params['to'] = _df.format(to);

    final res = await _api.dio.get('/planners', queryParameters: params);
    final data = (res.data['data'] as List).cast<Map<String, dynamic>>();
    return data
        .map((j) => MapEntry(
              (j['date'] as String).substring(0, 10),
              PlannerModel.fromApi(j),
            ))
        .toList(growable: false);
  }

  Future<PlannerModel> show(String date) async {
    final res = await _api.dio.get('/planners/$date');
    return PlannerModel.fromApi((res.data as Map).cast<String, dynamic>());
  }

  Future<PlannerModel> upsert(String date, PlannerModel plan) async {
    final res = await _api.dio.put('/planners/$date', data: plan.toApi());
    return PlannerModel.fromApi((res.data as Map).cast<String, dynamic>());
  }

  Future<void> destroy(String date) async {
    await _api.dio.delete('/planners/$date');
  }
}

final apiPlannerServiceProvider = Provider<ApiPlannerService>((ref) {
  return ApiPlannerService(ref.watch(apiClientProvider));
});
