import 'media_model.dart';

class ShowModel extends MediaModel {
  final ShowSubType subType;
  final String? director;
  final int? seasons;
  final int? episodes;
  final String? studio;
  final String? platform;
  final String? moodAfterWatching;
  final String? link;

  const ShowModel({
    required super.id,
    required super.title,
    super.genre,
    super.rating,
    super.status,
    super.coverUrl,
    super.reflection,
    super.startDate,
    super.endDate,
    required super.createdAt,
    required super.updatedAt,
    required this.subType,
    this.director,
    this.seasons,
    this.episodes,
    this.studio,
    this.platform,
    this.moodAfterWatching,
    this.link,
  }) : super(category: MediaCategory.show);

  @override
  Map<String, dynamic> toJson() => {
        ...buildBaseMediaJson(this),
        'subType': subType.wire,
        'director': director,
        'seasons': seasons,
        'episodes': episodes,
        'studio': studio,
        'platform': platform,
        'moodAfterWatching': moodAfterWatching,
        'link': link,
      };

  factory ShowModel.fromJson(Map<String, dynamic> j) {
    final b = parseBaseMediaJson(j);
    return ShowModel(
      id: b.id,
      title: b.title,
      genre: b.genre,
      rating: b.rating,
      status: b.status,
      coverUrl: b.coverUrl,
      reflection: b.reflection,
      startDate: b.startDate,
      endDate: b.endDate,
      createdAt: b.createdAt,
      updatedAt: b.updatedAt,
      subType: ShowSubTypeWire.fromWire(j['subType'] as String),
      director: j['director'] as String?,
      seasons: j['seasons'] as int?,
      episodes: j['episodes'] as int?,
      studio: j['studio'] as String?,
      platform: j['platform'] as String?,
      moodAfterWatching: j['moodAfterWatching'] as String?,
      link: j['link'] as String?,
    );
  }

  factory ShowModel.fromHive(Map map) =>
      ShowModel.fromJson(Map<String, dynamic>.from(map));

  Map<String, dynamic> toApi() => {
        'title': title,
        'category': 'show',
        'sub_type': subType.wire,
        'genre': genre ?? '',
        'rating': rating,
        'status': status.name,
        if (reflection != null) 'reflection': reflection,
        if (startDate != null)
          'start_date': startDate!.toIso8601String().substring(0, 10),
        if (endDate != null)
          'end_date': endDate!.toIso8601String().substring(0, 10),
        'details': {
          if (director != null) 'director': director,
          if (seasons != null) 'seasons': seasons,
          if (episodes != null) 'episodes': episodes,
          if (studio != null) 'studio': studio,
          if (platform != null) 'platform': platform,
          if (moodAfterWatching != null) 'moodAfterWatching': moodAfterWatching,
          if (link != null) 'link': link,
        },
      };

  factory ShowModel.fromApi(Map<String, dynamic> j) {
    final details = (j['details'] as Map?)?.cast<String, dynamic>() ?? const {};
    return ShowModel(
      id: j['id'].toString(),
      title: j['title'] as String,
      genre: j['genre'] as String?,
      rating: (j['rating'] as int?) ?? 0,
      status: MediaStatus.values.byName(j['status'] as String),
      coverUrl: j['cover_url'] as String?,
      reflection: j['reflection'] as String?,
      startDate: parseApiDate(j['start_date']),
      endDate: parseApiDate(j['end_date']),
      createdAt: DateTime.parse(j['created_at'] as String),
      updatedAt: DateTime.parse(j['updated_at'] as String),
      subType: ShowSubTypeWire.fromWire(j['sub_type'] as String),
      director: details['director'] as String?,
      seasons: details['seasons'] as int?,
      episodes: details['episodes'] as int?,
      studio: details['studio'] as String?,
      platform: details['platform'] as String?,
      moodAfterWatching: details['moodAfterWatching'] as String?,
      link: details['link'] as String?,
    );
  }

  ShowModel copyWith({
    String? id,
    String? title,
    String? genre,
    int? rating,
    MediaStatus? status,
    String? coverUrl,
    String? reflection,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    ShowSubType? subType,
    String? director,
    int? seasons,
    int? episodes,
    String? studio,
    String? platform,
    String? moodAfterWatching,
    String? link,
  }) =>
      ShowModel(
        id: id ?? this.id,
        title: title ?? this.title,
        genre: genre ?? this.genre,
        rating: rating ?? this.rating,
        status: status ?? this.status,
        coverUrl: coverUrl ?? this.coverUrl,
        reflection: reflection ?? this.reflection,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        subType: subType ?? this.subType,
        director: director ?? this.director,
        seasons: seasons ?? this.seasons,
        episodes: episodes ?? this.episodes,
        studio: studio ?? this.studio,
        platform: platform ?? this.platform,
        moodAfterWatching: moodAfterWatching ?? this.moodAfterWatching,
        link: link ?? this.link,
      );
}
