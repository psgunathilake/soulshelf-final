import 'package:flutter/material.dart';
import 'sub_entrance_page.dart';

class EntrancePage extends StatefulWidget {
  const EntrancePage({super.key});

  @override
  State<EntrancePage> createState() => _EntrancePageState();
}

class _EntrancePageState extends State<EntrancePage>
    with TickerProviderStateMixin {

  late AnimationController _floatController;
  late Animation<double> _floatAnim;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    //floating animation
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _floatAnim = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(
        parent: _floatController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _fadeController.forward();
  }

  // Smooth Fade Transition
  void _goToHome() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (_, __, ___) => const SubEntrancePage(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [

          //Background
          Positioned.fill(
            child: Image.asset(
              "assets/images/entrance_bg.jpg",
              fit: BoxFit.cover,
            ),
          ),

          Positioned.fill(
            child: Container(
              color: Colors.white.withValues(alpha: 0.35),
            ),
          ),

          FadeTransition(
            opacity: _fadeAnim,
            child: SafeArea(
              child: Column(
                children: [

                  const SizedBox(height: 90),

                  const Text(
                    "SoulShelf",
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                      color: Color(0xFF4F7C7B),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Container(
                    width: 170,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFC17C8A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "Read • Watch • Listen • Journal",
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF5F5B57),
                      letterSpacing: 1.2,
                    ),
                  ),

                  const Spacer(),

                  //RECTANGLE LOGO FRAME
                  AnimatedBuilder(
                    animation: _floatAnim,
                    builder: (_, child) {
                      return Transform.translate(
                        offset: Offset(0, _floatAnim.value),
                        child: child,
                      );
                    },
                    child: Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        color: Colors.transparent,
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x22000000),
                            blurRadius: 35,
                            offset: Offset(0, 18),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: Image.asset(
                          "assets/images/entrance_app_logo.png",
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 50),

                  //GO Button
                  GestureDetector(
                    onTap: _goToHome,
                    child: Container(
                      height: 55,
                      width: 200,
                      decoration: BoxDecoration(
                        color: const Color(0xFFC17C8A),
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 12,
                            offset: Offset(0, 6),
                          )
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          "Let's Go",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  const Padding(
                    padding: EdgeInsets.only(bottom: 32),
                    child: Text(
                      "Your peaceful media journey.",
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF5F5B57),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}