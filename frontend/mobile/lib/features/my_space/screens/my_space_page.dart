import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:soulshelf/data/repositories/user_repository.dart';
import 'journal_home_page.dart';

class MySpacePage extends ConsumerStatefulWidget {
  const MySpacePage({super.key});

  @override
  ConsumerState<MySpacePage> createState() => _MySpacePageState();
}

class _MySpacePageState extends ConsumerState<MySpacePage> {
  String enteredPin = "";

  @override
  void initState() {
    super.initState();
    // Default to '1234' on first entry so existing test installs and
    // the demo flow keep working. Phase 4 UX work can rework this into
    // an explicit "set your PIN" prompt.
    Future.microtask(() async {
      final repo = ref.read(userRepositoryProvider);
      if (!repo.hasPin()) {
        try {
          await repo.setPin('1234');
        } catch (_) {
          // Repository will have written to cache regardless of API
          // outcome; offline path enqueues. Nothing to surface here.
        }
      }
    });
  }

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

  Future<void> checkPin() async {
    final repo = ref.read(userRepositoryProvider);
    bool ok;
    try {
      ok = await repo.verifyPin(enteredPin);
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;

    if (ok) {
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
      backgroundColor: const Color(0xFFF6F4EF),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive sizing: scale the panda image with the screen
          // height and clamp it so it doesn't dominate small phones or
          // float lonely on tablets. Tighter ceiling than before so the
          // keypad always has room for 4 rows.
          final h = constraints.maxHeight;
          final imageHeight = (h * 0.18).clamp(90.0, 150.0);
          final topGap = (h * 0.02).clamp(8.0, 16.0);

          return Column(
            children: [
              /// TOP CONTENT — only respects status-bar inset
              SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    SizedBox(height: topGap),

                    /// TITLE
                    const Text(
                      "My Pin",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: topGap + 4),

                    /// PIN CIRCLES
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        4,
                        (index) => Container(
                          margin:
                              const EdgeInsets.symmetric(horizontal: 12),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF7E6B91),
                              width: 3,
                            ),
                            color: index < enteredPin.length
                                ? const Color(0xFF7E6B91)
                                : Colors.transparent,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: topGap),

                    Image.asset(
                      "assets/images/pin_pandas.png",
                      height: imageHeight,
                      fit: BoxFit.contain,
                    ),

                    SizedBox(height: topGap / 2),
                  ],
                ),
              ),

              /// PURPLE KEYPAD — full-bleed to bottom edge
              Expanded(
                child: Container(
                  width: double.infinity,
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFBFA3DE),
                        Color(0xFFA98DCB),
                        Color(0xFF9678BD),
                      ],
                      stops: [0.0, 0.55, 1.0],
                    ),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(40),
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Soft decorative bubble in the top-right of the
                      // keypad — gives the panel a bit of depth without
                      // competing with the buttons.
                      Positioned(
                        top: -40,
                        right: -30,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -50,
                        left: -40,
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                      ),

                      // Inner SafeArea keeps the buttons above the
                      // gesture bar while the purple itself bleeds
                      // underneath it.
                      SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
                          child: LayoutBuilder(
                            builder: (context, c) {
                              const cols = 3;
                              const rows = 4;
                              // Adapt spacing to height so very short
                              // keypad areas still fit; clamp so it never
                              // collapses or balloons.
                              final spacing =
                                  (c.maxHeight * 0.03).clamp(8.0, 16.0);

                              final cellW =
                                  (c.maxWidth - spacing * (cols - 1)) / cols;
                              final cellH =
                                  (c.maxHeight - spacing * (rows - 1)) / rows;
                              // Buttons stay circular by sizing to the
                              // smaller cell dimension; this guarantees
                              // they never overflow either axis.
                              final btnSize =
                                  cellW < cellH ? cellW : cellH;

                              Widget cell(int idx) {
                                final Widget btn = switch (idx) {
                                  9 => keyButton(
                                      icon: Icons.backspace_outlined,
                                      onTap: deletePin,
                                    ),
                                  10 => keyButton(
                                      text: "0",
                                      onTap: () => onNumberTap("0"),
                                    ),
                                  11 => keyButton(
                                      icon: Icons.check_rounded,
                                      onTap: checkPin,
                                    ),
                                  _ => keyButton(
                                      text: "${idx + 1}",
                                      onTap: () =>
                                          onNumberTap("${idx + 1}"),
                                    ),
                                };
                                return SizedBox(
                                  width: cellW,
                                  height: cellH,
                                  child: Center(
                                    child: SizedBox(
                                      width: btnSize,
                                      height: btnSize,
                                      child: btn,
                                    ),
                                  ),
                                );
                              }

                              Widget keypadRow(int r) => Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      cell(r * 3),
                                      cell(r * 3 + 1),
                                      cell(r * 3 + 2),
                                    ],
                                  );

                              return Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  keypadRow(0),
                                  keypadRow(1),
                                  keypadRow(2),
                                  keypadRow(3),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
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
      child: LayoutBuilder(
        builder: (context, c) {
          // Scale the glyph with the actual button size so it stays
          // proportional on small phones and tablets.
          final size = c.maxWidth;
          final textSize = (size * 0.36).clamp(16.0, 26.0);
          final iconSize = (size * 0.42).clamp(18.0, 30.0);
          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF2EAFB),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: text != null
                  ? Text(
                      text,
                      style: TextStyle(
                        fontSize: textSize,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF5C4B73),
                      ),
                    )
                  : Icon(
                      icon,
                      size: iconSize,
                      color: const Color(0xFF5C4B73),
                    ),
            ),
          );
        },
      ),
    );
  }
}