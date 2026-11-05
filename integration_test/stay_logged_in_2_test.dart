/// Part 2 of 2. A new run of the app goes straight to the dashboard with no login,
/// silently replaces the expired access token, and then logs out for good.
library;

import 'package:du_student_app/api/api_client.dart';
import 'package:flutter/material.dart';
import 'package:du_student_app/main.dart' as app;
import 'package:du_student_app/screens/dashboard.dart';
import 'package:du_student_app/screens/login.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('reopening the app stays logged in until logout', (t) async {
    t.view.physicalSize = const Size(848, 1800);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);

    app.main();
    final d = Driver(t);
    await d.until(find.byType(DashboardScreen));
    expect(find.byType(LoginScreen), findsNothing);
    await d.see('Hi, Rakshit Gajera');
    await d.shot('70_reopened_still_logged_in');
    expect((await t.runAsync(SecureTokenStore().read))!.accessToken, isNot('expired-access-token'));

    await d.logout();
    expect(await t.runAsync(SecureTokenStore().read), isNull);
  });
}
