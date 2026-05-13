import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../core/utils/pin_hasher.dart';
import '../models/user_model.dart';
import '../services/api_user_service.dart';
import '../services/pending_writes_box.dart';

/// Reads/writes the single local user profile stored in profileBox under
/// key `profile`. Non-user keys in profileBox (isLoggedIn, mySpacePin,
/// themeMode, etc.) are left untouched by this repository.
///
/// As of Phase 3 the Laravel API is the source of truth. `saveProfile`
/// remains a cache-only write (used by the auth flow on register/login,
/// which already received the canonical user payload from the server).
/// `updateProfile` is the new user-initiated edit path that PUTs to
/// `/api/user` and mirrors the server's refreshed row to cache.
class UserRepository {
  static const _profileKey = 'profile';

  final ApiUserService _api;
  final PendingWritesBox _queue;

  UserRepository(this._api, this._queue);

  Box get _box => Hive.box('profileBox');

  UserModel? getProfile() {
    final raw = _box.get(_profileKey);
    return raw == null ? null : UserModel.fromHive(raw as Map);
  }

  /// Cache-only write. Used by the auth flow after register/login where
  /// the UserModel already came from the server response — no PUT is
  /// needed (or wanted; it would just round-trip the same data).
  Future<void> saveProfile(UserModel user) =>
      _box.put(_profileKey, user.toHive());

  /// User-initiated profile edit. Writes the optimistic value to cache,
  /// PUTs to /api/user, then replaces cache with the server's refreshed
  /// row. Offline → enqueue.
  Future<void> updateProfile(UserModel user) async {
    await _box.put(_profileKey, user.toHive());

    try {
      final server = await _api.updateProfile(user);
      // Preserve cache-only fields (pinHash) the API doesn't echo back.
      final merged = Map<String, dynamic>.from(server.toHive());
      if (user.pinHash != null) merged['pinHash'] = user.pinHash;
      await _box.put(_profileKey, merged);
    } on DioException catch (e) {
      if (!_isOffline(e)) rethrow;
      await _queue.enqueue('update.user', {'body': user.toApi()});
    }
  }

  Future<void> deleteProfile() => _box.delete(_profileKey);

  // ------- Image uploads -------

  /// Uploads a new avatar via `POST /user/avatar`. Mirrors the server's
  /// refreshed user row to cache (preserving pinHash) and returns it.
  /// Returns null when offline — image uploads can't queue (the file may
  /// be gone before the queue drains). Same contract as
  /// `MediaRepository.uploadCover`.
  Future<UserModel?> uploadAvatar(File file) =>
      _uploadAndMerge((f) => _api.uploadAvatar(f), file);

  /// Uploads a new header image via `POST /user/header`. Same offline
  /// semantics as [uploadAvatar].
  Future<UserModel?> uploadHeader(File file) =>
      _uploadAndMerge((f) => _api.uploadHeader(f), file);

  Future<UserModel?> _uploadAndMerge(
    Future<UserModel> Function(File) call,
    File file,
  ) async {
    try {
      final server = await call(file);
      final cached = getProfile();
      final merged = Map<String, dynamic>.from(server.toHive());
      if (cached?.pinHash != null) merged['pinHash'] = cached!.pinHash;
      await _box.put(_profileKey, merged);
      return UserModel.fromHive(merged);
    } on DioException catch (e) {
      if (_isOffline(e)) return null;
      rethrow;
    }
  }

  // ------- PIN -------

  /// True if a PIN has been set (cache-side check; doesn't hit the server).
  bool hasPin() {
    final raw = _box.get(_profileKey);
    if (raw is! Map) return false;
    final pinHash = raw['pinHash'] as String?;
    return pinHash != null && pinHash.isNotEmpty;
  }

  /// Hashes [pin] with the current user id, mirrors to the cache, then
  /// PUTs to the server. Offline → enqueue; the cache is updated either
  /// way so subsequent local verifies work.
  Future<void> setPin(String pin) async {
    final profile = getProfile();
    if (profile == null) {
      throw StateError('Cannot set PIN before user profile is loaded');
    }
    final hash = hashPin(pin, profile.uid);

    final raw = _box.get(_profileKey);
    final base = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    base['pinHash'] = hash;
    await _box.put(_profileKey, base);

    try {
      await _api.setPin(hash);
    } on DioException catch (e) {
      if (!_isOffline(e)) rethrow;
      await _queue.enqueue('set.pin', {'pin_hash': hash});
    }
  }

  /// Hashes [pin] and checks it against the server (when online) or
  /// against the cached hash (when offline). Wrong PIN returns false
  /// without throwing.
  Future<bool> verifyPin(String pin) async {
    final profile = getProfile();
    if (profile == null) return false;
    final hash = hashPin(pin, profile.uid);

    try {
      return await _api.verifyPin(hash);
    } on DioException catch (e) {
      if (!_isOffline(e)) rethrow;
      // Offline → fall back to cached hash. Set during last setPin or
      // most recent /auth/me … actually /auth/me doesn't echo pin_hash,
      // so the cache is only populated by setPin itself.
      final raw = _box.get(_profileKey);
      if (raw is! Map) return false;
      final cached = raw['pinHash'] as String?;
      return cached != null && cached == hash;
    }
  }

  static bool _isOffline(DioException e) =>
      e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.sendTimeout;
}

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final api = ref.watch(apiUserServiceProvider);
  final queue = ref.watch(pendingWritesBoxProvider);
  return UserRepository(api, queue);
});
