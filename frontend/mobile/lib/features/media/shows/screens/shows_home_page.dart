import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soulshelf/core/utils/cover_image_provider.dart';
import 'package:soulshelf/data/models/media_model.dart';
import 'package:soulshelf/data/models/show_model.dart';
import 'package:soulshelf/data/repositories/media_repository.dart';
import 'package:soulshelf/data/repositories/recommendation_repository.dart';
import 'package:soulshelf/features/home/screens/home_page.dart';
import 'package:soulshelf/features/media/widgets/filter_sheet.dart';
import 'package:soulshelf/features/media/widgets/recommendation_strip.dart';
import 'add_show_page.dart';
import 'show_view_page.dart';

enum _ShowSort { newest, rating, title }

class ShowsHomePage extends ConsumerStatefulWidget {
  const ShowsHomePage({super.key});

  @override
  ConsumerState<ShowsHomePage> createState() => _ShowsHomePageState();
}

class _ShowsHomePageState extends ConsumerState<ShowsHomePage> {

  final TextEditingController searchController = TextEditingController();
  String _searchQuery = '';
  MediaFilter _filter = MediaFilter.empty;
  _ShowSort _sortBy = _ShowSort.newest;

  /// SEARCH
  void searchShows(String query) {
    setState(() => _searchQuery = query);
  }

  Map<String, dynamic> _toViewMap(ShowModel s) => {
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

  List<ShowModel> _applyFilter(List<ShowModel> all) {
    Iterable<ShowModel> out = all;
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      out = out.where((s) => s.title.toLowerCase().contains(q));
    }
    if (_filter.isActive) {
      out = out.where(_filter.matches);
    }
    final list = out.toList();
    switch (_sortBy) {
      case _ShowSort.newest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case _ShowSort.rating:
        list.sort((a, b) => b.rating.compareTo(a.rating));
      case _ShowSort.title:
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
    return PopupMenuButton<_ShowSort>(
      tooltip: 'Sort',
      icon: const Icon(Icons.more_vert, color: Color(0xff4a4a4a)),
      onSelected: (v) => setState(() => _sortBy = v),
      itemBuilder: (_) => [
        CheckedPopupMenuItem(
          value: _ShowSort.newest,
          checked: _sortBy == _ShowSort.newest,
          child: const Text('Sort by newest'),
        ),
        CheckedPopupMenuItem(
          value: _ShowSort.rating,
          checked: _sortBy == _ShowSort.rating,
          child: const Text('Sort by rating'),
        ),
        CheckedPopupMenuItem(
          value: _ShowSort.title,
          checked: _sortBy == _ShowSort.title,
          child: const Text('Sort by title'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncShows = ref.watch(showsStreamProvider);
    return Scaffold(

      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,

      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.15),
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(color: Colors.transparent),
          ),
        ),

        leading: IconButton(
          icon: const Icon(Icons.home, color: Color(0xff4a4a4a)),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
                  (route) => false,
            );
          },
        ),

        title: const Text(
          "Shows and Films",
          style: TextStyle(
            color: Color(0xff444444),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [_buildSortMenu()],
      ),

      body: Stack(
        children: [

          /// Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/show_bg.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),

          /// Page Content
          Column(
            children: [

              const SizedBox(height: 110),

              RecommendationStrip(
                title: 'Recommended For You',
                provider: showRecommendationsProvider,
                placeholderIcon: Icons.movie,
                tileColor: const Color(0xffe2e2e2),
                coverPlaceholder: const Color(0xffd9d9d9),
                titleColor: const Color(0xff444444),
                subtitleColor: const Color(0xff666666),
              ),

              const SizedBox(height: 10),

              /// SEARCH BAR + FILTER
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        onChanged: searchShows,
                        decoration: InputDecoration(
                          hintText: "Search your shows or films...",
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
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
                child: asyncShows.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Text('Error: $e',
                        style: const TextStyle(color: Color(0xff555555))),
                  ),
                  data: (allShows) {
                    final filtered = _applyFilter(allShows);
                    if (filtered.isEmpty) {
                      return Center(
                        child: Text(
                          allShows.isEmpty
                              ? 'No shows yet. Tap + to add one.'
                              : 'No shows match your search',
                          style: const TextStyle(color: Color(0xff555555)),
                        ),
                      );
                    }
                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.65,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final show = filtered[index];
                        return _ShowCard(
                          show: show,
                          viewMap: _toViewMap(show),
                          onDelete: () => ref
                              .read(mediaRepositoryProvider)
                              .deleteMedia(MediaCategory.show, show.id),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xff444444),
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddShowPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

}

class _ShowCard extends StatelessWidget {

  final ShowModel show;
  final Map<String, dynamic> viewMap;
  final VoidCallback onDelete;

  const _ShowCard({
    required this.show,
    required this.viewMap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {

    final cover = coverImageProvider(show.coverUrl);
    final bool hasImage = cover != null;

    return GestureDetector(

      onTap: () async {

        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ShowViewPage(show: viewMap),
          ),
        );

        if (result is Map && result['delete'] == true) {
          onDelete();
        }
      },

      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xffe2e2e2),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
                  color: Colors.grey.shade300,
                  image: cover != null
                      ? DecorationImage(
                    image: cover,
                    fit: BoxFit.cover,
                  )
                      : null,
                ),
                child:
                hasImage ? null : const Icon(Icons.movie, size: 40),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    show.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xff444444),
                    ),
                  ),

                  const SizedBox(height: 6),

                  Row(
                    children: List.generate(5, (i) {
                      return Icon(
                        Icons.star,
                        size: 16,
                        color: show.rating > i
                            ? Colors.orange
                            : Colors.grey.shade400,
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