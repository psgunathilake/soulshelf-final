import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Thin wrapper around `connectivity_plus`. "Online" = at least one
/// non-`none` connectivity result (wifi/mobile/ethernet/etc.). We don't
/// ping the server to verify real reachability — that's overkill for this
/// app and would just delay drains.
class ConnectivityService {
  final Connectivity _conn;

  ConnectivityService([Connectivity? conn]) : _conn = conn ?? Connectivity();

  Stream<bool> get onlineStream =>
      _conn.onConnectivityChanged.map(_anyOnline);

  Future<bool> isOnline() async {
    final results = await _conn.checkConnectivity();
    return _anyOnline(results);
  }

  static bool _anyOnline(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);
}

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});
