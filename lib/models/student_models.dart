typedef Json = Map<String, dynamic>;

double _double(Object? v) => (v as num).toDouble();

class Mentor {
  const Mentor({required this.name, this.designation, this.mobile, this.officeNo, this.email, this.department});

  factory Mentor.fromJson(Json j) => Mentor(
        name: j['name'] as String,
        designation: j['designation'] as String?,
        mobile: j['mobile'] as String?,
        officeNo: j['officeNo'] as String?,
        email: j['email'] as String?,
        department: j['department'] as String?,
      );

  final String name;
  final String? designation;
  final String? mobile;
  final String? officeNo;
  final String? email;
  final String? department;
}

class Profile {
  const Profile({
    required this.name,
    required this.classLabel,
    required this.batch,
    required this.rollNo,
    required this.currentSem,
    this.photoUrl,
    this.mobile,
    this.mentor,
  });

  factory Profile.fromJson(Json j) => Profile(
        name: j['name'] as String,
        photoUrl: j['photoUrl'] as String?,
        classLabel: j['classLabel'] as String,
        batch: j['batch'] as String,
        rollNo: j['rollNo'] as String,
        currentSem: j['currentSem'] as int,
        mobile: j['mobile'] as String?,
        mentor: j['mentor'] == null ? null : Mentor.fromJson(j['mentor'] as Json),
      );

  final String name;
  final String? photoUrl;
  final String classLabel;
  final String batch;
  final String rollNo;
  final int currentSem;
  final String? mobile;
  final Mentor? mentor;

  String get headline => '$classLabel | Roll No. $rollNo | $batch';
}

class Subject {
  const Subject({required this.id, required this.name, required this.code});

  factory Subject.fromJson(Json j) => Subject(id: j['id'] as String, name: j['name'] as String, code: j['code'] as String);

  final String id;
  final String name;
  final String code;
}

class AttendanceRow {
  const AttendanceRow({required this.date, required this.day, required this.slots});

  factory AttendanceRow.fromJson(Json j) =>
      AttendanceRow(date: j['date'] as String, day: j['day'] as String, slots: (j['slots'] as List).cast<String>());

  final String date;
  final String day;
  final List<String> slots;
}

class AttendanceSummary {
  const AttendanceSummary({
    required this.yearLabel,
    required this.percent,
    required this.present,
    required this.absent,
    required this.pending,
    required this.noAttendance,
    required this.total,
  });

  factory AttendanceSummary.fromJson(Json j) => AttendanceSummary(
        yearLabel: j['yearLabel'] as String,
        percent: _double(j['percent']),
        present: j['present'] as int,
        absent: j['absent'] as int,
        pending: j['pending'] as int,
        noAttendance: j['noAttendance'] as int,
        total: j['total'] as int,
      );

  /// Shown for a student with no totals recorded yet.
  static const empty = AttendanceSummary(yearLabel: '-', percent: 0, present: 0, absent: 0, pending: 0, noAttendance: 0, total: 0);

  final String yearLabel;
  final double percent;
  final int present;
  final int absent;
  final int pending;
  final int noAttendance;
  final int total;
}

class PastSem {
  const PastSem(this.sem, this.year, this.percent);

  factory PastSem.fromJson(Json j) => PastSem(j['semNo'] as int, j['yearLabel'] as String, _double(j['percent']));

  final int sem;
  final String year;
  final double percent;
}

class CourseRow {
  const CourseRow({required this.course, required this.total, required this.present, required this.percent});

  factory CourseRow.fromJson(Json j) =>
      CourseRow(course: j['course'] as String, total: j['total'] as int, present: j['present'] as int, percent: _double(j['percent']));

  final String course;
  final int total;
  final int present;
  final double percent;
}

class ContentItem {
  const ContentItem({required this.id, required this.uploadedAt, required this.title, required this.seen, this.subtitle, this.fileUrl, this.seenAt});

  factory ContentItem.fromJson(Json j) => ContentItem(
        id: j['id'] as String,
        fileUrl: j['fileUrl'] as String?,
        seenAt: j['seenAt'] as String?,
        uploadedAt: j['uploadedAt'] as String,
        title: j['title'] as String,
        subtitle: j['subtitle'] as String?,
        seen: j['seen'] as bool,
      );

  final String id;
  final String? fileUrl;
  final String? seenAt;
  final String uploadedAt;
  final String title;
  final String? subtitle;
  final bool seen;
}

class LmsContent {
  const LmsContent({required this.presentations, required this.labManuals, required this.author});
  final List<ContentItem> presentations;
  final List<ContentItem> labManuals;

  /// The API records no uploader, so this is the student's mentor.
  final String author;
}

class MentoringEntry {
  const MentoringEntry({required this.when, required this.mentorName, required this.issue, this.parentsDescription, this.nextMeeting});

  factory MentoringEntry.fromJson(Json j) => MentoringEntry(
        when: j['when'] as String,
        mentorName: j['mentorName'] as String,
        issue: j['issue'] as String,
        parentsDescription: j['parentsDescription'] as String?,
        nextMeeting: j['nextMeeting'] as String?,
      );

  final String when;
  final String mentorName;
  final String issue;
  final String? parentsDescription;
  final String? nextMeeting;
}

class MentorHistoryRow {
  const MentorHistoryRow({required this.mentorName, required this.fromDate, required this.meetings, this.toDate});

  factory MentorHistoryRow.fromJson(Json j) => MentorHistoryRow(
        mentorName: j['mentorName'] as String,
        fromDate: j['fromDate'] as String,
        toDate: j['toDate'] as String?,
        meetings: j['meetings'] as int,
      );

  final String mentorName;
  final String fromDate;
  final String? toDate;
  final int meetings;
}

class MentoringData {
  const MentoringData({required this.sessions, required this.history, this.mentor});

  factory MentoringData.fromJson(Json j) => MentoringData(
        mentor: j['mentor'] == null ? null : Mentor.fromJson(j['mentor'] as Json),
        sessions: (j['sessions'] as List).cast<Json>().map(MentoringEntry.fromJson).toList(),
        history: (j['history'] as List).cast<Json>().map(MentorHistoryRow.fromJson).toList(),
      );

  final Mentor? mentor;
  final List<MentoringEntry> sessions;
  final List<MentorHistoryRow> history;
}

class BusPass {
  const BusPass({
    required this.passNo,
    required this.busRoute,
    required this.active,
    required this.feesAmount,
    required this.feesPaid,
    this.batchCode,
    this.busCode,
    this.pickupAddress,
    this.pickupPoint,
    this.shift,
  });

  factory BusPass.fromJson(Json j) => BusPass(
        passNo: j['passNo'] as String,
        batchCode: j['batchCode'] as String?,
        busCode: j['busCode'] as String?,
        pickupAddress: j['pickupAddress'] as String?,
        busRoute: j['busRoute'] as String,
        pickupPoint: j['pickupPoint'] as String?,
        shift: j['shift'] as String?,
        active: j['active'] as bool,
        feesAmount: j['feesAmount'] as int,
        feesPaid: j['feesPaid'] as int,
      );

  final String passNo;
  final String? batchCode;
  final String? busCode;
  final String? pickupAddress;
  final String busRoute;
  final String? pickupPoint;
  final String? shift;
  final bool active;
  final int feesAmount;
  final int feesPaid;

  int get pending => feesAmount - feesPaid;
}

class BusReceipt {
  const BusReceipt({required this.receiptNo, required this.paidOn, required this.amount, this.description});

  factory BusReceipt.fromJson(Json j) => BusReceipt(
        receiptNo: j['receiptNo'] as String,
        paidOn: j['paidOn'] as String,
        amount: j['amount'] as int,
        description: j['description'] as String?,
      );

  final String receiptNo;
  final String paidOn;
  final int amount;
  final String? description;
}

/// One attempt at one unit's LMS test.
class LmsTestResult {
  const LmsTestResult({
    required this.semNo,
    required this.course,
    required this.unit,
    required this.testDate,
    required this.attemptNo,
    required this.marks,
    required this.maxMarks,
    required this.passed,
  });

  factory LmsTestResult.fromJson(Json j) => LmsTestResult(
        semNo: j['semNo'] as int,
        course: j['course'] as String,
        unit: j['unit'] as int,
        testDate: j['testDate'] as String,
        attemptNo: j['attemptNo'] as int,
        marks: j['marks'] as int,
        maxMarks: j['maxMarks'] as int,
        passed: j['passed'] as bool,
      );

  final int semNo;
  final String course;
  final int unit;
  final String testDate;
  final int attemptNo;
  final int marks;
  final int maxMarks;
  final bool passed;
}

class Circular {
  const Circular({required this.title, required this.content, required this.publishedAt, required this.pinned});

  factory Circular.fromJson(Json j) => Circular(
        title: j['title'] as String,
        content: j['content'] as String,
        publishedAt: j['publishedAt'] as String,
        pinned: j['pinned'] as bool,
      );

  final String title;

  /// Markdown source.
  final String content;
  final String publishedAt;
  final bool pinned;
}

class Grievance {
  const Grievance({
    required this.id,
    required this.grievanceNo,
    required this.category,
    required this.title,
    required this.description,
    required this.status,
    required this.filedAt,
    this.resolvedAt,
    this.resolvedBy,
    this.resolution,
  });

  factory Grievance.fromJson(Json j) => Grievance(
        id: j['id'] as String,
        grievanceNo: j['grievanceNo'] as String,
        category: j['category'] as String,
        title: j['title'] as String,
        description: j['description'] as String,
        status: j['status'] as String,
        filedAt: j['filedAt'] as String,
        resolvedAt: j['resolvedAt'] as String?,
        resolvedBy: j['resolvedBy'] as String?,
        resolution: j['resolution'] as String?,
      );

  final String id;
  final String grievanceNo;
  final String category;
  final String title;
  final String description;
  final String status;
  final String filedAt;
  final String? resolvedAt;
  final String? resolvedBy;
  final String? resolution;
}

class CertificateRequest {
  const CertificateRequest({
    required this.type,
    required this.copies,
    required this.status,
    required this.requestedAt,
    this.purpose,
    this.deliveryMode,
    this.details,
    this.remarks,
  });

  factory CertificateRequest.fromJson(Json j) => CertificateRequest(
        type: j['type'] as String,
        purpose: j['purpose'] as String?,
        copies: j['copies'] as int,
        deliveryMode: j['deliveryMode'] as String?,
        details: j['details'] as String?,
        status: j['status'] as String,
        remarks: j['remarks'] as String?,
        requestedAt: j['requestedAt'] as String,
      );

  final String type;
  final String? purpose;
  final int copies;
  final String? deliveryMode;
  final String? details;
  final String status;
  final String? remarks;
  final String requestedAt;
}

enum ExamType { exam('EXAM'), ia('IA'), lmsTest('LMS_TEST');
  const ExamType(this.apiValue);
  final String apiValue;
}

class ExamEntry {
  const ExamEntry({required this.title, required this.startDate, this.endDate, this.venue, this.subjectName});

  factory ExamEntry.fromJson(Json j) => ExamEntry(
        title: j['title'] as String,
        startDate: j['startDate'] as String,
        endDate: j['endDate'] as String?,
        venue: j['venue'] as String?,
        subjectName: (j['subject'] as Json?)?['name'] as String?,
      );

  final String title;
  final String startDate;
  final String? endDate;
  final String? venue;
  final String? subjectName;
}

class ResultRow {
  const ResultRow({required this.subject, required this.code, required this.grade, required this.attemptNo, this.season});

  factory ResultRow.fromJson(Json j) {
    final subject = j['subject'] as Json;
    return ResultRow(
      subject: subject['name'] as String,
      code: subject['code'] as String,
      grade: j['grade'] as String,
      season: j['examSeason'] as String?,
      attemptNo: j['attemptNo'] as int,
    );
  }

  final String subject;
  final String code;
  final String grade;
  final String? season;
  final int attemptNo;
}

class SemResult {
  const SemResult({required this.sem, required this.yearLabel, required this.spi, required this.backlogs, required this.rows, this.examName});

  factory SemResult.fromJson(Json j) => SemResult(
        sem: j['semNo'] as int,
        yearLabel: j['yearLabel'] as String,
        examName: j['examName'] as String?,
        spi: _double(j['spi']),
        backlogs: j['backlogs'] as int,
        rows: (j['courses'] as List).cast<Json>().map(ResultRow.fromJson).toList(),
      );

  final int sem;
  final String yearLabel;
  final String? examName;
  final double spi;
  final int backlogs;
  final List<ResultRow> rows;

  String get exam => examName ?? 'Semester - $sem Regular $yearLabel';
}

class GradeCount {
  const GradeCount(this.grade, this.count);
  final String grade;
  final int count;
}

class ResultsData {
  const ResultsData({
    required this.cpi,
    required this.backlogs,
    required this.totalSubjects,
    required this.passed,
    required this.grades,
    required this.semesters,
  });

  factory ResultsData.fromJson(Json j) {
    final grades = (j['grades'] as List).cast<Json>().map((g) => GradeCount(g['grade'] as String, g['count'] as int)).toList();
    // The API returns grades in no fixed order. Best first, unknown grades last.
    int rank(GradeCount g) {
      final i = _gradeOrder.indexOf(g.grade);
      return i < 0 ? _gradeOrder.length : i;
    }

    grades.sort((a, b) => rank(a).compareTo(rank(b)));
    return ResultsData(
      cpi: _double(j['cpi']),
      backlogs: j['backlogs'] as int,
      totalSubjects: j['totalSubjects'] as int,
      passed: j['passed'] as int,
      grades: grades,
      semesters: (j['semesters'] as List).cast<Json>().map(SemResult.fromJson).toList(),
    );
  }

  static const _gradeOrder = ['A++', 'A+', 'A', 'B+', 'B', 'C+', 'C', 'D', 'P', 'F', 'AB'];

  final double cpi;
  final int backlogs;
  final int totalSubjects;
  final int passed;
  final List<GradeCount> grades;
  final List<SemResult> semesters;
}
