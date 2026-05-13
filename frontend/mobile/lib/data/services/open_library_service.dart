import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/recommendation_item.dart';

/// Wraps the public Open Library REST API. No auth required.
/// Docs: https://openlibrary.org/dev/docs/api/subjects
class OpenLibraryService {
  static const _base = 'https://openlibrary.org';
  static const _coverBase = 'https://covers.openlibrary.org/b/id';

  final Dio _dio;

  OpenLibraryService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: _base,
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
              responseType: ResponseType.json,
            ));

  /// Fetches up to [limit] works tagged under [subject]. Subject is
  /// normalised to OL's lowercase + underscore form ("Science Fiction"
  /// → "science_fiction") since OL only matches that shape.
  Future<List<RecommendationItem>> fetchBySubject(
    String subject, {
    int limit = 20,
  }) async {
    final s = _normaliseSubject(subject);
    final r = await _dio.get(
      '/subjects/$s.json',
      queryParameters: {'limit': limit},
    );
    final works = (r.data as Map?)?['works'] as List? ?? const [];
    return works
        .whereType<Map>()
        .map(_workToItem)
        .toList(growable: false);
  }

  static String _normaliseSubject(String raw) =>
      raw.toLowerCase().trim().replaceAll(RegExp(r'\s+'), '_');

  static RecommendationItem _workToItem(Map work) {
    final title = work['title']?.toString() ?? 'Untitled';
    final authors = (work['authors'] as List?)
        ?.whereType<Map>()
        .map((a) => a['name']?.toString())
        .whereType<String>()
        .toList();
    final coverId = work['cover_id'];
    final workKey = work['key']?.toString();
    return RecommendationItem(
      title: title,
      subtitle: (authors != null && authors.isNotEmpty) ? authors.first : null,
      coverUrl: coverId is int ? '$_coverBase/$coverId-M.jpg' : null,
      externalUrl: workKey != null ? '$_base$workKey' : null,
      source: 'openlibrary',
    );
  }
}

final openLibraryServiceProvider = Provider<OpenLibraryService>(
  (ref) => OpenLibraryService(),
);
