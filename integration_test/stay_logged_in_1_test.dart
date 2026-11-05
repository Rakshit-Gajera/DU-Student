/// Part 1 of 2. Logs in and leaves the app with an expired-looking access token,
/// like a phone that has not opened the app for a while. Part 2 is a separate run
/// of the real app, so everything it knows comes from secure storage.
library;

import 'package:du_student_app/api/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('log in and close the app', (t) async {
    final d = await startApp(t);
    await d.login('000', 'student123');
    await d.see('Hi, Rakshit Gajera');

    final store = SecureTokenStore();
    final saved = (await t.runAsync(store.read))!;
    await t.runAsync(() => store.write(TokenPair('expired-access-token', saved.refreshToken)));
  });
}
