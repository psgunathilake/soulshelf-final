import 'package:flutter/material.dart';
import 'books_page.dart';
import 'songs_page.dart';
import 'shows_page.dart';
import 'my_space_intro_page.dart'; // ✅ NEW INTRO PAGE
import 'menu.dart';
import 'chat_bot.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isMenuOpen = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🌸 Background
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/bg.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 🌟 Main Content
          SafeArea(
            child: Column(
              children: [
                // 🔝 Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(Icons.home, size: 30),
                      IconButton(
                        icon: const Icon(Icons.menu, size: 30),
                        onPressed: () {
                          setState(() => isMenuOpen = true);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 👤 Profile
                const CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, size: 60),
                ),

                const SizedBox(height: 10),
                const Text(
                  "Hi User Name",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 30),

                // 🔘 Main Buttons
                buildButton(
                  "Books",
                  Icons.menu_book,
                  const BooksPage(),
                  Colors.brown.shade300,
                ),
                buildButton(
                  "Songs",
                  Icons.music_note,
                  const SongsPage(),
                  Colors.blue.shade300,
                ),
                buildButton(
                  "Shows and Films",
                  Icons.movie,
                  const ShowsPage(),
                  Colors.grey.shade400,
                ),
                buildButton(
                  "My Space",
                  Icons.edit_note,
                  const MySpaceIntroPage(), // ✅ UPDATED
                  Colors.purple.shade300,
                ),
              ],
            ),
          ),

          // 🌫️ Overlay when menu open
          if (isMenuOpen)
            GestureDetector(
              onTap: () => setState(() => isMenuOpen = false),
              child: Container(
                color: Colors.black.withValues(alpha: 0.3),
              ),
            ),

          // 📋 Slide-in Menu
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            top: 0,
            bottom: 0,
            right: isMenuOpen ? 0 : -260,
            child: Menu(
              onClose: () => setState(() => isMenuOpen = false),
            ),
          ),
        ],
      ),

      // 🤖 CHATBOT BUTTON (UNCHANGED ✅)
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.smart_toy),
        onPressed: () {
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
      ),
    );
  }

  // 🔘 Button Builder
  Widget buildButton(
      String title,
      IconData icon,
      Widget page,
      Color color,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          minimumSize: const Size(double.infinity, 55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => page),
          );
        },
        child: Row(
          children: [
            Icon(icon, color: Colors.black),
            const SizedBox(width: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
