import 'package:flutter/material.dart';
import 'books_detail_page.dart';

class BooksPage extends StatelessWidget {
  const BooksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // 👉 Tap anywhere to go next page
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BooksDetailPage()),
        );
      },
      child: Scaffold(
        body: Stack(
          children: [
            // 📚 Background image
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/books_bg.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // 📘 Card
                  Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.85,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.brown.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: Colors.blue,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: const [
                          Text(
                            "Books",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 20),
                          Text(
                            "\"Reading books\n"
                                "opens doors to new\n"
                                "worlds,\n"
                                "sharpens your\n"
                                "mind,\n"
                                "and inspires your\n"
                                "dreams—one page\n"
                                "at a time.\"",
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
