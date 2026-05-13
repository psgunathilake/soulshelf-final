import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/api_keys.dart';
import '../models/recommendation_item.dart';

/// Wraps the TMDB v3 REST API. Uses the api_key query-param flow (the v3
/// auth path) — simpler than the v4 Bearer token for read-only discover
/// calls. Key comes from [ApiKeys.tmdb] which is fed by --dart-define.
///
/// Docs: https://developer.themoviedb.org/reference
class TmdbService {
  static const _base = 'https://api.themoviedb.org/3';
  static const _imageBase = 'https://image.tmdb.org/t/p/w342';

  final Dio _dio;

  TmdbService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: _base,
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
              responseType: ResponseType.json,
            ));

  Future<List<RecommendationItem>> fetchPopularMovies({int limit = 20}) =>
      _discover('/discover/movie', limit, isMovie: true);

  Future<List<RecommendationItem>> fetchPopularTvShows({int limit = 20}) =>
      _discover('/discover/tv', limit, isMovie: false);

  Future<List<RecommendationItem>> _discover(
    String path,
    int limit, {
    required bool isMovie,
  }) async {
    if (!ApiKeys.hasTmdb) {
      throw StateError('TMDB_KEY missing — pass via --dart-define');
    }
    final r = await _dio.get(
      path,
      queryParameters: {
        'api_key': ApiKeys.tmdb,
        'sort_by': 'popularity.desc',
        'language': 'en-US',
        'page': 1,
      },
    );
    final results = (r.data as Map?)?['results'] as List? ?? const [];
    return results
        .whereType<Map>()
        .take(limit)
        .map((m) => _toItem(m, isMovie: isMovie))
        .toList(growable: false);
  }

  static RecommendationItem _toItem(Map m, {required bool isMovie}) {
    // Movies use `title` + `release_date`; TV uses `name` + `first_air_date`.
    final title = (isMovie ? m['title'] : m['name'])?.toString() ?? 'Untitled';
    final date = (isMovie ? m['release_date'] : m['first_air_date'])?.toString();
    final year = (date != null && date.length >= 4) ? date.substring(0, 4) : null;
    final posterPath = m['poster_path']?.toString();
    final id = m['id'];
    final externalUrl = id is int
        ? 'https://www.themoviedb.org/${isMovie ? "movie" : "tv"}/$id'
        : null;
    return RecommendationItem(
      title: title,
      subtitle: year,
      coverUrl: posterPath != null ? '$_imageBase$posterPath' : null,
      externalUrl: externalUrl,
      source: 'tmdb',
    );
  }
}

final tmdbServiceProvider = Provider<TmdbService>((ref) => TmdbService());
