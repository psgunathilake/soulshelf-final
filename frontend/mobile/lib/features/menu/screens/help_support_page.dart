import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  Future<void> _sendEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'pamusachi16@gmail.com',
      queryParameters: {
        'subject': 'SoulShelf Support Request',
        'body':
        'Hello SoulShelf Team,\n\nI need help with:',
      },
    );

    if (!await launchUrl(emailUri)) {
      throw Exception('Could not open email app');
    }
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  TextStyle sectionTitle = const TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
    color: Color(0xFF2A4D69), // deep blue
  );

  TextStyle bodyText = const TextStyle(
    fontSize: 14,
    height: 1.6,
    color: Color(0xFF444444),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF6FF), // soft sky blue
      appBar: AppBar(
        backgroundColor: const Color(0xFFEAF6FF),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2A4D69)),
        title: const Text(
          "Help & Support",
          style: TextStyle(
            color: Color(0xFF2A4D69),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E8), // soft peach
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2A4D69)
                        .withValues(alpha: 0.15),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(18),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [

                    Container(
                      height: 6,
                      width: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4A261), // sand accent
                        borderRadius:
                        BorderRadius.circular(10),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      "Welcome to the Help & Support section of SoulShelf. Here you can find guidance and assistance whenever you need it.",
                      style: bodyText,
                    ),

                    const SizedBox(height: 16),

                    Text("1. Getting Started",
                        style: sectionTitle),
                    const SizedBox(height: 6),
                    Text(
                      "• Create an account / login to personalize your experience.\n"
                          "• Tap the '+' button to add books, movies, anime, or music.\n"
                          "• Write journals with ratings, highlights, and images.\n"
                          "• Enable privacy lock for extra security.",
                      style: bodyText,
                    ),

                    const SizedBox(height: 16),

                    Text("2. Frequently Asked Questions (FAQ)",
                        style: sectionTitle),
                    const SizedBox(height: 6),
                    Text(
                      "Q1. Is SoulShelf free?\n"
                          "Yes, it is designed as a personal journaling app.\n\n"
                          "Q2. Can I add images?\n"
                          "Yes, you can upload images and screenshots.\n\n"
                          "Q3. What happens if I uninstall?\n"
                          "If logged in, data is backed up securely. Otherwise, local data may be lost.",
                      style: bodyText,
                    ),

                    const SizedBox(height: 16),

                    Text("3. Troubleshooting",
                        style: sectionTitle),
                    const SizedBox(height: 6),
                    Text(
                      "• Restart the app if something isn't working.\n"
                          "• Check your internet connection.\n"
                          "• Use 'Forgot Password' if login fails.",
                      style: bodyText,
                    ),

                    const SizedBox(height: 16),

                    Text("4. Contact Support",
                        style: sectionTitle),
                    const SizedBox(height: 6),
                    Text(
                      "If you need more help, reach out to us:",
                      style: bodyText,
                    ),

                    const SizedBox(height: 8),

                    GestureDetector(
                      onTap: _sendEmail,
                      child: const Text(
                        "pamusachi16@gmail.com",
                        style: TextStyle(
                          color: Color(0xFF2A4D69),
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      "We aim to respond within 24–48 hours.",
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF666666),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
