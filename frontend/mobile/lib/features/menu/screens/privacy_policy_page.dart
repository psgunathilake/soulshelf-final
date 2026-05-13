import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  Future<void> _sendEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'pamusachi16@gmail.com',
      queryParameters: {
        'subject': 'Privacy Policy Inquiry',
        'body':
        'Hello, I have a question regarding the Privacy Policy.',
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
      begin: const Offset(0, 0.08),
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

  TextStyle sectionTitleStyle = const TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
    color: Color(0xFF5C5C5C),
  );

  TextStyle bodyStyle = const TextStyle(
    fontSize: 14,
    height: 1.6,
    color: Color(0xFF6E6E6E),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF7F2), // soft mint
      appBar: AppBar(
        backgroundColor: const Color(0xFFEAF7F2),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF5C5C5C)),
        title: const Text(
          "Privacy Policy",
          style: TextStyle(
            color: Color(0xFF5C5C5C),
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
                color: const Color(0xFFFFF8EC), // warm cream
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFB8E3D9)
                        .withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(18),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Container(
                      height: 6,
                      width: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFC9A9), // peach
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text("1. Information We Collect",
                        style: sectionTitleStyle),
                    const SizedBox(height: 6),
                    Text(
                      "• Account Information: username, email, and profile picture (if provided).\n"
                          "• Content You Create: journal entries, notes, photos, and media uploads.\n"
                          "• Device Information: device type, OS version, and app version for performance improvement.\n",
                      style: bodyStyle,
                    ),

                    const SizedBox(height: 14),

                    Text("2. Data Storage and Security",
                        style: sectionTitleStyle),
                    const SizedBox(height: 6),
                    Text(
                      "• All personal data is securely stored using encrypted Firebase databases.\n"
                          "• Strict security measures prevent unauthorized access or misuse.\n"
                          "• Your content remains private and is never mixed with other users.\n",
                      style: bodyStyle,
                    ),

                    const SizedBox(height: 14),

                    Text("3. Information We Share",
                        style: sectionTitleStyle),
                    const SizedBox(height: 6),
                    Text(
                      "• We do not sell, rent, or trade your personal data.\n"
                          "• Data is never shared with third parties unless required by law.\n"
                          "• Journals and notes are visible only to you.\n",
                      style: bodyStyle,
                    ),

                    const SizedBox(height: 14),

                    Text("4. Your Rights",
                        style: sectionTitleStyle),
                    const SizedBox(height: 6),
                    Text(
                      "• Access & Edit your entries anytime.\n"
                          "• Delete content or permanently remove your account.\n"
                          "• Full control over what you upload and keep private.\n",
                      style: bodyStyle,
                    ),

                    const SizedBox(height: 14),

                    Text("5. Contact Us",
                        style: sectionTitleStyle),
                    const SizedBox(height: 6),
                    Text(
                      "If you have any questions regarding this Privacy Policy, contact us at:",
                      style: bodyStyle,
                    ),

                    const SizedBox(height: 8),

                    GestureDetector(
                      onTap: _sendEmail,
                      child: const Text(
                        "pamusachi16@gmail.com",
                        style: TextStyle(
                          color: Color(0xFF8E9EFF), // lavender
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
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
