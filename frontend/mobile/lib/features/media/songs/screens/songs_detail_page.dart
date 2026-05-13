import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soulshelf/core/utils/cover_image_provider.dart';
import 'package:soulshelf/data/models/media_model.dart';
import 'package:soulshelf/data/models/song_model.dart';
import 'package:soulshelf/data/repositories/media_repository.dart';
import 'package:soulshelf/data/repositories/recommendation_repository.dart';
import 'package:soulshelf/features/home/screens/home_page.dart';
import 'package:soulshelf/features/media/widgets/filter_sheet.dart';
import 'package:soulshelf/features/media/widgets/recommendation_strip.dart';
import 'add_song_page.dart';
import 'song_view_page.dart';

enum _SongSort { newest, rating, title }

class SongsDetailPage extends ConsumerStatefulWidget {
  const SongsDetailPage({super.key});

  @override
  ConsumerState<SongsDetailPage> createState() => _SongsDetailPageState();
}

class _SongsDetailPageState extends ConsumerState<SongsDetailPage> {

  /// SEARCH CONTROLLER
  final TextEditingController searchController = TextEditingController();
  String _searchQuery = '';
  MediaFilter _filter = MediaFilter.empty;
  _SongSort _sortBy = _SongSort.newest;

  /// SEARCH FUNCTION
  void searchSongs(String query) {
    setState(() => _searchQuery = query);
  }

  Map<String, dynamic> _toViewMap(SongModel s) => {
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

  List<SongModel> _applyFilter(List<SongModel> all) {
    Iterable<SongModel> out = all;
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      out = out.where((s) => s.title.toLowerCase().contains(q));
    }
    if (_filter.isActive) {
      out = out.where(_filter.matches);
    }
    final list = out.toList();
    switch (_sortBy) {
      case _SongSort.newest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case _SongSort.rating:
        list.sort((a, b) => b.rating.compareTo(a.rating));
      case _SongSort.title:
        list.sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    }
    return list;
  }

  Future<void> _openFilterSheet() async {
    final result = await showFilterSheet(context, current: _filter);
    if (result != null) setState(() => _filter = result);
  }

  Widget _buildSortMenu() {
    return PopupMenuButton<_SongSort>(
      tooltip: 'Sort',
      icon: const Icon(Icons.more_vert, color: Color(0xff1E2A38)),
      onSelected: (v) => setState(() => _sortBy = v),
      itemBuilder: (_) => [
        CheckedPopupMenuItem(
          value: _SongSort.newest,
          checked: _sortBy == _SongSort.newest,
          child: const Text('Sort by newest'),
        ),
        CheckedPopupMenuItem(
          value: _SongSort.rating,
          checked: _sortBy == _SongSort.rating,
          child: const Text('Sort by rating'),
        ),
        CheckedPopupMenuItem(
          value: _SongSort.title,
          checked: _sortBy == _SongSort.title,
          child: const Text('Sort by title'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncSongs = ref.watch(songsStreamProvider);
    return Scaffold(
      extendBodyBehindAppBar: true,

      // GLASS APP BAR
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.home, color: Color(0xff1E2A38)),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
                  (route) => false,
            );
          },
        ),
        title: const Text(
          "Music",
          style: TextStyle(
            color: Color(0xff1E2A38),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [_buildSortMenu()],
      ),

      // BACKGROUND IMAGE
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/music_bg.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 120),

            RecommendationStrip(
              title: 'Recommended For You',
              provider: songRecommendationsProvider,
              placeholderIcon: Icons.music_note,
              tileColor: Colors.white.withValues(alpha: 0.75),
              coverPlaceholder: const Color(0xFFBBDEFB),
              titleColor: const Color(0xff1F3A5F),
              subtitleColor: const Color(0xff2E4057),
              height: 130,
            ),

            const SizedBox(height: 10),

            ///SEARCH BAR + FILTER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      onChanged: searchSongs,
                      decoration: InputDecoration(
                        hintText: "Search your songs...",
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Stack(
                    children: [
                      IconButton(
                        tooltip: 'Filter',
                        icon: const Icon(Icons.tune),
                        onPressed: _openFilterSheet,
                      ),
                      if (_filter.isActive)
                        Positioned(
                          right: 8, top: 8,
                          child: Container(
                            width: 8, height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: asyncSongs.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text('Error: $e',
                      style: const TextStyle(color: Color(0xff2E4057))),
                ),
                data: (allSongs) {
                  final filtered = _applyFilter(allSongs);
                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        allSongs.isEmpty
                            ? 'No songs yet. Tap + to add one.'
                            : 'No songs match your search',
                        style: const TextStyle(
                            color: Color(0xff2E4057), fontSize: 16),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) =>
                        songCard(filtered[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddSongPage()),
          );
        },
      ),
    );
  }

  // SONG CARD
  Widget songCard(SongModel song) {
    final viewMap = _toViewMap(song);
    final cover = coverImageProvider(song.coverUrl);
    final hasImage = cover != null;
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SongViewPage(song: viewMap),
          ),
        );

        if (result is Map && result['delete'] == true) {
          await ref
              .read(mediaRepositoryProvider)
              .deleteMedia(MediaCategory.song, song.id);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                image: cover != null
                    ? DecorationImage(
                        image: cover,
                        fit: BoxFit.cover,
                      )
                    : null,
                color: Colors.blue.shade100,
              ),
              child: hasImage
                  ? null
                  : const Icon(
                      Icons.music_note,
                      color: Color(0xff1F3A5F),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff1E2A38),
                    ),
                  ),
                  Row(
                    children: List.generate(5, (i) {
                      return Icon(
                        i < song.rating ? Icons.star : Icons.star_border,
                        size: 18,
                        color: Colors.amber,
                      );
                    }),
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