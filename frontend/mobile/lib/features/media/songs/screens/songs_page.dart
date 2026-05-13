import 'package:flutter/material.dart';
import 'dart:async';
import 'songs_detail_page.dart';

class SongsPage extends StatefulWidget {
  const SongsPage({super.key});

  @override
  State<SongsPage> createState() => _SongsPageState();
}

class _SongsPageState extends State<SongsPage> {
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
                builder: (_) => const SongsDetailPage(),
              ),
            );
          }
        },
        child: Container(
          width: double.infinity,
          height: double.infinity,

          //background image
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFE3F2FD),
                Color(0xFFBBDEFB),
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
                      color: const Color(0xFFF5FAFF),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF42A5F5)
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
                          "Music",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: Color(0xFF0D47A1),
                          ),
                        ),
                        SizedBox(height: 26),
                        Text(
                          "Music is not just sound.\n\n"
                              "It’s emotion in rhythm,\n"
                              "memories in melody,\n"
                              "and healing in every note.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.7,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF1565C0),
                          ),
                        ),
                        SizedBox(height: 28),
                        Text(
                          "Tap anywhere to continue",
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF1E88E5),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Positioned(
                    top: -40,
                    child: Image.asset(
                      "assets/images/song.png",
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