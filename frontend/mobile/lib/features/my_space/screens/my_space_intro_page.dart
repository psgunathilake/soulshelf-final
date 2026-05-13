import 'package:flutter/material.dart';
import 'dart:async';
import 'my_space_page.dart';

class MySpaceIntroPage extends StatefulWidget {
  const MySpaceIntroPage({super.key});

  @override
  State<MySpaceIntroPage> createState() => _MySpaceIntroPageState();
}

class _MySpaceIntroPageState extends State<MySpaceIntroPage> {
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
                builder: (_) => const MySpacePage(),
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
                Color(0xFFF3E8FF),
                Color(0xFFE6F4EA),
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFA78BFA)
                              .withValues(alpha: 0.15),
                          blurRadius: 25,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          "My Space",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: Color(0xFF4C1D95),
                          ),
                        ),
                        SizedBox(height: 24),
                        Text(
                          "Write your thoughts.\n\n"
                              "Plan your days.\n"
                              "Capture your growth.\n\n"
                              "This is your space to reflect\n"
                              "and move forward.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.7,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        SizedBox(height: 28),
                        Text(
                          "Tap anywhere to continue",
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Positioned(
                    top: -40,
                    child: Image.asset(
                      "assets/images/myspace.png",
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