import 'package:flutter/material.dart';
import 'songs_detail_page.dart';

class SongsPage extends StatelessWidget {
  const SongsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // 👉 Tap anywhere to go to next screen
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const SongsDetailPage(),
          ),
        );
      },
      child: Scaffold(
        body: Stack(
          children: [
            // 🎨 Background image
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/music_bg.jpg"),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // 🎵 Blue quote card
                  Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.85,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: Colors.blueAccent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: const [
                          Text(
                            "Music",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 20),
                          Text(
                            "\"Music heals the heart and\nlifts the soul.\"",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  // 🔄 Loading indicator
                  Column(
                    children: const [
                      CircularProgressIndicator(color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        "Loading...",
                        style: TextStyle(color: Colors.black),
                      ),
                      SizedBox(height: 20),
                    ],
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
