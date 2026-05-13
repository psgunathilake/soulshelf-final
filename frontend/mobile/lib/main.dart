import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:soulshelf/features/auth/screens/entrance_page.dart';
import 'package:soulshelf/core/config/api_keys.dart';
import 'package:soulshelf/core/messenger.dart';
import 'package:soulshelf/core/theme/theme_controller.dart';
import 'package:soulshelf/data/services/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox('profileBox');
  await Hive.openBox('journalBox');
  await Hive.openBox('booksBox');
  await Hive.openBox('songsBox');
  await Hive.openBox('showsBox');
  await Hive.openBox('plannerBox');
  await Hive.openBox('collectionsBox');
  await Hive.openBox('pendingWritesBox');

  ApiKeys.debugLogStatus();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    // Boot the offline-write drainer. Triggers a cold-start drain if a
    // previous session left work in pendingWritesBox and we're online.
    ref.read(syncServiceProvider).start();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeMode,
      builder: (_, mode, __) {
        return MaterialApp(
          scaffoldMessengerKey: scaffoldMessengerKey,
          debugShowCheckedModeBanner: false,
          title: 'SoulShelf',
          themeMode: mode,

          ///LIGHT THEME
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorSchemeSeed: Colors.green,

            scaffoldBackgroundColor: const Color(0xFFEFF8E6),

            /// GLOBAL TEXT COLORS
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Colors.black),
              bodyMedium: TextStyle(color: Colors.black87),
              bodySmall: TextStyle(color: Colors.black54),
              titleLarge: TextStyle(color: Colors.black),
            ),

            /// ICON COLOR
            iconTheme: const IconThemeData(
              color: Colors.black87,
            ),

            /// GLASS CARD SUPPORT
            cardTheme: CardThemeData(
              color: Colors.white.withValues(alpha:0.6),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),

            /// GLOBAL PAGE TRANSITIONS
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: _FadeScaleTransitionBuilder(),
                TargetPlatform.iOS: _FadeScaleTransitionBuilder(),
                TargetPlatform.windows: _FadeScaleTransitionBuilder(),
                TargetPlatform.macOS: _FadeScaleTransitionBuilder(),
                TargetPlatform.linux: _FadeScaleTransitionBuilder(),
              },
            ),
          ),

          ///DARK THEME
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,

            scaffoldBackgroundColor: const Color(0xFF1F2623),
            canvasColor: const Color(0xFF262E2A),

            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF7FBF9C),
              secondary: Color(0xFF9BD1A8),
              surface: Color(0xFF2E3733),
            ),

            /// APP BAR
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF262E2A),
              foregroundColor: Colors.white,
            ),

            /// DARK GLASS CARDS
            cardTheme: CardThemeData(
              color: Colors.black.withValues(alpha:0.35),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),

            /// DIALOG
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFF2E3733),
            ),

            dividerColor: Colors.white24,

            /// ICONS
            iconTheme: const IconThemeData(
              color: Color(0xFF9BD1A8),
            ),

            /// GLOBAL TEXT COLORS
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Colors.white),
              bodyMedium: TextStyle(color: Colors.white70),
              bodySmall: TextStyle(color: Colors.white60),
              titleLarge: TextStyle(color: Colors.white),
            ),

            /// GLOBAL PAGE TRANSITIONS
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: _FadeScaleTransitionBuilder(),
                TargetPlatform.iOS: _FadeScaleTransitionBuilder(),
                TargetPlatform.windows: _FadeScaleTransitionBuilder(),
                TargetPlatform.macOS: _FadeScaleTransitionBuilder(),
                TargetPlatform.linux: _FadeScaleTransitionBuilder(),
              },
            ),
          ),

          home: const EntrancePage(),
        );
      },
    );
  }
}

/// GLOBAL FADE + SCALE PAGE TRANSITION
class _FadeScaleTransitionBuilder extends PageTransitionsBuilder {
  const _FadeScaleTransitionBuilder();

  @override
  Widget buildTransitions<T>(
      PageRoute<T> route,
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
      ) {

    final fadeAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    final scaleAnimation = Tween<double>(
      begin: 0.96,
      end: 1.0,
    ).animate(fadeAnimation);

    return FadeTransition(
      opacity: fadeAnimation,
      child: ScaleTransition(
        scale: scaleAnimation,
        child: child,
      ),
    );
  }
}