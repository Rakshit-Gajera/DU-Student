import { LmsContentType, ExamType, type AttendanceStatus } from '@prisma/client';
import { z } from 'zod';
import { asyncHandler, currentStudent, ok, okPage, okWithMeta } from '../lib/http';
import { optionalText, pageQuery, toPageParams, uuidParam } from '../lib/validation';
import * as attendance from '../services/attendance.service';
import * as certificates from '../services/certificates.service';
import * as circulars from '../services/circulars.service';
import * as exams from '../services/examSchedule.service';
import * as grievances from '../services/grievances.service';
import * as lms from '../services/lms.service';
import * as lmsResults from '../services/lmsResults.service';
import * as mentoring from '../services/mentoring.service';
import * as results from '../services/results.service';
import * as student from '../services/student.service';
import * as transport from '../services/transport.service';

const parsePage = (query: unknown) => toPageParams(pageQuery.parse(query));

const subjectParam = z.object({ subjectId: z.string().uuid('Invalid subject id') });

/** The labels the Flutter attendance grid draws. */
const STATUS_LABEL: Record<AttendanceStatus, string> = { P: 'P', A: 'A', AE: 'A (e)', NA: 'NA' };

export const profile = asyncHandler(async (req, res) => {
  ok(res, await student.getProfile(currentStudent(req).id));
});

export const subjects = asyncHandler(async (req, res) => {
  okPage(res, await student.listCurrentSubjects(currentStudent(req).id, parsePage(req.query)));
});

export const attendanceGrid = asyncHandler(async (req, res) => {
  const page = await attendance.getAttendanceGrid(currentStudent(req).id, parsePage(req.query));
  okPage(res, {
    items: page.items.map((row) => ({
      ...row,
      slots: row.slots.map((s) => (s ? STATUS_LABEL[s] : '-')),
    })),
    meta: page.meta,
  });
});

export const attendanceSummary = asyncHandler(async (req, res) => {
  ok(res, await attendance.getAttendanceSummary(currentStudent(req).id));
});

export const pastSemesters = asyncHandler(async (req, res) => {
  okPage(res, await attendance.listPastSemesters(currentStudent(req).id, parsePage(req.query)));
});

export const courseAttendance = asyncHandler(async (req, res) => {
  okPage(res, await attendance.listCourseAttendance(currentStudent(req).id, parsePage(req.query)));
});

export const getResults = asyncHandler(async (req, res) => {
  const { data, meta } = await results.getStudentResults(currentStudent(req).id, parsePage(req.query));
  okWithMeta(res, data, meta);
});

const lmsList = (type: LmsContentType) =>
  asyncHandler(async (req, res) => {
    const { subjectId } = subjectParam.parse(req.params);
    okPage(res, await lms.listContentForStudent(currentStudent(req).id, subjectId, type, parsePage(req.query)));
  });

export const presentations = lmsList(LmsContentType.PRESENTATION);
export const labManuals = lmsList(LmsContentType.LAB_MANUAL);

export const markLmsSeen = asyncHandler(async (req, res) => {
  const { id } = uuidParam.parse(req.params);
  await lms.markContentSeen(currentStudent(req).id, id);
  ok(res, { seen: true });
});

export const getMentoring = asyncHandler(async (req, res) => {
  const { data, meta } = await mentoring.getMentoringForStudent(currentStudent(req).id, parsePage(req.query));
  okWithMeta(res, data, meta);
});

export const getTransport = asyncHandler(async (req, res) => {
  okPage(res, await transport.listTransport(parsePage(req.query), { studentId: currentStudent(req).id }));
});

export const busReceipts = asyncHandler(async (req, res) => {
  okPage(res, await transport.listReceipts(currentStudent(req).id, parsePage(req.query)));
});

export const lmsTestResults = asyncHandler(async (req, res) => {
  okPage(res, await lmsResults.listLmsResults(currentStudent(req).id, parsePage(req.query)));
});

export const getCirculars = asyncHandler(async (req, res) => {
  okPage(res, await circulars.listCirculars(parsePage(req.query), { studentId: currentStudent(req).id, publishedOnly: true }));
});

export const listGrievances = asyncHandler(async (req, res) => {
  okPage(res, await grievances.listGrievances(parsePage(req.query), { studentId: currentStudent(req).id }));
});

const grievanceBody = z.object({
  category: z.string().trim().min(1, 'Category is required').max(100),
  title: z.string().trim().min(1, 'Title is required').max(200),
  description: z.string().trim().min(1, 'Description is required').max(5000),
});

export const fileGrievance = asyncHandler(async (req, res) => {
  const body = grievanceBody.parse(req.body);
  ok(res, await grievances.fileGrievance(currentStudent(req).id, body), 201);
});

export const listCertificates = asyncHandler(async (req, res) => {
  okPage(res, await certificates.listCertificates(parsePage(req.query), { studentId: currentStudent(req).id }));
});

const certificateBody = z.object({
  type: z.string().trim().min(1, 'Certificate type is required').max(200),
  purpose: optionalText(200),
  copies: z.coerce.number().int().min(1).max(10).default(1),
  deliveryMode: optionalText(100),
  details: optionalText(2000),
});

export const requestCertificate = asyncHandler(async (req, res) => {
  const body = certificateBody.parse(req.body);
  ok(res, await certificates.requestCertificate(currentStudent(req).id, body), 201);
});

const examQuery = pageQuery.extend({ type: z.nativeEnum(ExamType).optional() });

export const examSchedule = asyncHandler(async (req, res) => {
  const { type, ...page } = examQuery.parse(req.query);
  okPage(res, await exams.listExamSchedules(toPageParams(page), { studentId: currentStudent(req).id, type }));
});
