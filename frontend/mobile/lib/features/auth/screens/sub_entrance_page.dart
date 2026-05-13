import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soulshelf/data/repositories/auth_repository.dart';
import 'package:soulshelf/features/auth/screens/email_verification_page.dart';
import 'package:soulshelf/features/auth/screens/login_page.dart';
import 'package:soulshelf/features/home/screens/home_page.dart';

class SubEntrancePage extends ConsumerStatefulWidget {
  const SubEntrancePage({super.key});

  @override
  ConsumerState<SubEntrancePage> createState() => _SubEntrancePageState();
}

class _SubEntrancePageState extends ConsumerState<SubEntrancePage>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
    _navigateToHome();
  }

  void _navigateToHome() async {
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    final repo = ref.read(authRepositoryProvider);
    final status = repo.currentStatus;
    debugPrint(
        '[AUTH ROUTE] status=$status currentUser=${repo.currentUser?.uid ?? "null"}');
    final Widget destination;
    switch (status) {
      case AuthStatus.authenticated:
        destination = const HomePage();
        break;
      case AuthStatus.awaitingVerification:
        destination = const EmailVerificationPage();
        break;
      case AuthStatus.unauthenticated:
      case AuthStatus.unknown:
        destination = const LoginPage();
        break;
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (_, __, ___) => destination,
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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          //Background Image
          SizedBox.expand(
            child: Opacity(
              opacity: 0.85, // light fade effect
              child: Image.asset(
                'assets/images/splash_bg.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),

          //Animated Glass Box
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 35),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      Image.asset(
                        'assets/images/panda_hi_logo.png',
                        width: 230,
                      ),

                      const SizedBox(height: 18),

                      const Text(
                        "Welcome to SoulShelf",
                        style: TextStyle(
                          color: Color(0xFF4F7C7B),
                          fontSize: 16,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}