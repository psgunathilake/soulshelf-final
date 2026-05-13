import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';

/// Thin dio wrapper over `GET /api/user/stats`. The endpoint returns the
/// denormalized counter blob from `users.stats` (see SPEC §5.4); on a
/// fresh user with null stats the server kicks a one-time recompute.
class ApiStatsService {
  final ApiClient _api;

  ApiStatsService(this._api);

  /// Returns the raw stats dict — keys per SPEC §5.4 plus `mediaByCategory`,
  /// `mediaByStatus`, `recomputedAt`. Caller is responsible for casting
  /// nested fields it cares about.
  Future<Map<String, dynamic>> fetch() async {
    final res = await _api.dio.get('/user/stats');
    return (res.data as Map).cast<String, dynamic>();
  }
}

final apiStatsServiceProvider = Provider<ApiStatsService>((ref) {
  return ApiStatsService(ref.watch(apiClientProvider));
});
