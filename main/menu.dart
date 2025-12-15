import 'package:flutter/material.dart';

class Menu extends StatefulWidget {
  final VoidCallback onClose;

  const Menu({super.key, required this.onClose});

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  bool darkMode = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
      decoration: const BoxDecoration(
        color: Color(0xFFD2B9A3), // beige background
      ),
      child: Column(
        children: [
          // ☰ Close button
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: const Icon(Icons.menu),
              onPressed: widget.onClose,
            ),
          ),

          const SizedBox(height: 20),

          menuButton(Icons.person, "Profile edit", () {}),
          menuButton(Icons.settings, "Settings", () {}),

          // 🌙 Dark Mode Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.dark_mode),
                  SizedBox(width: 10),
                  Text("Dark Mode"),
                ],
              ),
              Switch(
                value: darkMode,
                onChanged: (value) {
                  setState(() {
                    darkMode = value;
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 10),

          menuButton(Icons.help_outline, "Help & Support", () {}),

          const Spacer(),

          // 🐱 Illustration (optional)
          SizedBox(
            height: 120,
            child: Image.asset(
              "assets/cat_books.png",
              fit: BoxFit.contain,
            ),
          ),

          const SizedBox(height: 10),

          // 🚪 Logout
          TextButton(
            onPressed: () {},
            child: const Text(
              "Log out",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Menu Button
  Widget menuButton(IconData icon, String text, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.9),
          minimumSize: const Size(double.infinity, 45),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onTap,
        child: Row(
          children: [
            Icon(icon, color: Colors.black),
            const SizedBox(width: 10),
            Text(text, style: const TextStyle(color: Colors.black)),
          ],
        ),
      ),
    );
  }
}
