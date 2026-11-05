/// Two students log in to the real app. Everything the admin creates, edits and
/// deletes for one of them must show for that student only. Cleans up after itself.
///
///   flutter test integration_test/two_students_test.dart -d windows
library;

import 'package:du_student_app/api/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'admin_client.dart';
import 'support.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('each student only sees their own data, and the admin can change each separately', (t) async {
    final admin = (await t.runAsync(Admin.login))!;
    Future<T> call<T>(Future<T> Function() f) async => (await t.runAsync(f)) as T;

    final seeded = await call(() => admin.get('/students', {'search': '000'})) as List;
    final aId = (seeded.single as Map)['id'] as String;

    // ------------------------------------------- Create a second student
    final created = await call(() => admin.post('/students', {
          'enrollmentNo': 'E2E-001',
          'name': 'Second Student',
          'classLabel': 'E2E-Class-3',
          'batch': 'Batch 9',
          'rollNo': '901',
          'currentSem': 3,
          'email': 'second.student@example.com',
          'mobile': '9990001112',
          'password': 'second-pass-1',
        })) as Map;
    final bId = created['id'] as String;

    try {
      final subjects = await call(() => admin.get('/subjects', {'limit': 100})) as List;
      final sem3 = subjects.cast<Map>().firstWhere((s) => s['semester'] == 3);

      await call(() => admin.put('/attendance/summary', {
            'studentId': bId,
            'yearLabel': '2025-26 - B',
            'percent': 66.66,
            'present': 20,
            'absent': 10,
            'pending': 0,
            'noAttendance': 0,
            'total': 30,
          }));
      final circular = await call(() => admin.post('/circulars', {
            'studentId': bId,
            'title': 'Only for the second student',
            'content': 'A **private** notice.',
            'publishedAt': '2026-11-01T10:00:00+05:30',
          })) as Map;
      await call(() => admin.post('/exam-schedule', {'studentId': bId, 'type': 'EXAM', 'title': 'Second student exam', 'startDate': '2026-12-01'}));
      await call(() => admin.post('/lms', {'studentId': bId, 'subjectId': sem3['id'], 'type': 'PRESENTATION', 'title': 'Second student slides', 'uploadedAt': '2026-11-01'}));
      await call(() => admin.post('/lms-results', {
            'studentId': bId,
            'semNo': 3,
            'course': 'Second student course',
            'unit': 1,
            'testDate': '2026-11-02',
            'marks': 7,
            'maxMarks': 30,
            'passed': false,
          }));
      final pass = await call(() => admin.post('/transport', {
            'studentId': bId,
            'busRoute': 'Second route',
            'passNo': 'SAMPLE/9001',
            'busCode': 'BUS-77',
            'batchCode': 'B-BATCH',
            'pickupPoint': 'Second stop',
            'pickupAddress': '12 Second Street',
            'validFrom': '2026-06-01',
            'validTo': '2026-12-01',
            'feesAmount': 900,
            'feesPaid': 400,
          })) as Map;
      await call(() => admin.post('/transport/receipts', {'studentId': bId, 'receiptNo': 'R-B-1', 'paidOn': '2026-06-02', 'amount': 400, 'description': 'First instalment'}));
      final grievance = await call(() => admin.post('/grievances', {'studentId': bId, 'category': 'Other', 'title': 'Filed by the admin', 'description': 'For the second student'})) as Map;
      final certificate = await call(() => admin.post('/certificates', {'studentId': bId, 'type': 'Second student certificate', 'copies': 2})) as Map;

      // ----------------------------------------- Second student, by email
      final d = await startApp(t);
      await d.login('second.student@example.com', 'second-pass-1');
      await d.see('Hi, Second Student');
      await d.see('E2E-Class-3 | Roll No. 901 | Batch 9');
      await d.see('66.66%');
      await d.shot('50_b_dashboard');

      await d.open('Circular');
      await d.see('Only for the second student');
      d.missing('Theory Semester End Examination');
      await d.close();

      await d.open('Exam Schedule');
      await d.see('Second student exam');
      d.missing('Theory Semester End Examination');
      await d.close();

      await d.open('LMS Test Result');
      await d.see('Second student course');
      d.missing('Discrete Mathematics');
      await d.tapRich('Second student course');
      await d.see('7 / 30');
      await d.see('Fail');
      await d.shot('51_b_lms_results');
      await d.close();

      await d.open('Transport');
      for (final v in ['Bus Pass No. SAMPLE/9001', 'BUS-77', 'B-BATCH', '12 Second Street', 'Second route', '₹ 900', '₹ 500']) {
        await d.see(v);
      }
      expect(find.text('SAMPLE'), findsOneWidget);
      d.missing('Demo Pickup Point');
      await d.shot('52_b_transport');
      await d.tapText('Receipt');
      await d.see('R-B-1');
      await d.see('First instalment');
      await d.close();

      await d.open('Grievance Registration');
      await d.see('Filed by the admin');
      d.missing('Seat broken');
      await d.close();

      await d.open('Certificate Request');
      await d.see('Second student certificate');
      d.missing('DU - Bonafide Certificate');
      await d.close();

      // ---------------------------------------- Edit for one student only
      await call(() => admin.put('/transport/${pass['id']}', {'pickupAddress': '99 Changed Road', 'busCode': 'BUS-88'}));
      await call(() => admin.put('/circulars/${circular['id']}', {'title': 'Changed notice'}));
      await call(() => admin.put('/grievances/${grievance['id']}', {'status': 'IN_PROGRESS', 'title': 'Title edited by the admin'}));
      await call(() => admin.put('/certificates/${certificate['id']}', {'status': 'PENDING', 'type': 'Type edited by the admin'}));

      await d.open('Transport');
      await d.see('99 Changed Road');
      await d.see('BUS-88');
      await d.close();
      await d.open('Circular');
      await d.see('Changed notice');
      await d.close();
      await d.open('Grievance Registration');
      await d.see('Title edited by the admin');
      await d.see('In progress');
      await d.close();
      await d.open('Certificate Request');
      await d.see('Type edited by the admin');
      await d.close();

      // -------------------------------------------------- Delete one thing
      await call(() => admin.delete('/grievances/${grievance['id']}'));
      await call(() => admin.delete('/certificates/${certificate['id']}'));
      await d.open('Grievance Registration');
      d.missing('Title edited by the admin');
      await d.close();
      await d.open('Certificate Request');
      await d.see('No any request found');
      await d.close();
      await d.logout();

      // --------------------------- First student, by mobile, is untouched
      await d.login('0000000000', 'student123');
      await d.see('Hi, Rakshit Gajera');
      await d.see('83.39%');
      await d.shot('53_a_dashboard');

      await d.open('Circular');
      await d.see('Theory Semester End Examination');
      d.missing('Changed notice');
      await d.close();

      await d.open('Transport');
      await d.see('Bus Pass No. SAMPLE/0000');
      await d.see('BUS-00');
      d.missing('99 Changed Road');
      await d.close();

      await d.open('Grievance Registration');
      await d.see('Seat broken');
      await d.close();

      await d.open('LMS Test Result');
      await d.see('DAA (2301CS402)');
      d.missing('Second student course');
      await d.close();
      await d.logout();

      // ------------------------ One student's token cannot read the other's
      final client = ApiClient(tokens: MemoryTokenStoreForE2e(), baseUrl: 'http://localhost:4000');
      await call(() => client.post('/api/auth/login', body: {'identifier': 'E2E-001', 'password': 'second-pass-1'}).then((r) {
            final data = r.data as Map<String, dynamic>;
            return client.tokens.write(TokenPair(data['accessToken'] as String, data['refreshToken'] as String));
          }));
      final aCirculars = await call(() => admin.get('/circulars', {'studentId': aId})) as List;
      expect(aCirculars, isNotEmpty);
      final seen = await call(() => client.get('/api/student/circulars'));
      expect((seen.data as List).map((c) => (c as Map)['studentId']).toSet(), {bId});
      await call(() => client.get('/api/admin/students').then<void>((_) => fail('a student reached an admin route'), onError: (Object e) {
            expect(e, isA<ApiException>());
          }));

      // -------------------------- A password change ends existing sessions
      await call(() => admin.put('/students/$bId', {'password': 'second-pass-2'}));
      final session = await call(client.tokens.read);
      await call(() => client.tokens.write(TokenPair('expired-access-token', session!.refreshToken)));
      await call(() => client.get('/api/student/profile').then<void>((_) => fail('the old session still works'), onError: (Object e) {
            expect(e, isA<ApiException>().having((x) => x.statusCode, 'status', 401));
          }));
      expect(await call(client.tokens.read), isNull);

      // ----------------------------------------------- Remember Me is off
      await t.enterText(find.byKey(const Key('enrollment')), 'E2E-001');
      await t.enterText(find.byKey(const Key('password')), 'second-pass-2');
      await t.tap(find.byKey(const Key('remember')));
      await t.pump();
      await t.tap(find.byKey(const Key('login')));
      await d.see('Hi, Second Student');
      expect(await t.runAsync(SecureTokenStore().read), isNull, reason: 'without Remember Me nothing is saved');
      await d.logout();

      // ------------------------------------ Forgot password tells them how
      await d.tapKey('forgot');
      await d.see('contact the university administration');
      await d.shot('54_forgot');
      await d.tapText('OK');
    } finally {
      await call(() => admin.delete('/students/$bId'));
    }

    // Deleting the student takes everything of theirs with them.
    final after = await call(() => admin.get('/transport', {'search': 'SAMPLE/9001'})) as List;
    expect(after, isEmpty);
  });
}
