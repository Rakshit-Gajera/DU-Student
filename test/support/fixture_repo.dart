import 'dart:convert';
import 'dart:io';

import 'package:du_student_app/api/api_client.dart';
import 'package:du_student_app/models/student_models.dart';
import 'package:du_student_app/providers/auth_provider.dart';
import 'package:du_student_app/providers/student_provider.dart';
import 'package:du_student_app/repositories/student_repo.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

Future<void> loadFonts() async {
  for (final w in ['Light', 'Regular', 'Medium', 'SemiBold', 'Bold']) {
    await (FontLoader('Quicksand$w')..addFont(rootBundle.load('assets/fonts/Quicksand-$w.ttf'))).load();
  }
  final root = Platform.environment['FLUTTER_ROOT'] ?? 'C:/Users/rkgaj/flutter';
  final bytes = File('$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf').readAsBytesSync();
  final icons = FontLoader('MaterialIcons')..addFont(Future.value(ByteData.sublistView(bytes)));
  await icons.load();
}

/// Responses captured from the API after `prisma db seed`, with the student's
/// photoUrl removed so tests draw the bundled photo instead of using the network.
final Map<String, dynamic> seed = jsonDecode(File('test/fixtures/seed.json').readAsStringSync()) as Map<String, dynamic>;

List<T> _list<T>(String key, T Function(Json) parse) => (seed[key] as List).cast<Json>().map(parse).toList();

final Subject fixtureDaa = Subject.fromJson((seed['subjects'] as List).first as Json);

/// Parses the fixture with the same fromJson code the live repository uses.
class FixtureStudentRepo implements StudentRepo {
  const FixtureStudentRepo();

  @override
  Future<Profile> profile() async => Profile.fromJson(seed['profile'] as Json);
  @override
  Future<List<Subject>> subjects() async => _list('subjects', Subject.fromJson);
  @override
  Future<List<AttendanceRow>> attendance() async => _list('attendance', AttendanceRow.fromJson);
  @override
  Future<AttendanceSummary?> attendanceSummary() async => AttendanceSummary.fromJson(seed['attendanceSummary'] as Json);
  @override
  Future<List<BusReceipt>> busReceipts() async => _list('busReceipts', BusReceipt.fromJson);
  @override
  Future<List<LmsTestResult>> lmsTestResults() async => _list('lmsResults', LmsTestResult.fromJson);
  @override
  Future<void> markSeen(String contentId) async {}
  @override
  Future<void> fileGrievance({required String category, required String title, required String description}) async {}
  @override
  Future<void> requestCertificate({required String type, required int copies, String? purpose, String? deliveryMode, String? details}) async {}
  @override
  Future<List<PastSem>> pastSemesters() async => _list('pastSems', PastSem.fromJson);
  @override
  Future<List<CourseRow>> courseAttendance() async => _list('courses', CourseRow.fromJson);
  @override
  Future<ResultsData> results() async => ResultsData.fromJson(seed['results'] as Json);
  @override
  Future<List<ContentItem>> presentations(String subjectId) async => _list('presentations', ContentItem.fromJson);
  @override
  Future<List<ContentItem>> labManuals(String subjectId) async => _list('labManuals', ContentItem.fromJson);
  @override
  Future<MentoringData> mentoring() async => MentoringData.fromJson(seed['mentoring'] as Json);
  @override
  Future<List<BusPass>> transport() async => _list('transport', BusPass.fromJson);
  @override
  Future<List<Circular>> circulars() async => _list('circulars', Circular.fromJson);
  @override
  Future<List<Grievance>> grievances() async => _list('grievances', Grievance.fromJson);
  @override
  Future<List<CertificateRequest>> certificates() async => _list('certificates', CertificateRequest.fromJson);
  @override
  Future<List<ExamEntry>> examSchedule(ExamType type) async => _list('exam${type.apiValue}', ExamEntry.fromJson);
}

class MemoryTokenStore implements TokenStore {
  MemoryTokenStore([this.tokens]);
  TokenPair? tokens;

  @override
  Future<TokenPair?> read() async => tokens;
  @override
  Future<void> write(TokenPair tokens, {bool? remember}) async => this.tokens = tokens;
  @override
  Future<void> clear() async => tokens = null;
}

List<Override> fixtureOverrides({StudentRepo repo = const FixtureStudentRepo(), TokenStore? tokens}) => [
      studentRepoProvider.overrideWithValue(repo),
      tokenStoreProvider.overrideWithValue(tokens ?? MemoryTokenStore(const TokenPair('access', 'refresh'))),
    ];
