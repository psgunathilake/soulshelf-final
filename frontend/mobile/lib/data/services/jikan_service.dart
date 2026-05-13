import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/recommendation_item.dart';

/// Wraps the public Jikan v4 REST API (MyAnimeList proxy). No auth required.
/// Rate-limited to ~3 req/sec and 60 req/min — recommendations are
/// per-screen-load so we stay well under the ceiling in practice.
///
/// Docs: https://docs.api.jikan.moe/
class JikanService {
  static const _base = 'https://api.jikan.moe/v4';

  final Dio _dio;

  JikanService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: _base,
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
              responseType: ResponseType.json,
            ));

  /// Top-ranked anime overall. First-cut Jikan integration; a genre-filtered
  /// variant (`/anime?genres=`) can layer on later once the user has enough
  /// anime entries to derive a meaningful genre signal.
  Future<List<RecommendationItem>> fetchTopAnime({int limit = 20}) async {
    final r = await _dio.get('/top/anime', queryParameters: {'limit': limit});
    final data = (r.data as Map?)?['data'] as List? ?? const [];
    return data
        .whereType<Map>()
        .map(_toItem)
        .toList(growable: false);
  }

  static RecommendationItem _toItem(Map a) {
    final title = (a['title_english'] ?? a['title'])?.toString() ?? 'Untitled';
    final score = a['score'];
    final imageUrl = (((a['images'] as Map?)?['jpg']) as Map?)?['image_url']
        ?.toString();
    final url = a['url']?.toString();
    return RecommendationItem(
      title: title,
      subtitle: score is num ? '★ ${score.toStringAsFixed(1)}' : null,
      coverUrl: imageUrl,
      externalUrl: url,
      source: 'jikan',
    );
  }
}

final jikanServiceProvider = Provider<JikanService>((ref) => JikanService());
