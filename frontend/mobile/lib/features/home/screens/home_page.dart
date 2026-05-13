import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:soulshelf/core/utils/cover_image_provider.dart';
import 'package:soulshelf/data/models/user_model.dart';
import 'package:soulshelf/features/collections/screens/collections_intro_page.dart';
import 'package:soulshelf/features/dashboard/widgets/home_stats_card.dart';
import 'package:soulshelf/features/media/books/screens/books_page.dart';
import 'package:soulshelf/features/media/songs/screens/songs_page.dart';
import 'package:soulshelf/features/media/shows/screens/shows_page.dart';
import 'package:soulshelf/features/my_space/screens/my_space_intro_page.dart';
import 'package:soulshelf/features/menu/screens/menu.dart';
import 'package:soulshelf/features/chatbot/screens/chat_bot_page.dart';



class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {

  bool isMenuOpen = false;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileBox = Hive.box('profileBox');

    return Scaffold(
      body: ValueListenableBuilder(
        valueListenable: profileBox.listenable(keys: const ['profile']),
        builder: (context, box, _) {
          final raw = box.get('profile');
          final headerProvider = raw is Map
              ? coverImageProvider(UserModel.fromHive(raw).headerUrl)
              : null;

          return Stack(
            children: [

              Positioned.fill(
                child: Image.asset(
                  "assets/images/home_bg.png",
                  fit: BoxFit.cover,
                ),
              ),

              Positioned.fill(
                child: Container(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.black.withValues(alpha: 0.45)
                      : Colors.white.withValues(alpha: 0.35),
                ),
              ),


              SizedBox(
                height: 230,
                width: double.infinity,
                child: ClipPath(
                  clipper: WaveClipper(),
                  child: headerProvider != null
                      ? Image(
                          image: headerProvider,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: const Color(0xFFC17C8A)
                              .withValues(alpha: 0.85),
                        ),
                ),
              ),

              SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.menu,
                              size: 28,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              setState(() => isMenuOpen = true);
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    Image.asset(
                      "assets/images/app_logo.png",
                      height: 120,
                    ),

                    const SizedBox(height: 12),

                    const HomeStatsCard(),

                    const SizedBox(height: 8),

                    buildButton(
                      "Books",
                      "assets/images/book.png",
                      const BooksPage(),
                      const Color(0xFFF3E5D8),
                    ),
                    buildButton(
                      "Songs",
                      "assets/images/song.png",
                      const SongsPage(),
                      const Color(0xFFE3F2FD),
                    ),
                    buildButton(
                      "Shows and Films",
                      "assets/images/show.png",
                      const ShowsPage(),
                      const Color(0xFFFCE4EC),
                    ),
                    buildButton(
                      "My Space",
                      "assets/images/myspace.png",
                      const MySpaceIntroPage(),
                      const Color(0xFFF3E8FF),
                    ),
                    buildButton(
                      "Collections",
                      "assets/images/collection.png",
                      const CollectionsIntroPage(),
                      const Color(0xFFFFE0B2),
                      imageHeight: 70,
                    ),

                    const SizedBox(height: 24),
                  ],
                  ),
                ),
              ),

              if (isMenuOpen)
                GestureDetector(
                  onTap: () =>
                      setState(() => isMenuOpen = false),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.3),
                  ),
                ),

              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                top: 0,
                bottom: 0,
                right: isMenuOpen ? 0 : -Menu.width,
                child: Menu(
                  onClose: () =>
                      setState(() => isMenuOpen = false),
                ),
              ),
            ],
          );
        },
      ),

      //Chatbot Button
      floatingActionButton: ScaleTransition(
        scale: Tween(begin: 1.0, end: 1.12).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Curves.easeInOut,
          ),
        ),
        child: GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(25),
                ),
              ),
              builder: (_) => const ChatBot(),
            );
          },
          child: Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              "assets/images/chatbot.png",
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildButton(
      String title,
      String imagePath,
      Widget page,
      Color color, {
        double imageHeight = 55,
      }) {
    return _homeRowButton(
      title: title,
      page: page,
      color: color,
      leading: Transform.translate(
        offset: const Offset(-10, 0),
        child: Image.asset(
          imagePath,
          height: imageHeight,
        ),
      ),
    );
  }

  Widget _homeRowButton({
    required String title,
    required Widget page,
    required Color color,
    required Widget leading,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
      child: Stack(
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              elevation: 2,
              minimumSize: const Size(double.infinity, 75),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => page),
              );
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                leading,
                const SizedBox(width: 25),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          Positioned.fill(
            child: IgnorePointer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  "assets/images/dot_bg.png",
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(
        size.width / 2, size.height,
        size.width, size.height - 40);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}