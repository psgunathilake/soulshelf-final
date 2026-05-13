import 'package:flutter/material.dart';
import 'dart:async';
import 'shows_home_page.dart';

class ShowsPage extends StatefulWidget {
  const ShowsPage({super.key});

  @override
  State<ShowsPage> createState() => _ShowsPageState();
}

class _ShowsPageState extends State<ShowsPage> {
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
                builder: (_) => const ShowsHomePage(),
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
                Color(0xFFF1F3F5),
                Color(0xFFE0E0E0),
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
                    padding: const EdgeInsets.all(24),
                    margin: const EdgeInsets.only(top: 70),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          "Shows and Films",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                        SizedBox(height: 24),
                        Text(
                          "Watching shows is not just entertainment.\n\n"
                              "It’s a way to see the world\n"
                              "through different eyes.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.6,
                            fontStyle: FontStyle.italic,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 24),
                        Text(
                          "Tap anywhere to continue",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Positioned(
                    top: -40,
                    child: Image.asset(
                      "assets/images/show.png",
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