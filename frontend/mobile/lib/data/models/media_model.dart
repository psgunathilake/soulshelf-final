enum MediaCategory { book, song, show }

enum ShowSubType { movie, tvShow, anime }

extension ShowSubTypeWire on ShowSubType {
  String get wire => switch (this) {
        ShowSubType.movie => 'movie',
        ShowSubType.tvShow => 'tv_show',
        ShowSubType.anime => 'anime',
      };

  static ShowSubType fromWire(String s) => switch (s) {
        'movie' => ShowSubType.movie,
        'tv_show' => ShowSubType.tvShow,
        'anime' => ShowSubType.anime,
        _ => throw ArgumentError('Unknown ShowSubType: $s'),
      };
}

enum MediaStatus { planned, ongoing, completed }

/// Shared fields for Books, Songs, and Shows. Subclasses add their own
/// specific fields (e.g. author, singer, director).
abstract class MediaModel {
  final String id;
  final String title;
  final MediaCategory category;
  final String? genre;
  final int rating;
  final MediaStatus status;
  final String? coverUrl;
  final String? reflection;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MediaModel({
    required this.id,
    required this.title,
    required this.category,
    this.genre,
    this.rating = 0,
    this.status = MediaStatus.planned,
    this.coverUrl,
    this.reflection,
    this.startDate,
    this.endDate,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson();
  Map<String, dynamic> toHive() => toJson();
}

int? _toEpoch(DateTime? d) => d?.millisecondsSinceEpoch;
DateTime? _fromEpoch(dynamic v) =>
    v == null ? null : DateTime.fromMillisecondsSinceEpoch(v as int);

/// Parse a Laravel `date`-cast field. The server emits either `'YYYY-MM-DD'`
/// or a full ISO-8601 timestamp depending on cast configuration; both are
/// valid input to `DateTime.parse`.
DateTime? parseApiDate(dynamic v) {
  if (v == null) return null;
  final s = v as String;
  return DateTime.parse(s);
}

Map<String, dynamic> buildBaseMediaJson(MediaModel m) => {
      'id': m.id,
      'title': m.title,
      'category': m.category.name,
      'genre': m.genre,
      'rating': m.rating,
      'status': m.status.name,
      'coverUrl': m.coverUrl,
      'reflection': m.reflection,
      'startDate': _toEpoch(m.startDate),
      'endDate': _toEpoch(m.endDate),
      'createdAt': m.createdAt.millisecondsSinceEpoch,
      'updatedAt': m.updatedAt.millisecondsSinceEpoch,
    };

({
  String id,
  String title,
  String? genre,
  int rating,
  MediaStatus status,
  String? coverUrl,
  String? reflection,
  DateTime? startDate,
  DateTime? endDate,
  DateTime createdAt,
  DateTime updatedAt,
}) parseBaseMediaJson(Map<String, dynamic> j) => (
      id: j['id'] as String,
      title: j['title'] as String,
      genre: j['genre'] as String?,
      rating: (j['rating'] as int?) ?? 0,
      status: MediaStatus.values.byName(
          (j['status'] as String?) ?? MediaStatus.planned.name),
      coverUrl: j['coverUrl'] as String?,
      reflection: j['reflection'] as String?,
      startDate: _fromEpoch(j['startDate']),
      endDate: _fromEpoch(j['endDate']),
      createdAt: _fromEpoch(j['createdAt']) ?? DateTime.now(),
      updatedAt: _fromEpoch(j['updatedAt']) ?? DateTime.now(),
    );
