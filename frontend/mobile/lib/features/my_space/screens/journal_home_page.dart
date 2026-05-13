import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:soulshelf/data/models/journal_model.dart';
import 'package:soulshelf/data/repositories/journal_repository.dart';
import 'package:soulshelf/features/home/screens/home_page.dart';
import 'journal_day_page.dart';

class JournalHomePage extends ConsumerStatefulWidget {
  const JournalHomePage({super.key});

  @override
  ConsumerState<JournalHomePage> createState() => _JournalHomePageState();
}

class _JournalHomePageState extends ConsumerState<JournalHomePage> {

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  String? _selectedDayPreviewText;
  List<JournalTodo> _selectedDayTodos = const [];
  List<String> _selectedDayBirthdays = const [];

  bool _hasData = false;

  bool _entryHasContent(JournalModel e) =>
      (e.content?.isNotEmpty ?? false) ||
      (e.shortNote ?? '').isNotEmpty ||
      e.todos.isNotEmpty ||
      e.birthdays.isNotEmpty ||
      e.mood > 0 ||
      e.stress > 0 ||
      e.weather != null ||
      e.waterCups > 0;

  /// LOAD PREVIEW DATA
  void loadPreview(DateTime day) {
    final entry = ref.read(journalRepositoryProvider).getEntry(day);

    if (entry != null) {
      _selectedDayPreviewText = entry.shortNote;
      _selectedDayTodos = entry.todos;
      _selectedDayBirthdays = entry.birthdays;
      _hasData = _entryHasContent(entry);
    } else {
      _selectedDayPreviewText = null;
      _selectedDayTodos = const [];
      _selectedDayBirthdays = const [];
      _hasData = false;
    }

    setState(() {});
  }

  /// CHECK IF A DAY HAS DATA (FOR CALENDAR DOTS)
  bool hasDataForDay(DateTime day) {
    final entry = ref.read(journalRepositoryProvider).getEntry(day);
    return entry != null && _entryHasContent(entry);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      extendBodyBehindAppBar: true,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
                  (route) => false,
            );
          },
        ),

        title: const Text(
          "My Journal",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        centerTitle: true,
      ),

      body: Stack(
        children: [

          /// BACKGROUND IMAGE
          Positioned.fill(
            child: Image.asset(
              "assets/images/journal_bg.png",
              fit: BoxFit.cover,
            ),
          ),

          SafeArea(
            child: Column(
              children: [

                const SizedBox(height: 80),

                /// CALENDAR
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),

                  child: Container(
                    padding: const EdgeInsets.all(15),

                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha:0.95),
                      borderRadius: BorderRadius.circular(20),

                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha:0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),

                    child: TableCalendar(

                      firstDay: DateTime(2000, 1, 1),
                      lastDay: DateTime(2050, 12, 31),
                      focusedDay: _focusedDay,

                      calendarFormat: CalendarFormat.month,

                      availableCalendarFormats: const {
                        CalendarFormat.month: 'Month',
                      },

                      selectedDayPredicate: (day) {
                        return isSameDay(_selectedDay, day);
                      },

                      /// CALENDAR DOTS
                      calendarBuilders: CalendarBuilders(
                        markerBuilder: (context, date, events) {

                          if (hasDataForDay(date)) {

                            return Positioned(
                              bottom: 4,
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            );
                          }

                          return null;
                        },
                      ),

                      onDaySelected: (selectedDay, focusedDay) {

                        /// DOUBLE TAP
                        if (isSameDay(_selectedDay, selectedDay)) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  JournalDayPage(date: selectedDay),
                            ),
                          );
                          return;
                        }

                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });

                        loadPreview(selectedDay);
                      },

                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      calendarStyle: CalendarStyle(
                        todayDecoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),

                        selectedDecoration: const BoxDecoration(
                          color: Colors.deepPurple,
                          shape: BoxShape.circle,
                        ),

                        defaultTextStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),

                        weekendTextStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                const Text(
                  "Tap a day to preview ✍️\nDouble tap to open your day",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 20),

                /// PREVIEW SECTION
                if (_selectedDay != null && _hasData)
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(15),

                      decoration: BoxDecoration(

                        color: Colors.white.withValues(alpha:0.55),

                        borderRadius: BorderRadius.circular(22),

                        border: Border.all(
                          color: Colors.white.withValues(alpha:0.4),
                        ),

                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha:0.35),
                            blurRadius: 25,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),

                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            const Text(
                              "Day Preview",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black,
                              ),
                            ),

                            const SizedBox(height: 10),

                            Text(
                              _selectedDayPreviewText ?? "",
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 20),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [

                                /// BIRTHDAYS
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [

                                      const Text(
                                        "Birthdays",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),

                                      const SizedBox(height: 10),

                                      ..._selectedDayBirthdays.map(
                                            (b) => Padding(
                                          padding:
                                          const EdgeInsets.only(bottom: 6),
                                          child: Text(
                                            "🎂 $b",
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 12),

                                /// TODO
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [

                                      const Text(
                                        "Todo",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),

                                      const SizedBox(height: 10),

                                      ..._selectedDayTodos.map(
                                            (todo) => ListTile(
                                          dense: true,
                                          contentPadding: EdgeInsets.zero,
                                          leading: Icon(
                                            todo.done
                                                ? Icons.check_circle
                                                : Icons.circle_outlined,
                                            color: Colors.black,
                                          ),
                                          title: Text(
                                            todo.text,
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
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