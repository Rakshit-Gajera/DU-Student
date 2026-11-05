/// Checks the real API client and repository against a running, freshly seeded API.
/// Skipped unless LIVE_API_URL is set:
///
///   LIVE_API_URL=http://localhost:4000 flutter test test/live_api_test.dart
///
/// The last group draws screens from the API and compares them with the goldens,
/// which are drawn from test/fixtures/seed.json, so they must match pixel for pixel.
library;

import 'dart:io';

import 'package:du_student_app/api/api_client.dart';
import 'package:du_student_app/format.dart';
import 'package:du_student_app/main.dart';
import 'package:du_student_app/models/student_models.dart';
import 'package:du_student_app/repositories/auth_repo.dart';
import 'package:du_student_app/repositories/student_repo.dart';
import 'package:du_student_app/screens/attendance.dart';
import 'package:du_student_app/screens/dashboard.dart';
import 'package:du_student_app/screens/feedback_lms.dart';
import 'package:du_student_app/screens/lms.dart';
import 'package:du_student_app/screens/mentoring.dart';
import 'package:du_student_app/screens/requests.dart';
import 'package:du_student_app/screens/results.dart';
import 'package:du_student_app/screens/transport.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixture_repo.dart';

/// What the real client got from the API. Real HTTP cannot run inside a widget test's
/// fake clock, so the requests are made first and the screens drawn from their results.
class FetchedRepo extends FixtureStudentRepo {
  FetchedRepo._(this.profileData, this.subjectList, this.grid, this.summary, this.past, this.courses, this.resultData, this.slides, this.labs, this.mentoringData, this.passes, this.circularList, this.grievanceList, this.certificateList, this.exams, this.receipts, this.lmsResults);

  static Future<FetchedRepo> load(StudentRepo r, String subjectId) async => FetchedRepo._(
        await r.profile(),
        await r.subjects(),
        await r.attendance(),
        await r.attendanceSummary(),
        await r.pastSemesters(),
        await r.courseAttendance(),
        await r.results(),
        await r.presentations(subjectId),
        await r.labManuals(subjectId),
        await r.mentoring(),
        await r.transport(),
        await r.circulars(),
        await r.grievances(),
        await r.certificates(),
        {for (final type in ExamType.values) type: await r.examSchedule(type)},
        await r.busReceipts(),
        await r.lmsTestResults(),
      );

  final Profile profileData;
  final List<Subject> subjectList;
  final List<AttendanceRow> grid;
  final AttendanceSummary? summary;
  final List<PastSem> past;
  final List<CourseRow> courses;
  final ResultsData resultData;
  final List<ContentItem> slides;
  final List<ContentItem> labs;
  final MentoringData mentoringData;
  final List<BusPass> passes;
  final List<Circular> circularList;
  final List<Grievance> grievanceList;
  final List<CertificateRequest> certificateList;
  final Map<ExamType, List<ExamEntry>> exams;
  final List<BusReceipt> receipts;
  final List<LmsTestResult> lmsResults;

  /// The golden draws the bundled copy of the photo. The served copy is checked separately.
  @override
  Future<Profile> profile() async => Profile(
        name: profileData.name,
        classLabel: profileData.classLabel,
        batch: profileData.batch,
        rollNo: profileData.rollNo,
        currentSem: profileData.currentSem,
        mobile: profileData.mobile,
        mentor: profileData.mentor,
      );
  @override
  Future<List<Subject>> subjects() async => subjectList;
  @override
  Future<List<AttendanceRow>> attendance() async => grid;
  @override
  Future<AttendanceSummary?> attendanceSummary() async => summary;
  @override
  Future<List<PastSem>> pastSemesters() async => past;
  @override
  Future<List<CourseRow>> courseAttendance() async => courses;
  @override
  Future<ResultsData> results() async => resultData;
  @override
  Future<List<ContentItem>> presentations(String subjectId) async => slides;
  @override
  Future<List<ContentItem>> labManuals(String subjectId) async => labs;
  @override
  Future<MentoringData> mentoring() async => mentoringData;
  @override
  Future<List<BusPass>> transport() async => passes;
  @override
  Future<List<Circular>> circulars() async => circularList;
  @override
  Future<List<Grievance>> grievances() async => grievanceList;
  @override
  Future<List<CertificateRequest>> certificates() async => certificateList;
  @override
  Future<List<ExamEntry>> examSchedule(ExamType type) async => exams[type]!;
  @override
  Future<List<BusReceipt>> busReceipts() async => receipts;
  @override
  Future<List<LmsTestResult>> lmsTestResults() async => lmsResults;
}

void main() {
  final url = Platform.environment['LIVE_API_URL'];
  final skip = url == null ? 'Set LIVE_API_URL to run against a seeded API' : null;

  group('seeded API', skip: skip, () {
    late StudentRepo repo;
    late MemoryTokenStore store;
    late ApiClient client;
    late Subject daa;

    setUpAll(() async {
      HttpOverrides.global = null; // flutter test blocks real HTTP by default.
      store = MemoryTokenStore();
      client = ApiClient(tokens: store, baseUrl: url!);
      await AuthRepo(client).login('000', 'student123');
      repo = StudentRepo(client);
      daa = (await repo.subjects()).first;
    });

    test('profile', () async {
      final p = await repo.profile();
      expect(p.name, 'Rakshit Gajera');
      expect(p.headline, 'BTech+Hons-5B | Roll No. 000 | Batch 2');
      expect(p.currentSem, 5);
      expect(p.mentor!.department, 'Computer Science & Engineering');
      expect(initials(p.mentor!.department!), 'CSE');
      expect('${p.mentor!.designation} | ${p.mentor!.officeNo}', 'Assistant Professor | 00');
    });

    test('the photo in the profile is served', () async {
      final photo = (await repo.profile()).photoUrl!;
      final request = await HttpClient().getUrl(Uri.parse(url!).resolve(photo));
      final response = await request.close();
      await response.drain<void>();
      expect(response.statusCode, 200);
      expect(response.headers.contentType?.mimeType, 'image/jpeg');
    });

    test('subjects', () async {
      expect((await repo.subjects()).map((s) => s.code), ['2301CS402', '2301CS501', '2301CS595', '2301CS632', '2301HS503', '2401CS521']);
    });

    test('attendance grid', () async {
      final rows = await repo.attendance();
      expect(rows, hasLength(11));
      expect('${gridDate(rows.first.date)} ${rows.first.day}', '09-Oct-26 Fri');
      expect(rows.first.slots, ['NA', 'NA', 'NA', 'NA', '-']);
      final examDay = rows.firstWhere((r) => gridDate(r.date) == '26-Sep-26');
      expect(examDay.slots, ['A (e)', '-', '-', '-', '-']);
      expect(gridDate(rows.last.date), '24-Sep-26');
      expect(rows.last.slots, ['P', 'P', 'A', 'P', '-']);
    });

    test('current semester totals', () async {
      final s = (await repo.attendanceSummary())!;
      expect(s.yearLabel, '2026-27 - Odd');
      expect(s.percent, 83.39);
      expect([s.present, s.absent, s.pending, s.noAttendance, s.total], [241, 48, 0, 58, 347]);
    });

    test('past semesters and course attendance', () async {
      expect((await repo.pastSemesters()).map((s) => '${s.sem} ${s.year} ${s.percent.toStringAsFixed(2)}'),
          ['4 2025-26 - Even 90.03', '3 2025-26 - Odd 94.24', '2 2024-25 - Even 92.11', '1 2024-25 - Odd 100.00']);
      final courses = await repo.courseAttendance();
      expect(courses, hasLength(12));
      expect(courses.first.course, '2301CS401 - Database Management System - II - Practical');
      expect(courses.first.percent.toStringAsFixed(2), '76.47');
      expect(courses.last.course, 'PC I - Practical');
      expect(courses.fold(0, (n, c) => n + c.total), 351);
      expect(courses.fold(0, (n, c) => n + c.present), 316);
    });

    test('results', () async {
      final r = await repo.results();
      expect(r.cpi.toStringAsFixed(2), '7.86');
      expect(r.backlogs, 0);
      expect(r.semesters.map((s) => s.exam).first, 'BTech Semester - 4 Regular Summer-2026');
      expect(r.totalSubjects, 24);
      expect(r.passed, 24);
      expect(r.semesters.map((s) => '${s.sem}:${s.spi.toStringAsFixed(2)}'), ['4:7.17', '3:8.08', '2:8.46', '1:7.69']);
      expect(r.semesters.first.rows.map((c) => '${c.code} ${c.grade} ${c.season} ${c.attemptNo}').first, '2301CS401 A Summer-2026 1');
      // The old hard-coded tiles said A 9 and B+ 4, which did not match the app's own course rows.
      expect(r.grades.map((g) => '${g.grade}=${g.count}'), ['A++=1', 'A+=6', 'A=10', 'B+=3', 'B=3', 'P=1']);
    });

    test('LMS', () async {
      final slides = await repo.presentations(daa.id);
      expect(slides, hasLength(5));
      expect(slides.every((s) => s.seen), isTrue);
      expect(istDate(slides.first.seenAt!), '05-11-2026');
      expect(calendarDate(slides.first.uploadedAt), '27-06-2026');
      final labs = await repo.labManuals(daa.id);
      expect(labs.map((l) => l.title).toSet(), {'Practical Dates', 'BTech CSE DAA - Lab manual solution', 'B.Sc. (Hons.) CS  DAA - Lab manual solution'});
    });

    test('mentoring', () async {
      final m = await repo.mentoring();
      expect(m.mentor!.email, 'rakshit.gajera@example.com');
      expect(m.history.map((h) => '${calendarDate(h.fromDate)} ${h.toDate == null ? '-' : calendarDate(h.toDate!)} ${h.meetings}'),
          ['11-08-2026 - 0', '24-11-2025 01-08-2026 1', '10-10-2024 31-05-2025 2']);
      expect(m.sessions.map((s) => '${istDateTime(s.when)} ${s.issue}'), [
        '18-03-2026 01:29 PM Demo mentoring discussion',
        '04-03-2025 11:27 AM Demo lab schedule discussion',
        '12-09-2024 10:15 AM Demo attendance discussion',
      ]);
    });

    test('transport', () async {
      final pass = (await repo.transport()).single;
      expect(pass.passNo, 'SAMPLE/0000');
      expect(pass.batchCode, 'DEMO-CSE-5');
      expect(pass.busCode, 'BUS-00');
      expect(pass.pickupAddress, 'Demo Pickup Address');
      expect(pass.busRoute, 'Bus No. 00 - Demo Route - Shift-1');
      expect(pass.pickupPoint, 'Demo Pickup Point');
      expect(pass.shift, 'Shift-1 (Morning Shift)(07:45 AM to 01:50 PM)');
      expect([pass.feesAmount, pass.feesPaid, pass.pending], [0, 0, 0]);
    });

    test('bus receipts and LMS test results', () async {
      expect(await repo.busReceipts(), hasLength(6));
      final marks = await repo.lmsTestResults();
      expect(marks.first.semNo, 5);
      expect(marks.first.course, 'DAA (2301CS402)');
      expect('${marks.first.marks} / ${marks.first.maxMarks}', '24 / 30');
    });

    test('logs in with enrollment no. and mobile, and refuses a wrong password', () async {
      Future<void> login(String id, String pw) => AuthRepo(ApiClient(tokens: MemoryTokenStore(), baseUrl: url!)).login(id, pw);
      await login('000', 'student123');
      await login('0000000000', 'student123');
      await expectLater(login('000', 'wrong'), throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 401)));
    });

    test('grievances', () async {
      final all = await repo.grievances();
      final seat = all.firstWhere((g) => g.grievanceNo == '2024/00090');
      expect(istDate(seat.filedAt), '05-12-2024');
      expect(elapsed(seat.filedAt, seat.resolvedAt!), '7 Days 7 Hours 10 Minutes');
      expect(istDateTime(seat.resolvedAt!), '12-12-2024 02:09 PM');
      final water = all.firstWhere((g) => g.grievanceNo == '2024/00029');
      expect(elapsed(water.filedAt, water.resolvedAt!), '3 Days 19 Hours 10 Minutes');
      expect(istDateTime(water.resolvedAt!), '06-08-2024 11:30 AM');
    });

    test('circulars, certificates and exam schedule', () async {
      final circulars = await repo.circulars();
      expect(circulars.first.pinned, isTrue);
      expect(circulars.first.content, contains('**Demo circular.**'));
      expect(await repo.certificates(), isNotEmpty);
      final exams = await repo.examSchedule(ExamType.exam);
      expect(exams.map((e) => calendarDate(e.startDate)), ['12-10-2026', '19-10-2026']);
      expect(calendarDate(exams.first.endDate!), '17-10-2026');
      expect(await repo.examSchedule(ExamType.ia), isEmpty);
      expect(await repo.examSchedule(ExamType.lmsTest), isEmpty);
    });

    test('a bad access token refreshes silently against the real API', () async {
      final refresh = (await store.read())!.refreshToken;
      await store.write(TokenPair('not-a-valid-token', refresh));
      expect((await repo.profile()).name, 'Rakshit Gajera');
      expect((await store.read())!.accessToken, isNot('not-a-valid-token'));
    });

    test('a bad refresh token ends the session against the real API', () async {
      final expiredCalls = <int>[];
      final bad = MemoryTokenStore(const TokenPair('bad-access', 'bad-refresh'));
      final c = ApiClient(tokens: bad, baseUrl: url!, onSessionExpired: () => expiredCalls.add(1));
      await expectLater(StudentRepo(c).profile(), throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 401)));
      expect(expiredCalls, hasLength(1));
      expect(bad.tokens, isNull);
    });
  });

  group('screens drawn from the API match the goldens', skip: skip, () {
    late FetchedRepo fetched;
    late Subject daa;

    setUpAll(() async {
      await loadFonts();
      HttpOverrides.global = null;
      final client = ApiClient(tokens: MemoryTokenStore(), baseUrl: url!);
      await AuthRepo(client).login('000', 'student123');
      final repo = StudentRepo(client);
      daa = (await repo.subjects()).first;
      fetched = await FetchedRepo.load(repo, daa.id);
    });

    final screens = <String, Widget Function()>{
      'dashboard_top': () => const DashboardScreen(),
      'attendance_current': () => const AttendanceScreen(),
      'attendance_previous': () => const AttendanceScreen(initialTab: 1),
      'attendance_detail': () => const AttendanceDetailScreen(),
      'lms': () => const LmsScreen(),
      'lms_presentation': () => LmsSubjectScreen(subject: daa),
      'lms_lab': () => LmsSubjectScreen(subject: daa, initialLab: true),
      'mentoring': () => const MentoringScreen(),
      'n_history': () => const MentoringScreen(initialTab: 1),
      'transport': () => TransportScreen(fixedTime: DateTime(2026, 11, 5, 10, 58, 54)),
      'n_res0': () => const ResultsScreen(),
      'n_res4': () => const ResultsScreen(openSem: 4),
      'n_res3': () => const ResultsScreen(openSem: 3),
      'n_res2': () => const ResultsScreen(openSem: 2),
      'n_res1': () => const ResultsScreen(openSem: 1),
      'n_gr': () => const GrievanceScreen(),
      'n_grx': () => const GrievanceScreen(expanded: true),
      'n_circ': () => const CircularScreen(),
      'n_cert': () => const CertificateScreen(),
      'n_sch0': () => const ScheduleScreen(),
      'n_sch1': () => const ScheduleScreen(initialTab: 1),
      'n_lr5': () => const LmsResultScreen(),
      'n_lr5o': () => const LmsResultScreen(openIndex: 1),
      'n_lr6': () => const LmsResultScreen(sem: 6),
    };

    for (final MapEntry(key: name, value: screen) in screens.entries) {
      testWidgets(name, (t) async {
        HttpOverrides.global = null;
        t.view.physicalSize = const Size(1272, 2772);
        t.view.devicePixelRatio = 3;
        t.view.padding = const FakeViewPadding(top: 144, bottom: 69);
        addTearDown(t.view.reset);
        debugDisableShadows = false;
        await t.pumpWidget(ProviderScope(overrides: fixtureOverrides(repo: fetched), retry: (_, _) => null, child: DuApp(home: screen())));
        await t.pump();
        await t.pump();
        expect(find.byKey(const Key('skeleton')), findsNothing);
        expect(find.byKey(const Key('error-card')), findsNothing);
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
        await t.pump(const Duration(seconds: 1));
        await expectLater(find.byType(DuApp), matchesGoldenFile('goldens/out/$name.png'));
        debugDisableShadows = true;
      });
    }
  });
}
