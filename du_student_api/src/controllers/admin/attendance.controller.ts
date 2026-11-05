import { AttendanceStatus } from '@prisma/client';
import { z } from 'zod';
import { asyncHandler, ok, okPage } from '../../lib/http';
import { dateString, studentPageQuery, toPageParams, uuidParam } from '../../lib/validation';
import * as attendance from '../../services/attendance.service';

const bulkBody = z.object({
  records: z
    .array(
      z.object({
        studentId: z.string().uuid('Invalid studentId'),
        date: dateString,
        slot: z.number().int().min(1).max(12),
        status: z.nativeEnum(AttendanceStatus).nullable(),
        subjectId: z.string().uuid('Invalid subjectId').nullable().optional(),
      }),
    )
    .min(1, 'At least one record is required')
    .max(2000, 'At most 2000 records at a time'),
});

const pastSemBody = z.object({
  studentId: z.string().uuid('Invalid studentId'),
  semNo: z.number().int().min(1).max(12),
  yearLabel: z.string().trim().min(1, 'Year label is required').max(50),
  percent: z.number().min(0).max(100),
});

const count = z.number().int().min(0);
const summaryBody = z.object({
  studentId: z.string().uuid('Invalid studentId'),
  yearLabel: z.string().trim().min(1, 'Year label is required').max(50),
  percent: z.number().min(0).max(100),
  present: count,
  absent: count,
  pending: count,
  noAttendance: count,
  total: count,
});
const summaryQuery = z.object({ studentId: z.string().uuid('Invalid studentId') });

const courseBody = z
  .object({
    studentId: z.string().uuid('Invalid studentId'),
    course: z.string().trim().min(1, 'Course is required').max(300),
    total: z.number().int().min(0),
    present: z.number().int().min(0),
  })
  .refine((c) => c.present <= c.total, {
    path: ['present'],
    message: 'Present cannot exceed total',
  });

function parseStudentPage(query: unknown) {
  const { studentId, page, limit } = studentPageQuery.parse(query);
  return { studentId, params: toPageParams({ page, limit }) };
}

export const grid = asyncHandler(async (req, res) => {
  const { studentId, params } = parseStudentPage(req.query);
  okPage(res, await attendance.getAttendanceGrid(studentId, params));
});

export const bulk = asyncHandler(async (req, res) => {
  const { records } = bulkBody.parse(req.body);
  ok(res, await attendance.bulkSaveAttendance(records));
});

export const getSummary = asyncHandler(async (req, res) => {
  ok(res, await attendance.getAttendanceSummary(summaryQuery.parse(req.query).studentId));
});

export const saveSummary = asyncHandler(async (req, res) => {
  ok(res, await attendance.saveAttendanceSummary(summaryBody.parse(req.body)));
});

export const listPastSems = asyncHandler(async (req, res) => {
  const { studentId, params } = parseStudentPage(req.query);
  okPage(res, await attendance.listPastSemesters(studentId, params));
});

export const savePastSem = asyncHandler(async (req, res) => {
  ok(res, await attendance.savePastSemester(pastSemBody.parse(req.body)));
});

export const removePastSem = asyncHandler(async (req, res) => {
  await attendance.deletePastSemester(uuidParam.parse(req.params).id);
  ok(res, { deleted: true });
});

export const listCourses = asyncHandler(async (req, res) => {
  const { studentId, params } = parseStudentPage(req.query);
  okPage(res, await attendance.listCourseAttendance(studentId, params));
});

export const saveCourse = asyncHandler(async (req, res) => {
  ok(res, await attendance.saveCourseAttendance(courseBody.parse(req.body)));
});

export const removeCourse = asyncHandler(async (req, res) => {
  await attendance.deleteCourseAttendance(uuidParam.parse(req.params).id);
  ok(res, { deleted: true });
});
