import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import '../services/api_auth_service.dart';
import 'user_repository.dart';

enum AuthStatus { unknown, unauthenticated, awaitingVerification, authenticated }

class AuthFailure implements Exception {
  final String code;
  final String message;
  AuthFailure(this.code, this.message);

  @override
  String toString() => message;
}

class AuthRepository {
  final ApiAuthService _service;
  final UserRepository _userRepo;

  AuthRepository(this._service, this._userRepo);

  Stream<UserModel?> get userChanges =>
      _service.authStateChanges().map((s) => s.user);

  Stream<AuthStatus> get statusStream =>
      _service.authStateChanges().map(_statusForState);

  AuthStatus get currentStatus => _statusForUser(_service.currentUser);

  UserModel? get currentUser => _service.currentUser;

  AuthStatus _statusForState(AuthState s) {
    if (s.initializing) return AuthStatus.unknown;
    return _statusForUser(s.user);
  }

  AuthStatus _statusForUser(UserModel? u) {
    if (u == null) return AuthStatus.unauthenticated;
    return u.emailVerified
        ? AuthStatus.authenticated
        : AuthStatus.awaitingVerification;
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final user =
          await _service.register(name: name, email: email, password: password);
      await _userRepo.saveProfile(user);
      return user;
    } on DioException catch (e) {
      throw _failureFor(e);
    }
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _service.login(email: email, password: password);
      final existing = _userRepo.getProfile();
      if (existing == null || existing.uid != user.uid) {
        await _userRepo.saveProfile(user);
      }
      return user;
    } on DioException catch (e) {
      throw _failureFor(e);
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _service.sendPasswordReset(email);
    } on DioException catch (e) {
      throw _failureFor(e);
    }
  }

  Future<void> resendVerificationEmail() async {
    try {
      await _service.sendEmailVerification();
    } on DioException catch (e) {
      throw _failureFor(e);
    }
  }

  Future<bool> reloadAndCheckVerified() async {
    final user = await _service.reloadUser();
    return user?.emailVerified ?? false;
  }

  Future<void> signOut() => _service.signOut();

  AuthFailure _failureFor(DioException e) {
    // Network errors (no response from server)
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return AuthFailure(
          'network-request-failed', 'Network error. Check your connection.');
    }

    final res = e.response;
    final status = res?.statusCode ?? 0;
    final data = res?.data;

    // Laravel 422 — validation failures
    if (status == 422 && data is Map && data['errors'] is Map) {
      final errors = (data['errors'] as Map).cast<String, dynamic>();

      if (errors['email'] is List) {
        final messages =
            (errors['email'] as List).whereType<String>().join(' ').toLowerCase();
        if (messages.contains('already been taken')) {
          return AuthFailure('email-already-in-use',
              'An account already exists for that email.');
        }
        if (messages.contains('credentials are incorrect') ||
            messages.contains('invalid')) {
          return AuthFailure(
              'invalid-credential', 'Email or password is incorrect.');
        }
      }
      if (errors['password'] is List) {
        return AuthFailure(
            'weak-password',
            'Password is too weak. Use 8+ chars with a digit, '
            'an uppercase and a lowercase letter.');
      }
      // Generic validation error — surface the first message.
      final firstField = errors.entries.first;
      final firstMsg = (firstField.value as List).whereType<String>().firstOrNull
          ?? 'Please check the form and try again.';
      return AuthFailure('validation-failed', firstMsg);
    }

    // 401 / 403 / 419 — auth issues
    if (status == 401 || status == 403) {
      return AuthFailure(
          'invalid-credential', 'Email or password is incorrect.');
    }

    // 5xx
    if (status >= 500) {
      return AuthFailure(
          'server-error', 'Server error. Please try again shortly.');
    }

    return AuthFailure('unknown-error',
        (data is Map && data['message'] is String)
            ? data['message'] as String
            : 'Authentication failed.');
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final service = ref.watch(apiAuthServiceProvider);
  final userRepo = ref.watch(userRepositoryProvider);
  return AuthRepository(service, userRepo);
});
