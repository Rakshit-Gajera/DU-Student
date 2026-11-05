import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Override with `--dart-define=API_BASE_URL=https://...`. The defaults reach an
/// API running on this machine; the Android emulator sees the host as 10.0.2.2.
final String apiBaseUrl = () {
  const defined = String.fromEnvironment('API_BASE_URL');
  if (defined.isNotEmpty) return defined;
  final android = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  return android ? 'http://10.0.2.2:4000' : 'http://localhost:4000';
}();

/// Turns "/uploads/x.jpeg" from the API into a full URL.
String resolveApiUrl(String path) => Uri.parse(apiBaseUrl).resolve(path).toString();

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class TokenPair {
  const TokenPair(this.accessToken, this.refreshToken);
  final String accessToken;
  final String refreshToken;
}

abstract class TokenStore {
  Future<TokenPair?> read();

  /// [remember] false keeps the session in memory only, so it ends with the app.
  /// Leaving it out keeps the earlier choice, which is what a token refresh wants.
  Future<void> write(TokenPair tokens, {bool? remember});
  Future<void> clear();
}

class SecureTokenStore implements TokenStore {
  SecureTokenStore([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  final FlutterSecureStorage _storage;
  TokenPair? _cached;
  bool _loaded = false;
  bool _remember = true;

  @override
  Future<TokenPair?> read() async {
    if (_loaded) return _cached;
    final access = await _storage.read(key: _accessKey);
    final refresh = await _storage.read(key: _refreshKey);
    _cached = access != null && refresh != null ? TokenPair(access, refresh) : null;
    _loaded = true;
    return _cached;
  }

  @override
  Future<void> write(TokenPair tokens, {bool? remember}) async {
    _cached = tokens;
    _loaded = true;
    _remember = remember ?? _remember;
    if (!_remember) {
      await _storage.delete(key: _accessKey);
      await _storage.delete(key: _refreshKey);
      return;
    }
    await _storage.write(key: _accessKey, value: tokens.accessToken);
    await _storage.write(key: _refreshKey, value: tokens.refreshToken);
  }

  @override
  Future<void> clear() async {
    _cached = null;
    _loaded = true;
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}

/// One `{ success, data, meta }` response.
class ApiEnvelope {
  const ApiEnvelope(this.data, this.meta);
  final dynamic data;
  final Map<String, dynamic>? meta;
}

class ApiClient {
  ApiClient({required this.tokens, required String baseUrl, HttpClientAdapter? adapter, this.onSessionExpired}) {
    final options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
    );
    _dio = Dio(options);
    _refreshDio = Dio(options);
    if (adapter != null) {
      _dio.httpClientAdapter = adapter;
      _refreshDio.httpClientAdapter = adapter;
    }
    _dio.interceptors.add(InterceptorsWrapper(onRequest: _attachToken, onError: _refreshOn401));
  }

  final TokenStore tokens;

  /// Called when the refresh token is rejected, so the user must log in again.
  final void Function()? onSessionExpired;

  late final Dio _dio;

  /// Has no interceptors, so a rejected refresh cannot trigger another refresh.
  late final Dio _refreshDio;

  /// Shared by every request that hits a 401 while a refresh is running.
  Future<String>? _refreshing;

  static const _retriedKey = 'retried_after_refresh';
  static const _sentTokenKey = 'sent_access_token';

  Future<void> _attachToken(RequestOptions options, RequestInterceptorHandler handler) async {
    if (!_isAuthRoute(options)) {
      final current = await tokens.read();
      if (current != null) {
        options.headers['Authorization'] = 'Bearer ${current.accessToken}';
        options.extra[_sentTokenKey] = current.accessToken;
      }
    }
    handler.next(options);
  }

  Future<void> _refreshOn401(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    if (err.response?.statusCode != 401 || _isAuthRoute(options) || options.extra[_retriedKey] == true) {
      return handler.next(err);
    }
    try {
      // Another request may have refreshed while this one was on its way back.
      final current = await tokens.read();
      if (current == null || current.accessToken == options.extra[_sentTokenKey]) {
        await (_refreshing ??= _refresh().whenComplete(() => _refreshing = null));
      }
      options.extra[_retriedKey] = true;
      handler.resolve(await _dio.fetch<dynamic>(options));
    } on _SessionExpired {
      handler.next(err);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  Future<String> _refresh() async {
    final current = await tokens.read();
    if (current == null) {
      onSessionExpired?.call();
      throw const _SessionExpired();
    }
    final Response<dynamic> response;
    try {
      response = await _refreshDio.post<dynamic>('/api/auth/refresh', data: {'refreshToken': current.refreshToken});
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      // Only a rejected token ends the session. Being offline or a server error does not.
      if (status == 400 || status == 401) {
        await tokens.clear();
        onSessionExpired?.call();
        throw const _SessionExpired();
      }
      rethrow;
    }
    // The user logged out while the refresh was running: do not bring the session back.
    if ((await tokens.read())?.refreshToken != current.refreshToken) throw const _SessionExpired();
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    final access = data['accessToken'] as String;
    await tokens.write(TokenPair(access, data['refreshToken'] as String));
    return access;
  }

  bool _isAuthRoute(RequestOptions options) => options.path.startsWith('/api/auth/');

  Future<ApiEnvelope> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get<dynamic>(path, queryParameters: query));

  Future<ApiEnvelope> post(String path, {Object? body}) => _send(() => _dio.post<dynamic>(path, data: body));

  /// Follows `meta.totalPages` and returns the items of every page.
  Future<List<T>> getAll<T>(String path, T Function(Map<String, dynamic>) parse, {Map<String, dynamic>? query}) async {
    final items = <T>[];
    for (var page = 1;; page++) {
      final response = await get(path, query: {...?query, 'page': page, 'limit': 100});
      items.addAll((response.data as List).cast<Map<String, dynamic>>().map(parse));
      final totalPages = (response.meta?['totalPages'] as num?)?.toInt() ?? 1;
      if (page >= totalPages) return items;
    }
  }

  Future<ApiEnvelope> _send(Future<Response<dynamic>> Function() request) async {
    try {
      final body = (await request()).data as Map<String, dynamic>;
      return ApiEnvelope(body['data'], body['meta'] as Map<String, dynamic>?);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  ApiException _toApiException(DioException e) {
    final response = e.response;
    if (response == null) {
      return const ApiException('Could not reach the server. Check your connection and try again.');
    }
    final body = response.data;
    final message = body is Map && body['error'] is String ? body['error'] as String : 'The server could not complete this request.';
    return ApiException(message, statusCode: response.statusCode);
  }
}

class _SessionExpired implements Exception {
  const _SessionExpired();
}
