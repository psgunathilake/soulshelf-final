import 'media_model.dart' show parseApiDate;

/// Daily planner for a specific calendar day (keyed by `yyyy-MM-dd`).
class PlannerModel {
  /// Map of hour slot (e.g. `"05"`..`"22"`) to free-text entry.
  final Map<String, String> schedule;
  final List<String> priorities;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PlannerModel({
    this.schedule = const {},
    this.priorities = const [],
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'schedule': schedule,
        'priorities': priorities,
        'notes': notes,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
      };

  Map<String, dynamic> toHive() => toJson();

  factory PlannerModel.fromJson(Map<String, dynamic> j) => PlannerModel(
        schedule: Map<String, String>.from(j['schedule'] as Map? ?? const {}),
        priorities: ((j['priorities'] as List?) ?? const [])
            .map((e) => e as String)
            .toList(),
        notes: j['notes'] as String?,
        createdAt: j['createdAt'] == null
            ? DateTime.now()
            : DateTime.fromMillisecondsSinceEpoch(j['createdAt'] as int),
        updatedAt: j['updatedAt'] == null
            ? DateTime.now()
            : DateTime.fromMillisecondsSinceEpoch(j['updatedAt'] as int),
      );

  factory PlannerModel.fromHive(Map map) =>
      PlannerModel.fromJson(Map<String, dynamic>.from(map));

  Map<String, dynamic> toApi() => {
        'schedule': schedule,
        'priorities': priorities,
        if (notes != null) 'notes': notes,
      };

  factory PlannerModel.fromApi(Map<String, dynamic> j) => PlannerModel(
        schedule: Map<String, String>.from(
          (j['schedule'] as Map?)?.map(
                (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
              ) ??
              const {},
        ),
        priorities: ((j['priorities'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        notes: j['notes'] as String?,
        createdAt: parseApiDate(j['created_at']) ?? DateTime.now(),
        updatedAt: parseApiDate(j['updated_at']) ?? DateTime.now(),
      );

  PlannerModel copyWith({
    Map<String, String>? schedule,
    List<String>? priorities,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      PlannerModel(
        schedule: schedule ?? this.schedule,
        priorities: priorities ?? this.priorities,
        notes: notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
