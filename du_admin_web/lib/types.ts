/** Mirrors the API response shapes (Prisma models, with dates as ISO strings). */

export interface PageMeta {
  page: number;
  limit: number;
  total: number;
  totalPages: number;
}

export interface Paged<T> {
  items: T[];
  meta: PageMeta;
}

export type AdminRole = 'ADMIN' | 'SUPERADMIN';

export interface Admin {
  id: string;
  username: string;
  email: string;
  name: string;
  role: AdminRole;
}

export interface Mentor {
  id: string;
  name: string;
  designation: string | null;
  mobile: string | null;
  officeNo: string | null;
  email: string | null;
  department: string | null;
}

export interface Student {
  id: string;
  enrollmentNo: string;
  name: string;
  photoUrl: string | null;
  classLabel: string;
  batch: string;
  rollNo: string;
  currentSem: number;
  email: string | null;
  mobile: string | null;
  department: string | null;
  mentorId: string | null;
  mentor: Mentor | null;
  createdAt: string;
  updatedAt: string;
}

export interface StudentSummary {
  id: string;
  name: string;
  enrollmentNo: string;
  classLabel?: string;
}

export interface Subject {
  id: string;
  code: string;
  name: string;
  type: string;
  semester: number | null;
}

export type AttendanceStatus = 'P' | 'A' | 'AE' | 'NA';

export interface AttendanceRow {
  date: string;
  day: string;
  slots: (AttendanceStatus | null)[];
}

export interface AttendanceSummary {
  studentId: string;
  yearLabel: string;
  percent: number;
  present: number;
  absent: number;
  pending: number;
  noAttendance: number;
  total: number;
}

export interface MentorHistoryRow {
  id: string;
  studentId: string;
  mentorName: string;
  fromDate: string;
  toDate: string | null;
  meetings: number;
}

export interface BusReceipt {
  id: string;
  studentId: string;
  receiptNo: string;
  paidOn: string;
  amount: number;
  description: string | null;
}

export interface LmsTestResult {
  id: string;
  studentId: string;
  semNo: number;
  course: string;
  position: number;
  unit: number;
  testDate: string;
  attemptNo: number;
  marks: number;
  maxMarks: number;
  passed: boolean;
}

export type ExamType = 'EXAM' | 'IA' | 'LMS_TEST';

export interface ExamSchedule {
  id: string;
  studentId: string;
  type: ExamType;
  title: string;
  startDate: string;
  endDate: string | null;
  venue: string | null;
}

export interface PastSemester {
  id: string;
  studentId: string;
  semNo: number;
  yearLabel: string;
  percent: number;
}

export interface CourseAttendance {
  id: string;
  studentId: string;
  course: string;
  total: number;
  present: number;
  percent: number;
}

export interface CourseResult {
  id: string;
  semResultId: string;
  subjectId: string;
  grade: string;
  credits: number;
  examSeason: string | null;
  attemptNo: number;
  subject: Subject;
}

export interface SemesterResult {
  id: string;
  studentId: string;
  semNo: number;
  yearLabel: string;
  spi: number;
  cpi: number;
  backlogs: number;
  updatedAt: string;
  courses: CourseResult[];
}

export type LmsContentType = 'PRESENTATION' | 'LAB_MANUAL';

export interface LmsContent {
  id: string;
  studentId: string;
  subjectId: string;
  type: LmsContentType;
  title: string;
  subtitle: string | null;
  fileUrl: string | null;
  uploadedAt: string;
  visible: boolean;
}

export interface MentoringSession {
  id: string;
  studentId: string;
  mentorName: string;
  issue: string;
  parentsDescription: string | null;
  nextMeeting: string | null;
  when: string;
}

export interface Transport {
  id: string;
  studentId: string;
  busRoute: string;
  passNo: string;
  batchCode: string | null;
  busCode: string | null;
  pickupAddress: string | null;
  pickupPoint: string | null;
  shift: string | null;
  validFrom: string;
  validTo: string;
  active: boolean;
  feesAmount: number;
  feesPaid: number;
  student: StudentSummary;
}

export interface Circular {
  id: string;
  studentId: string;
  title: string;
  content: string;
  publishedAt: string;
  pinned: boolean;
}

export type GrievanceStatus = 'PENDING' | 'IN_PROGRESS' | 'RESOLVED';

export interface Grievance {
  id: string;
  studentId: string;
  grievanceNo: string;
  category: string;
  title: string;
  description: string;
  status: GrievanceStatus;
  filedAt: string;
  resolvedAt: string | null;
  resolvedBy: string | null;
  resolution: string | null;
  student: StudentSummary;
}

export type CertificateStatus = 'PENDING' | 'APPROVED' | 'REJECTED';

export interface CertificateRequest {
  id: string;
  studentId: string;
  type: string;
  purpose: string | null;
  copies: number;
  deliveryMode: string | null;
  details: string | null;
  status: CertificateStatus;
  remarks: string | null;
  requestedAt: string;
  decidedAt: string | null;
  decidedBy: string | null;
  student: StudentSummary;
}

export interface DashboardStats {
  totalStudents: number;
  openGrievances: number;
  pendingCertificates: number;
  totalSubjects: number;
}

export interface LoginResult {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
  admin: Admin;
}

export interface UploadResult {
  url: string;
  mimeType: string;
  size: number;
}
