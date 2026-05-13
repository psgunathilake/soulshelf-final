import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/recommendation_item.dart';

/// Reusable horizontal recommendation strip for category pages. Each
/// category (Books / Songs / Shows) passes its own palette + placeholder
/// icon so the visual treatment matches the page's theme.
///
/// Watches an AsyncValue provider; renders loading spinner, error text,
/// or the tile list. Online-only with last-result fallback is handled
/// upstream in [RecommendationRepository] — by the time this widget
/// sees an error state, even the cached fallback was unavailable.
class RecommendationStrip extends ConsumerWidget {
  const RecommendationStrip({
    super.key,
    required this.title,
    required this.provider,
    required this.placeholderIcon,
    required this.tileColor,
    required this.coverPlaceholder,
    required this.titleColor,
    required this.subtitleColor,
    this.borderColor,
    this.height = 140,
    this.maxItems = 8,
  });

  final String title;
  final ProviderListenable<AsyncValue<List<RecommendationItem>>> provider;
  final IconData placeholderIcon;
  final Color tileColor;
  final Color coverPlaceholder;
  final Color titleColor;
  final Color subtitleColor;
  final Color? borderColor;
  final double height;
  final int maxItems;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(provider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: height,
          child: async.when(
            loading: () => const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (_, __) => Center(
              child: Text(
                'Could not load recommendations',
                style: TextStyle(color: subtitleColor, fontSize: 12),
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                return Center(
                  child: Text(
                    'No suggestions yet',
                    style: TextStyle(color: subtitleColor, fontSize: 12),
                  ),
                );
              }
              final shown = items.length > maxItems
                  ? items.sublist(0, maxItems)
                  : items;
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: shown.length,
                itemBuilder: (_, i) => _Tile(
                  item: shown[i],
                  placeholderIcon: placeholderIcon,
                  tileColor: tileColor,
                  coverPlaceholder: coverPlaceholder,
                  titleColor: titleColor,
                  subtitleColor: subtitleColor,
                  borderColor: borderColor,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.item,
    required this.placeholderIcon,
    required this.tileColor,
    required this.coverPlaceholder,
    required this.titleColor,
    required this.subtitleColor,
    this.borderColor,
  });

  final RecommendationItem item;
  final IconData placeholderIcon;
  final Color tileColor;
  final Color coverPlaceholder;
  final Color titleColor;
  final Color subtitleColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final cover = item.coverUrl;
    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(15),
        border: borderColor != null ? Border.all(color: borderColor!) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 70,
            decoration: BoxDecoration(
              color: coverPlaceholder,
              borderRadius: BorderRadius.circular(10),
              image: cover != null
                  ? DecorationImage(
                      image: NetworkImage(cover),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: cover != null
                ? null
                : Center(child: Icon(placeholderIcon, color: subtitleColor)),
          ),
          const SizedBox(height: 6),
          Text(
            item.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: titleColor,
            ),
          ),
          if (item.subtitle != null)
            Text(
              item.subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: subtitleColor),
            ),
        ],
      ),
    );
  }
}
