import 'media_model.dart';

class BookModel extends MediaModel {
  final String? author;
  final int? pages;
  final String? link;

  const BookModel({
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
    this.author,
    this.pages,
    this.link,
  }) : super(category: MediaCategory.book);

  @override
  Map<String, dynamic> toJson() => {
        ...buildBaseMediaJson(this),
        'author': author,
        'pages': pages,
        'link': link,
      };

  factory BookModel.fromJson(Map<String, dynamic> j) {
    final b = parseBaseMediaJson(j);
    return BookModel(
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
      author: j['author'] as String?,
      pages: j['pages'] as int?,
      link: j['link'] as String?,
    );
  }

  factory BookModel.fromHive(Map map) =>
      BookModel.fromJson(Map<String, dynamic>.from(map));

  Map<String, dynamic> toApi() => {
        'title': title,
        'category': 'book',
        'genre': genre ?? '',
        'rating': rating,
        'status': status.name,
        if (reflection != null) 'reflection': reflection,
        if (startDate != null)
          'start_date': startDate!.toIso8601String().substring(0, 10),
        if (endDate != null)
          'end_date': endDate!.toIso8601String().substring(0, 10),
        'details': {
          if (author != null) 'author': author,
          if (pages != null) 'pages': pages,
          if (link != null) 'link': link,
        },
      };

  factory BookModel.fromApi(Map<String, dynamic> j) {
    final details = (j['details'] as Map?)?.cast<String, dynamic>() ?? const {};
    return BookModel(
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
      author: details['author'] as String?,
      pages: details['pages'] as int?,
      link: details['link'] as String?,
    );
  }

  BookModel copyWith({
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
    String? author,
    int? pages,
    String? link,
  }) =>
      BookModel(
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
        author: author ?? this.author,
        pages: pages ?? this.pages,
        link: link ?? this.link,
      );
}
