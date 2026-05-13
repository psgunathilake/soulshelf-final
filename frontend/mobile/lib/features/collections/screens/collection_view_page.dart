import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/utils/cover_image_provider.dart';
import '../../../data/models/book_model.dart';
import '../../../data/models/collection_model.dart';
import '../../../data/models/media_model.dart';
import '../../../data/models/show_model.dart';
import '../../../data/models/song_model.dart';
import '../../../data/repositories/collection_repository.dart';
import '../../../data/repositories/media_repository.dart';
import '../../media/books/screens/book_view_page.dart';
import '../../media/shows/screens/show_view_page.dart';
import '../../media/songs/screens/song_view_page.dart';
import 'collection_form_page.dart';

/// FR6 — collection detail. On open, force-fetches the eager-loaded
/// `media` array (so `mediaIds` is populated even if the list endpoint's
/// merge dropped it). Members render mixed-category; tap → existing
/// view page. Swipe-left → detach. AppBar edit/delete.
class CollectionViewPage extends ConsumerStatefulWidget {
  const CollectionViewPage({super.key, required this.collectionId});
  final String collectionId;

  @override
  ConsumerState<CollectionViewPage> createState() => _CollectionViewPageState();
}

class _CollectionViewPageState extends ConsumerState<CollectionViewPage> {
  @override
  void initState() {
    super.initState();
    // Force-fetch the eager-loaded `media` so mediaIds is fresh. Best-effort.
    Future.microtask(() {
      ref.read(collectionRepositoryProvider)
          .getCollectionWithMembers(widget.collectionId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box('collectionsBox').listenable(
        keys: [widget.collectionId],
      ),
      builder: (context, _, _) {
        final repo = ref.read(collectionRepositoryProvider);
        final c = repo.getCollection(widget.collectionId);

        if (c == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()));
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(c.name, overflow: TextOverflow.ellipsis),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CollectionFormPage(existing: c),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _confirmDelete(context, c),
              ),
            ],
          ),
          body: _Body(collection: c),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, CollectionModel c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete collection?'),
        content: Text('"${c.name}" will be removed. Members are not deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel')),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    if (!context.mounted) return;
    await ref.read(collectionRepositoryProvider).deleteCollection(c.id);
    if (!context.mounted) return;
    Navigator.pop(context);
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.collection});
  final CollectionModel collection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(mediaRepositoryProvider);
    final cover = coverImageProvider(collection.coverUrl);

    final members = collection.mediaIds
        .map((id) => MapEntry(id, repo.findMediaById(id)))
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (cover != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image(image: cover, fit: BoxFit.cover),
            ),
          ),
        if (cover != null) const SizedBox(height: 16),
        if (collection.description != null && collection.description!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              collection.description!,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ),
        Text(
          collection.mediaIds.length == 1
              ? '1 item'
              : '${collection.mediaIds.length} items',
          style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54),
        ),
        const SizedBox(height: 8),
        if (collection.mediaIds.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: Text(
              'No items yet. Add some from a book/song/show detail page.',
              style: TextStyle(color: Colors.black54),
              textAlign: TextAlign.center,
            )),
          )
        else
          ...members.map((e) => _MemberTile(
                key: ValueKey(e.key),
                mediaId: e.key,
                media: e.value,
                onDetach: () async {
                  await ref.read(collectionRepositoryProvider)
                      .detachMedia(collection.id, e.key);
                },
              )),
      ],
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    super.key,
    required this.mediaId,
    required this.media,
    required this.onDetach,
  });
  final String mediaId;
  final MediaModel? media;
  final Future<void> Function() onDetach;

  @override
  Widget build(BuildContext context) {
    final m = media;
    final cover = coverImageProvider(m?.coverUrl);

    return Dismissible(
      key: ValueKey('member-$mediaId'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.redAccent,
        child: const Icon(Icons.remove_circle_outline, color: Colors.white),
      ),
      onDismissed: (_) => onDetach(),
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: SizedBox(
            width: 44, height: 44,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: cover == null
                  ? Container(
                      color: const Color(0xFFE0E0E0),
                      child: const Icon(Icons.image_outlined,
                        color: Colors.black38))
                  : Image(image: cover, fit: BoxFit.cover),
            ),
          ),
          title: Text(
            m?.title ?? 'Unavailable',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            m == null
                ? 'Open the matching list to load this item.'
                : _categoryLabel(m.category),
            style: const TextStyle(fontSize: 12),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: m == null ? null : () => _openDetail(context, m),
        ),
      ),
    );
  }

  static String _categoryLabel(MediaCategory cat) => switch (cat) {
    MediaCategory.book => 'Book',
    MediaCategory.song => 'Song',
    MediaCategory.show => 'Show',
  };

  static void _openDetail(BuildContext context, MediaModel m) {
    Widget? page;
    switch (m) {
      case BookModel b:
        page = BookViewPage(book: _bookViewMap(b));
        break;
      case SongModel s:
        page = SongViewPage(song: _songViewMap(s));
        break;
      case ShowModel s:
        page = ShowViewPage(show: _showViewMap(s));
        break;
    }
    if (page == null) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => page!));
  }

  // The view pages still consume legacy Map<String, dynamic> shapes
  // (Phase-1 design). These three helpers mirror the `_toViewMap` helpers
  // in books/songs/shows detail pages so the same pages render correctly
  // when opened from a collection.
  static Map<String, dynamic> _bookViewMap(BookModel b) => {
    'id': b.id,
    'name': b.title,
    'author': b.author ?? '',
    'image': b.coverUrl,
    'rating': b.rating,
    'genre': b.genre ?? '',
    'status': b.status.name,
    'pages': b.pages?.toString() ?? '',
    'notes': b.reflection ?? '',
  };

  static Map<String, dynamic> _songViewMap(SongModel s) => {
    'id': s.id,
    'title': s.title,
    'singer': s.singer ?? '',
    'composer': s.composer ?? '',
    'lyricist': s.lyricist ?? '',
    'rating': s.rating,
    'lyrics': s.lyrics ?? '',
    'genre': s.genre ?? '',
    'language': s.language ?? '',
    'mood': s.mood ?? '',
    'favorite': s.favorite,
    'link': s.link ?? '',
    'notes': s.reflection ?? '',
    'releaseDate': s.releaseDate?.toIso8601String(),
    'imagePath': s.coverUrl,
  };

  static Map<String, dynamic> _showViewMap(ShowModel s) => {
    'id': s.id,
    'title': s.title,
    'type': s.subType.wire,
    'rating': s.rating,
    'status': s.status.name,
    'genre': s.genre ?? '',
    'date': s.endDate,
    'note': s.reflection ?? '',
    'image': s.coverUrl,
  };
}
