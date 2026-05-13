import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/cover_image_provider.dart';
import '../../../data/models/collection_model.dart';
import '../../../data/repositories/collection_repository.dart';
import 'collection_form_page.dart';
import 'collection_view_page.dart';

/// FR6 — collections list. Renders cached collections in a 2-column grid;
/// FAB opens the create form. Tapping a tile opens the view page.
class CollectionsListPage extends ConsumerWidget {
  const CollectionsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_collectionsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Collections')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('New'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load: $e')),
        data: (items) => items.isEmpty
            ? _Empty(onCreate: () => _openForm(context))
            : GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.78,
                ),
                itemCount: items.length,
                itemBuilder: (_, i) => _CollectionTile(c: items[i]),
              ),
      ),
    );
  }

  void _openForm(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CollectionFormPage()),
    );
  }
}

final _collectionsStreamProvider =
    StreamProvider.autoDispose<List<CollectionModel>>(
  (ref) => ref.watch(collectionRepositoryProvider).watchAllCollections(),
);

class _CollectionTile extends StatelessWidget {
  const _CollectionTile({required this.c});
  final CollectionModel c;

  @override
  Widget build(BuildContext context) {
    final cover = coverImageProvider(c.coverUrl);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CollectionViewPage(collectionId: c.id),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF3E8FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                child: cover == null
                    ? Container(
                        color: const Color(0xFFE0CDF6),
                        alignment: Alignment.center,
                        child: const Icon(Icons.collections_bookmark_outlined,
                          size: 36, color: Colors.black45),
                      )
                    : Image(image: cover, fit: BoxFit.cover),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    c.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    c.mediaIds.length == 1
                        ? '1 item'
                        : '${c.mediaIds.length} items',
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onCreate});
  final VoidCallback onCreate;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.collections_bookmark_outlined,
            size: 56, color: Colors.black38),
          const SizedBox(height: 16),
          const Text(
            'No collections yet',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Group your books, songs, and shows into themed albums.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 20),
          FilledButton.tonal(
            onPressed: onCreate,
            child: const Text('Create one'),
          ),
        ],
      ),
    ),
  );
}
