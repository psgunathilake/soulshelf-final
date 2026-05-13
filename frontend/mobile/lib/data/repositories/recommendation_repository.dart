import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/media_model.dart';
import '../models/recommendation_item.dart';
import '../models/show_model.dart';
import '../services/jikan_service.dart';
import '../services/lastfm_service.dart';
import '../services/open_library_service.dart';
import '../services/tmdb_service.dart';
import 'media_repository.dart';

/// Composes the Phase-5 external recommendation services and ranks results
/// by the user's existing taste signals (most-frequent saved genre per
/// category; for shows, also the most-frequent sub-type).
///
/// Online-only with last-result fallback per category: keeps the most
/// recent successful result in memory so a transient network failure on
/// the next fetch shows yesterday's strip instead of an empty/error state.
/// Lost on app restart by design (Phase 5 kickoff decision #4).
class RecommendationRepository {
  final OpenLibraryService _openLibrary;
  final TmdbService _tmdb;
  final JikanService _jikan;
  final LastFmService _lastFm;
  final MediaRepository _media;

  RecommendationRepository(this._openLibrary, this._tmdb, this._jikan,
      this._lastFm, this._media);

  List<RecommendationItem>? _lastBooks;
  List<RecommendationItem>? _lastShows;
  List<RecommendationItem>? _lastSongs;

  /// Book recommendations from Open Library, biased toward the user's
  /// top saved genre. Falls back to "fiction" when the user has no books
  /// (or no genre tags) yet.
  Future<List<RecommendationItem>> forBooks() async {
    final subject =
        _topGenre(_media.getAllBooks().map((b) => b.genre)) ?? 'fiction';
    return _withFallback(
      () => _openLibrary.fetchBySubject(subject),
      () => _lastBooks,
      (r) => _lastBooks = r,
    );
  }

  /// Show / film / anime recommendations. Picks the upstream service by
  /// the user's most-frequent sub-type:
  ///   - anime  → Jikan /top/anime
  ///   - movie  → TMDB /discover/movie
  ///   - tvShow → TMDB /discover/tv
  ///   - none   → TMDB /discover/tv
  Future<List<RecommendationItem>> forShows() async {
    final shows = _media.getAllShows();
    final topSub = _topShowSubType(shows);
    return _withFallback(
      () => _fetchShowsFor(topSub),
      () => _lastShows,
      (r) => _lastShows = r,
    );
  }

  Future<List<RecommendationItem>> _fetchShowsFor(ShowSubType? sub) {
    return switch (sub) {
      ShowSubType.anime => _jikan.fetchTopAnime(),
      ShowSubType.movie => _tmdb.fetchPopularMovies(),
      ShowSubType.tvShow || null => _tmdb.fetchPopularTvShows(),
    };
  }

  /// Song recommendations from Last.fm. Uses tag.gettoptracks with the
  /// user's most-saved genre when available; falls back to chart.gettoptracks
  /// (global top) when the user has no songs or no genre tags yet.
  Future<List<RecommendationItem>> forSongs() async {
    final genre = _topGenre(_media.getAllSongs().map((s) => s.genre));
    return _withFallback(
      () => genre != null
          ? _lastFm.fetchByTag(genre)
          : _lastFm.fetchTopTracks(),
      () => _lastSongs,
      (r) => _lastSongs = r,
    );
  }

  // ---------- helpers ----------

  Future<List<RecommendationItem>> _withFallback(
    Future<List<RecommendationItem>> Function() fetcher,
    List<RecommendationItem>? Function() readCache,
    void Function(List<RecommendationItem>) writeCache,
  ) async {
    try {
      final result = await fetcher();
      writeCache(result);
      return result;
    } catch (_) {
      final cached = readCache();
      if (cached != null) return cached;
      rethrow;
    }
  }

  static String? _topGenre(Iterable<String?> genres) {
    final counts = <String, int>{};
    for (final g in genres) {
      final t = g?.trim();
      if (t == null || t.isEmpty) continue;
      counts[t] = (counts[t] ?? 0) + 1;
    }
    if (counts.isEmpty) return null;
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  static ShowSubType? _topShowSubType(List<ShowModel> shows) {
    if (shows.isEmpty) return null;
    final counts = <ShowSubType, int>{};
    for (final s in shows) {
      counts[s.subType] = (counts[s.subType] ?? 0) + 1;
    }
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }
}

final recommendationRepositoryProvider =
    Provider<RecommendationRepository>((ref) {
  return RecommendationRepository(
    ref.watch(openLibraryServiceProvider),
    ref.watch(tmdbServiceProvider),
    ref.watch(jikanServiceProvider),
    ref.watch(lastFmServiceProvider),
    ref.watch(mediaRepositoryProvider),
  );
});

final bookRecommendationsProvider =
    FutureProvider.autoDispose<List<RecommendationItem>>(
  (ref) => ref.watch(recommendationRepositoryProvider).forBooks(),
);

final showRecommendationsProvider =
    FutureProvider.autoDispose<List<RecommendationItem>>(
  (ref) => ref.watch(recommendationRepositoryProvider).forShows(),
);

final songRecommendationsProvider =
    FutureProvider.autoDispose<List<RecommendationItem>>(
  (ref) => ref.watch(recommendationRepositoryProvider).forSongs(),
);
