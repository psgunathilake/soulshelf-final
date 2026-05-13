import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import 'api_client.dart';

/// Thin dio wrapper over `/api/user`. The auth-related `/api/auth/me`
/// lives in `ApiAuthService` (it's tied to the auth-state stream). This
/// service only handles user-initiated profile mutations.
class ApiUserService {
  final ApiClient _api;

  ApiUserService(this._api);

  /// `PUT /api/user` — updates name / bio / preferences. Server returns
  /// the refreshed user row.
  Future<UserModel> updateProfile(UserModel user) async {
    final res = await _api.dio.put('/user', data: user.toApi());
    return UserModel.fromApi((res.data as Map).cast<String, dynamic>());
  }

  /// `PUT /api/user/pin` — server stores the pre-hashed digest. Returns
  /// 204; this method returns void on success.
  Future<void> setPin(String pinHash) async {
    await _api.dio.put('/user/pin', data: {'pin_hash': pinHash});
  }

  /// `POST /api/user/pin/verify` — returns `{valid: bool}`. Mismatch is
  /// 200 with `valid: false` (not 422) so callers don't need exception
  /// handling for the common wrong-PIN case.
  Future<bool> verifyPin(String pinHash) async {
    final res = await _api.dio.post(
      '/user/pin/verify',
      data: {'pin_hash': pinHash},
    );
    return (res.data['valid'] as bool?) ?? false;
  }

  /// `POST /api/user/avatar` (multipart). Returns the refreshed user row
  /// with `photo_url` populated.
  Future<UserModel> uploadAvatar(File file) => _uploadImage('/user/avatar', file);

  /// `POST /api/user/header` (multipart). Returns the refreshed user row
  /// with `header_url` populated.
  Future<UserModel> uploadHeader(File file) => _uploadImage('/user/header', file);

  Future<UserModel> _uploadImage(String path, File file) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split(Platform.pathSeparator).last,
      ),
    });
    final res = await _api.dio.post(
      path,
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
    return UserModel.fromApi((res.data as Map).cast<String, dynamic>());
  }
}

final apiUserServiceProvider = Provider<ApiUserService>((ref) {
  return ApiUserService(ref.watch(apiClientProvider));
});
