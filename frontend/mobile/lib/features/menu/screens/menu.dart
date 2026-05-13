import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'profile_edit_page.dart';
import 'settings_page.dart';
import 'help_support_page.dart';
import 'package:soulshelf/data/repositories/auth_repository.dart';
import 'package:soulshelf/data/services/pending_writes_box.dart';
import 'package:soulshelf/data/services/sync_service.dart';
import 'package:soulshelf/features/auth/screens/login_page.dart';
import 'package:soulshelf/core/theme/theme_controller.dart';

class Menu extends ConsumerStatefulWidget {
  static const double width = 280;

  final VoidCallback onClose;

  const Menu({super.key, required this.onClose});

  @override
  ConsumerState<Menu> createState() => _MenuState();
}

class _MenuState extends ConsumerState<Menu> {
  bool get isDarkMode =>
      ThemeController.themeMode.value == ThemeMode.dark;

  /// Local "in-flight" flag for the manual Sync-now action so the chip
  /// can show a spinner while the drain runs. SyncService itself
  /// guards against concurrent drains, so re-taps are safe no-ops.
  bool _manualSyncing = false;

  Future<void> _onSyncTap() async {
    if (_manualSyncing) return;
    setState(() => _manualSyncing = true);
    try {
      await ref.read(syncServiceProvider).sync();
    } finally {
      if (mounted) setState(() => _manualSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [

        /// BACKGROUND IMAGE
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Image.asset(
              "assets/images/menu_bg.png",
              fit: BoxFit.cover,
            ),
          ),
        ),

        Container(
          width: Menu.width,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),

          decoration: BoxDecoration(
            color: const Color(0xFFFFF5E6).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFF4F7C5B),
              width: 2,
            ),
          ),

          child: Column(
            children: [

              // Close button
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onClose,
                ),
              ),

              const SizedBox(height: 12),

              // Logo
              Column(
                children: [
                  CircleAvatar(
                    radius: 65,
                    backgroundColor: const Color(0xFFF8F6EC),
                    child: ClipOval(
                      child: Image.asset(
                        "assets/images/app_logo.png",
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Your Space",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // Profile Edit
              menuButton(
                Icons.person,
                "Profile edit",
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProfileEditPage(),
                    ),
                  );
                },
              ),

              // Settings
              menuButton(
                Icons.settings,
                "Settings",
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SettingsPage(),
                    ),
                  );
                },
              ),

              // Dark Mode
              ValueListenableBuilder<ThemeMode>(
                valueListenable: ThemeController.themeMode,
                builder: (_, mode, __) {
                  final bool darkMode = mode == ThemeMode.dark;

                  return Row(
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
                        onChanged: (_) {
                          ThemeController.toggleTheme();
                        },
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 12),

              // Help & Support
              menuButton(
                Icons.help_outline,
                "Help & Support",
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HelpSupportPage(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 6),

              // Pending writes chip — visible only when the offline
              // queue has entries. Tap to manually trigger a drain.
              _buildPendingChip(),

              const Spacer(),

              // Panda Image
              const SizedBox(
                height: 240,
                child: Center(
                  child: Image(
                    image: AssetImage("assets/images/panda.png"),
                    height: 210,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(height: 6),

              // Logout
              TextButton(
                onPressed: () async {
                  await ref.read(authRepositoryProvider).signOut();
                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginPage(),
                    ),
                        (_) => false,
                  );
                },
                child: const Text(
                  "Log out",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget menuButton(
      IconData icon,
      String text,
      VoidCallback onTap,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.94),
          minimumSize: const Size(double.infinity, 45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 1.5,
        ),
        onPressed: onTap,
        child: Row(
          children: [
            Icon(icon, color: Colors.black87),
            const SizedBox(width: 10),
            Text(
              text,
              style: const TextStyle(
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Pending-writes chip. Hidden while the offline queue is empty so it
  /// only surfaces when there's actually something to show. Reads the
  /// count from a Hive watch stream, so it updates live as enqueue /
  /// drain happens.
  Widget _buildPendingChip() {
    final asyncCount = ref.watch(pendingWritesCountProvider);
    final count = asyncCount.value ?? 0;

    if (count == 0 && !_manualSyncing) {
      return const SizedBox.shrink();
    }

    final label = _manualSyncing
        ? 'Syncing…'
        : count == 1
            ? '1 pending write'
            : '$count pending writes';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: _manualSyncing ? null : _onSyncTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
            child: Row(
              children: [
                if (_manualSyncing)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF8A6D00),
                    ),
                  )
                else
                  const Icon(Icons.sync,
                      size: 18, color: Color(0xFF8A6D00)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF6B5400),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (!_manualSyncing)
                  const Text(
                    'Tap to sync',
                    style: TextStyle(
                      color: Color(0xFF8A6D00),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}