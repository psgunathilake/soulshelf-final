import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:soulshelf/data/models/planner_model.dart';
import 'package:soulshelf/data/repositories/planner_repository.dart';

class DailyPlannerPage extends ConsumerStatefulWidget {
  const DailyPlannerPage({super.key});

  @override
  ConsumerState<DailyPlannerPage> createState() => _DailyPlannerPageState();
}

class _DailyPlannerPageState extends ConsumerState<DailyPlannerPage> {
  final Map<String, TextEditingController> scheduleControllers = {};
  final List<Map<String, dynamic>> priorities = [];
  final TextEditingController notesController = TextEditingController();
  final TextEditingController newPriorityController = TextEditingController();

  final Color textColor = const Color(0xFF4E342E);

  /// Today's plan key (yyyy-MM-dd). Fixed at open time.
  final DateTime _planDate = DateTime.now();

  /// 18 slots: 5 AM .. 10 PM. Displayed as "5:00 AM", stored under "05".
  final List<String> timeSlots = List.generate(
    18,
        (i) => DateFormat('h:00 a').format(DateTime(2025, 1, 1, 5 + i)),
  );

  String _hourKeyForIndex(int i) => (5 + i).toString().padLeft(2, '0');

  @override
  void initState() {
    super.initState();
    for (var time in timeSlots) {
      scheduleControllers[time] = TextEditingController();
    }
    _loadExistingPlan();
  }

  void _loadExistingPlan() {
    final existing = ref.read(plannerRepositoryProvider).getPlan(_planDate);
    if (existing == null) return;

    for (var i = 0; i < timeSlots.length; i++) {
      final hourKey = _hourKeyForIndex(i);
      final value = existing.schedule[hourKey];
      if (value != null) {
        scheduleControllers[timeSlots[i]]!.text = value;
      }
    }
    notesController.text = existing.notes ?? '';
    for (final p in existing.priorities) {
      priorities.add({
        'done': false,
        'controller': TextEditingController(text: p),
      });
    }
  }

  @override
  void dispose() {
    for (var c in scheduleControllers.values) {
      c.dispose();
    }
    for (final p in priorities) {
      (p['controller'] as TextEditingController).dispose();
    }
    notesController.dispose();
    newPriorityController.dispose();
    super.dispose();
  }

  Future<void> _savePlan() async {
    final schedule = <String, String>{};
    for (var i = 0; i < timeSlots.length; i++) {
      final text = scheduleControllers[timeSlots[i]]!.text.trim();
      if (text.isNotEmpty) {
        schedule[_hourKeyForIndex(i)] = text;
      }
    }

    final priorityTexts = priorities
        .map((p) => (p['controller'] as TextEditingController).text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final existing = ref.read(plannerRepositoryProvider).getPlan(_planDate);
    final now = DateTime.now();
    final plan = PlannerModel(
      schedule: schedule,
      priorities: priorityTexts,
      notes: notesController.text.trim().isEmpty
          ? null
          : notesController.text.trim(),
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    await ref.read(plannerRepositoryProvider).savePlan(_planDate, plan);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Plan saved')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /// background image behind AppBar
      extendBodyBehindAppBar: true,


      /// GLASS HEADER
      appBar: AppBar(
        title: Text(
          "Daily Plan",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        leading: BackButton(color: textColor),

        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,

        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              color: Colors.white.withValues(alpha: 0.25),
            ),
          ),
        ),
      ),

      body: Stack(
        children: [

          /// BACKGROUND IMAGE
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/daily_planner_bg.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),

          /// LIGHT OVERLAY
          Container(
            color: Colors.white.withValues(alpha: 0.35),
          ),

          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  "Schedule",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),

                const SizedBox(height: 12),

                /// TIME SCHEDULE
                Column(
                  children: timeSlots.map((time) {
                    return Row(
                      children: [
                        SizedBox(
                          width: 70,
                          child: Text(
                            time,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: scheduleControllers[time],
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: const InputDecoration(
                              border: UnderlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                /// PRIORITIES
                Text(
                  "Priorities",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),

                ...priorities.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;

                  return Row(
                    children: [
                      Checkbox(
                        value: item["done"],
                        onChanged: (v) {
                          setState(() => item["done"] = v);
                        },
                      ),
                      Expanded(
                        child: TextField(
                          controller: item["controller"],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            decoration: item["done"]
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          decoration:
                          const InputDecoration(border: InputBorder.none),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, size: 18, color: textColor),
                        onPressed: () {
                          setState(() => priorities.removeAt(index));
                        },
                      ),
                    ],
                  );
                }),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: newPriorityController,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          hintText: "Add priority",
                          hintStyle: TextStyle(color: textColor),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add, color: textColor),
                      onPressed: () {
                        if (newPriorityController.text.isNotEmpty) {
                          setState(() {
                            priorities.add({
                              "done": false,
                              "controller": TextEditingController(
                                text: newPriorityController.text,
                              ),
                            });
                            newPriorityController.clear();
                          });
                        }
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                /// NOTES
                Text(
                  "Notes",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),

                const SizedBox(height: 8),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: notesController,
                    maxLines: 6,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Write notes here...",
                      hintStyle: TextStyle(color: textColor),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                /// SAVE BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      elevation: 6,
                      side: BorderSide(color: textColor),
                    ),
                    onPressed: _savePlan,
                    child: Text(
                      "Save",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
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