import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../models/user_model.dart';
import 'api_client.dart';

/// Auth-state snapshot pushed by [ApiAuthService.authStateChanges].
class AuthState {
  final UserModel? user;
  final bool initializing;

  const AuthState({this.user, this.initializing = false});

  const AuthState.unknown() : this(user: null, initializing: true);
  const AuthState.unauthenticated() : this(user: null, initializing: false);
  const AuthState.authenticated(UserModel user)
      : this(user: user, initializing: false);
}

/// HTTP wrapper around the Laravel `/api/auth/*` endpoints. Mirrors the
/// surface of the previous FirebaseAuthService so AuthRepository didn't
/// need a structural rewrite.
class ApiAuthService {
  final ApiClient _api;
  final _stateController = StreamController<AuthState>.broadcast();

  UserModel? _currentUser;

  ApiAuthService(this._api) {
    // Synchronously hydrate the in-memory user from the cached Hive
    // profile so callers reading `currentUser` / `currentStatus` on
    // app launch see the authenticated state immediately, instead of
    // racing the async `/auth/me` validation in `_bootstrap`. Without
    // this, the entrance page reads `null` and routes to login on
    // every cold start.
    final token = ApiClient.token;
    final rawProfile = Hive.box('profileBox').get('profile');
    debugPrint(
        '[AUTH BOOT] token=${token.isEmpty ? "EMPTY" : "len=${token.length}"} '
        'profile=${rawProfile == null ? "NULL" : "Map(${(rawProfile as Map).keys.toList()})"}');
    if (token.isNotEmpty) {
      if (rawProfile is Map) {
        try {
          _currentUser = UserModel.fromHive(rawProfile);
          debugPrint(
              '[AUTH BOOT] hydrated currentUser: uid=${_currentUser!.uid} '
              'email=${_currentUser!.email} verified=${_currentUser!.emailVerified}');
        } catch (e, st) {
          debugPrint('[AUTH BOOT] fromHive THREW: $e\n$st');
        }
      } else {
        debugPrint('[AUTH BOOT] token present but profile cache is empty/null');
      }
    }

    // Replay the latest state to new listeners.
    _stateController.onListen = () {
      _stateController.add(_currentSnapshot());
    };

    // Bootstrap: if a token is cached, validate it against /me. Otherwise
    // emit unauthenticated immediately.
    _bootstrap();

    // Watch for token changes (e.g., 401 interceptor clears it) and re-emit.
    Hive.box('profileBox').watch(key: 'authToken').listen((_) {
      if (ApiClient.token.isEmpty && _currentUser != null) {
        _currentUser = null;
        _emit();
      }
    });
  }

  Stream<AuthState> authStateChanges() => _stateController.stream;

  UserModel? get currentUser => _currentUser;

  Future<void> _bootstrap() async {
    if (ApiClient.token.isEmpty) {
      _currentUser = null;
      _emit();
      return;
    }
    try {
      final res = await _api.dio.get('/auth/me');
      _currentUser =
          UserModel.fromApi(res.data['user'] as Map<String, dynamic>);
      _emit();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // Token actually rejected by the server — the 401 interceptor
        // has wiped it from Hive. Surface as unauthenticated.
        _currentUser = null;
        _emit();
        return;
      }
      // Network error / server unreachable — the token is still
      // presumed valid. Fall back to the cached profile so the user
      // doesn't get kicked to login every time the dev server
      // restarts or the network briefly drops. The 401 interceptor
      // will catch the token if it's actually invalid the next time
      // a request makes it through.
      final cached = Hive.box('profileBox').get('profile');
      if (cached is Map) {
        _currentUser = UserModel.fromHive(cached);
      } else {
        _currentUser = null;
      }
      _emit();
    } catch (_) {
      _currentUser = null;
      _emit();
    }
  }

  AuthState _currentSnapshot() => _currentUser == null
      ? const AuthState.unauthenticated()
      : AuthState.authenticated(_currentUser!);

  void _emit() => _stateController.add(_currentSnapshot());

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final res = await _api.dio.post('/auth/register', data: {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': password,
    });
    final user = UserModel.fromApi(res.data['user'] as Map<String, dynamic>);
    final token = res.data['token'] as String;
    await ApiClient.setToken(token);
    _currentUser = user;
    _emit();
    return user;
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final res = await _api.dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final user = UserModel.fromApi(res.data['user'] as Map<String, dynamic>);
    final token = res.data['token'] as String;
    await ApiClient.setToken(token);
    _currentUser = user;
    _emit();
    return user;
  }

  Future<void> sendPasswordReset(String email) =>
      _api.dio.post('/auth/forgot-password', data: {'email': email});

  Future<void> sendEmailVerification() async {
    await _api.dio.post('/auth/email/resend');
  }

  /// Re-fetch the current user from the server so callers can re-check
  /// `emailVerified`.
  Future<UserModel?> reloadUser() async {
    if (ApiClient.token.isEmpty) return null;
    try {
      final res = await _api.dio.get('/auth/me');
      _currentUser =
          UserModel.fromApi(res.data['user'] as Map<String, dynamic>);
      _emit();
      return _currentUser;
    } on DioException {
      return _currentUser;
    }
  }

  Future<void> updateDisplayName(String name) async {
    // No dedicated endpoint yet — name was set during register. Profile
    // update lands in Phase 3 with PUT /api/user.
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(name: name);
      _emit();
    }
  }

  Future<void> signOut() async {
    try {
      if (ApiClient.token.isNotEmpty) {
        await _api.dio.post('/auth/logout');
      }
    } on DioException {
      // Network error during logout is non-fatal — we still clear local state.
    } finally {
      await ApiClient.clearToken();
      _currentUser = null;
      _emit();
    }
  }
}

final apiAuthServiceProvider = Provider<ApiAuthService>((ref) {
  return ApiAuthService(ref.watch(apiClientProvider));
});
