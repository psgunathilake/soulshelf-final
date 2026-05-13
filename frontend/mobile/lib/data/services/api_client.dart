import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

/// Default base URL for the Laravel API. `10.0.2.2` is the Android emulator's
/// host loopback; iOS simulator + desktop builds should pass
/// `--dart-define=API_BASE_URL=http://localhost:8000/api`.
const String _defaultBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000/api',
);

/// The API host without the `/api` suffix — used to rewrite asset URLs
/// (e.g. `/storage/...`) the backend stamps with `config('app.url')`,
/// which is often `localhost:8000` in dev and unreachable from the
/// emulator. See [coverImageProvider] for the rewrite logic.
final String apiHostUrl = _defaultBaseUrl.endsWith('/api')
    ? _defaultBaseUrl.substring(0, _defaultBaseUrl.length - 4)
    : _defaultBaseUrl;

/// Hive keys for the auth token cache.
const String _tokenKey = 'authToken';
const String _profileBoxName = 'profileBox';

/// Thin singleton wrapper around dio. Attaches the cached Bearer token to
/// every request and clears it from Hive on 401 responses.
class ApiClient {
  final Dio dio;

  ApiClient._(this.dio);

  factory ApiClient() {
    final instance = Dio(BaseOptions(
      baseUrl: _defaultBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      // Treat 4xx as exceptions so callers can `try/catch DioException`.
      validateStatus: (status) => status != null && status < 400,
    ));

    instance.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = Hive.box(_profileBoxName).get(_tokenKey) as String?;
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (e, handler) {
        if (e.response?.statusCode == 401) {
          // Token rejected by server — clear the cache so the auth-state
          // listener (api_auth_service) emits null and the app routes back
          // to login.
          Hive.box(_profileBoxName).delete(_tokenKey);
        }
        handler.next(e);
      },
    ));

    instance.interceptors.add(_RetryInterceptor(instance));

    return ApiClient._(instance);
  }

  static String get token =>
      (Hive.box(_profileBoxName).get(_tokenKey) as String?) ?? '';

  static Future<void> setToken(String token) =>
      Hive.box(_profileBoxName).put(_tokenKey, token);

  static Future<void> clearToken() =>
      Hive.box(_profileBoxName).delete(_tokenKey);
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

/// Retries transient connection-class failures once. HTTP errors are NOT
/// retried — they're deterministic (422/403/404/500 won't change on retry).
/// 500ms × 1.5 = 750ms wait before the single retry; the request is then
/// re-issued through the same dio instance so other interceptors still run.
class _RetryInterceptor extends Interceptor {
  static const _retriesKey = '_retries';
  static const _maxRetries = 1;
  final Dio _dio;

  _RetryInterceptor(this._dio);

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final attempts = (err.requestOptions.extra[_retriesKey] as int?) ?? 0;
    if (attempts >= _maxRetries || !_isRetryable(err)) {
      return handler.next(err);
    }

    err.requestOptions.extra[_retriesKey] = attempts + 1;
    await Future.delayed(const Duration(milliseconds: 750));

    try {
      final response = await _dio.fetch(err.requestOptions);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  static bool _isRetryable(DioException e) =>
      e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.sendTimeout;
}
