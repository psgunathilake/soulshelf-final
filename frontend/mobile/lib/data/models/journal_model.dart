import 'dart:convert';

import 'media_model.dart' show parseApiDate;

/// Recursively coerces nested maps to `Map<String, dynamic>`.
///
/// Hive returns maps as `Map<dynamic, dynamic>` on read-back. Code that
/// expects `Map<String, dynamic>` (e.g. `flutter_quill`'s `Document.fromJson`,
/// which iterates Quill Delta ops) will throw a type-cast error if we hand
/// it the raw structure. We normalize once at deserialization.
dynamic _deepStringKeyed(dynamic v) {
  if (v is Map) {
    return v.map<String, dynamic>(
      (k, val) => MapEntry(k.toString(), _deepStringKeyed(val)),
    );
  }
  if (v is List) {
    return v.map(_deepStringKeyed).toList();
  }
  return v;
}

class JournalTodo {
  final String id;
  final String text;
  final bool done;

  const JournalTodo({
    required this.id,
    required this.text,
    this.done = false,
  });

  Map<String, dynamic> toJson() => {'id': id, 'text': text, 'done': done};

  factory JournalTodo.fromJson(Map<String, dynamic> j) => JournalTodo(
        id: j['id'] as String,
        text: j['text'] as String,
        done: (j['done'] as bool?) ?? false,
      );

  JournalTodo copyWith({String? id, String? text, bool? done}) => JournalTodo(
        id: id ?? this.id,
        text: text ?? this.text,
        done: done ?? this.done,
      );
}

/// A journal entry for a specific calendar day (keyed by `yyyy-MM-dd`).
class JournalModel {
  /// Quill Delta as a list of ops. Stored as-is for flutter_quill.
  final List<dynamic>? content;

  /// Short free-text note shown on the day-view header (separate from the
  /// rich Quill content). Phase-1 extension to SPEC §5.2.
  final String? shortNote;

  final int mood;
  final int stress;
  final String? weather;
  final int waterCups;
  final List<JournalTodo> todos;
  final List<String> birthdays;
  final String? linkedMediaId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const JournalModel({
    this.content,
    this.shortNote,
    this.mood = 0,
    this.stress = 0,
    this.weather,
    this.waterCups = 0,
    this.todos = const [],
    this.birthdays = const [],
    this.linkedMediaId,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'content': content,
        'shortNote': shortNote,
        'mood': mood,
        'stress': stress,
        'weather': weather,
        'waterCups': waterCups,
        'todos': todos.map((t) => t.toJson()).toList(),
        'birthdays': birthdays,
        'linkedMediaId': linkedMediaId,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
      };

  Map<String, dynamic> toHive() => toJson();

  factory JournalModel.fromJson(Map<String, dynamic> j) => JournalModel(
        content: j['content'] == null
            ? null
            : _deepStringKeyed(j['content']) as List<dynamic>,
        shortNote: j['shortNote'] as String?,
        mood: (j['mood'] as int?) ?? 0,
        stress: (j['stress'] as int?) ?? 0,
        weather: j['weather'] as String?,
        waterCups: (j['waterCups'] as int?) ?? 0,
        todos: ((j['todos'] as List?) ?? const [])
            .map((e) => JournalTodo.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        birthdays: ((j['birthdays'] as List?) ?? const [])
            .map((e) => e as String)
            .toList(),
        linkedMediaId: j['linkedMediaId'] as String?,
        createdAt: j['createdAt'] == null
            ? DateTime.now()
            : DateTime.fromMillisecondsSinceEpoch(j['createdAt'] as int),
        updatedAt: j['updatedAt'] == null
            ? DateTime.now()
            : DateTime.fromMillisecondsSinceEpoch(j['updatedAt'] as int),
      );

  factory JournalModel.fromHive(Map map) =>
      JournalModel.fromJson(Map<String, dynamic>.from(map));

  /// Wire shape for `PUT /api/journals/{date}`. Note `shortNote` is NOT
  /// sent — it's a Phase-1 extension that doesn't exist in the
  /// `journals` table. The repository preserves it cache-side via
  /// merge-on-refresh.
  Map<String, dynamic> toApi() => {
        'content': jsonEncode(content ?? []),
        'mood': mood,
        'stress': stress,
        if (weather != null) 'weather': weather,
        'water_cups': waterCups,
        'todos': todos.map((t) => t.toJson()).toList(),
        'birthdays': birthdays,
        if (linkedMediaId != null)
          'linked_media_id': int.tryParse(linkedMediaId!),
      };

  factory JournalModel.fromApi(Map<String, dynamic> j) {
    final rawContent = j['content'];
    List<dynamic>? parsedContent;
    if (rawContent is String && rawContent.isNotEmpty) {
      final decoded = jsonDecode(rawContent);
      parsedContent = decoded is List ? decoded : null;
    } else if (rawContent is List) {
      parsedContent = rawContent;
    }

    return JournalModel(
      content: parsedContent == null
          ? null
          : _deepStringKeyed(parsedContent) as List<dynamic>,
      shortNote: null,
      mood: (j['mood'] as int?) ?? 0,
      stress: (j['stress'] as int?) ?? 0,
      weather: j['weather'] as String?,
      waterCups: (j['water_cups'] as int?) ?? 0,
      todos: ((j['todos'] as List?) ?? const [])
          .map((e) => JournalTodo.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      birthdays: ((j['birthdays'] as List?) ?? const [])
          .map((e) => e as String)
          .toList(),
      linkedMediaId: j['linked_media_id']?.toString(),
      createdAt: parseApiDate(j['created_at']) ?? DateTime.now(),
      updatedAt: parseApiDate(j['updated_at']) ?? DateTime.now(),
    );
  }

  JournalModel copyWith({
    List<dynamic>? content,
    String? shortNote,
    int? mood,
    int? stress,
    String? weather,
    int? waterCups,
    List<JournalTodo>? todos,
    List<String>? birthdays,
    String? linkedMediaId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      JournalModel(
        content: content ?? this.content,
        shortNote: shortNote ?? this.shortNote,
        mood: mood ?? this.mood,
        stress: stress ?? this.stress,
        weather: weather ?? this.weather,
        waterCups: waterCups ?? this.waterCups,
        todos: todos ?? this.todos,
        birthdays: birthdays ?? this.birthdays,
        linkedMediaId: linkedMediaId ?? this.linkedMediaId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
