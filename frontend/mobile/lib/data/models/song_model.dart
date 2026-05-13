import 'media_model.dart';

class SongModel extends MediaModel {
  final String? singer;
  final String? composer;
  final String? lyricist;
  final String? lyrics;
  final String? link;
  final String? language;
  final String? mood;
  final DateTime? releaseDate;
  final bool favorite;

  const SongModel({
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
    this.singer,
    this.composer,
    this.lyricist,
    this.lyrics,
    this.link,
    this.language,
    this.mood,
    this.releaseDate,
    this.favorite = false,
  }) : super(category: MediaCategory.song);

  @override
  Map<String, dynamic> toJson() => {
        ...buildBaseMediaJson(this),
        'singer': singer,
        'composer': composer,
        'lyricist': lyricist,
        'lyrics': lyrics,
        'link': link,
        'language': language,
        'mood': mood,
        'releaseDate': releaseDate?.millisecondsSinceEpoch,
        'favorite': favorite,
      };

  factory SongModel.fromJson(Map<String, dynamic> j) {
    final b = parseBaseMediaJson(j);
    return SongModel(
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
      singer: j['singer'] as String?,
      composer: j['composer'] as String?,
      lyricist: j['lyricist'] as String?,
      lyrics: j['lyrics'] as String?,
      link: j['link'] as String?,
      language: j['language'] as String?,
      mood: j['mood'] as String?,
      releaseDate: j['releaseDate'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(j['releaseDate'] as int),
      favorite: (j['favorite'] as bool?) ?? false,
    );
  }

  factory SongModel.fromHive(Map map) =>
      SongModel.fromJson(Map<String, dynamic>.from(map));

  Map<String, dynamic> toApi() => {
        'title': title,
        'category': 'song',
        'genre': genre ?? '',
        'rating': rating,
        'status': status.name,
        if (reflection != null) 'reflection': reflection,
        if (startDate != null)
          'start_date': startDate!.toIso8601String().substring(0, 10),
        if (endDate != null)
          'end_date': endDate!.toIso8601String().substring(0, 10),
        'details': {
          if (singer != null) 'singer': singer,
          if (composer != null) 'composer': composer,
          if (lyricist != null) 'lyricist': lyricist,
          if (lyrics != null) 'lyrics': lyrics,
          if (link != null) 'link': link,
          if (language != null) 'language': language,
          if (mood != null) 'mood': mood,
          if (releaseDate != null)
            'releaseDate':
                releaseDate!.toIso8601String().substring(0, 10),
          'favorite': favorite,
        },
      };

  factory SongModel.fromApi(Map<String, dynamic> j) {
    final details = (j['details'] as Map?)?.cast<String, dynamic>() ?? const {};
    return SongModel(
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
      singer: details['singer'] as String?,
      composer: details['composer'] as String?,
      lyricist: details['lyricist'] as String?,
      lyrics: details['lyrics'] as String?,
      link: details['link'] as String?,
      language: details['language'] as String?,
      mood: details['mood'] as String?,
      releaseDate: parseApiDate(details['releaseDate']),
      favorite: (details['favorite'] as bool?) ?? false,
    );
  }

  SongModel copyWith({
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
    String? singer,
    String? composer,
    String? lyricist,
    String? lyrics,
    String? link,
    String? language,
    String? mood,
    DateTime? releaseDate,
    bool? favorite,
  }) =>
      SongModel(
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
        singer: singer ?? this.singer,
        composer: composer ?? this.composer,
        lyricist: lyricist ?? this.lyricist,
        lyrics: lyrics ?? this.lyrics,
        link: link ?? this.link,
        language: language ?? this.language,
        mood: mood ?? this.mood,
        releaseDate: releaseDate ?? this.releaseDate,
        favorite: favorite ?? this.favorite,
      );
}
