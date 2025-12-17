import 'package:flutter/material.dart';
import 'journal_home_page.dart';

class MySpacePage extends StatefulWidget {
  const MySpacePage({super.key});

  @override
  State<MySpacePage> createState() => _MySpacePageState();
}

class _MySpacePageState extends State<MySpacePage> {
  final String correctPin = "1234";
  String enteredPin = "";

  void onNumberTap(String number) {
    if (enteredPin.length < 4) {
      setState(() => enteredPin += number);

      if (enteredPin.length == 4) {
        checkPin();
      }
    }
  }

  void deletePin() {
    if (enteredPin.isNotEmpty) {
      setState(() {
        enteredPin =
            enteredPin.substring(0, enteredPin.length - 1);
      });
    }
  }

  void checkPin() {
    if (enteredPin == correctPin) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const JournalHomePage(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Wrong PIN")),
      );
      setState(() => enteredPin = "");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),

            const Text(
              "My Space",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Enter your private PIN",
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 28),

            // 🔵 PIN DOTS (SMALLER & CLEAN)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                4,
                    (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < enteredPin.length
                        ? const Color(0xFF8BB4E8)
                        : Colors.grey.shade300,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // 🔢 KEYPAD (COMPACT)
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 40, vertical: 30),
                decoration: const BoxDecoration(
                  color: Color(0xFF8BB4E8),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                ),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 12,
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 18,
                    crossAxisSpacing: 18,
                  ),
                  itemBuilder: (context, index) {
                    if (index == 9) {
                      return keyButton(
                        icon: Icons.backspace_outlined,
                        onTap: deletePin,
                      );
                    } else if (index == 10) {
                      return keyButton(
                        text: "0",
                        onTap: () => onNumberTap("0"),
                      );
                    } else if (index == 11) {
                      return keyButton(
                        icon: Icons.check_rounded,
                        onTap: checkPin,
                      );
                    } else {
                      return keyButton(
                        text: "${index + 1}",
                        onTap: () =>
                            onNumberTap("${index + 1}"),
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget keyButton({
    String? text,
    IconData? icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.95),
        ),
        child: Center(
          child: text != null
              ? Text(
            text,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          )
              : Icon(icon, size: 22),
        ),
      ),
    );
  }
}
