import '../api/api_client.dart';

class AuthRepo {
  const AuthRepo(this._api);
  final ApiClient _api;

  Future<bool> hasSession() async => await _api.tokens.read() != null;

  /// [identifier] is an email, mobile number or enrollment number.
  Future<void> login(String identifier, String password, {bool remember = true}) async {
    final response = await _api.post('/api/auth/login', body: {'identifier': identifier, 'password': password});
    final data = response.data as Map<String, dynamic>;
    await _api.tokens.write(TokenPair(data['accessToken'] as String, data['refreshToken'] as String), remember: remember);
  }

  /// JWTs are stateless and the API has no logout route, so this forgets them locally.
  Future<void> logout() => _api.tokens.clear();
}
