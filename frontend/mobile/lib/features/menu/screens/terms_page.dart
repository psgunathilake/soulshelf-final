import 'package:flutter/material.dart';



class TermsPage extends StatefulWidget {
  const TermsPage({super.key});

  @override
  State<TermsPage> createState() => _TermsPageState();
}

class _TermsPageState extends State<TermsPage>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
    color: Color(0xFF5C5C5C),
  );

  TextStyle bodyText = const TextStyle(
    fontSize: 14,
    height: 1.6,
    color: Color(0xFF6E6E6E),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F0FF), // soft lavender
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F0FF),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF5C5C5C)),
        title: const Text(
          "Terms Of Service",
          style: TextStyle(
            color: Color(0xFF5C5C5C),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Stack(
        children: [

          Positioned(
            bottom: -40,
            left: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: const BoxDecoration(
                color: Color(0xFFFFD8C2), // pastel peach
                shape: BoxShape.circle,
              ),
            ),
          ),

          ///Animated Card
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBF5),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFB8C0FF)
                            .withValues(alpha: 0.3),
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
                            color: const Color(0xFF8E9EFF),
                            borderRadius:
                            BorderRadius.circular(10),
                          ),
                        ),

                        const SizedBox(height: 16),

                        Text(
                          "Welcome to [App Name]! By using this application, you agree to the following Terms of Service.",
                          style: bodyText,
                        ),

                        const SizedBox(height: 14),

                        Text("1. Acceptance of Terms",
                            style: sectionTitle),
                        const SizedBox(height: 6),
                        Text(
                          "By downloading or using this App, you agree to be bound by these Terms. If you do not agree, please stop using the App immediately.",
                          style: bodyText,
                        ),

                        const SizedBox(height: 14),

                        Text("2. Services",
                            style: sectionTitle),
                        const SizedBox(height: 6),
                        Text(
                          "• This App is a personal journaling and media tracking application.\n"
                              "• You can write, store, and organize journal entries.\n"
                              "• The App is user-friendly and secure.\n"
                              "• Each user has private database storage.",
                          style: bodyText,
                        ),

                        const SizedBox(height: 14),

                        Text("3. User Responsibility",
                            style: sectionTitle),
                        const SizedBox(height: 6),
                        Text(
                          "• Provide accurate account information.\n"
                              "• Keep login credentials secure.\n"
                              "• Use the App only for lawful purposes.\n"
                              "• Avoid uploading harmful or illegal content.",
                          style: bodyText,
                        ),

                        const SizedBox(height: 14),

                        Text("4. Limitation of Liability",
                            style: sectionTitle),
                        const SizedBox(height: 6),
                        Text(
                          "• The App is provided 'as is' without warranties.\n"
                              "• We are not responsible for data loss due to device issues or misuse.\n"
                              "• No system can guarantee 100% security.",
                          style: bodyText,
                        ),

                        const SizedBox(height: 14),

                        Text("5. Changes to Terms",
                            style: sectionTitle),
                        const SizedBox(height: 6),
                        Text(
                          "We may update these Terms from time to time. Continued use of the App means you accept the updated Terms.",
                          style: bodyText,
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
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
