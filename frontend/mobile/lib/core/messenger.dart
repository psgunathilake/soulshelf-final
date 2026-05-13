import 'package:flutter/material.dart';

/// Global scaffold messenger key used by services that need to post
/// snackbars without a [BuildContext] (e.g. [SyncService] when a drain
/// completes). Wired into [MaterialApp.scaffoldMessengerKey] in main.dart.
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
