import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../repositories/auth_repo.dart';

final tokenStoreProvider = Provider<TokenStore>((ref) => SecureTokenStore());

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(
      tokens: ref.watch(tokenStoreProvider),
      baseUrl: apiBaseUrl,
      onSessionExpired: () => ref.read(authProvider.notifier).sessionExpired(),
    ));

final authRepoProvider = Provider<AuthRepo>((ref) => AuthRepo(ref.watch(apiClientProvider)));

enum AuthStatus { unknown, signedIn, signedOut }

class AuthNotifier extends Notifier<AuthStatus> {
  @override
  AuthStatus build() => AuthStatus.unknown;

  /// Reads stored tokens at startup. An expired token is handled on the first request.
  Future<AuthStatus> restore() async {
    state = await ref.read(authRepoProvider).hasSession() ? AuthStatus.signedIn : AuthStatus.signedOut;
    return state;
  }

  Future<void> login(String identifier, String password, {bool remember = true}) async {
    await ref.read(authRepoProvider).login(identifier, password, remember: remember);
    state = AuthStatus.signedIn;
  }

  Future<void> logout() async {
    await ref.read(authRepoProvider).logout();
    state = AuthStatus.signedOut;
  }

  void sessionExpired() => state = AuthStatus.signedOut;
}

final authProvider = NotifierProvider<AuthNotifier, AuthStatus>(AuthNotifier.new);
