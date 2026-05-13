import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  final String imagePath;

  const AppBackground({
    super.key,
    required this.child,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {

    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [

        /// Background Image
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(imagePath),
              fit: BoxFit.cover,
            ),
          ),
        ),

        /// Dark Mode Overlay
        if (isDark)
          Container(
            color: Colors.black.withValues(alpha: 0.45),
          ),

        /// Page Content
        child,
      ],
    );
  }
}