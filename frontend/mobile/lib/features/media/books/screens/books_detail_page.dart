import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soulshelf/core/utils/cover_image_provider.dart';
import 'package:soulshelf/data/models/book_model.dart';
import 'package:soulshelf/data/models/media_model.dart';
import 'package:soulshelf/data/repositories/media_repository.dart';
import 'package:soulshelf/data/repositories/recommendation_repository.dart';
import 'package:soulshelf/features/home/screens/home_page.dart';
import 'package:soulshelf/features/media/widgets/filter_sheet.dart';
import 'package:soulshelf/features/media/widgets/recommendation_strip.dart';
import 'add_book_page.dart';
import 'book_view_page.dart';

enum _MediaSort { newest, rating, title }

class BooksDetailPage extends ConsumerStatefulWidget {
  const BooksDetailPage({super.key});

  @override
  ConsumerState<BooksDetailPage> createState() => _BooksDetailPageState();
}

class _BooksDetailPageState extends ConsumerState<BooksDetailPage>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  /// SEARCH
  final TextEditingController searchController = TextEditingController();
  String _searchQuery = '';
  MediaFilter _filter = MediaFilter.empty;
  _MediaSort _sortBy = _MediaSort.newest;

  final Color mainColor = const Color(0xFFF3E5D8);
  final Color darkAccent = const Color(0xFF8D6E63);
  final Color softBackground = const Color(0xFFFFF8F2);
  final Color cardColor = const Color(0xFFFFE0B2);
  final Color buttonColor = const Color(0xFFD7A86E);
  final Color textPrimary = const Color(0xFF5D4037);
  final Color borderColor = const Color(0xFFE6CFC2);

  @override
  void initState() {
    super.initState();

    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 400));

    _fadeAnimation =
        Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInOut,
        ));

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
            .animate(CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOut,
        ));

    _controller.forward();
  }

  /// SEARCH FUNCTION
  void searchBooks(String query) {
    setState(() => _searchQuery = query);
  }

  /// Convert a BookModel into the legacy map shape consumed by
  /// [bookCard] and [BookViewPage]. Keeps those widgets unchanged.
  Map<String, dynamic> _toViewMap(BookModel b) => {
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

  List<BookModel> _applyFilter(List<BookModel> all) {
    Iterable<BookModel> out = all;
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      out = out.where((b) => b.title.toLowerCase().contains(q));
    }
    if (_filter.isActive) {
      out = out.where(_filter.matches);
    }
    final list = out.toList();
    switch (_sortBy) {
      case _MediaSort.newest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case _MediaSort.rating:
        list.sort((a, b) => b.rating.compareTo(a.rating));
      case _MediaSort.title:
        list.sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    }
    return list;
  }

  Future<void> _openFilterSheet() async {
    final result = await showFilterSheet(context, current: _filter);
    if (result != null) setState(() => _filter = result);
  }

  Widget _buildSortMenu(Color iconColor) {
    return PopupMenuButton<_MediaSort>(
      tooltip: 'Sort',
      icon: Icon(Icons.more_vert, color: iconColor),
      onSelected: (v) => setState(() => _sortBy = v),
      itemBuilder: (_) => [
        CheckedPopupMenuItem(
          value: _MediaSort.newest,
          checked: _sortBy == _MediaSort.newest,
          child: const Text('Sort by newest'),
        ),
        CheckedPopupMenuItem(
          value: _MediaSort.rating,
          checked: _sortBy == _MediaSort.rating,
          child: const Text('Sort by rating'),
        ),
        CheckedPopupMenuItem(
          value: _MediaSort.title,
          checked: _sortBy == _MediaSort.title,
          child: const Text('Sort by title'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncBooks = ref.watch(booksStreamProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(color: Colors.white.withValues(alpha: 0.15)),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.home, color: darkAccent),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
              (route) => false,
            );
          },
        ),
        title: Text(
          "Books",
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [_buildSortMenu(darkAccent)],
      ),

      body: Stack(
        children: [

          Positioned.fill(
            child: Image.asset(
              "assets/images/books_bg.png",
              fit: BoxFit.cover,
            ),
          ),

          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  const SizedBox(height: 110),

                  RecommendationStrip(
                    title: 'Recommended For You',
                    provider: bookRecommendationsProvider,
                    placeholderIcon: Icons.menu_book,
                    tileColor: cardColor,
                    coverPlaceholder: softBackground,
                    titleColor: textPrimary,
                    subtitleColor: darkAccent,
                    borderColor: borderColor,
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
                            onChanged: searchBooks,
                            decoration: InputDecoration(
                              hintText: "Search your books...",
                              prefixIcon:
                                  Icon(Icons.search, color: darkAccent),
                              filled: true,
                              fillColor: softBackground,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: borderColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: borderColor),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Stack(
                          children: [
                            IconButton(
                              tooltip: 'Filter',
                              icon: Icon(Icons.tune, color: darkAccent),
                              onPressed: _openFilterSheet,
                            ),
                            if (_filter.isActive)
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  Expanded(
                    child: asyncBooks.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(
                        child: Text('Error: $e',
                            style: TextStyle(color: textPrimary)),
                      ),
                      data: (allBooks) {
                        final filtered = _applyFilter(allBooks);
                        if (filtered.isEmpty) {
                          return Center(
                            child: Text(
                              allBooks.isEmpty
                                  ? 'No books yet. Tap + to add one.'
                                  : 'No books match your search',
                              style: TextStyle(color: textPrimary),
                            ),
                          );
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) =>
                              bookCard(filtered[index]),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: buttonColor,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddBookPage()),
          );
        },
      ),
    );
  }



  Widget bookCard(BookModel book) {
    final viewMap = _toViewMap(book);
    final cover = coverImageProvider(book.coverUrl);
    final hasImage = cover != null;
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookViewPage(book: viewMap),
          ),
        );

        if (result is Map && result['delete'] == true) {
          await ref
              .read(mediaRepositoryProvider)
              .deleteMedia(MediaCategory.book, book.id);
        }
        // Other returns are ignored — the stream will refresh the
        // list on any box change. In a later pass we can wire
        // BookViewPage to update via repo.updateBook.
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: softBackground,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(10),
                image: cover != null
                    ? DecorationImage(
                        image: cover,
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: hasImage
                  ? null
                  : Icon(Icons.menu_book, color: darkAccent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textPrimary),
                  ),
                  Text(
                    book.author ?? '',
                    style: TextStyle(color: darkAccent),
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