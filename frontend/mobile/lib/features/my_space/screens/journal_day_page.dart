import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'package:soulshelf/data/models/journal_model.dart';
import 'package:soulshelf/data/repositories/journal_repository.dart';
import 'daily_planner_page.dart';
import 'journal_list_page.dart';

class JournalDayPage extends ConsumerStatefulWidget {
  final DateTime date;

  const JournalDayPage({super.key, required this.date});

  @override
  ConsumerState<JournalDayPage> createState() => _JournalDayPageState();
}

class _JournalDayPageState extends ConsumerState<JournalDayPage> {

  bool isEditing = true;

  int moodIndex = -1;
  int stressLevel = -1;
  int weatherIndex = -1;
  int waterCups = 0;

  List<dynamic>? journalJson;

  final TextEditingController noteController = TextEditingController();
  final TextEditingController newTaskController = TextEditingController();
  final TextEditingController newBirthdayController = TextEditingController();

  final List<Map<String, dynamic>> todoList = [];
  final List<String> birthdayList = [];

  final moods = [
    Icons.sentiment_very_satisfied,
    Icons.sentiment_satisfied,
    Icons.sentiment_neutral,
    Icons.sentiment_dissatisfied,
  ];

  /// Parallel to weatherIcons. Kept as strings to match SPEC §5.2.
  final weatherKeys = ['sunny', 'cloudy', 'thunderstorm', 'rainy'];
  final weatherIcons = [
    Icons.wb_sunny,
    Icons.cloud,
    Icons.thunderstorm,
    Icons.umbrella,
  ];

  @override
  void initState() {
    super.initState();
    loadSavedDay();
  }

  @override
  void dispose() {
    noteController.dispose();
    newTaskController.dispose();
    newBirthdayController.dispose();
    super.dispose();
  }

  void loadSavedDay() {
    final entry = ref.read(journalRepositoryProvider).getEntry(widget.date);
    if (entry == null) return;

    noteController.text = entry.shortNote ?? '';
    journalJson = entry.content;
    moodIndex = (entry.mood >= 1 && entry.mood <= moods.length)
        ? entry.mood - 1
        : -1;
    stressLevel = entry.stress == 0 ? -1 : entry.stress - 1;
    weatherIndex = entry.weather == null
        ? -1
        : weatherKeys.indexOf(entry.weather!);
    if (weatherIndex == -1 && entry.weather != null) {
      weatherIndex = -1;
    }
    waterCups = entry.waterCups;

    todoList
      ..clear()
      ..addAll(entry.todos.map((t) => {
            'id': t.id,
            'text': t.text,
            'done': t.done,
          }));

    birthdayList
      ..clear()
      ..addAll(entry.birthdays);

    setState(() {});
  }

  Future<void> saveDay() async {
    final repo = ref.read(journalRepositoryProvider);
    final existing = repo.getEntry(widget.date);
    final now = DateTime.now();

    final model = JournalModel(
      content: journalJson,
      shortNote:
          noteController.text.trim().isEmpty ? null : noteController.text.trim(),
      mood: moodIndex == -1 ? 0 : moodIndex + 1,
      stress: stressLevel == -1 ? 0 : stressLevel + 1,
      weather: weatherIndex == -1 ? null : weatherKeys[weatherIndex],
      waterCups: waterCups,
      todos: todoList
          .map((t) => JournalTodo(
                id: (t['id'] as String?) ?? const Uuid().v4(),
                text: (t['text'] as String?) ?? '',
                done: (t['done'] as bool?) ?? false,
              ))
          .toList(),
      birthdays: List<String>.from(birthdayList),
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    await repo.saveEntry(widget.date, model);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Journal saved')),
    );
  }

  @override
  Widget build(BuildContext context) {

    final formattedDate =
    DateFormat("EEEE, MMM d, yyyy").format(widget.date);

    return Scaffold(
      body: Stack(
        children: [

          /// BACKGROUND IMAGE
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/day_bg.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),

          /// SOFT WASH — mutes the notebook-spiral background so black
          /// text on the form cards above stays AA-readable. Without
          /// this, the busy bg fights the form and tanks contrast.
          Positioned.fill(
            child: Container(
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),

          SafeArea(
            child: Column(
              children: [

                /// HEADER — back arrow on the left, title centered, and
                /// nav icons (Daily Planner + Journal) on the right. The
                /// nav lives here instead of the bottom row so commit
                /// actions (Save/Edit) stay separate from navigation.
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back,
                              color: Colors.black),
                          tooltip: 'Back',
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Expanded(
                          child: Text(
                            "My Day",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.event_note,
                              color: Colors.black),
                          tooltip: 'Daily Planner',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const DailyPlannerPage(),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.menu_book,
                              color: Colors.black),
                          tooltip: 'Journal',
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => JournalListPage(
                                  date: widget.date,
                                  documentJson: journalJson,
                                ),
                              ),
                            );
                            if (result != null) {
                              setState(() => journalJson = result);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Text(
                            formattedDate,
                            style: const TextStyle(
                                color: Colors.black,
                                fontSize: 13,
                                fontWeight: FontWeight.bold),
                          ),

                          const SizedBox(height: 8),

                          /// NOTE
                          TextField(
                            controller: noteController,
                            enabled: isEditing,
                            style: const TextStyle(color: Colors.black),
                            maxLines: 2,
                            decoration: const InputDecoration(
                              hintText:
                              "Hi today is a good day to have a good day",
                              hintStyle: TextStyle(color: Colors.black54),
                              border: OutlineInputBorder(),
                            ),
                          ),

                          const SizedBox(height: 16),

                          /// MOOD — per-mood color pill on the selected
                          /// option so the choice reads at a glance
                          /// (green = happy, blue = sad). Replaces the
                          /// orange-only selected state.
                          const Text("Mood",
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Row(
                            children: List.generate(moods.length, (index) {
                              const moodColors = [
                                Color(0xFF4CAF50),
                                Color(0xFF8BC34A),
                                Color(0xFF9E9E9E),
                                Color(0xFF5C6BC0),
                              ];
                              final selected = moodIndex == index;
                              return Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: GestureDetector(
                                  onTap: isEditing
                                      ? () => setState(
                                          () => moodIndex = index)
                                      : null,
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 150),
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: selected
                                          ? moodColors[index]
                                              .withValues(alpha: 0.22)
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: selected
                                            ? moodColors[index]
                                            : Colors.black26,
                                        width: selected ? 2 : 1,
                                      ),
                                    ),
                                    child: Icon(
                                      moods[index],
                                      color: selected
                                          ? moodColors[index]
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 14),

                          /// STRESS — filled dots take the color of the
                          /// current level (green→amber→red), so the
                          /// overall stress reads at a glance instead of
                          /// counting black dots.
                          const Text("Stress",
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Row(
                            children: List.generate(5, (index) {
                              const stressPalette = [
                                Color(0xFF66BB6A),
                                Color(0xFFAED581),
                                Color(0xFFFFB74D),
                                Color(0xFFFF8A65),
                                Color(0xFFE53935),
                              ];
                              final filled = stressLevel >= index;
                              final tint = stressLevel >= 0
                                  ? stressPalette[stressLevel]
                                  : Colors.black26;
                              return GestureDetector(
                                onTap: isEditing
                                    ? () => setState(
                                        () => stressLevel = index)
                                    : null,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 4),
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: filled
                                        ? tint
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: filled
                                          ? tint
                                          : Colors.black26,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 14),

                          /// WEATHER — equal-width pills via Expanded.
                          /// Selected pill carries the per-weather tint.
                          const Text("Weather",
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Row(
                            children:
                                List.generate(weatherIcons.length, (index) {
                              const weatherColors = [
                                Color(0xFFFFA726),
                                Color(0xFF78909C),
                                Color(0xFF5C6BC0),
                                Color(0xFF42A5F5),
                              ];
                              final selected = weatherIndex == index;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: isEditing
                                      ? () => setState(
                                          () => weatherIndex = index)
                                      : null,
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 150),
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? weatherColors[index]
                                              .withValues(alpha: 0.18)
                                          : Colors.transparent,
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      border: Border.all(
                                        color: selected
                                            ? weatherColors[index]
                                            : Colors.black26,
                                        width: selected ? 2 : 1,
                                      ),
                                    ),
                                    child: Icon(
                                      weatherIcons[index],
                                      color: selected
                                          ? weatherColors[index]
                                          : Colors.black87,
                                      size: 26,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),

                          /// WATER TRACKER
                          const SizedBox(height: 10),
                          const Text("Water Intake",
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold)),

                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove,color: Colors.black),
                                onPressed: () {
                                  if (waterCups > 0) {
                                    setState(() => waterCups--);
                                  }
                                },
                              ),
                              Text("$waterCups cups",
                                  style: const TextStyle(color: Colors.black)),
                              IconButton(
                                icon: const Icon(Icons.add,color: Colors.black),
                                onPressed: () {
                                  setState(() => waterCups++);
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          /// BIRTHDAYS — full-width section. Stacked
                          /// above Todo (was previously side-by-side
                          /// inside a Row, which got cramped on phones).
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Birthdays",
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold),
                              ),
                              if (birthdayList.isEmpty && !isEditing)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 6),
                                  child: Text(
                                    "No birthdays yet",
                                    style: TextStyle(color: Colors.black54),
                                  ),
                                ),
                              ...birthdayList.asMap().entries.map((entry) {
                                final i = entry.key;
                                final name = entry.value;
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                  title: Text(name,
                                      style: const TextStyle(
                                          color: Colors.black)),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.close,
                                        color: Colors.red),
                                    onPressed: isEditing
                                        ? () => setState(() =>
                                            birthdayList.removeAt(i))
                                        : null,
                                  ),
                                );
                              }),
                              if (isEditing)
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: newBirthdayController,
                                        style: const TextStyle(
                                            color: Colors.black),
                                        decoration: const InputDecoration(
                                          hintText: "Add birthday",
                                          hintStyle: TextStyle(
                                              color: Colors.black54),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add,
                                          color: Colors.black),
                                      onPressed: () {
                                        if (newBirthdayController
                                            .text.isNotEmpty) {
                                          setState(() {
                                            birthdayList.add(
                                                newBirthdayController.text);
                                            newBirthdayController.clear();
                                          });
                                        }
                                      },
                                    ),
                                  ],
                                ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          /// TODO — full-width section.
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Todo",
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold),
                              ),
                              if (todoList.isEmpty && !isEditing)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 6),
                                  child: Text(
                                    "No tasks yet",
                                    style: TextStyle(color: Colors.black54),
                                  ),
                                ),
                              ...todoList.asMap().entries.map((entry) {
                                final i = entry.key;
                                final task = entry.value;
                                return Row(
                                  children: [
                                    Checkbox(
                                      value: task["done"],
                                      onChanged: isEditing
                                          ? (val) => setState(
                                              () => task["done"] = val)
                                          : null,
                                    ),
                                    Expanded(
                                      child: Text(
                                        task["text"],
                                        style: TextStyle(
                                          color: Colors.black,
                                          decoration: task["done"]
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close,
                                          color: Colors.red),
                                      onPressed: isEditing
                                          ? () => setState(
                                              () => todoList.removeAt(i))
                                          : null,
                                    ),
                                  ],
                                );
                              }),
                              if (isEditing)
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: newTaskController,
                                        style: const TextStyle(
                                            color: Colors.black),
                                        decoration: const InputDecoration(
                                          hintText: "New task",
                                          hintStyle: TextStyle(
                                              color: Colors.black54),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add,
                                          color: Colors.black),
                                      onPressed: () {
                                        if (newTaskController
                                            .text.isNotEmpty) {
                                          setState(() {
                                            todoList.add({
                                              "text":
                                                  newTaskController.text,
                                              "done": false
                                            });
                                            newTaskController.clear();
                                          });
                                        }
                                      },
                                    ),
                                  ],
                                ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          const SizedBox(height: 12),

                          /// SAVE / EDIT TOGGLE — single primary button.
                          /// In edit mode it commits + drops into read mode;
                          /// in read mode it re-enters edit mode. Replaces
                          /// the prior two-button row, which was ambiguous
                          /// (both visible at once with no state cue).
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 6),
                                  decoration: BoxDecoration(
                                    color: isEditing
                                        ? const Color(0xFF7E6B91)
                                        : Colors.white.withValues(alpha: 0.55),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 8,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      if (isEditing) {
                                        saveDay();
                                        setState(() => isEditing = false);
                                      } else {
                                        setState(() => isEditing = true);
                                      }
                                    },
                                    icon: Icon(
                                      isEditing
                                          ? Icons.check_rounded
                                          : Icons.edit_outlined,
                                      color: isEditing
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                    label: Text(
                                      isEditing ? 'Save' : 'Edit',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isEditing
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      side: BorderSide.none,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}