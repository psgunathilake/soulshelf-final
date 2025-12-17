import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'daily_planner_page.dart';
import 'journal_list_page.dart';

class JournalDayPage extends StatefulWidget {
  final DateTime date;

  const JournalDayPage({
    super.key,
    required this.date,
  });

  @override
  State<JournalDayPage> createState() => _JournalDayPageState();
}

class _JournalDayPageState extends State<JournalDayPage> {
  bool isEditing = true;

  int moodIndex = -1;
  int stressLevel = -1;
  int weatherIndex = -1;

  final TextEditingController noteController = TextEditingController();
  final TextEditingController newTaskController = TextEditingController();
  final TextEditingController newBirthdayController = TextEditingController();

  final List<Map<String, dynamic>> todoList = [];
  final List<TextEditingController> birthdayList = [];

  final moods = [
    Icons.sentiment_very_satisfied,
    Icons.sentiment_satisfied,
    Icons.sentiment_neutral,
    Icons.sentiment_dissatisfied,
  ];

  final weatherIcons = [
    Icons.wb_sunny,
    Icons.cloud,
    Icons.thunderstorm,
    Icons.umbrella,
  ];

  @override
  Widget build(BuildContext context) {
    final formattedDate =
    DateFormat("EEEE, MMM d, yyyy").format(widget.date);

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text("My Day"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // DATE
            Text(
              formattedDate,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 8),

            // NOTE
            TextField(
              controller: noteController,
              enabled: isEditing,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: "Hi today is a good day to have a good day",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // MOOD
            _sectionTitle("Mood"),
            Row(
              children: List.generate(moods.length, (index) {
                return IconButton(
                  icon: Icon(
                    moods[index],
                    size: 32,
                    color:
                    moodIndex == index ? Colors.orange : Colors.grey,
                  ),
                  onPressed: isEditing
                      ? () => setState(() => moodIndex = index)
                      : null,
                );
              }),
            ),

            // STRESS
            _sectionTitle("Stress level"),
            Row(
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: isEditing
                      ? () => setState(() => stressLevel = index)
                      : null,
                  child: Container(
                    margin: const EdgeInsets.all(6),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: stressLevel >= index
                          ? Colors.black
                          : Colors.grey.shade300,
                    ),
                  ),
                );
              }),
            ),

            // WEATHER
            _sectionTitle("Weather"),
            Row(
              children: List.generate(weatherIcons.length, (index) {
                return IconButton(
                  icon: Icon(
                    weatherIcons[index],
                    size: 30,
                    color:
                    weatherIndex == index ? Colors.blue : Colors.grey,
                  ),
                  onPressed: isEditing
                      ? () => setState(() => weatherIndex = index)
                      : null,
                );
              }),
            ),

            const SizedBox(height: 20),

            // BIRTHDAY + TODO
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // BIRTHDAY LIST
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle("Birthday"),
                      ...birthdayList.asMap().entries.map((entry) {
                        final index = entry.key;
                        final controller = entry.value;

                        return Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: controller,
                                enabled: isEditing,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: "Name",
                                ),
                              ),
                            ),
                            if (isEditing)
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () {
                                  setState(() {
                                    birthdayList.removeAt(index);
                                  });
                                },
                              ),
                          ],
                        );
                      }),
                      if (isEditing)
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: newBirthdayController,
                                decoration: const InputDecoration(
                                  hintText: "Add name",
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                if (newBirthdayController.text.isNotEmpty) {
                                  setState(() {
                                    birthdayList.add(
                                      TextEditingController(
                                        text:
                                        newBirthdayController.text,
                                      ),
                                    );
                                    newBirthdayController.clear();
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // TODO LIST
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle("To-do list"),
                      ...todoList.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;

                        return Row(
                          children: [
                            Checkbox(
                              value: item["done"],
                              onChanged: isEditing
                                  ? (v) =>
                                  setState(() => item["done"] = v)
                                  : null,
                            ),
                            Expanded(
                              child: TextField(
                                enabled: isEditing,
                                controller: item["controller"],
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                ),
                                style: TextStyle(
                                  decoration: item["done"]
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                            if (isEditing)
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () {
                                  setState(() {
                                    todoList.removeAt(index);
                                  });
                                },
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
                                decoration: const InputDecoration(
                                  hintText: "Add task",
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                if (newTaskController.text.isNotEmpty) {
                                  setState(() {
                                    todoList.add({
                                      "done": false,
                                      "controller":
                                      TextEditingController(
                                        text:
                                        newTaskController.text,
                                      ),
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
                ),
              ],
            ),

            const SizedBox(height: 20),

            // SAVE / EDIT
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => setState(() => isEditing = false),
                  child: const Text("Save"),
                ),
                OutlinedButton(
                  onPressed: () => setState(() => isEditing = true),
                  child: const Text("Edit"),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // NAVIGATION BUTTONS
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DailyPlannerPage(),
                        ),
                      );
                    },
                    child: const Text("Daily Planner"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => JournalListPage(
                            date: widget.date,
                            existingText: "",
                          ),
                        ),
                      );
                    },
                    child: const Text("Journal"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}