import 'dart:async';

import 'package:du_student_app/api/api_client.dart';
import 'package:du_student_app/main.dart';
import 'package:du_student_app/models/student_models.dart';
import 'package:du_student_app/providers/auth_provider.dart';
import 'package:du_student_app/repositories/auth_repo.dart';
import 'package:du_student_app/screens/attendance.dart';
import 'package:du_student_app/screens/dashboard.dart';
import 'package:du_student_app/screens/feedback_lms.dart';
import 'package:du_student_app/screens/lms.dart';
import 'package:du_student_app/screens/login.dart';
import 'package:du_student_app/screens/mentoring.dart';
import 'package:du_student_app/screens/requests.dart';
import 'package:du_student_app/screens/results.dart';
import 'package:du_student_app/screens/transport.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixture_repo.dart';

/// Every call waits on [gate], then fails while [failing] is set.
class ControlledRepo extends FixtureStudentRepo {
  ControlledRepo({this.failing = false});
  bool failing;
  Completer<void>? gate;

  Future<T> _run<T>(Future<T> Function() ok) async {
    await gate?.future;
    if (failing) throw const ApiException('Could not reach the server. Check your connection and try again.');
    return ok();
  }

  @override
  Future<Profile> profile() => _run(super.profile);
  @override
  Future<List<Subject>> subjects() => _run(super.subjects);
  @override
  Future<List<AttendanceRow>> attendance() => _run(super.attendance);
  @override
  Future<AttendanceSummary?> attendanceSummary() => _run(super.attendanceSummary);
  @override
  Future<List<BusReceipt>> busReceipts() => _run(super.busReceipts);
  @override
  Future<List<LmsTestResult>> lmsTestResults() => _run(super.lmsTestResults);
  @override
  Future<List<PastSem>> pastSemesters() => _run(super.pastSemesters);
  @override
  Future<List<CourseRow>> courseAttendance() => _run(super.courseAttendance);
  @override
  Future<ResultsData> results() => _run(super.results);
  @override
  Future<List<ContentItem>> presentations(String subjectId) => _run(() => super.presentations(subjectId));
  @override
  Future<List<ContentItem>> labManuals(String subjectId) => _run(() => super.labManuals(subjectId));
  @override
  Future<MentoringData> mentoring() => _run(super.mentoring);
  @override
  Future<List<BusPass>> transport() => _run(super.transport);
  @override
  Future<List<Circular>> circulars() => _run(super.circulars);
  @override
  Future<List<Grievance>> grievances() => _run(super.grievances);
  @override
  Future<List<CertificateRequest>> certificates() => _run(super.certificates);
  @override
  Future<List<ExamEntry>> examSchedule(ExamType type) => _run(() => super.examSchedule(type));
}

class FakeAuthRepo implements AuthRepo {
  FakeAuthRepo(this.store);
  final TokenStore store;
  Object? loginError;

  @override
  Future<bool> hasSession() async => await store.read() != null;
  @override
  Future<void> login(String identifier, String password, {bool remember = true}) async {
    if (loginError != null) throw loginError!;
    await store.write(const TokenPair('a', 'r'));
  }

  @override
  Future<void> logout() => store.clear();
}

final screens = <String, Widget>{
  'dashboard': const DashboardScreen(),
  'attendance current': const AttendanceScreen(),
  'attendance previous': const AttendanceScreen(initialTab: 1),
  'attendance detail': const AttendanceDetailScreen(),
  'results': const ResultsScreen(),
  'lms': const LmsScreen(),
  'lms subject': LmsSubjectScreen(subject: fixtureDaa),
  'mentoring': const MentoringScreen(),
  'transport': TransportScreen(fixedTime: DateTime(2026, 11, 5)),
  'circulars': const CircularScreen(),
  'grievances': const GrievanceScreen(),
  'certificates': const CertificateScreen(),
  'exam schedule': const ScheduleScreen(),
  'lms test results': const LmsResultScreen(),
};

Future<void> pumpScreen(WidgetTester t, Widget screen, ControlledRepo repo) async {
  t.view.physicalSize = const Size(1272, 2772);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  await t.pumpWidget(ProviderScope(overrides: fixtureOverrides(repo: repo), retry: (_, _) => null, child: DuApp(home: screen)));
}

void main() {
  setUpAll(loadFonts);

  for (final MapEntry(key: name, value: screen) in screens.entries) {
    testWidgets('$name: skeleton, then error card, then data after retry', (t) async {
      final repo = ControlledRepo(failing: true)..gate = Completer();
      await pumpScreen(t, screen, repo);
      await t.pump();
      expect(find.byKey(const Key('skeleton')), findsWidgets);
      expect(find.byKey(const Key('error-card')), findsNothing);

      repo.gate!.complete();
      await t.pump();
      await t.pump();
      expect(find.byKey(const Key('skeleton')), findsNothing);
      expect(find.byKey(const Key('error-card')), findsOneWidget);
      expect(find.textContaining('Could not reach the server'), findsOneWidget);

      repo.failing = false;
      repo.gate = Completer();
      await t.tap(find.byKey(const Key('retry')));
      await t.pump();
      await t.pump();
      expect(find.byKey(const Key('skeleton')), findsWidgets, reason: 'retry shows the skeleton again');

      repo.gate!.complete();
      await t.pump();
      await t.pump();
      await t.pump();
      expect(find.byKey(const Key('skeleton')), findsNothing);
      expect(find.byKey(const Key('error-card')), findsNothing);
      await t.pumpWidget(const SizedBox());
    });
  }

  testWidgets('the bus pass always carries the SAMPLE watermark', (t) async {
    await pumpScreen(t, TransportScreen(fixedTime: DateTime(2026, 11, 5)), ControlledRepo());
    await t.pump();
    await t.pump();
    expect(find.text('SAMPLE'), findsOneWidget);
    expect(find.text('Bus Pass No. SAMPLE/0000'), findsOneWidget);
    expect(find.text('Demo Pickup Point'), findsOneWidget);
  });

  testWidgets('circular Markdown is rendered, not shown as source', (t) async {
    await pumpScreen(t, const CircularScreen(), ControlledRepo());
    await t.pump();
    await t.pump();
    expect(find.textContaining('**', findRichText: true), findsNothing);
    expect(find.textContaining('Demo circular.', findRichText: true), findsWidgets);
  });

  group('login', () {
    late MemoryTokenStore store;
    late FakeAuthRepo auth;

    Future<void> pumpApp(WidgetTester t, Widget home) async {
      t.view.physicalSize = const Size(1272, 2772);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      await t.pumpWidget(ProviderScope(
        overrides: [...fixtureOverrides(tokens: store), authRepoProvider.overrideWithValue(auth)],
        retry: (_, _) => null,
        child: DuApp(home: home),
      ));
    }

    setUp(() {
      store = MemoryTokenStore();
      auth = FakeAuthRepo(store);
    });

    testWidgets('splash goes to login without a stored session', (t) async {
      await pumpApp(t, const SplashScreen());
      await t.pump(const Duration(seconds: 2));
      await t.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('splash goes to the dashboard with a stored session', (t) async {
      store.tokens = const TokenPair('a', 'r');
      await pumpApp(t, const SplashScreen());
      await t.pump(const Duration(seconds: 2));
      await t.pumpAndSettle();
      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.text('Hi, Rakshit Gajera'), findsOneWidget);
    });

    testWidgets('empty fields are not submitted', (t) async {
      auth.loginError = StateError('should not be called');
      await pumpApp(t, const LoginScreen());
      await t.tap(find.byKey(const Key('login')));
      await t.pump();
      expect(find.byKey(const Key('login-error')), findsOneWidget);
    });

    testWidgets('a wrong password shows the server message and stays on login', (t) async {
      auth.loginError = const ApiException('Invalid credentials', statusCode: 401);
      await pumpApp(t, const LoginScreen());
      await t.enterText(find.byKey(const Key('enrollment')), '000');
      await t.enterText(find.byKey(const Key('password')), 'wrong');
      await t.tap(find.byKey(const Key('login')));
      await t.pumpAndSettle();
      expect(find.text('Invalid credentials'), findsOneWidget);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('logging in opens the dashboard and logout returns to login', (t) async {
      await pumpApp(t, const LoginScreen());
      await t.enterText(find.byKey(const Key('enrollment')), '000');
      await t.enterText(find.byKey(const Key('password')), 'pw');
      await t.tap(find.byKey(const Key('login')));
      await t.pumpAndSettle();
      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(store.tokens, isNotNull);

      await t.tap(find.byType(GestureDetector).first);
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('logout')));
      await t.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(DashboardScreen), findsNothing);
      expect(store.tokens, isNull);
    });

    testWidgets('a rejected refresh returns to login from a screen deep in the stack', (t) async {
      store.tokens = const TokenPair('a', 'r');
      await pumpApp(t, const SplashScreen());
      await t.pump(const Duration(seconds: 2));
      await t.pumpAndSettle();
      final container = ProviderScope.containerOf(t.element(find.byType(DashboardScreen)));
      Navigator.of(t.element(find.byType(DashboardScreen))).push(MaterialPageRoute(builder: (_) => const MentoringScreen()));
      await t.pumpAndSettle();

      container.read(authProvider.notifier).sessionExpired();
      await t.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(MentoringScreen), findsNothing);
    });
  });
}
