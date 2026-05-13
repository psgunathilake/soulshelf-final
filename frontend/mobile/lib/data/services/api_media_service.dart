import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/book_model.dart';
import '../models/media_model.dart';
import '../models/show_model.dart';
import '../models/song_model.dart';
import 'api_client.dart';

/// Thin dio wrapper over `/api/media/*`. Mirrors the shape of
/// [ApiAuthService]: methods return parsed model types; callers
/// catch `DioException` for network/HTTP failures.
class ApiMediaService {
  final ApiClient _api;

  ApiMediaService(this._api);

  /// `GET /api/media?category=...&per_page=100`. Returns the `data` array
  /// from the paginator parsed as typed models. 100 is the server's
  /// `per_page` ceiling; pagination beyond that is a polish item.
  Future<List<MediaModel>> list({required MediaCategory category}) async {
    final res = await _api.dio.get(
      '/media',
      queryParameters: {
        'category': category.name,
        'per_page': 100,
      },
    );
    final data = (res.data['data'] as List).cast<Map<String, dynamic>>();
    return data.map(_parseRow).toList(growable: false);
  }

  /// `GET /api/media/{id}` — single row.
  Future<MediaModel> show(int serverId) async {
    final res = await _api.dio.get('/media/$serverId');
    return _parseRow((res.data as Map).cast<String, dynamic>());
  }

  /// `POST /api/media`. Server returns the created row with its assigned id.
  Future<MediaModel> create(MediaModel m) async {
    final res = await _api.dio.post('/media', data: _toApi(m));
    return _parseRow((res.data as Map).cast<String, dynamic>());
  }

  /// `PUT /api/media/{id}`. Server returns the refreshed row.
  Future<MediaModel> update(int serverId, MediaModel m) async {
    final res = await _api.dio.put('/media/$serverId', data: _toApi(m));
    return _parseRow((res.data as Map).cast<String, dynamic>());
  }

  /// `DELETE /api/media/{id}` — 204 no-content on success.
  Future<void> destroy(int serverId) async {
    await _api.dio.delete('/media/$serverId');
  }

  /// `POST /api/media/{id}/cover` (multipart). Server stores the file
  /// at `users/{user_id}/covers/{media_id}.jpg`, writes the absolute URL
  /// back to `media.cover_url`, and returns the refreshed row.
  Future<MediaModel> uploadCover(int serverId, File file) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split(Platform.pathSeparator).last,
      ),
    });
    final res = await _api.dio.post(
      '/media/$serverId/cover',
      data: form,
      // dio sets the multipart Content-Type + boundary automatically
      // when given FormData; the default 'application/json' header on
      // the BaseOptions would otherwise stick.
      options: Options(contentType: 'multipart/form-data'),
    );
    return _parseRow((res.data as Map).cast<String, dynamic>());
  }

  // ---- internals ----

  /// Dispatches to the right `toApi()` based on runtime type.
  /// Cleaner than adding `toApi` to the abstract `MediaModel` because
  /// each subclass already knows its own wire shape.
  static Map<String, dynamic> _toApi(MediaModel m) => switch (m) {
        BookModel b => b.toApi(),
        SongModel s => s.toApi(),
        ShowModel s => s.toApi(),
        _ => throw ArgumentError('Unknown MediaModel subtype: ${m.runtimeType}'),
      };

  /// Dispatches to the right `fromApi()` based on the row's `category` field.
  static MediaModel _parseRow(Map<String, dynamic> j) {
    final cat = j['category'] as String;
    return switch (cat) {
      'book' => BookModel.fromApi(j),
      'song' => SongModel.fromApi(j),
      'show' => ShowModel.fromApi(j),
      _ => throw ArgumentError('Unknown media category: $cat'),
    };
  }
}

final apiMediaServiceProvider = Provider<ApiMediaService>((ref) {
  return ApiMediaService(ref.watch(apiClientProvider));
});
