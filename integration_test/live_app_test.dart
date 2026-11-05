/// Runs the real app, with real secure storage and real HTTP, against a freshly
/// seeded API on the default local address. Goes through the UI like a student:
///
///   flutter test integration_test/live_app_test.dart -d windows
library;

import 'package:du_student_app/api/api_client.dart';
import 'package:du_student_app/providers/auth_provider.dart';
import 'package:du_student_app/screens/dashboard.dart';
import 'package:du_student_app/screens/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('log in, read every screen from the API, refresh silently, log out', (t) async {
    final d = await startApp(t);
    await d.shot('01_login');

    await d.login('000', 'wrong-password');
    await d.see('Invalid credentials');
    expect(find.byType(LoginScreen), findsOneWidget);

    await d.login('000', 'student123');
    await d.see('Hi, Rakshit Gajera');
    await d.see('BTech+Hons-5B | Roll No. 000 | Batch 2');
    await d.see('83.39%');
    await d.see('Sem - 5');
    await d.shot('02_dashboard');

    await d.open('Attendance');
    for (final v in ['09-Oct-26', 'A (e)', '241', '48', '347', '83.39%', '2026-27 - Odd']) {
      await d.see(v);
    }
    await d.shot('03_attendance');
    await d.tapText('Previous');
    await d.loaded();
    for (final v in ['2025-26 - Even', '90.03%', '100.00%']) {
      await d.see(v);
    }
    await d.tapRich('2025-26 - Even');
    await d.loaded();
    for (final v in ['Attendance Detail', '76.47%', 'PC I - Practical', '351', '316', '90.03%']) {
      await d.see(v);
    }
    await d.back();
    await d.close();

    await d.open('Results');
    for (final v in ['7.86', '7.17', '8.08', '8.46', '7.69', 'Sem Wise Result']) {
      await d.see(v);
    }
    await d.tapText('Sem - 4');
    await d.see('Back-End Web Technology');
    await d.see('Summer-2026');
    await d.shot('04_results');
    await d.tapText('Result');
    await d.tapText('Select Exam Result');
    await d.see('BTech Semester - 4 Regular Summer-2026');
    await t.tap(find.byIcon(Icons.close));
    await d.settle();
    await d.close();

    await d.open('LMS Dashboard');
    for (final v in ['Semester-5', 'Subjects', 'Graph Theory', 'Sem - BTech+Hons-5B', '2401CS521']) {
      await d.see(v);
    }
    await d.tapText('Design and Analysis of Algorithm');
    await d.loaded();
    for (final v in ['Presentation (5)', 'Lab Manual (3)', 'Unit-1 Introduction', '27-06-2026', 'By: Rakshit Gajera', 'Seen on 05-11-2026']) {
      await d.see(v);
    }
    await d.shot('05_lms_subject');
    await d.tapText('Lab Manual (3)');
    await d.see('Practical Dates');
    await d.back();
    await d.close();

    await d.open('Mentoring');
    for (final v in ['Assistant Professor', 'rakshit.gajera@example.com', '18-03-2026 01:29 PM', 'Demo mentoring discussion']) {
      await d.see(v);
    }
    await d.shot('06_mentoring');
    await d.tapText("Mentor's History");
    await d.see('24-11-2025  - 01-08-2026');
    await d.see('Meetings : 2');
    await d.close();

    await d.open('Transport');
    for (final v in ['SAMPLE', 'Bus Pass No. SAMPLE/0000', 'Demo Pickup Point', 'Bus No. 00 - Demo Route', '₹ 0', 'DEMO-CSE-5']) {
      await d.see(v);
    }
    for (final v in ['Bus Code', 'BUS-00', 'Pickup Address', 'Demo Pickup Address']) {
      await d.see(v);
    }
    await d.shot('07_transport');
    await d.tapText('Receipt');
    await d.see('SAMPLE/R/0006');
    await d.close();

    await d.open('LMS Test Result');
    await d.see('DAA (2301CS402)');
    await d.tapRich('CN (2301CS501)');
    await d.see('24 / 30');
    await d.see('Attempt - 2');
    await d.tapText('Sem  - 6');
    await d.see('LMS Mark Not Found');
    await d.close();

    await d.open('Circular');
    for (final v in ['Theory Semester End Examination', 'Demo circular.', '15-09-2026']) {
      await d.see(v);
    }
    d.missing('**');
    await d.shot('08_circulars');
    await d.close();

    await d.open('Grievance Registration');
    for (final v in ['Seat broken', '2024/00090', 'Water leakage in bus', 'Pending', 'Resolved']) {
      await d.see(v);
    }
    await d.shot('09_grievances');
    await d.close();

    await d.open('Certificate Request');
    for (final v in ['DU - Bonafide Certificate', 'Pending', 'In Person']) {
      await d.see(v);
    }
    await d.close();

    await d.open('Exam Schedule');
    for (final v in ['12-10-2026 To 17-10-2026', 'Theory Semester End Examination']) {
      await d.see(v);
    }
    await d.shot('10_schedule');
    await d.close();

    // Silent refresh: a useless access token must not interrupt the student.
    final container = ProviderScope.containerOf(t.element(find.byType(DashboardScreen)));
    final store = container.read(tokenStoreProvider);
    final saved = await t.runAsync(store.read);
    await t.runAsync(() => store.write(TokenPair('not-a-valid-token', saved!.refreshToken)));
    await d.open('Circular');
    await d.see('Demo circular.');
    await d.close();
    final refreshed = await t.runAsync(store.read);
    expect(refreshed!.accessToken, isNot('not-a-valid-token'));
    expect(find.byType(LoginScreen), findsNothing);

    // The session really is in secure storage: a new store reads the same tokens.
    expect((await t.runAsync(SecureTokenStore().read))!.accessToken, refreshed.accessToken);

    // A rejected refresh token sends the student back to login.
    await t.runAsync(() => store.write(const TokenPair('not-a-valid-token', 'not-a-valid-refresh-token')));
    await t.tap(find.byIcon(Icons.menu));
    await d.settle();
    await t.tap(find.text('Circular').last);
    await d.until(find.byType(LoginScreen));
    expect(await t.runAsync(SecureTokenStore().read), isNull);

    // Log in again, then log out from the profile menu.
    await d.login('000', 'student123');
    await d.see('Hi, Rakshit Gajera');
    await d.logout();
    expect(await t.runAsync(SecureTokenStore().read), isNull);
  });
}
