import 'package:du_student_app/main.dart';
import 'package:du_student_app/screens/all_menu.dart';
import 'package:du_student_app/screens/attendance.dart';
import 'package:du_student_app/screens/dashboard.dart';
import 'package:du_student_app/screens/feedback_lms.dart';
import 'package:du_student_app/screens/requests.dart';
import 'package:du_student_app/screens/results.dart';
import 'package:du_student_app/screens/lms.dart';
import 'package:du_student_app/screens/login.dart';
import 'package:du_student_app/screens/mentoring.dart';
import 'package:du_student_app/screens/transport.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixture_repo.dart';

/// Renders each screen at the reference phone's 1272x2772 @3x so the output
/// can be overlaid on the screenshots in test/goldens/reference. Data comes from
/// test/fixtures/seed.json, which is what the API returns after seeding.
Future<void> shot(WidgetTester t, String name, Widget screen, {Future<void> Function()? then}) async {
  t.view.physicalSize = const Size(1272, 2772);
  t.view.devicePixelRatio = 3;
  t.view.padding = const FakeViewPadding(top: 144, bottom: 69);
  addTearDown(t.view.reset);
  debugDisableShadows = false;
  await t.pumpWidget(ProviderScope(overrides: fixtureOverrides(), retry: (_, _) => null, child: DuApp(home: screen)));
  // Lets the fixture data reach the screen, so its images can be precached below.
  await t.pump();
  await t.pump();
  await t.runAsync(() async {
    for (final e in find.byType(Image).evaluate()) {
      await precacheImage((e.widget as Image).image, e);
    }
    for (final e in find.byType(CircleAvatar).evaluate()) {
      final bg = (e.widget as CircleAvatar).backgroundImage;
      if (bg != null) await precacheImage(bg, e);
    }
    for (final e in find.byType(Container).evaluate()) {
      final d = (e.widget as Container).decoration;
      if (d is BoxDecoration && d.image != null) await precacheImage(d.image!.image, e);
    }
  });
  await t.pump();
  if (then != null) await then();
  await t.pump(const Duration(seconds: 1));
  await expectLater(find.byType(DuApp), matchesGoldenFile('goldens/out/$name.png'));
  debugDisableShadows = true;
}

void main() {
  setUpAll(loadFonts);

  testWidgets('splash', (t) => shot(t, 'splash', const SplashScreen(autoAdvance: false)));
  testWidgets('login', (t) => shot(t, 'login', const LoginScreen()));
  testWidgets('dashboard_top', (t) => shot(t, 'dashboard_top', const DashboardScreen()));
  testWidgets('dashboard_bottom', (t) => shot(t, 'dashboard_bottom', const DashboardScreen(), then: () async {
        await t.drag(find.byType(ListView).first, const Offset(0, -700));
        await t.pumpAndSettle();
      }));
  testWidgets('profile_menu', (t) => shot(t, 'profile_menu', const DashboardScreen(), then: () async {
        await t.tap(find.byType(GestureDetector).first);
        await t.pumpAndSettle();
      }));
  testWidgets('all_menu', (t) => shot(t, 'all_menu', const AllMenuScreen()));
  testWidgets('attendance_current', (t) => shot(t, 'attendance_current', const AttendanceScreen()));
  testWidgets('attendance_previous', (t) => shot(t, 'attendance_previous', const AttendanceScreen(initialTab: 1)));
  testWidgets('attendance_detail', (t) => shot(t, 'attendance_detail', const AttendanceDetailScreen()));
  testWidgets('lms', (t) => shot(t, 'lms', const LmsScreen()));
  testWidgets('lms_presentation', (t) => shot(t, 'lms_presentation', LmsSubjectScreen(subject: fixtureDaa)));
  testWidgets('lms_lab', (t) => shot(t, 'lms_lab', LmsSubjectScreen(subject: fixtureDaa, initialLab: true)));
  testWidgets('mentoring', (t) => shot(t, 'mentoring', const MentoringScreen()));
  testWidgets('transport', (t) => shot(t, 'transport', TransportScreen(fixedTime: DateTime(2026, 11, 5, 10, 58, 54))));

  Future<void> tapText(WidgetTester t, String s) async { await t.tap(find.text(s).first); await t.pumpAndSettle(); }
  Future<void> tapKey(WidgetTester t, String s) async { await t.tap(find.byKey(Key(s))); await t.pumpAndSettle(); }
  testWidgets('n_history', (t) => shot(t, 'n_history', const MentoringScreen(initialTab: 1), then: () => t.pumpAndSettle()));
  testWidgets('n_timetable', (t) => shot(t, 'n_timetable', const MentoringScreen(initialTab: 2), then: () => t.pumpAndSettle()));
  testWidgets('n_res4', (t) => shot(t, 'n_res4', const ResultsScreen(openSem: 4)));
  testWidgets('n_res3', (t) => shot(t, 'n_res3', const ResultsScreen(openSem: 3)));
  testWidgets('n_res2', (t) => shot(t, 'n_res2', const ResultsScreen(openSem: 2)));
  testWidgets('n_res1', (t) => shot(t, 'n_res1', const ResultsScreen(openSem: 1)));
  testWidgets('n_res0', (t) => shot(t, 'n_res0', const ResultsScreen()));
  testWidgets('n_restab', (t) => shot(t, 'n_restab', const ResultsScreen(initialTab: 1)));
  testWidgets('n_ressheet', (t) => shot(t, 'n_ressheet', const ResultsScreen(initialTab: 1), then: () => tapText(t, 'Select Exam Result')));
  testWidgets('n_cal', (t) => shot(t, 'n_cal', const AcademicCalendarScreen()));
  testWidgets('n_dcr', (t) => shot(t, 'n_dcr', const DataChangeScreen()));
  testWidgets('n_dcradd', (t) => shot(t, 'n_dcradd', const DataChangeScreen(), then: () => tapKey(t, 'add')));
  testWidgets('n_dcrtype', (t) => shot(t, 'n_dcrtype', const DataChangeScreen(), then: () async { await tapKey(t, 'add'); await tapText(t, 'Select Data Change Request Type'); }));
  testWidgets('n_fbac', (t) => shot(t, 'n_fbac', const FeedbackScreen()));
  testWidgets('n_fbov', (t) => shot(t, 'n_fbov', const FeedbackScreen(overall: true)));
  testWidgets('n_lr5', (t) => shot(t, 'n_lr5', const LmsResultScreen()));
  testWidgets('n_lr5o', (t) => shot(t, 'n_lr5o', const LmsResultScreen(openIndex: 1)));
  testWidgets('n_lr6', (t) => shot(t, 'n_lr6', const LmsResultScreen(sem: 6)));
  testWidgets('n_gr', (t) => shot(t, 'n_gr', const GrievanceScreen()));
  testWidgets('n_grx', (t) => shot(t, 'n_grx', const GrievanceScreen(expanded: true)));
  testWidgets('n_grfilter', (t) => shot(t, 'n_grfilter', const GrievanceScreen(), then: () => tapKey(t, 'filter')));
  testWidgets('n_gradd', (t) => shot(t, 'n_gradd', const GrievanceScreen(), then: () => tapKey(t, 'add')));
  testWidgets('n_grtype', (t) => shot(t, 'n_grtype', const GrievanceScreen(), then: () async { await tapKey(t, 'add'); await tapText(t, 'Select Grievance Type'); }));
  testWidgets('n_sch0', (t) => shot(t, 'n_sch0', const ScheduleScreen()));
  testWidgets('n_sch1', (t) => shot(t, 'n_sch1', const ScheduleScreen(initialTab: 1)));
  testWidgets('n_circ', (t) => shot(t, 'n_circ', const CircularScreen()));
  testWidgets('n_cert', (t) => shot(t, 'n_cert', const CertificateScreen()));
  testWidgets('n_certadd', (t) => shot(t, 'n_certadd', const AddCertificateScreen()));
  testWidgets('n_certdel', (t) => shot(t, 'n_certdel', const AddCertificateScreen(), then: () => tapKey(t, 'delivery')));
  testWidgets('n_certcop', (t) => shot(t, 'n_certcop', const AddCertificateScreen(), then: () => tapKey(t, 'copies')));
  testWidgets('n_certtype', (t) => shot(t, 'n_certtype', const AddCertificateScreen(), then: () => tapKey(t, 'cert')));
}
