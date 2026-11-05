import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/student_models.dart';
import '../repositories/student_repo.dart';
import 'auth_provider.dart';

final studentRepoProvider = Provider<StudentRepo>((ref) => StudentRepo(ref.watch(apiClientProvider)));

// All of these are autoDispose: reopening a screen fetches fresh data, and
// logging out (which removes every screen) drops the student's data from memory.

final profileProvider = FutureProvider.autoDispose<Profile>((ref) => ref.watch(studentRepoProvider).profile());

final subjectsProvider = FutureProvider.autoDispose<List<Subject>>((ref) => ref.watch(studentRepoProvider).subjects());

/// Waits for both, so a failure in one cannot leave the other's error unhandled.
Future<(A, B)> _both<A, B>(Future<A> a, Future<B> b) async {
  await Future.wait<Object?>([a, b]);
  return (await a, await b);
}

/// Current semester totals, or the empty set when none are recorded.
final attendanceSummaryProvider = FutureProvider.autoDispose<AttendanceSummary>(
    (ref) async => await ref.watch(studentRepoProvider).attendanceSummary() ?? AttendanceSummary.empty);

final lmsHomeProvider = FutureProvider.autoDispose<(Profile, List<Subject>)>(
    (ref) => _both(ref.watch(profileProvider.future), ref.watch(subjectsProvider.future)));

final dashboardProvider = FutureProvider.autoDispose<((Profile, List<Subject>), AttendanceSummary)>(
    (ref) => _both(ref.watch(lmsHomeProvider.future), ref.watch(attendanceSummaryProvider.future)));

final attendanceProvider = FutureProvider.autoDispose<((Profile, AttendanceSummary), List<AttendanceRow>)>((ref) => _both(
      _both(ref.watch(profileProvider.future), ref.watch(attendanceSummaryProvider.future)),
      ref.watch(studentRepoProvider).attendance(),
    ));

final pastSemestersProvider = FutureProvider.autoDispose<List<PastSem>>((ref) => ref.watch(studentRepoProvider).pastSemesters());

final courseAttendanceProvider = FutureProvider.autoDispose<List<CourseRow>>((ref) => ref.watch(studentRepoProvider).courseAttendance());

final resultsProvider = FutureProvider.autoDispose<ResultsData>((ref) => ref.watch(studentRepoProvider).results());

final lmsContentProvider = FutureProvider.autoDispose.family<LmsContent, String>((ref, subjectId) async {
  final repo = ref.watch(studentRepoProvider);
  final profile = ref.watch(profileProvider.future);
  final presentations = repo.presentations(subjectId);
  final labManuals = repo.labManuals(subjectId);
  await Future.wait<Object?>([profile, presentations, labManuals]);
  return LmsContent(
    presentations: _oldestFirst(await presentations),
    labManuals: _oldestFirst(await labManuals),
    author: (await profile).mentor?.name ?? '-',
  );
});

/// The API sends newest first; the LMS screen lists oldest first. The sort is
/// stable, so items uploaded on the same day keep the order the API gave them.
List<ContentItem> _oldestFirst(List<ContentItem> items) {
  final indexed = items.indexed.toList()
    ..sort((a, b) {
      final byDate = a.$2.uploadedAt.compareTo(b.$2.uploadedAt);
      return byDate != 0 ? byDate : a.$1.compareTo(b.$1);
    });
  return [for (final e in indexed) e.$2];
}

/// Opens a file in the device's browser or viewer. Returns whether it opened.
final fileOpenerProvider = Provider<Future<bool> Function(String url)>((ref) => (url) async {
      final uri = Uri.tryParse(url);
      if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) return false;
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    });

final mentoringProvider = FutureProvider.autoDispose<MentoringData>((ref) => ref.watch(studentRepoProvider).mentoring());

final transportProvider = FutureProvider.autoDispose<(Profile, List<BusPass>)>(
    (ref) => _both(ref.watch(profileProvider.future), ref.watch(studentRepoProvider).transport()));

final busReceiptsProvider = FutureProvider.autoDispose<List<BusReceipt>>((ref) => ref.watch(studentRepoProvider).busReceipts());

final lmsTestResultsProvider = FutureProvider.autoDispose<List<LmsTestResult>>((ref) => ref.watch(studentRepoProvider).lmsTestResults());

final circularsProvider = FutureProvider.autoDispose<List<Circular>>((ref) => ref.watch(studentRepoProvider).circulars());

final grievancesProvider = FutureProvider.autoDispose<List<Grievance>>((ref) => ref.watch(studentRepoProvider).grievances());

final certificatesProvider = FutureProvider.autoDispose<List<CertificateRequest>>((ref) => ref.watch(studentRepoProvider).certificates());

final examScheduleProvider = FutureProvider.autoDispose.family<List<ExamEntry>, ExamType>((ref, type) => ref.watch(studentRepoProvider).examSchedule(type));
