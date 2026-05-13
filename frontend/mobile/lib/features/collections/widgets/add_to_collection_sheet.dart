import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/cover_image_provider.dart';
import '../../../data/models/collection_model.dart';
import '../../../data/repositories/collection_repository.dart';
import '../screens/collection_form_page.dart';

/// Opens a modal listing all collections; tapping toggles membership for
/// the given [mediaId]. "Create new" pushes [CollectionFormPage] and
/// auto-attaches the media to whichever collection the form returns.
///
/// Detail screens (BookViewPage / SongViewPage / ShowViewPage) call this
/// from an AppBar action. The screens stay un-Riverpodified — this sheet
/// owns its own ConsumerWidget body.
Future<void> showAddToCollectionSheet(
  BuildContext context, {
  required String mediaId,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _Sheet(mediaId: mediaId),
  );
}

class _Sheet extends ConsumerWidget {
  const _Sheet({required this.mediaId});
  final String mediaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_collectionsForSheetProvider);
    final repo  = ref.read(collectionRepositoryProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollController) => Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Add to collection',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('Create new collection'),
            onTap: () async {
              final newId = await Navigator.push<String?>(
                context,
                MaterialPageRoute(
                  builder: (_) => const CollectionFormPage(),
                ),
              );
              if (newId != null && newId.isNotEmpty) {
                await repo.attachMedia(newId, mediaId);
              }
            },
          ),
          const Divider(height: 1),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Failed: $e')),
              data: (items) => items.isEmpty
                  ? const Center(child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No collections yet. Tap "Create new collection".',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54)),
                    ))
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: items.length,
                      itemBuilder: (_, i) => _Row(
                        c: items[i],
                        mediaId: mediaId,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

final _collectionsForSheetProvider =
    StreamProvider.autoDispose<List<CollectionModel>>(
  (ref) => ref.watch(collectionRepositoryProvider).watchAllCollections(),
);

class _Row extends ConsumerWidget {
  const _Row({required this.c, required this.mediaId});
  final CollectionModel c;
  final String mediaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cover = coverImageProvider(c.coverUrl);
    final attached = c.mediaIds.contains(mediaId);
    final repo = ref.read(collectionRepositoryProvider);

    return ListTile(
      leading: SizedBox(
        width: 40, height: 40,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: cover == null
              ? Container(
                  color: const Color(0xFFEDE7F6),
                  child: const Icon(Icons.collections_bookmark_outlined,
                    size: 20, color: Colors.black45))
              : Image(image: cover, fit: BoxFit.cover),
        ),
      ),
      title: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        c.mediaIds.length == 1 ? '1 item' : '${c.mediaIds.length} items',
        style: const TextStyle(fontSize: 11),
      ),
      trailing: Icon(
        attached ? Icons.check_circle : Icons.add_circle_outline,
        color: attached ? Colors.green : Colors.black45,
      ),
      onTap: () async {
        if (attached) {
          await repo.detachMedia(c.id, mediaId);
        } else {
          await repo.attachMedia(c.id, mediaId);
        }
      },
    );
  }
}
