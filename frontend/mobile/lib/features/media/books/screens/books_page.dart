import 'package:flutter/material.dart';
import 'dart:async';
import 'books_detail_page.dart';

class BooksPage extends StatefulWidget {
  const BooksPage({super.key});

  @override
  State<BooksPage> createState() => _BooksPageState();
}

class _BooksPageState extends State<BooksPage> {
  bool _showContent = false;

  @override
  void initState() {
    super.initState();

    Timer(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() => _showContent = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (_showContent) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const BooksDetailPage(),
              ),
            );
          }
        },
        child: Container(
          width: double.infinity,
          height: double.infinity,

          // background image
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFF5EBDD),
                Color(0xFFE8D5C4),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            image: DecorationImage(
              image: AssetImage("assets/images/dot_bg.png"),
              fit: BoxFit.cover,
            ),
          ),

          child: Center(
            child: AnimatedOpacity(
              opacity: _showContent ? 1 : 0,
              duration: const Duration(milliseconds: 400),
              child: Stack(
                alignment: Alignment.topCenter,
                clipBehavior: Clip.none,
                children: [

                  Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    padding: const EdgeInsets.all(28),
                    margin: const EdgeInsets.only(top: 70),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF9F2),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8D6E63)
                              .withValues(alpha: 0.25),
                          blurRadius: 25,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          "Books",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: Color(0xFF4E342E),
                          ),
                        ),
                        SizedBox(height: 26),
                        Text(
                          "Reading books is more than turning pages.\n\n"
                              "It’s traveling across worlds,\n"
                              "living a thousand lives,\n"
                              "and discovering parts of yourself\n"
                              "within every story.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.7,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF5D4037),
                          ),
                        ),
                        SizedBox(height: 28),
                        Text(
                          "Tap anywhere to continue",
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6D4C41),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Positioned(
                    top: -40,
                    child: Image.asset(
                      "assets/images/book.png",
                      height: 150,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}