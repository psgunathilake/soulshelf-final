import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/collection_model.dart';
import 'api_client.dart';

/// Thin dio wrapper over `/api/collections/*`. Includes the two pivot
/// endpoints for managing collection→media membership.
class ApiCollectionService {
  final ApiClient _api;

  ApiCollectionService(this._api);

  Future<List<CollectionModel>> list() async {
    final res = await _api.dio.get(
      '/collections',
      queryParameters: {'per_page': 100},
    );
    final data = (res.data['data'] as List).cast<Map<String, dynamic>>();
    return data
        .map(CollectionModel.fromApi)
        .toList(growable: false);
  }

  /// `GET /api/collections/{id}` — eager-loads the `media` relation, so
  /// the returned `CollectionModel.mediaIds` is populated.
  Future<CollectionModel> show(int serverId) async {
    final res = await _api.dio.get('/collections/$serverId');
    return CollectionModel.fromApi((res.data as Map).cast<String, dynamic>());
  }

  Future<CollectionModel> create(CollectionModel c) async {
    final res = await _api.dio.post('/collections', data: c.toApi());
    return CollectionModel.fromApi((res.data as Map).cast<String, dynamic>());
  }

  Future<CollectionModel> update(int serverId, CollectionModel c) async {
    final res =
        await _api.dio.put('/collections/$serverId', data: c.toApi());
    return CollectionModel.fromApi((res.data as Map).cast<String, dynamic>());
  }

  Future<void> destroy(int serverId) async {
    await _api.dio.delete('/collections/$serverId');
  }

  /// `POST /api/collections/{id}/media`. Server returns 204.
  Future<void> attachMedia(int collectionId, int mediaId) async {
    await _api.dio.post(
      '/collections/$collectionId/media',
      data: {'media_id': mediaId},
    );
  }

  /// `DELETE /api/collections/{id}/media/{mediaId}`. Server returns 204.
  Future<void> detachMedia(int collectionId, int mediaId) async {
    await _api.dio.delete('/collections/$collectionId/media/$mediaId');
  }

  /// `POST /api/collections/{id}/cover` (multipart). Same shape as
  /// `ApiMediaService.uploadCover` — server stores the file at
  /// `users/{user_id}/collections/{collection_id}.jpg`, writes the
  /// absolute URL to `collections.cover_url`, returns the refreshed row.
  Future<CollectionModel> uploadCover(int serverId, File file) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split(Platform.pathSeparator).last,
      ),
    });
    final res = await _api.dio.post(
      '/collections/$serverId/cover',
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
    return CollectionModel.fromApi((res.data as Map).cast<String, dynamic>());
  }
}

final apiCollectionServiceProvider = Provider<ApiCollectionService>((ref) {
  return ApiCollectionService(ref.watch(apiClientProvider));
});
