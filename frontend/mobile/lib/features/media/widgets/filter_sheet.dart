import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/media_model.dart';

/// In-memory filter struct shared across the three media list pages.
/// Per Phase-4 decision #4, filters reset on app close (no persistence).
class MediaFilter {
  final Set<MediaStatus> statuses;
  final String? genre;
  final int minRating;
  final int maxRating;
  final DateTime? dateFrom;
  final DateTime? dateTo;

  const MediaFilter({
    this.statuses = const {},
    this.genre,
    this.minRating = 0,
    this.maxRating = 5,
    this.dateFrom,
    this.dateTo,
  });

  static const empty = MediaFilter();

  bool get isActive =>
      statuses.isNotEmpty ||
      (genre != null && genre!.isNotEmpty) ||
      minRating > 0 ||
      maxRating < 5 ||
      dateFrom != null ||
      dateTo != null;

  /// True if [m] passes the filter. Date matching uses `endDate ?? startDate`
  /// — i.e. "when did this media activity happen" without distinguishing.
  bool matches(MediaModel m) {
    if (statuses.isNotEmpty && !statuses.contains(m.status)) return false;
    if (genre != null && genre!.trim().isNotEmpty) {
      final g = m.genre?.toLowerCase() ?? '';
      if (!g.contains(genre!.trim().toLowerCase())) return false;
    }
    if (m.rating < minRating || m.rating > maxRating) return false;
    final d = m.endDate ?? m.startDate;
    if (dateFrom != null && (d == null || d.isBefore(dateFrom!))) return false;
    if (dateTo != null && (d == null || d.isAfter(dateTo!))) return false;
    return true;
  }

  MediaFilter copyWith({
    Set<MediaStatus>? statuses,
    String? genre,
    int? minRating,
    int? maxRating,
    DateTime? dateFrom,
    DateTime? dateTo,
    bool clearGenre = false,
    bool clearDateRange = false,
  }) =>
      MediaFilter(
        statuses: statuses ?? this.statuses,
        genre: clearGenre ? null : (genre ?? this.genre),
        minRating: minRating ?? this.minRating,
        maxRating: maxRating ?? this.maxRating,
        dateFrom: clearDateRange ? null : (dateFrom ?? this.dateFrom),
        dateTo: clearDateRange ? null : (dateTo ?? this.dateTo),
      );
}

/// Shows the filter modal. Returns the new filter on Apply, the empty
/// filter on Clear-all, or null if dismissed.
Future<MediaFilter?> showFilterSheet(
  BuildContext context, {
  required MediaFilter current,
}) {
  return showModalBottomSheet<MediaFilter?>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _FilterSheet(initial: current),
  );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial});
  final MediaFilter initial;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late Set<MediaStatus> _statuses;
  late TextEditingController _genre;
  late RangeValues _rating;
  DateTime? _from;
  DateTime? _to;

  @override
  void initState() {
    super.initState();
    _statuses = {...widget.initial.statuses};
    _genre = TextEditingController(text: widget.initial.genre ?? '');
    _rating = RangeValues(
      widget.initial.minRating.toDouble(),
      widget.initial.maxRating.toDouble(),
    );
    _from = widget.initial.dateFrom;
    _to = widget.initial.dateTo;
  }

  @override
  void dispose() {
    _genre.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 1),
      initialDateRange: (_from != null && _to != null)
          ? DateTimeRange(start: _from!, end: _to!)
          : null,
    );
    if (picked != null) {
      setState(() { _from = picked.start; _to = picked.end; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('MMM d, yyyy');
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(2)),
            )),
            const SizedBox(height: 16),
            const Text('Filter',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 18),

            const Text('Status', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: MediaStatus.values.map((s) => FilterChip(
                label: Text(_statusLabel(s)),
                selected: _statuses.contains(s),
                onSelected: (v) => setState(() {
                  if (v) {
                    _statuses.add(s);
                  } else {
                    _statuses.remove(s);
                  }
                }),
              )).toList(),
            ),
            const SizedBox(height: 18),

            const Text('Genre contains',
              style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: _genre,
              decoration: const InputDecoration(
                hintText: 'e.g. fiction, jazz, drama',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 18),

            Text('Rating  (${_rating.start.toInt()} – ${_rating.end.toInt()})',
              style: const TextStyle(fontWeight: FontWeight.w600)),
            RangeSlider(
              values: _rating,
              min: 0,
              max: 5,
              divisions: 5,
              labels: RangeLabels(
                _rating.start.toInt().toString(),
                _rating.end.toInt().toString()),
              onChanged: (v) => setState(() => _rating = v),
            ),
            const SizedBox(height: 8),

            const Text('Date range',
              style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(child: OutlinedButton.icon(
                  onPressed: _pickDateRange,
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    (_from == null || _to == null)
                        ? 'Any date'
                        : '${df.format(_from!)}  →  ${df.format(_to!)}',
                    overflow: TextOverflow.ellipsis,
                  ),
                )),
                if (_from != null || _to != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() {
                      _from = null; _to = null;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 22),

            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, MediaFilter.empty),
                  child: const Text('Clear all'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () => Navigator.pop(
                    context,
                    MediaFilter(
                      statuses: _statuses,
                      genre: _genre.text.trim().isEmpty ? null : _genre.text.trim(),
                      minRating: _rating.start.toInt(),
                      maxRating: _rating.end.toInt(),
                      dateFrom: _from,
                      dateTo: _to,
                    ),
                  ),
                  child: const Text('Apply'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _statusLabel(MediaStatus s) => switch (s) {
    MediaStatus.planned   => 'Planned',
    MediaStatus.ongoing   => 'Ongoing',
    MediaStatus.completed => 'Completed',
  };
}
