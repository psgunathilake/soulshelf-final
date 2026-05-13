import 'media_model.dart' show parseApiDate;

class CollectionModel {
  final String id;
  final String name;
  final String? description;
  final String? coverUrl;
  final List<String> mediaIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CollectionModel({
    required this.id,
    required this.name,
    this.description,
    this.coverUrl,
    this.mediaIds = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'coverUrl': coverUrl,
        'mediaIds': mediaIds,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
      };

  Map<String, dynamic> toHive() => toJson();

  factory CollectionModel.fromJson(Map<String, dynamic> j) => CollectionModel(
        id: j['id'] as String,
        name: j['name'] as String,
        description: j['description'] as String?,
        coverUrl: j['coverUrl'] as String?,
        mediaIds: ((j['mediaIds'] as List?) ?? const [])
            .map((e) => e as String)
            .toList(),
        createdAt: j['createdAt'] == null
            ? DateTime.now()
            : DateTime.fromMillisecondsSinceEpoch(j['createdAt'] as int),
        updatedAt: j['updatedAt'] == null
            ? DateTime.now()
            : DateTime.fromMillisecondsSinceEpoch(j['updatedAt'] as int),
      );

  factory CollectionModel.fromHive(Map map) =>
      CollectionModel.fromJson(Map<String, dynamic>.from(map));

  /// Wire shape for `POST /api/collections` and `PUT /api/collections/{id}`.
  /// `mediaIds` is NOT sent — the server manages membership via the pivot
  /// endpoints (`POST /api/collections/{id}/media`).
  Map<String, dynamic> toApi() => {
        'name': name,
        if (description != null) 'description': description,
        if (coverUrl != null) 'cover_url': coverUrl,
      };

  /// Parses both list-response rows (no `media` array) and show-response
  /// rows (eager-loaded `media: [...]`). When `media` is absent, mediaIds
  /// defaults to `const []`; the repository's refresh-merge preserves any
  /// previously-loaded membership in cache.
  factory CollectionModel.fromApi(Map<String, dynamic> j) {
    final mediaList = (j['media'] as List?)?.cast<Map<String, dynamic>>();
    return CollectionModel(
      id: j['id'].toString(),
      name: j['name'] as String,
      description: j['description'] as String?,
      coverUrl: j['cover_url'] as String?,
      mediaIds:
          mediaList?.map((m) => m['id'].toString()).toList() ?? const [],
      createdAt: parseApiDate(j['created_at']) ?? DateTime.now(),
      updatedAt: parseApiDate(j['updated_at']) ?? DateTime.now(),
    );
  }

  CollectionModel copyWith({
    String? id,
    String? name,
    String? description,
    String? coverUrl,
    List<String>? mediaIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      CollectionModel(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        coverUrl: coverUrl ?? this.coverUrl,
        mediaIds: mediaIds ?? this.mediaIds,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
