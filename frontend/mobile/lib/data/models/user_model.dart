class UserModel {
  final String uid;
  final String name;
  final String email;
  final DateTime? emailVerifiedAt;
  final String? photoUrl;
  final String? headerUrl;
  final String? bio;
  final String? pinHash;
  final Map<String, dynamic> preferences;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.emailVerifiedAt,
    this.photoUrl,
    this.headerUrl,
    this.bio,
    this.pinHash,
    this.preferences = const {},
  });

  bool get emailVerified => emailVerifiedAt != null;

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'name': name,
        'email': email,
        'emailVerifiedAt': emailVerifiedAt?.toIso8601String(),
        'photoUrl': photoUrl,
        'headerUrl': headerUrl,
        'bio': bio,
        'pinHash': pinHash,
        'preferences': preferences,
      };

  Map<String, dynamic> toHive() => toJson();

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        uid: j['uid'] as String,
        name: j['name'] as String? ?? '',
        email: j['email'] as String? ?? '',
        emailVerifiedAt: _parseDate(j['emailVerifiedAt']),
        photoUrl: j['photoUrl'] as String?,
        headerUrl: j['headerUrl'] as String?,
        bio: j['bio'] as String?,
        pinHash: j['pinHash'] as String?,
        preferences: _parsePreferences(j['preferences']),
      );

  factory UserModel.fromHive(Map map) =>
      UserModel.fromJson(Map<String, dynamic>.from(map));

  /// Wire shape for `PUT /api/user`. Email / photoUrl / headerUrl / pinHash
  /// are NOT editable through this endpoint — uploads use the dedicated
  /// `/user/avatar` and `/user/header` routes; PIN endpoints land in 3.9.
  Map<String, dynamic> toApi() => {
        'name': name,
        'bio': bio,
        // Send null for empty preferences — Laravel/MySQL can't tell `{}`
        // from `[]` and round-trips empty objects as JSON arrays, which
        // then breaks `fromApi` on the next read.
        'preferences': preferences.isEmpty ? null : preferences,
      };

  /// Build a UserModel from the snake_case JSON shape returned by the
  /// Laravel /api/auth/* endpoints.
  factory UserModel.fromApi(Map<String, dynamic> j) => UserModel(
        uid: j['id'].toString(),
        name: j['name'] as String? ?? '',
        email: j['email'] as String? ?? '',
        emailVerifiedAt: _parseDate(j['email_verified_at']),
        photoUrl: j['photo_url'] as String?,
        headerUrl: j['header_url'] as String?,
        bio: j['bio'] as String?,
        // pin_hash is server-side only and stripped from the API response;
        // the client maintains its own cached copy in profileBox['pinHash'].
        pinHash: null,
        preferences: _parsePreferences(j['preferences']),
      );

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    DateTime? emailVerifiedAt,
    String? photoUrl,
    String? headerUrl,
    String? bio,
    String? pinHash,
    Map<String, dynamic>? preferences,
  }) =>
      UserModel(
        uid: uid ?? this.uid,
        name: name ?? this.name,
        email: email ?? this.email,
        emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
        photoUrl: photoUrl ?? this.photoUrl,
        headerUrl: headerUrl ?? this.headerUrl,
        bio: bio ?? this.bio,
        pinHash: pinHash ?? this.pinHash,
        preferences: preferences ?? this.preferences,
      );

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  /// Tolerant of Laravel's empty-object → empty-array quirk: a `[]` from
  /// the wire is treated as no preferences. Anything that isn't a Map
  /// becomes an empty map.
  static Map<String, dynamic> _parsePreferences(dynamic v) {
    if (v is Map) return Map<String, dynamic>.from(v);
    return const <String, dynamic>{};
  }
}
