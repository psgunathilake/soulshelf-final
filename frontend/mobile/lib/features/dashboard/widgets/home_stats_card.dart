import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/stats_repository.dart';
import '../screens/dashboard_page.dart';

/// Compact stats summary embedded in the Home column. Reads
/// `statsStreamProvider`, which emits the cached blob immediately and
/// then a fresh server fetch — so the card is always populated and
/// auto-refreshes when Home opens. Tap navigates to the full dashboard.
class HomeStatsCard extends ConsumerWidget {
  const HomeStatsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(statsStreamProvider);
    final stats = async.valueOrNull;

    final mediaCount = (stats?['mediaCount'] as int?) ?? 0;
    final streak     = (stats?['streak']     as int?) ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
      child: Material(
        color: const Color(0xFFE8F5E9),
        elevation: 1,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DashboardPage()),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Your Journey',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _StatBlock(
                        value: '$mediaCount',
                        label: mediaCount == 1 ? 'item tracked' : 'items tracked',
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: const Color(0xFF2E7D32).withValues(alpha: 0.2),
                    ),
                    Expanded(
                      child: _StatBlock(
                        value: '$streak',
                        label: streak == 1 ? 'day streak' : 'day streak',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B5E20),
            height: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.black54,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}
