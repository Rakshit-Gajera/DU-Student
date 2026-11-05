import '../api/api_client.dart';
import '../models/student_models.dart';

/// Every student route. The API takes the student from the JWT.
class StudentRepo {
  const StudentRepo(this._api);
  final ApiClient _api;

  static const _base = '/api/student';

  Future<Profile> profile() async => Profile.fromJson((await _api.get('$_base/profile')).data as Json);

  Future<List<Subject>> subjects() => _api.getAll('$_base/subjects', Subject.fromJson);

  Future<List<AttendanceRow>> attendance() => _api.getAll('$_base/attendance', AttendanceRow.fromJson);

  Future<AttendanceSummary?> attendanceSummary() async {
    final data = (await _api.get('$_base/attendance/summary')).data;
    return data == null ? null : AttendanceSummary.fromJson(data as Json);
  }

  Future<List<PastSem>> pastSemesters() => _api.getAll('$_base/attendance/past-sems', PastSem.fromJson);

  Future<List<CourseRow>> courseAttendance() => _api.getAll('$_base/attendance/courses', CourseRow.fromJson);

  Future<ResultsData> results() async =>
      ResultsData.fromJson((await _api.get('$_base/results', query: {'limit': 100})).data as Json);

  Future<List<ContentItem>> presentations(String subjectId) => _api.getAll('$_base/lms/$subjectId/presentations', ContentItem.fromJson);

  Future<List<ContentItem>> labManuals(String subjectId) => _api.getAll('$_base/lms/$subjectId/lab-manuals', ContentItem.fromJson);

  Future<void> markSeen(String contentId) async {
    await _api.post('$_base/lms/content/$contentId/seen');
  }

  Future<MentoringData> mentoring() async =>
      MentoringData.fromJson((await _api.get('$_base/mentoring', query: {'limit': 100})).data as Json);

  Future<List<BusPass>> transport() => _api.getAll('$_base/transport', BusPass.fromJson);

  Future<List<BusReceipt>> busReceipts() => _api.getAll('$_base/transport/receipts', BusReceipt.fromJson);

  Future<List<LmsTestResult>> lmsTestResults() => _api.getAll('$_base/lms-results', LmsTestResult.fromJson);

  Future<List<Circular>> circulars() => _api.getAll('$_base/circulars', Circular.fromJson);

  Future<List<Grievance>> grievances() => _api.getAll('$_base/grievances', Grievance.fromJson);

  Future<void> fileGrievance({required String category, required String title, required String description}) async {
    await _api.post('$_base/grievances', body: {'category': category, 'title': title, 'description': description});
  }

  Future<void> requestCertificate({required String type, required int copies, String? purpose, String? deliveryMode, String? details}) async {
    await _api.post('$_base/certificates', body: {
      'type': type,
      'copies': copies,
      'purpose': purpose,
      'deliveryMode': deliveryMode,
      'details': details,
    });
  }

  Future<List<CertificateRequest>> certificates() => _api.getAll('$_base/certificates', CertificateRequest.fromJson);

  Future<List<ExamEntry>> examSchedule(ExamType type) =>
      _api.getAll('$_base/exam-schedule', ExamEntry.fromJson, query: {'type': type.apiValue});
}
