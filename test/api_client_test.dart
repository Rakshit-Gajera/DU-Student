import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:du_student_app/api/api_client.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixture_repo.dart';

/// Answers like the API: a data route needs the current access token, and
/// /api/auth/refresh swaps the refresh token for a new pair.
class FakeApi implements HttpClientAdapter {
  String validAccess = 'new-access';
  String validRefresh = 'old-refresh';
  int refreshCalls = 0;
  int refreshStatus = 200;
  bool offline = false;
  Completer<void>? holdRefresh;
  final dataHeaders = <String?>[];

  ResponseBody _json(int status, Object body) => ResponseBody.fromString(jsonEncode(body), status, headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      });

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? requestStream, Future<void>? cancelFuture) async {
    if (offline) throw DioException.connectionError(requestOptions: options, reason: 'offline');
    if (options.path == '/api/auth/refresh') {
      refreshCalls++;
      await holdRefresh?.future;
      if (refreshStatus != 200) return _json(refreshStatus, {'success': false, 'error': 'Invalid or expired refresh token'});
      if (options.data['refreshToken'] != validRefresh) return _json(401, {'success': false, 'error': 'Invalid or expired refresh token'});
      return _json(200, {
        'success': true,
        'data': {'accessToken': validAccess, 'refreshToken': 'new-refresh', 'expiresIn': 900},
      });
    }
    if (options.path == '/api/auth/login') return _json(401, {'success': false, 'error': 'Invalid credentials'});
    final auth = options.headers['Authorization'] as String?;
    dataHeaders.add(auth);
    if (auth != 'Bearer $validAccess') return _json(401, {'success': false, 'error': 'Authentication required'});
    if (options.path == '/api/paged') {
      final page = options.queryParameters['page'] as int;
      return _json(200, {
        'success': true,
        'data': [{'n': page}],
        'meta': {'page': page, 'limit': 100, 'total': 3, 'totalPages': 3},
      });
    }
    return _json(200, {'success': true, 'data': 'ok'});
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late FakeApi api;
  late MemoryTokenStore store;
  late ApiClient client;
  late int expired;

  setUp(() {
    api = FakeApi();
    store = MemoryTokenStore(const TokenPair('expired-access', 'old-refresh'));
    expired = 0;
    client = ApiClient(tokens: store, baseUrl: 'http://test', adapter: api, onSessionExpired: () => expired++);
  });

  test('an expired access token refreshes silently and the request is retried', () async {
    final response = await client.get('/api/x');

    expect(response.data, 'ok');
    expect(api.refreshCalls, 1);
    expect(api.dataHeaders, ['Bearer expired-access', 'Bearer new-access']);
    expect(store.tokens!.accessToken, 'new-access');
    expect(store.tokens!.refreshToken, 'new-refresh', reason: 'the rotated refresh token must be stored');
    expect(expired, 0);
  });

  test('requests that fail together share one refresh', () async {
    api.holdRefresh = Completer();
    final all = Future.wait([client.get('/api/a'), client.get('/api/b'), client.get('/api/c')]);
    await pumpEventQueue();
    api.holdRefresh!.complete();

    expect((await all).map((r) => r.data), ['ok', 'ok', 'ok']);
    expect(api.refreshCalls, 1);
  });

  test('a rejected refresh token ends the session', () async {
    api.refreshStatus = 401;

    await expectLater(client.get('/api/x'), throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 401)));
    expect(store.tokens, isNull);
    expect(expired, 1);
  });

  test('a server error during refresh keeps the session', () async {
    api.refreshStatus = 500;

    await expectLater(client.get('/api/x'), throwsA(isA<ApiException>()));
    expect(store.tokens, isNotNull);
    expect(expired, 0);
  });

  test('being offline is a friendly error and keeps the session', () async {
    api.offline = true;

    await expectLater(client.get('/api/x'), throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('Could not reach'))));
    expect(store.tokens, isNotNull);
    expect(expired, 0);
  });

  test('a wrong password does not try to refresh', () async {
    await expectLater(client.post('/api/auth/login', body: {}), throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Invalid credentials')));
    expect(api.refreshCalls, 0);
    expect(expired, 0);
  });

  test('a refresh that finishes after logout does not restore the session', () async {
    api.holdRefresh = Completer();
    final request = client.get('/api/x');
    await pumpEventQueue();
    await store.clear();
    api.holdRefresh!.complete();

    await expectLater(request, throwsA(isA<ApiException>()));
    expect(store.tokens, isNull);
  });

  test('getAll follows every page', () async {
    store.tokens = TokenPair(api.validAccess, 'old-refresh');

    final pages = await client.getAll('/api/paged', (j) => j['n'] as int);

    expect(pages, [1, 2, 3]);
  });
}
