/**
 * Demo data, taken from the Flutter app (lib/demo_data.dart and lib/screens/*).
 *
 * Safe to run repeatedly. Accounts and reference data are upserted, and only the
 * data belonging to the demo student is replaced. An existing password is never
 * reset, and other students are left alone.
 */
import { copyFile, mkdir } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import path from 'node:path';
import { PrismaClient, type AttendanceStatus } from '@prisma/client';
import bcrypt from 'bcrypt';
import { recalculateStudentResults } from '../src/services/results.service';

const prisma = new PrismaClient();
const BCRYPT_COST = 12;

const IST = '+05:30';
const date = (iso: string): Date => new Date(`${iso}T00:00:00.000Z`);
const istTime = (iso: string, hhmm: string): Date => new Date(`${iso}T${hhmm}:00.000${IST}`);

const CURRENT_SUBJECTS = [
  ['Design and Analysis of Algorithm', '2301CS402'],
  ['Computer Network', '2301CS501'],
  ['Graph Theory', '2301CS595'],
  ['Machine Learning', '2301CS632'],
  ['Professional Communication - II', '2301HS503'],
  ['Building RESTful APIs with ASP.NET Core', '2401CS521'],
] as const;

/** Index 0 is slot 1. "-" (no lecture) has no database row. */
const ATTENDANCE: readonly (readonly [string, readonly (AttendanceStatus | '-')[]])[] = [
  ['2026-10-09', ['NA', 'NA', 'NA', 'NA', '-']],
  ['2026-10-08', ['NA', 'NA', 'NA', 'NA', '-']],
  ['2026-10-07', ['NA', 'NA', 'NA', 'NA', '-']],
  ['2026-10-06', ['NA', 'NA', 'NA', 'NA', '-']],
  ['2026-10-05', ['NA', 'NA', 'NA', 'NA', 'NA']],
  ['2026-09-30', ['NA', 'P', 'NA', '-', '-']],
  ['2026-09-29', ['P', 'P', '-', '-', '-']],
  ['2026-09-28', ['A', 'A', 'A', 'P', '-']],
  ['2026-09-26', ['AE', '-', '-', '-', '-']],
  ['2026-09-25', ['P', 'P', 'P', 'P', '-']],
  ['2026-09-24', ['P', 'P', 'A', 'P', '-']],
];

const ATTENDANCE_SUMMARY = {
  yearLabel: '2026-27 - Odd',
  percent: 83.39,
  present: 241,
  absent: 48,
  pending: 0,
  noAttendance: 58,
  total: 347,
};

const PAST_SEMESTERS = [
  { semNo: 4, yearLabel: '2025-26 - Even', percent: 90.03 },
  { semNo: 3, yearLabel: '2025-26 - Odd', percent: 94.24 },
  { semNo: 2, yearLabel: '2024-25 - Even', percent: 92.11 },
  { semNo: 1, yearLabel: '2024-25 - Odd', percent: 100 },
];

const COURSE_ATTENDANCE = [
  { course: '2301CS401 - Database Management System - II - Practical', total: 17, present: 13 },
  { course: '2301CS401 - Database Management System - II - Theory', total: 41, present: 36 },
  { course: '2301CS404 - Python Programming - Practical', total: 18, present: 15 },
  { course: '2301CS404 - Python Programming - Theory', total: 47, present: 45 },
  { course: '2301CS405 - Software Engineering - Practical', total: 17, present: 14 },
  { course: '2301CS405 - Software Engineering - Theory', total: 41, present: 39 },
  { course: '2301HS402 - Probability & Statistics - Practical', total: 15, present: 12 },
  { course: '2301HS402 - Probability & Statistics - Theory', total: 57, present: 52 },
  { course: '2301HS403 - Professional Communication - I - Practical', total: 14, present: 12 },
  { course: '2501CS402 - Back-End Web Technology - Practical', total: 31, present: 27 },
  { course: '2501CS402 - Back-End Web Technology - Theory', total: 52, present: 50 },
  { course: 'PC I - Practical', total: 1, present: 1 },
];

/**
 * The app has grades, SPI and CPI but no credits. These credits are inferred:
 * they are a plausible set that reproduces exactly what the app displays
 * (SPI 7.17 / 8.08 / 8.46 / 7.69 and CPI 7.86). Replace them with the real
 * scheme when it is available.
 */
const SEMESTERS = [
  {
    semNo: 1,
    yearLabel: 'Winter-2024',
    examName: 'DU - B.Tech. Semester - 1 Regular Winter-2024',
    courses: [
      ['Computer Programming using C', '2301CS101', 'B', 6],
      ['Digital Fundamentals', '2301CS102', 'B+', 5],
      ['Induction Program', '2301DU001', 'P', 0],
      ['Environmental Studies', '2301DU002', 'A+', 3],
      ['Indian Constitution', '2301DU003', 'A', 4],
      ['Mathematics - I', '2301HS101', 'A++', 3],
      ['Physics', '2301HS103', 'A', 5],
    ],
  },
  {
    semNo: 2,
    yearLabel: 'Summer-2025',
    examName: 'DU - B.Tech. Semester - 2 Regular Summer-2025',
    courses: [
      ['Object Oriented Programming using Java', '2301CS201', 'A', 5],
      ['Web Designing', '2301CS202', 'A+', 5],
      ['English', '2301HS102', 'A+', 5],
      ['Mathematics - II', '2301HS201', 'A+', 5],
      ['Engineering Graphics', '2301ME103', 'B+', 4],
    ],
  },
  {
    semNo: 3,
    yearLabel: 'Winter-2025',
    examName: 'DU - B.Tech. Semester - 3 Regular Winter-2025',
    courses: [
      ['Data Structure', '2301CS301', 'A', 4],
      ['Database Management System - I', '2301CS302', 'A', 4],
      ['Office Automation Tools', '2301DU004', 'A', 4],
      ['Indian Knowledge System', '2301DU005', 'A+', 2],
      ['Discrete Mathematics', '2301HS301', 'A', 5],
      ['Front-End Web Technology', '2501CS303', 'A', 5],
    ],
  },
  {
    semNo: 4,
    yearLabel: 'Summer-2026',
    examName: 'BTech Semester - 4 Regular Summer-2026',
    courses: [
      ['Database Management System - II', '2301CS401', 'A', 3],
      ['Python Programming', '2301CS404', 'A+', 3],
      ['Software Engineering', '2301CS405', 'B', 4],
      ['Probability & Statistics', '2301HS402', 'B+', 4],
      ['Professional Communication - I', '2301HS403', 'A', 4],
      ['Back-End Web Technology', '2501CS402', 'B', 5],
    ],
  },
] as const;

const PRESENTATIONS = [
  ['2026-06-27', 'Unit-1 Introduction and Analysis of Algorithm', '1 - Introduction and Analysis of Algorithm', true],
  ['2026-06-27', 'Unit 2  Divide and Conquer Algorithm', '2 - Divide and Conquer Algorithm', true],
  ['2026-06-27', 'Unit 3 Greedy Algorithm', '3 - Greedy Algorithm', true],
  ['2026-06-27', 'Unit 4 Dynamic Programming', '4 - Dynamic Programming', true],
  [
    '2026-06-27',
    'Unit 5 Graph Algorithm, Branch & Bound, String Matching and NP-Completeness',
    '5 - Graph Algorithm, Back Tracking, Branch & Bound, String Matching and NP-Completeness',
    true,
  ],
] as const;

const LAB_MANUALS = [
  ['2026-09-24', 'Practical Dates', null, false],
  ['2026-09-26', 'BTech CSE DAA - Lab manual solution', null, true],
  ['2026-09-26', 'B.Sc. (Hons.) CS  DAA - Lab manual solution', null, false],
] as const;

const MENTOR_NAME = 'Rakshit Gajera';

const MENTORING = [
  { when: istTime('2026-03-18', '13:29'), issue: 'Demo mentoring discussion' },
  { when: istTime('2025-03-04', '11:27'), issue: 'Demo lab schedule discussion' },
  { when: istTime('2024-09-12', '10:15'), issue: 'Demo attendance discussion' },
];

const MENTOR_HISTORY = [
  { mentorName: MENTOR_NAME, fromDate: date('2026-08-11'), toDate: null, meetings: 0 },
  { mentorName: MENTOR_NAME, fromDate: date('2025-11-24'), toDate: date('2026-08-01'), meetings: 1 },
  { mentorName: MENTOR_NAME, fromDate: date('2024-10-10'), toDate: date('2025-05-31'), meetings: 2 },
];

const RESOLUTION = 'Necessary things has been done by Transport Department';

const GRIEVANCES = [
  {
    grievanceNo: '2024/00090',
    category: 'Transportation Service',
    title: 'Seat broken',
    description:
      "On Bus no.59, the last two seater seat is almost broken, the cushan is tilted down side it's not at all comfortable to sit, hence there's always a problem of a person to sit elsewhere or stand....pls do fix it, what are paying ₹11.5k for?",
    status: 'RESOLVED',
    filedAt: istTime('2024-12-05', '06:59'),
    resolvedAt: istTime('2024-12-12', '14:09'),
    resolvedBy: MENTOR_NAME,
    resolution: RESOLUTION,
  },
  {
    grievanceNo: '2024/00029',
    category: 'Transportation Service',
    title: 'Water leakage in bus',
    description:
      'There is water leakage in the bus when it rains. The seats are totally wet and we students have to stand and go to our homes, approximately standard 40 mins.\nBus no. 15',
    status: 'RESOLVED',
    filedAt: istTime('2024-08-02', '16:20'),
    resolvedAt: istTime('2024-08-06', '11:30'),
    resolvedBy: MENTOR_NAME,
    resolution: RESOLUTION,
  },
  {
    // Not in the app. Added so the admin grievance queue has an open item to work on.
    grievanceNo: '2026/00001',
    category: 'Amenities & Maintenance',
    title: 'Demo: projector not working in classroom',
    description: 'Demo grievance. The projector in the classroom has not been working this week.',
    status: 'PENDING',
    filedAt: istTime('2026-10-01', '10:00'),
    resolvedAt: null,
    resolvedBy: null,
    resolution: null,
  },
] as const;

/** Dates come from the academic calendar in the app. */
const CIRCULARS = [
  {
    title: 'Theory Semester End Examination (Tentative)',
    content:
      '**Demo circular.** The theory semester end examination is tentatively scheduled to begin on **19-10-2026**.\n\nPlease check the exam schedule for details.',
    publishedAt: istTime('2026-09-15', '10:00'),
    pinned: true,
  },
  {
    title: 'Submission of Term Work and Practical Examination',
    content:
      '**Demo circular.** Submission of term work and the SEE practical examination / viva will run from **12-10-2026 to 17-10-2026**.',
    publishedAt: istTime('2026-09-10', '10:00'),
    pinned: false,
  },
  {
    title: 'Commencement of Next Semester (Tentative)',
    content: '**Demo circular.** The next semester is tentatively scheduled to begin on **07-12-2026**.',
    publishedAt: istTime('2026-10-20', '10:00'),
    pinned: false,
  },
];

const EXAMS = [
  {
    title: 'Submission Of Term Work & SEE Practical Examination/Viva',
    startDate: date('2026-10-12'),
    endDate: date('2026-10-17'),
    semester: 5,
  },
  {
    title: 'Theory Semester End Examination (Tentative)',
    startDate: date('2026-10-19'),
    endDate: null,
    semester: 5,
  },
];

/** Five units, the same in every course: [unit, date, attempt, marks]. Out of 30. */
const LMS_MARKS: readonly (readonly [number, string, number, number])[] = [
  [1, '2026-07-15', 1, 24],
  [1, '2026-07-29', 2, 21],
  [2, '2026-08-24', 1, 25],
  [3, '2026-08-24', 1, 22],
  [3, '2026-09-14', 2, 20],
  [4, '2026-10-07', 1, 23],
  [4, '2026-10-19', 2, 22],
  [5, '2026-10-07', 1, 14],
  [5, '2026-10-19', 2, 23],
];

const LMS_COURSES: Readonly<Record<number, readonly string[]>> = {
  5: ['DAA (2301CS402)', 'CN (2301CS501)', 'ML (2301CS632)', 'GT (2301CS595)', 'Building RESTful APIs with ASP.NET Core (2401CS521)'],
  4: ['Probability & Statistics (2301HS402)', 'PP (2301CS404)', 'DBMS-II (2301CS401)', 'SE (2301CS405)', 'BEWT (2501CS402)'],
  3: ['Indian Knowledge System (2301DU005)', 'Discrete Mathematics (2301HS301)', 'DS (2301CS301)', 'DBMS-I (2301CS302)', 'FEWT (2501CS303)'],
  2: ['EG (2301ME103)', 'MATHS-II (2301HS201)', 'OOPJ (2301CS201)', 'WD (2301CS202)', 'ENG (2301HS102)'],
  1: ['ES (2301DU002)', 'MATHS-I (2301HS101)', 'CPC (2301CS101)', 'PHY (2301HS103)', 'IC (2301DU003)', 'DF (2301CS102)'],
};

const BUS_RECEIPTS = [
  { receiptNo: 'SAMPLE/R/0006', paidOn: date('2026-06-08'), amount: 0, description: 'Sample receipt: 2026-27 - Odd' },
  { receiptNo: 'SAMPLE/R/0005', paidOn: date('2026-01-05'), amount: 0, description: 'Sample receipt: 2025-26 - Even' },
  { receiptNo: 'SAMPLE/R/0004', paidOn: date('2025-06-09'), amount: 0, description: 'Sample receipt: 2025-26 - Odd' },
  { receiptNo: 'SAMPLE/R/0003', paidOn: date('2025-01-06'), amount: 0, description: 'Sample receipt: 2024-25 - Even' },
  { receiptNo: 'SAMPLE/R/0002', paidOn: date('2024-08-05'), amount: 0, description: 'Sample receipt: 2024-25 - Odd' },
  { receiptNo: 'SAMPLE/R/0001', paidOn: date('2024-07-22'), amount: 0, description: 'Sample receipt: admission' },
];

/** Copies the photo the app bundles into the upload folder so the API can serve it. */
async function seedPhoto(): Promise<string | null> {
  const source = path.resolve(__dirname, '../../assets/demo/rakshit.jpeg');
  if (!existsSync(source)) return null;
  const uploadDir = path.resolve(process.env.UPLOAD_DIR ?? 'uploads');
  await mkdir(uploadDir, { recursive: true });
  await copyFile(source, path.join(uploadDir, 'demo-rakshit.jpeg'));
  return '/uploads/demo-rakshit.jpeg';
}

async function main(): Promise<void> {
  await prisma.admin.upsert({
    where: { username: 'admin' },
    update: {},
    create: {
      username: 'admin',
      email: 'admin@example.com',
      name: 'Administrator',
      role: 'SUPERADMIN',
      passwordHash: await bcrypt.hash('admin123', BCRYPT_COST),
    },
  });

  const mentorId = '00000000-0000-4000-8000-000000000021';
  await prisma.mentor.upsert({
    where: { id: mentorId },
    update: {},
    create: {
      id: mentorId,
      name: MENTOR_NAME,
      designation: 'Assistant Professor',
      mobile: '0000000000',
      officeNo: '00',
      email: 'rakshit.gajera@example.com',
      department: 'Computer Science & Engineering',
    },
  });

  const profile = {
    name: 'Rakshit Gajera',
    photoUrl: await seedPhoto(),
    classLabel: 'BTech+Hons-5B',
    batch: 'Batch 2',
    rollNo: '000',
    currentSem: 5,
    mobile: '0000000000',
    department: 'Computer Science & Engineering',
    mentorId,
  };
  const student = await prisma.student.upsert({
    where: { enrollmentNo: '000' },
    update: profile,
    create: {
      ...profile,
      enrollmentNo: '000',
      passwordHash: await bcrypt.hash('student123', BCRYPT_COST),
    },
  });
  const studentId = student.id;

  // ---------------------------------------------------------- Subjects
  const upsertSubject = (code: string, name: string, semester: number) =>
    prisma.subject.upsert({
      where: { code },
      update: { name, semester },
      create: { code, name, semester },
    });

  const current = await Promise.all(CURRENT_SUBJECTS.map(([name, code]) => upsertSubject(code, name, 5)));
  const daa = current[0];
  if (!daa) throw new Error('Design and Analysis of Algorithm was not seeded');

  // ---------------------------------------------------------- Replace demo student data
  await prisma.$transaction([
    prisma.attendanceRecord.deleteMany({ where: { studentId } }),
    prisma.pastSemesterAttendance.deleteMany({ where: { studentId } }),
    prisma.mentorHistory.deleteMany({ where: { studentId } }),
    prisma.circular.deleteMany({ where: { studentId } }),
    prisma.examSchedule.deleteMany({ where: { studentId } }),
    prisma.lmsContent.deleteMany({ where: { studentId } }),
    prisma.lmsTestResult.deleteMany({ where: { studentId } }),
    prisma.busReceipt.deleteMany({ where: { studentId } }),
    prisma.courseAttendance.deleteMany({ where: { studentId } }),
    prisma.semesterResult.deleteMany({ where: { studentId } }),
    prisma.mentoringSession.deleteMany({ where: { studentId } }),
    prisma.certificateRequest.deleteMany({ where: { studentId } }),
    prisma.lmsContentView.deleteMany({ where: { studentId } }),
    // Grievances filed while testing. The demo ones are restored further down.
    prisma.grievance.deleteMany({
      where: { studentId, grievanceNo: { notIn: GRIEVANCES.map((g) => g.grievanceNo) } },
    }),
  ]);
  await prisma.attendanceSummary.upsert({
    where: { studentId },
    update: ATTENDANCE_SUMMARY,
    create: { ...ATTENDANCE_SUMMARY, studentId },
  });

  await prisma.attendanceRecord.createMany({
    data: ATTENDANCE.flatMap(([day, slots]) =>
      slots.flatMap((status, i) =>
        status === '-' ? [] : [{ studentId, date: date(day), slot: i + 1, status }],
      ),
    ),
  });
  await prisma.pastSemesterAttendance.createMany({
    data: PAST_SEMESTERS.map((s) => ({ ...s, studentId })),
  });
  await prisma.courseAttendance.createMany({
    data: COURSE_ATTENDANCE.map((c) => ({ ...c, studentId })),
  });

  // ---------------------------------------------------------- Results
  for (const sem of SEMESTERS) {
    const courses = [];
    for (const [name, code, grade, credits] of sem.courses) {
      const subject = await upsertSubject(code, name, sem.semNo);
      courses.push({ subjectId: subject.id, grade, credits, examSeason: sem.yearLabel });
    }
    await prisma.semesterResult.create({
      data: {
        studentId,
        semNo: sem.semNo,
        yearLabel: sem.yearLabel,
        examName: sem.examName,
        courses: { create: courses },
      },
    });
  }
  await prisma.$transaction((tx) => recalculateStudentResults(tx, studentId));

  // ---------------------------------------------------------- LMS (DAA, as in the app)
  const lmsItems = [
    ...PRESENTATIONS.map((p) => ({ item: p, type: 'PRESENTATION' as const })),
    ...LAB_MANUALS.map((l) => ({ item: l, type: 'LAB_MANUAL' as const })),
  ];
  for (const { item, type } of lmsItems) {
    const [uploadedAt, title, subtitle, seen] = item;
    const content = await prisma.lmsContent.create({
      data: { studentId, subjectId: daa.id, type, title, subtitle, uploadedAt: date(uploadedAt) },
    });
    if (seen) {
      await prisma.lmsContentView.create({
        data: { studentId, contentId: content.id, seenAt: istTime('2026-11-05', '10:00') },
      });
    }
  }

  // ---------------------------------------------------------- Mentoring
  await prisma.mentoringSession.createMany({
    data: MENTORING.map((m) => ({ ...m, studentId, mentorName: MENTOR_NAME })),
  });
  await prisma.mentorHistory.createMany({
    data: MENTOR_HISTORY.map((h) => ({ ...h, studentId })),
  });

  // ---------------------------------------------------------- Transport (sample pass, as in the app)
  const transport = {
    studentId,
    busRoute: 'Bus No. 00 - Demo Route - Shift-1',
    batchCode: 'DEMO-CSE-5',
    busCode: 'BUS-00',
    pickupAddress: 'Demo Pickup Address',
    pickupPoint: 'Demo Pickup Point',
    shift: 'Shift-1 (Morning Shift)(07:45 AM to 01:50 PM)',
    validFrom: date('2026-06-08'),
    validTo: date('2026-12-06'),
    active: true,
    feesAmount: 0,
    feesPaid: 0,
  };
  await prisma.transport.upsert({
    where: { passNo: 'SAMPLE/0000' },
    update: transport,
    create: { ...transport, passNo: 'SAMPLE/0000' },
  });

  // ---------------------------------------------------------- Circulars, exams
  await prisma.circular.createMany({ data: CIRCULARS.map((c) => ({ ...c, studentId })) });
  await prisma.examSchedule.createMany({ data: EXAMS.map((e) => ({ ...e, studentId })) });
  await prisma.busReceipt.createMany({ data: BUS_RECEIPTS.map((r) => ({ ...r, studentId })) });
  await prisma.lmsTestResult.createMany({
    data: Object.entries(LMS_COURSES).flatMap(([semNo, courses]) =>
      courses.flatMap((course, position) =>
        LMS_MARKS.map(([unit, testDate, attemptNo, marks]) => ({
          studentId,
          semNo: Number(semNo),
          course,
          position,
          unit,
          testDate: date(testDate),
          attemptNo,
          marks,
        })),
      ),
    ),
  });

  // ---------------------------------------------------------- Requests
  for (const g of GRIEVANCES) {
    const { grievanceNo, ...fields } = g;
    await prisma.grievance.upsert({
      where: { grievanceNo },
      update: { ...fields, studentId },
      create: { ...g, studentId },
    });
  }
  await prisma.certificateRequest.create({
    data: {
      studentId,
      type: 'DU - Bonafide Certificate',
      purpose: 'Other',
      copies: 1,
      deliveryMode: 'In Person',
      details: 'Demo certificate request',
      requestedAt: istTime('2026-11-05', '10:00'),
    },
  });

  const latest = await prisma.semesterResult.findFirst({
    where: { studentId },
    orderBy: { semNo: 'desc' },
  });
  console.log(`Seeded demo student ${student.name} (CPI ${latest?.cpi}).`);
  console.log('Admin login: admin / admin123   Student login: 000 / student123');
}

main()
  .catch((err: unknown) => {
    console.error(err);
    process.exitCode = 1;
  })
  .finally(() => {
    void prisma.$disconnect();
  });
