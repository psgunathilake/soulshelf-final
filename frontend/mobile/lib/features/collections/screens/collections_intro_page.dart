import 'package:flutter/material.dart';
import 'dart:async';
import 'collections_list_page.dart';

class CollectionsIntroPage extends StatefulWidget {
  const CollectionsIntroPage({super.key});

  @override
  State<CollectionsIntroPage> createState() => _CollectionsIntroPageState();
}

class _CollectionsIntroPageState extends State<CollectionsIntroPage> {
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
                builder: (_) => const CollectionsListPage(),
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
                Color(0xFFFFE0B2),
                Color(0xFFFFD180),
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
                      color: const Color(0xFFFFF8E7),
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
                          "Collections",
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
                          "Some stories travel together.\n\n"
                              "A book that pairs with a song,\n"
                              "a show that finds its echo,\n"
                              "a memory that lives across forms —\n"
                              "gathered in one place,\n"
                              "ready to revisit.",
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
                      "assets/images/collection.png",
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
