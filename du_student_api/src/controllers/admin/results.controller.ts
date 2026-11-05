import { z } from 'zod';
import { GRADES } from '../../lib/grades';
import { asyncHandler, ok, okPage } from '../../lib/http';
import { optionalText, studentPageQuery, toPageParams, uuidParam } from '../../lib/validation';
import * as results from '../../services/results.service';

const course = z.object({
  subjectId: z.string().uuid('Invalid subjectId'),
  grade: z.string().refine((g) => GRADES.includes(g), `Grade must be one of ${GRADES.join(', ')}`),
  credits: z.number().int().min(0).max(30),
  examSeason: optionalText(50),
  attemptNo: z.number().int().min(1).max(20).default(1),
});

const uniqueSubjects = (courses: { subjectId: string }[]): boolean =>
  new Set(courses.map((c) => c.subjectId)).size === courses.length;
const courses = z.array(course).max(30).refine(uniqueSubjects, 'A subject can appear only once per semester');

const createBody = z.object({
  studentId: z.string().uuid('Invalid studentId'),
  semNo: z.number().int().min(1).max(12),
  yearLabel: z.string().trim().min(1, 'Year label is required').max(50),
  courses,
});

const updateBody = z.object({
  semNo: z.number().int().min(1).max(12).optional(),
  yearLabel: z.string().trim().min(1, 'Year label is required').max(50).optional(),
  courses: courses.optional(),
});

export const list = asyncHandler(async (req, res) => {
  const { studentId, page, limit } = studentPageQuery.parse(req.query);
  okPage(res, await results.listResults(studentId, toPageParams({ page, limit })));
});

export const get = asyncHandler(async (req, res) => {
  ok(res, await results.getResult(uuidParam.parse(req.params).id));
});

export const create = asyncHandler(async (req, res) => {
  ok(res, await results.createResult(createBody.parse(req.body)), 201);
});

export const remove = asyncHandler(async (req, res) => {
  await results.deleteResult(uuidParam.parse(req.params).id);
  ok(res, { deleted: true });
});

export const update = asyncHandler(async (req, res) => {
  const { id } = uuidParam.parse(req.params);
  ok(res, await results.updateResult(id, updateBody.parse(req.body)));
});
