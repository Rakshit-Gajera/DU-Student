/// Makes a change through each admin route the admin site uses, then checks that the
/// real app shows it. Also files requests in the app and answers them as the admin.
/// Changes the demo data, so re-seed afterwards (tool/run_e2e.ps1 does):
///
///   flutter test integration_test/admin_to_app_test.dart -d windows
library;

import 'package:du_student_app/providers/student_provider.dart';
import 'package:du_student_app/screens/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'admin_client.dart';
import 'support.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('admin changes reach the app, and app requests reach the admin', (t) async {
    final admin = (await t.runAsync(Admin.login))!;
    Future<T> call<T>(Future<T> Function() f) async => (await t.runAsync(f)) as T;

    final students = await call(() => admin.get('/students', {'search': '000'})) as List;
    final studentId = (students.single as Map)['id'] as String;
    final student = await call(() => admin.get('/students/$studentId')) as Map;
    final mentor = student['mentor'] as Map;

    final d = await startApp(t);
    await d.login('000', 'student123');
    await d.see('Hi, Rakshit Gajera');

    // ---------------------------------------------------------- Profile
    await call(() => admin.put('/students/$studentId', {'name': 'Rakshit E2E', 'classLabel': 'E2E-Class-5', 'rollNo': '777'}));
    await d.pullToRefresh();
    await d.see('Hi, Rakshit E2E');
    await d.see('E2E-Class-5 | Roll No. 777');
    await d.shot('20_profile_changed');

    // ------------------------------------------------- Attendance totals
    await call(() => admin.put('/attendance/summary', {
          'studentId': studentId,
          'yearLabel': '2026-27 - E2E',
          'percent': 77.77,
          'present': 200,
          'absent': 57,
          'pending': 3,
          'noAttendance': 40,
          'total': 300,
        }));
    await d.pullToRefresh();
    await d.see('77.77%');

    // ------------------------------------------------- Daily grid, past, course
    await call(() => admin.post('/attendance/bulk', {
          'records': [
            {'studentId': studentId, 'date': '2026-10-12', 'slot': 1, 'status': 'P'},
            {'studentId': studentId, 'date': '2026-10-12', 'slot': 2, 'status': 'AE'},
          ],
        }));
    await call(() => admin.put('/attendance/past-sems', {'studentId': studentId, 'semNo': 4, 'yearLabel': '2025-26 - Even', 'percent': 55.55}));
    await call(() => admin.put('/attendance/courses', {'studentId': studentId, 'course': 'E2E Course - Theory', 'total': 10, 'present': 5}));

    await d.open('Attendance');
    for (final v in ['77.77%', '2026-27 - E2E', ' / 300', '12-Oct-26']) {
      await d.see(v);
    }
    await d.shot('21_attendance_changed');
    await d.tapText('Previous');
    await d.loaded();
    await d.see('55.55%');
    await d.tapRich('2025-26 - Even');
    await d.loaded();
    for (final v in ['E2E Course - Theory', '50.00%', '361', '321']) {
      await d.see(v);
    }
    await d.back();
    await d.close();

    // ---------------------------------------------------------- Results
    final results = await call(() => admin.get('/results', {'studentId': studentId})) as List;
    final sem4 = results.cast<Map>().firstWhere((s) => s['semNo'] == 4);
    final courses = [
      for (final c in (sem4['courses'] as List).cast<Map>())
        {
          'subjectId': c['subjectId'],
          'grade': c['subject']['code'] == '2501CS402' ? 'A++' : c['grade'],
          'credits': c['credits'],
          'examSeason': c['examSeason'],
          'attemptNo': c['attemptNo'],
        },
    ];
    final updated = await call(() => admin.put('/results/${sem4['id']}', {'courses': courses})) as Map;
    final spi = (updated['spi'] as num).toStringAsFixed(2);
    final cpi = (updated['cpi'] as num).toStringAsFixed(2);
    expect(spi, isNot('7.17'), reason: 'changing a grade should recalculate SPI');

    await d.open('Results');
    await d.see(spi);
    await d.see(cpi);
    await d.tapText('Sem - 4');
    await d.see('A++');
    await d.shot('22_results_changed');
    await d.close();

    // -------------------------------------------------------------- LMS
    final subjects = await call(() => admin.get('/subjects', {'limit': 100})) as List;
    final daa = subjects.cast<Map>().firstWhere((s) => s['code'] == '2301CS402');
    final slide = await call(() => admin.post('/lms', {
          'studentId': studentId,
          'subjectId': daa['id'],
          'type': 'PRESENTATION',
          'title': 'E2E Slides',
          'subtitle': 'Added by the admin',
          'uploadedAt': '2026-11-01',
        })) as Map;
    await d.open('LMS Dashboard');
    await d.tapText('Design and Analysis of Algorithm');
    await d.loaded();
    await d.see('Presentation (6)');
    await d.see('E2E Slides');
    await d.shot('23_lms_added');
    await d.back();

    await call(() => admin.put('/lms/${slide['id']}', {'visible': false}));
    await d.tapText('Design and Analysis of Algorithm');
    await d.loaded();
    await d.see('Presentation (5)');
    d.missing('E2E Slides');
    await d.back();
    await d.close();
    await call(() => admin.delete('/lms/${slide['id']}'));

    // -------------------------------------------------------- Mentoring
    await call(() => admin.put('/mentoring/mentors/${mentor['id']}', {'name': 'E2E Mentor', 'email': 'e2e.mentor@example.com', 'mobile': '1112223334'}));
    try {
      await call(() => admin.post('/mentoring', {
            'studentId': studentId,
            'mentorName': 'E2E Mentor',
            'issue': 'E2E session issue',
            'parentsDescription': 'E2E parents note',
            'when': '2026-11-02T10:00:00+05:30',
          }));
      await call(() => admin.post('/mentoring/history', {
            'studentId': studentId,
            'mentorName': 'E2E Mentor',
            'fromDate': '2026-11-01',
            'meetings': 9,
          }));
      await d.open('Mentoring');
      for (final v in ['E2E Mentor', 'e2e.mentor@example.com', '1112223334', 'E2E session issue', 'E2E parents note', '02-11-2026 10:00 AM']) {
        await d.see(v);
      }
      await d.shot('24_mentoring_changed');
      await d.tapText("Mentor's History");
      await d.see('01-11-2026 -');
      await d.see('Meetings : 9');
      await d.close();
    } finally {
      await call(() => admin.put('/mentoring/mentors/${mentor['id']}', {
            'name': mentor['name'],
            'email': mentor['email'],
            'mobile': mentor['mobile'],
          }));
    }

    // -------------------------------------------------------- Transport
    final passes = await call(() => admin.get('/transport', {'studentId': studentId})) as List;
    final pass = passes.single as Map;
    await call(() => admin.put('/transport/${pass['id']}', {'pickupPoint': 'E2E Stop', 'pickupAddress': 'E2E Address', 'busCode': 'E2E-BUS', 'batchCode': 'E2E-BATCH', 'feesAmount': 1500, 'feesPaid': 500, 'active': false}));
    await d.open('Transport');
    for (final v in ['E2E Stop', 'E2E Address', 'E2E-BUS', 'E2E-BATCH', '₹ 1500', '₹ 500', '₹ 1000', 'Inactive']) {
      await d.see(v);
    }
    await d.see('SAMPLE');
    expect(find.text('SAMPLE'), findsOneWidget, reason: 'the watermark stays whatever the admin changes');
    await d.shot('25_transport_changed');
    await d.close();

    // -------------------------------------------------------- Circulars
    final circular = await call(() => admin.post('/circulars', {
          'studentId': studentId,
          'title': 'E2E Circular',
          'content': '**E2E bold** and a [link](https://example.com)',
          'publishedAt': '2026-11-01T10:00:00+05:30',
          'pinned': true,
        })) as Map;
    await d.open('Circular');
    await d.see('E2E Circular');
    await d.see('E2E bold');
    d.missing('**E2E');
    await d.shot('26_circular_added');
    await d.back();
    await d.back();

    await call(() => admin.delete('/circulars/${circular['id']}'));
    await d.open('Circular');
    d.missing('E2E Circular');
    await d.close();

    // ------------------------------------- LMS results and bus receipts
    final mark = await call(() => admin.post('/lms-results', {
          'studentId': studentId,
          'semNo': 5,
          'course': 'E2E LMS course',
          'unit': 1,
          'testDate': '2026-11-03',
          'marks': 11,
          'maxMarks': 30,
          'passed': false,
        })) as Map;
    final receipt = await call(() => admin.post('/transport/receipts', {
          'studentId': studentId,
          'receiptNo': 'E2E-RECEIPT',
          'paidOn': '2026-11-03',
          'amount': 750,
          'description': 'E2E receipt',
        })) as Map;
    await d.open('LMS Test Result');
    await d.tapRich('E2E LMS course');
    await d.see('11 / 30');
    await d.see('Fail');
    await d.close();
    await d.open('Transport');
    await d.tapText('Receipt');
    await d.see('E2E-RECEIPT');
    await d.see('₹ 750');
    await d.close();

    await call(() => admin.put('/lms-results/${mark['id']}', {'marks': 25, 'passed': true}));
    await call(() => admin.put('/transport/receipts/${receipt['id']}', {'amount': 800}));
    await d.open('LMS Test Result');
    await d.tapRich('E2E LMS course');
    await d.see('25 / 30');
    await d.close();
    await d.open('Transport');
    await d.tapText('Receipt');
    await d.see('₹ 800');
    await d.close();

    await call(() => admin.delete('/lms-results/${mark['id']}'));
    await call(() => admin.delete('/transport/receipts/${receipt['id']}'));
    await d.open('LMS Test Result');
    d.missing('E2E LMS course');
    await d.close();

    // ---------------------------------------------------- Exam schedule
    final exam = await call(() => admin.post('/exam-schedule', {
          'studentId': studentId,
          'type': 'IA',
          'title': 'E2E Internal Assessment',
          'startDate': '2026-11-20',
          'semester': 5,
          'venue': 'E2E Hall',
        })) as Map;
    await d.open('Exam Schedule');
    await d.tapText('IA Schedule');
    await d.loaded();
    await d.see('E2E Internal Assessment');
    await d.see('20-11-2026');
    await d.see('E2E Hall');
    await d.shot('27_exam_added');
    await d.close();
    await call(() => admin.delete('/exam-schedule/${exam['id']}'));

    // ------------------------------------------- Grievance: app to admin to app
    await d.open('Grievance Registration');
    await d.tapKey('add');
    await d.tapKey('submit');
    await d.see('Fill in the type, title and description.');
    await d.tapKey('grievance-type');
    await d.tapText('Hostel Service');
    await d.fill('grievance-title', 'E2E grievance from the app');
    await d.fill('grievance-description', 'Filed by the end-to-end test.');
    await d.shot('28_grievance_form');
    await d.tapKey('submit');
    await d.see('E2E grievance from the app');

    final found = await call(() => admin.get('/grievances', {'search': 'E2E grievance from the app'})) as List;
    final grievance = found.single as Map;
    expect(grievance['category'], 'Hostel Service');
    expect(grievance['status'], 'PENDING');
    await d.close();

    await call(() => admin.put('/grievances/${grievance['id']}', {'status': 'RESOLVED', 'resolution': 'E2E resolved by the admin'}));
    await d.open('Grievance Registration');
    await d.fillSearch('E2E grievance');
    await t.tap(find.byIcon(Icons.keyboard_arrow_down).first);
    await d.settle();
    await d.see('Resolved');
    await d.see('E2E resolved by the admin');
    await d.see('By admin');
    await d.shot('29_grievance_resolved');
    await d.back();
    await d.back();

    // ----------------------------------------- Certificate: app to admin to app
    await d.open('Certificate Request');
    await d.tapKey('add');
    await d.tapKey('submit');
    await d.see('Select the certificate type, purpose and delivery mode.');
    await d.tapKey('cert');
    await d.tapText('DU - Character Certificate (Charge Per Certificate: 100)');
    await d.tapKey('purpose');
    await d.tapText('Other');
    await d.tapKey('copies');
    await d.tapText('3');
    await d.tapKey('delivery');
    await d.tapText('In Person');
    await d.fill('cert-details', 'E2E certificate details');
    await d.tapKey('submit');
    await d.see('DU - Character Certificate');
    await d.see('No. of Copies : 3');

    final requests = await call(() => admin.get('/certificates', {'search': 'Character'})) as List;
    final request = requests.single as Map;
    expect(request['details'], 'E2E certificate details');
    await d.close();

    await call(() => admin.put('/certificates/${request['id']}', {'status': 'APPROVED', 'remarks': 'E2E approved by the admin'}));
    await d.open('Certificate Request');
    await d.see('Approved');
    await d.see('E2E approved by the admin');
    await d.shot('30_certificate_approved');
    await d.close();

    // ---------------------------------------------------- LMS seen date
    final container = ProviderScope.containerOf(t.element(find.byType(DashboardScreen)));
    final repo = container.read(studentRepoProvider);
    final labs = await call(() => repo.labManuals(daa['id'] as String));
    final unseen = labs.firstWhere((l) => !l.seen);
    await call(() => repo.markSeen(unseen.id));
    final after = await call(() => repo.labManuals(daa['id'] as String));
    final marked = after.firstWhere((l) => l.id == unseen.id);
    expect(marked.seen, isTrue);
    expect(marked.seenAt, isNotNull);

    await d.logout();
  });
}

extension on Driver {
  Future<void> fillSearch(String value) async {
    await t.enterText(find.byType(TextField).first, value);
    await settle();
  }
}
