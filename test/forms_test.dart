import 'package:du_student_app/api/api_client.dart';
import 'package:du_student_app/main.dart';
import 'package:du_student_app/models/student_models.dart';
import 'package:du_student_app/providers/student_provider.dart';
import 'package:du_student_app/repositories/student_repo.dart';
import 'package:du_student_app/screens/lms.dart';
import 'package:du_student_app/screens/requests.dart';
import 'package:du_student_app/screens/results.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixture_repo.dart';

class RecordingRepo extends FixtureStudentRepo {
  final grievanceCalls = <Map<String, String>>[];
  final certificateCalls = <Map<String, Object?>>[];
  final seen = <String>[];
  ApiException? failure;
  String? fileUrl;

  @override
  Future<void> fileGrievance({required String category, required String title, required String description}) async {
    if (failure != null) throw failure!;
    grievanceCalls.add({'category': category, 'title': title, 'description': description});
  }

  @override
  Future<void> requestCertificate({required String type, required int copies, String? purpose, String? deliveryMode, String? details}) async {
    if (failure != null) throw failure!;
    certificateCalls.add({'type': type, 'copies': copies, 'purpose': purpose, 'deliveryMode': deliveryMode, 'details': details});
  }

  @override
  Future<void> markSeen(String contentId) async => seen.add(contentId);

  @override
  Future<List<ContentItem>> presentations(String subjectId) async => [
        for (final c in await super.presentations(subjectId))
          ContentItem(id: c.id, uploadedAt: c.uploadedAt, title: c.title, seen: c.seen, subtitle: c.subtitle, seenAt: c.seenAt, fileUrl: fileUrl),
      ];
}

Future<void> pump(WidgetTester t, Widget screen, StudentRepo repo, {Future<bool> Function(String)? opener}) async {
  t.view.physicalSize = const Size(1272, 2772);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  await t.pumpWidget(ProviderScope(
    overrides: [...fixtureOverrides(repo: repo), if (opener != null) fileOpenerProvider.overrideWithValue(opener)],
    retry: (_, _) => null,
    child: DuApp(home: screen),
  ));
  await t.pumpAndSettle();
}

Future<void> fill(WidgetTester t, String key, String value) => t.enterText(find.descendant(of: find.byKey(Key(key)), matching: find.byType(TextField)), value);

Future<void> tapKey(WidgetTester t, String key) async {
  await t.tap(find.byKey(Key(key)));
  await t.pumpAndSettle();
}

Future<void> tapText(WidgetTester t, String text) async {
  await t.tap(find.text(text).last);
  await t.pumpAndSettle();
}

void main() {
  setUpAll(loadFonts);

  group('grievance form', () {
    testWidgets('needs every field', (t) async {
      final repo = RecordingRepo();
      await pump(t, const GrievanceScreen(), repo);
      await tapKey(t, 'add');
      await tapKey(t, 'submit');
      expect(find.byKey(const Key('form-error')), findsOneWidget);
      expect(repo.grievanceCalls, isEmpty);
    });

    testWidgets('sends what was entered and closes', (t) async {
      final repo = RecordingRepo();
      await pump(t, const GrievanceScreen(), repo);
      await tapKey(t, 'add');
      await tapKey(t, 'grievance-type');
      await tapText(t, 'Hostel Service');
      expect(find.text('Hostel Service'), findsOneWidget);
      await fill(t, 'grievance-title', ' Broken fan ');
      await fill(t, 'grievance-description', 'Room 12');
      await tapKey(t, 'submit');

      expect(repo.grievanceCalls.single, {'category': 'Hostel Service', 'title': 'Broken fan', 'description': 'Room 12'});
      expect(find.text('Add Grievance Request'), findsNothing);
    });

    testWidgets('keeps the form open and shows a server error', (t) async {
      final repo = RecordingRepo()..failure = const ApiException('Title is required');
      await pump(t, const GrievanceScreen(), repo);
      await tapKey(t, 'add');
      await tapKey(t, 'grievance-type');
      await tapText(t, 'Hostel Service');
      await fill(t, 'grievance-title', 'x');
      await fill(t, 'grievance-description', 'y');
      await tapKey(t, 'submit');

      expect(find.text('Title is required'), findsOneWidget);
      expect(find.text('Add Grievance Request'), findsOneWidget);
    });
  });

  group('certificate form', () {
    testWidgets('needs type, purpose and delivery mode', (t) async {
      final repo = RecordingRepo();
      await pump(t, const AddCertificateScreen(), repo);
      await tapKey(t, 'submit');
      expect(find.byKey(const Key('form-error')), findsOneWidget);
      expect(repo.certificateCalls, isEmpty);
    });

    testWidgets('a placeholder row does not count as a choice', (t) async {
      final repo = RecordingRepo();
      await pump(t, const AddCertificateScreen(), repo);
      await tapKey(t, 'purpose');
      await tapText(t, 'Other');
      await tapKey(t, 'purpose');
      await t.tap(find.text('Select Purpose').last);
      await t.pumpAndSettle();
      await tapKey(t, 'submit');
      expect(repo.certificateCalls, isEmpty);
    });

    testWidgets('sends what was chosen and joins the two text boxes', (t) async {
      final repo = RecordingRepo();
      await pump(t, const AddCertificateScreen(), repo);
      await tapKey(t, 'cert');
      await tapText(t, 'DU - Bonafide Certificate');
      await tapKey(t, 'purpose');
      await tapText(t, 'Other');
      await tapKey(t, 'copies');
      await tapText(t, '3');
      await tapKey(t, 'delivery');
      await tapText(t, 'In Person');
      await fill(t, 'cert-details', 'For a visa');
      await fill(t, 'cert-description', 'Urgent');
      await tapKey(t, 'submit');

      expect(repo.certificateCalls.single, {
        'type': 'DU - Bonafide Certificate',
        'copies': 3,
        'purpose': 'Other',
        'deliveryMode': 'In Person',
        'details': 'For a visa\nUrgent',
      });
    });
  });

  group('search and filter', () {
    testWidgets('grievance search', (t) async {
      await pump(t, const GrievanceScreen(), RecordingRepo());
      await t.enterText(find.byType(TextField).first, 'seat');
      await t.pump();
      expect(find.text('Seat broken'), findsOneWidget);
      expect(find.text('Water leakage in bus'), findsNothing);
    });

    testWidgets('grievance filter', (t) async {
      await pump(t, const GrievanceScreen(), RecordingRepo());
      await tapKey(t, 'filter');
      await tapKey(t, 'filter-Completed');
      expect(find.text('Seat broken'), findsOneWidget);
      expect(find.textContaining('projector'), findsNothing);

      await tapKey(t, 'filter');
      await tapKey(t, 'filter-Pending');
      expect(find.text('Seat broken'), findsNothing);
      expect(find.textContaining('projector'), findsOneWidget);
    });

    testWidgets('LMS search', (t) async {
      await pump(t, const LmsScreen(), RecordingRepo());
      await t.enterText(find.byType(TextField).first, '2301cs595');
      await t.pump();
      expect(find.text('Graph Theory'), findsOneWidget);
      expect(find.text('Computer Network'), findsNothing);
    });

    testWidgets('circular search', (t) async {
      await pump(t, const CircularScreen(), RecordingRepo());
      await t.enterText(find.byType(TextField).first, 'next semester');
      await t.pump();
      expect(find.text('Commencement of Next Semester (Tentative)'), findsOneWidget);
      expect(find.text('Submission of Term Work and Practical Examination'), findsNothing);
    });
  });

  group('LMS files', () {
    Future<void> tapFirstPill(WidgetTester t) async {
      await t.tap(find.text('Presentation').first);
      await t.pumpAndSettle();
    }

    testWidgets('an item without a file says so and is not marked seen', (t) async {
      final repo = RecordingRepo();
      await pump(t, LmsSubjectScreen(subject: fixtureDaa), repo);
      await tapFirstPill(t);
      expect(find.text('No file has been uploaded for this item yet.'), findsOneWidget);
      expect(repo.seen, isEmpty);
    });

    testWidgets('opening a file marks it seen, using the full URL', (t) async {
      final repo = RecordingRepo()..fileUrl = '/uploads/x.pdf';
      final opened = <String>[];
      await pump(t, LmsSubjectScreen(subject: fixtureDaa), repo, opener: (url) async {
        opened.add(url);
        return true;
      });
      await tapFirstPill(t);
      expect(opened.single, endsWith('/uploads/x.pdf'));
      expect(opened.single, startsWith('http'));
      expect(repo.seen, hasLength(1));
    });

    testWidgets('a file that cannot open is not marked seen', (t) async {
      final repo = RecordingRepo()..fileUrl = '/uploads/x.pdf';
      await pump(t, LmsSubjectScreen(subject: fixtureDaa), repo, opener: (_) async => false);
      await tapFirstPill(t);
      expect(find.text('Could not open this file.'), findsOneWidget);
      expect(repo.seen, isEmpty);
    });
  });

  testWidgets('a semester with no exam name gets one from its number and year', (t) async {
    const sem = SemResult(sem: 6, yearLabel: 'Summer-2027', spi: 8, backlogs: 0, rows: []);
    expect(sem.exam, 'Semester - 6 Regular Summer-2027');
    await pump(t, const ResultsScreen(initialTab: 1), RecordingRepo());
    await tapText(t, 'Select Exam Result');
    expect(find.text('BTech Semester - 4 Regular Summer-2026'), findsOneWidget);
  });
}
