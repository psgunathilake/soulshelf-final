import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/journal_model.dart';
import '../../../data/models/media_model.dart';
import '../../../data/repositories/journal_repository.dart';
import '../../../data/repositories/media_repository.dart';
import '../../../data/repositories/stats_repository.dart';

/// FR9 — Statistics Dashboard. Read-only screen; pull-to-refresh
/// re-fetches `users.stats` from the server. Renders four sections:
/// summary cards, category pie, status bar, mood line, top genres.
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsStreamProvider);
    final journals  = ref.watch(_journalsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Journey'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(statsStreamProvider);
          await ref.read(statsStreamProvider.future);
        },
        child: statsAsync.when(
          loading: () => const _LoadingScroll(),
          error: (e, _) => _ErrorScroll(message: '$e'),
          data: (stats) {
            if (stats == null || stats.isEmpty) {
              return const _EmptyScroll();
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SummaryRow(stats: stats),
                const SizedBox(height: 24),
                _CategoryPie(stats: stats),
                const SizedBox(height: 24),
                _StatusBar(stats: stats),
                const SizedBox(height: 24),
                _MoodLine(journals: journals.valueOrNull ?? const []),
                const SizedBox(height: 24),
                _TopGenres(),
                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ------------------------------- providers -------------------------------

/// Local provider used only by the dashboard's mood chart. Defined here
/// so it doesn't pollute the JournalRepository module's public surface.
final _journalsStreamProvider =
    StreamProvider.autoDispose<List<MapEntry<String, JournalModel>>>(
  (ref) => ref.watch(journalRepositoryProvider).watchAllEntries(),
);

// ------------------------------- summary --------------------------------

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.stats});
  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    final mediaCount   = (stats['mediaCount']   as int?) ?? 0;
    final journalCount = (stats['journalCount'] as int?) ?? 0;
    final streak       = (stats['streak']       as int?) ?? 0;

    return Row(
      children: [
        Expanded(child: _MetricCard(
          label: 'Media',
          value: '$mediaCount',
          icon: Icons.auto_stories_rounded,
          color: const Color(0xFFF3E5D8),
          iconBgColor: const Color(0xFFD7B894),
          iconColor: const Color(0xFF6D4C41),
        )),
        const SizedBox(width: 12),
        Expanded(child: _MetricCard(
          label: 'Entries',
          value: '$journalCount',
          icon: Icons.edit_calendar_rounded,
          color: const Color(0xFFE3F2FD),
          iconBgColor: const Color(0xFF90CAF9),
          iconColor: const Color(0xFF1565C0),
        )),
        const SizedBox(width: 12),
        Expanded(child: _MetricCard(
          label: 'Streak',
          value: '$streak',
          icon: Icons.local_fire_department_rounded,
          color: const Color(0xFFFFE0B2),
          iconBgColor: const Color(0xFFFFB74D),
          iconColor: const Color(0xFFE65100),
        )),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.iconBgColor,
    required this.iconColor,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color iconBgColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Column(
        children: [
          // Icon-on-pill: a 40px circular badge with the deeper tint
          // gives the icon a clear focal point and matches modern
          // dashboard/tracker UX (Apple Health, Strava, etc.).
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }
}

// ----------------------------- category pie -----------------------------

class _CategoryPie extends StatelessWidget {
  const _CategoryPie({required this.stats});
  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    final byCat = (stats['mediaByCategory'] as Map?)?.cast<String, dynamic>() ?? {};
    final book = (byCat['book'] as int?) ?? 0;
    final song = (byCat['song'] as int?) ?? 0;
    final show = (byCat['show'] as int?) ?? 0;
    final total = book + song + show;

    return _SectionCard(
      title: 'Category distribution',
      child: total == 0
          ? const _EmptyHint('No media tracked yet.')
          : SizedBox(
              height: 180,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 32,
                        sections: [
                          if (book > 0) PieChartSectionData(
                            value: book.toDouble(),
                            title: '$book',
                            color: const Color(0xFFD7B894),
                            radius: 50,
                            titleStyle: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600,
                              color: Colors.black87),
                          ),
                          if (song > 0) PieChartSectionData(
                            value: song.toDouble(),
                            title: '$song',
                            color: const Color(0xFF90CAF9),
                            radius: 50,
                            titleStyle: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600,
                              color: Colors.black87),
                          ),
                          if (show > 0) PieChartSectionData(
                            value: show.toDouble(),
                            title: '$show',
                            color: const Color(0xFFB0BEC5),
                            radius: 50,
                            titleStyle: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600,
                              color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _LegendDot(color: const Color(0xFFD7B894), label: 'Books'),
                        const SizedBox(height: 6),
                        _LegendDot(color: const Color(0xFF90CAF9), label: 'Songs'),
                        const SizedBox(height: 6),
                        _LegendDot(color: const Color(0xFFB0BEC5), label: 'Shows'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(
        color: color, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Text(label, style: const TextStyle(fontSize: 13)),
    ],
  );
}

// ------------------------------ status bar -------------------------------

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.stats});
  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    final s = (stats['mediaByStatus'] as Map?)?.cast<String, dynamic>() ?? {};
    final planned   = (s['planned']   as int?) ?? 0;
    final ongoing   = (s['ongoing']   as int?) ?? 0;
    final completed = (s['completed'] as int?) ?? 0;
    final counts = [planned, ongoing, completed];
    final maxVal = counts.reduce((a, b) => a > b ? a : b);

    return _SectionCard(
      title: 'Status breakdown',
      child: maxVal == 0
          ? const _EmptyHint('No media tracked yet.')
          : SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (maxVal + 1).toDouble(),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        // Reserve room for label + count line so
                        // zero-count buckets are still readable when
                        // their bar is invisible.
                        reservedSize: 44,
                        getTitlesWidget: (v, _) {
                          const labels = ['Planned', 'Ongoing', 'Done'];
                          final i = v.toInt();
                          if (i < 0 || i >= labels.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  labels[i],
                                  style: const TextStyle(fontSize: 11),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${counts[i]}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: counts[i] == 0
                                        ? Colors.black38
                                        : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    _bar(0, planned,   const Color(0xFFFFB74D)),
                    _bar(1, ongoing,   const Color(0xFF64B5F6)),
                    _bar(2, completed, const Color(0xFF81C784)),
                  ],
                ),
              ),
            ),
    );
  }

  BarChartGroupData _bar(int x, int y, Color color) => BarChartGroupData(
    x: x,
    barRods: [
      BarChartRodData(
        toY: y.toDouble(),
        color: color,
        width: 32,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
      ),
    ],
  );
}

// ------------------------------- mood line -------------------------------

class _MoodLine extends StatelessWidget {
  const _MoodLine({required this.journals});
  final List<MapEntry<String, JournalModel>> journals;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final df    = DateFormat('yyyy-MM-dd');

    // Build a map keyed by yyyy-MM-dd → mood.
    final byDate = <String, int>{};
    for (final e in journals) {
      byDate[e.key] = e.value.mood;
    }

    // Last 30 days, oldest → newest. x-axis index = days from oldest.
    final spots = <FlSpot>[];
    for (int i = 0; i < 30; i++) {
      final day = today.subtract(Duration(days: 29 - i));
      final mood = byDate[df.format(day)];
      if (mood != null) {
        spots.add(FlSpot(i.toDouble(), mood.toDouble()));
      }
    }

    return _SectionCard(
      title: 'Mood — last 30 days',
      child: spots.isEmpty
          ? const _EmptyHint('No journal entries in the last 30 days.')
          : SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: 29,
                  // Mood is stored as integer 1..4 (see JournalModel),
                  // so bound the axis explicitly and force integer ticks.
                  // Without these, fl_chart auto-picks 0.5/1.5/2.5 which
                  // wrap inside the narrow reservedSize and stack the
                  // digits on top of each other.
                  minY: 0,
                  maxY: 4,
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        interval: 1,
                        getTitlesWidget: (v, _) {
                          if (v % 1 != 0) return const SizedBox.shrink();
                          return Text(
                            v.toInt().toString(),
                            style: const TextStyle(
                                fontSize: 11, color: Colors.black54),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        interval: 14,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          final String label;
                          if (i == 0) {
                            label = '30d';
                          } else if (i == 14) {
                            label = '15d';
                          } else if (i == 29) {
                            label = 'now';
                          } else {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              label,
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.black54),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      preventCurveOverShooting: true,
                      color: const Color(0xFF7E57C2),
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF7E57C2).withValues(alpha: 0.15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// ------------------------------ top genres -------------------------------

class _TopGenres extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(mediaRepositoryProvider);

    final byCategory = <MediaCategory, Map<String, int>>{
      MediaCategory.book: _countGenres(repo.getAllBooks().map((m) => m.genre)),
      MediaCategory.song: _countGenres(repo.getAllSongs().map((m) => m.genre)),
      MediaCategory.show: _countGenres(repo.getAllShows().map((m) => m.genre)),
    };

    return _SectionCard(
      title: 'Top genres',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _genreLine('Books', byCategory[MediaCategory.book]!),
          const SizedBox(height: 6),
          _genreLine('Songs', byCategory[MediaCategory.song]!),
          const SizedBox(height: 6),
          _genreLine('Shows', byCategory[MediaCategory.show]!),
        ],
      ),
    );
  }

  Widget _genreLine(String label, Map<String, int> counts) {
    final top = _topOf(counts);
    return Row(
      children: [
        SizedBox(width: 64,
          child: Text(label, style: const TextStyle(
            fontWeight: FontWeight.w600))),
        const SizedBox(width: 8),
        Expanded(child: Text(
          top == null ? '—' : '${top.key}  (${top.value})',
          style: const TextStyle(color: Colors.black87),
        )),
      ],
    );
  }

  static Map<String, int> _countGenres(Iterable<String?> genres) {
    final m = <String, int>{};
    for (final g in genres) {
      if (g == null || g.isEmpty) continue;
      m[g] = (m[g] ?? 0) + 1;
    }
    return m;
  }

  static MapEntry<String, int>? _topOf(Map<String, int> counts) {
    if (counts.isEmpty) return null;
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b);
  }
}

// ----------------------------- shared widgets ----------------------------

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    color: Theme.of(context).colorScheme.surfaceContainerLowest,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    ),
  );
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Center(
      child: Text(message, style: const TextStyle(color: Colors.black54))),
  );
}

class _LoadingScroll extends StatelessWidget {
  const _LoadingScroll();
  @override
  Widget build(BuildContext context) => const Center(
    child: CircularProgressIndicator());
}

class _EmptyScroll extends StatelessWidget {
  const _EmptyScroll();
  @override
  Widget build(BuildContext context) => ListView(
    children: const [
      SizedBox(height: 120),
      Center(child: Text(
        'Add some media or a journal entry to see stats.',
        style: TextStyle(color: Colors.black54))),
    ],
  );
}

class _ErrorScroll extends StatelessWidget {
  const _ErrorScroll({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      const SizedBox(height: 80),
      const Icon(Icons.error_outline, size: 40, color: Colors.black45),
      const SizedBox(height: 12),
      Center(child: Text(message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.black54))),
    ],
  );
}
