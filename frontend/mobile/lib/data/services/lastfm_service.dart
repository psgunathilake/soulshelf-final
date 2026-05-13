import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/api_keys.dart';
import '../models/recommendation_item.dart';

/// Wraps the Last.fm public REST API. Uses the api_key query param flow
/// (read-only, no signing). Key comes from [ApiKeys.lastfm], fed by
/// --dart-define.
///
/// Docs: https://www.last.fm/api
class LastFmService {
  static const _base = 'https://ws.audioscrobbler.com/2.0/';

  final Dio _dio;

  LastFmService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
              responseType: ResponseType.json,
            ));

  /// Top tracks for a genre tag (e.g. "rock", "pop", "hip-hop"). Last.fm
  /// is forgiving about spaces / case; tag is normalised to lowercase
  /// before the request.
  Future<List<RecommendationItem>> fetchByTag(String tag, {int limit = 20}) =>
      _call({
        'method': 'tag.gettoptracks',
        'tag': tag.toLowerCase().trim(),
        'limit': limit,
      });

  /// Global chart toptracks. Used when the user has no songs (or no genre
  /// tags) yet and we have no taste signal to bias on.
  Future<List<RecommendationItem>> fetchTopTracks({int limit = 20}) => _call({
        'method': 'chart.gettoptracks',
        'limit': limit,
      });

  Future<List<RecommendationItem>> _call(Map<String, dynamic> params) async {
    if (!ApiKeys.hasLastfm) {
      throw StateError('LASTFM_KEY missing — pass via --dart-define');
    }
    final r = await _dio.get(
      _base,
      queryParameters: {
        ...params,
        'api_key': ApiKeys.lastfm,
        'format': 'json',
      },
    );
    final tracks =
        (((r.data as Map?)?['tracks']) as Map?)?['track'] as List? ?? const [];
    return tracks
        .whereType<Map>()
        .map(_toItem)
        .toList(growable: false);
  }

  static RecommendationItem _toItem(Map t) {
    final title = t['name']?.toString() ?? 'Untitled';
    final artistName =
        ((t['artist'] as Map?)?['name'])?.toString();
    final url = t['url']?.toString();
    // image is a list of {"#text": url, "size": small|medium|large|extralarge|mega}.
    // Pick the largest non-empty entry.
    final images = (t['image'] as List?) ?? const [];
    String? coverUrl;
    for (final candidate in images.whereType<Map>().toList().reversed) {
      final txt = candidate['#text']?.toString();
      if (txt != null && txt.isNotEmpty) {
        coverUrl = txt;
        break;
      }
    }
    return RecommendationItem(
      title: title,
      subtitle: artistName,
      coverUrl: coverUrl,
      externalUrl: url,
      source: 'lastfm',
    );
  }
}

final lastFmServiceProvider =
    Provider<LastFmService>((ref) => LastFmService());
