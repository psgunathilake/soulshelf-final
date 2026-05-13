/// Slim cross-source recommendation tile. Same shape across the four
/// upstream APIs (Open Library, TMDB, Jikan, Last.fm) so the UI renders
/// the horizontal strip identically regardless of where the item came from.
class RecommendationItem {
  final String title;
  final String? subtitle;
  final String? coverUrl;
  final String? externalUrl;
  final String source;

  const RecommendationItem({
    required this.title,
    this.subtitle,
    this.coverUrl,
    this.externalUrl,
    required this.source,
  });
}
