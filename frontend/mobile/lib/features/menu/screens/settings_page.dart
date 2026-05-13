import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'privacy_policy_page.dart';
import 'terms_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  Future<void> _sendFeedback() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'pamusach16@gmail.com',
      query: 'subject=App Feedback&body=Hi, I would like to share...',
    );

    if (!await launchUrl(emailUri)) {
      throw 'Could not open mail app';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6F3ED),
      body: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: const Color(0xFF2E8B82),
                width: 3,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                children: [

                  ///BACKGROUND IMAGE
                  Positioned.fill(
                    child: Image.asset(
                      "assets/images/settings_bg.png",
                      fit: BoxFit.cover,
                    ),
                  ),



                  /// MAIN CONTENT WITH ANIMATION
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: [

                            /// TOP BAR
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.close, size: 28),
                                  onPressed: () =>
                                      Navigator.pop(context),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 22, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius:
                                    BorderRadius.circular(30),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.settings),
                                      SizedBox(width: 8),
                                      Text(
                                        "Settings",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                              ],
                            ),

                            const SizedBox(height: 25),

                            /// PRIVACY SECTION
                            sectionTitle("Privacy"),
                            settingsTile("Privacy Policy", () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                  const PrivacyPolicyPage(),
                                ),
                              );
                            }),

                            settingsTile("Terms Of Service", () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                  const TermsPage(),
                                ),
                              );
                            }),

                            const SizedBox(height: 25),

                            /// ABOUT SECTION
                            sectionTitle("About"),
                            settingsTile("Version 1.0.0", () {}),
                            settingsTile("Rate App", () {}),
                            settingsTile("Send Feedback", _sendFeedback),

                            const Spacer(),

                            const Spacer(),


                          ],
                        ),
                      ),
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

  /// SECTION TITLE
  Widget sectionTitle(String text) {
    return Container(
      alignment: Alignment.centerLeft,
      margin: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  /// SETTINGS TILE
  Widget settingsTile(String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        color: const Color(0xFFF5EEDC),
        borderRadius: BorderRadius.circular(18),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
