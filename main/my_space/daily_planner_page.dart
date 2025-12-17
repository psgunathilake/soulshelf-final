import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DailyPlannerPage extends StatefulWidget {
  const DailyPlannerPage({super.key});

  @override
  State<DailyPlannerPage> createState() => _DailyPlannerPageState();
}

class _DailyPlannerPageState extends State<DailyPlannerPage> {
  final Map<String, TextEditingController> scheduleControllers = {};
  final List<Map<String, dynamic>> priorities = [];
  final TextEditingController notesController = TextEditingController();
  final TextEditingController newPriorityController = TextEditingController();

  final List<String> timeSlots = List.generate(
    18,
        (i) => DateFormat('h:00 a')
        .format(DateTime(2025, 1, 1, 5 + i)),
  );

  @override
  void initState() {
    super.initState();
    for (var time in timeSlots) {
      scheduleControllers[time] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (var c in scheduleControllers.values) {
      c.dispose();
    }
    notesController.dispose();
    newPriorityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daily Plan"),
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Schedule",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            // ⏰ TIME SCHEDULE
            Column(
              children: timeSlots.map((time) {
                return Row(
                  children: [
                    SizedBox(
                      width: 70,
                      child: Text(
                        time,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: scheduleControllers[time],
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

            // 🎯 PRIORITIES
            const Text(
              "Priorities",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      decoration:
                      const InputDecoration(border: InputBorder.none),
                      style: TextStyle(
                        decoration: item["done"]
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
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
                    decoration:
                    const InputDecoration(hintText: "Add priority"),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
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

            // 📝 NOTES
            const Text(
              "Notes",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.yellow.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: notesController,
                maxLines: 6,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "Write notes here...",
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 💾 SAVE BUTTON
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Save"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
