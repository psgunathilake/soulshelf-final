import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/journal_model.dart';
import 'api_client.dart';

/// Thin dio wrapper over `/api/journals/*`. Journal entries are upserted
/// by date (server uses `(user_id, date)` as the composite key).
class ApiJournalService {
  static final _df = DateFormat('yyyy-MM-dd');

  final ApiClient _api;

  ApiJournalService(this._api);

  /// `GET /api/journals[?from=...&to=...]`. Returns each row keyed by its
  /// date string so callers can write straight to the cache box.
  Future<List<MapEntry<String, JournalModel>>> list({
    DateTime? from,
    DateTime? to,
  }) async {
    final params = <String, dynamic>{'per_page': 100};
    if (from != null) params['from'] = _df.format(from);
    if (to != null) params['to'] = _df.format(to);

    final res = await _api.dio.get('/journals', queryParameters: params);
    final data = (res.data['data'] as List).cast<Map<String, dynamic>>();
    return data
        .map((j) => MapEntry(
              (j['date'] as String).substring(0, 10),
              JournalModel.fromApi(j),
            ))
        .toList(growable: false);
  }

  Future<JournalModel> show(String date) async {
    final res = await _api.dio.get('/journals/$date');
    return JournalModel.fromApi((res.data as Map).cast<String, dynamic>());
  }

  /// `PUT /api/journals/{date}` — server treats it as upsert. Returns 201
  /// on first write, 200 on subsequent writes.
  Future<JournalModel> upsert(String date, JournalModel entry) async {
    final res = await _api.dio.put('/journals/$date', data: entry.toApi());
    return JournalModel.fromApi((res.data as Map).cast<String, dynamic>());
  }

  Future<void> destroy(String date) async {
    await _api.dio.delete('/journals/$date');
  }
}

final apiJournalServiceProvider = Provider<ApiJournalService>((ref) {
  return ApiJournalService(ref.watch(apiClientProvider));
});
