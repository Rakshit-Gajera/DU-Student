import { z } from 'zod';
import { asyncHandler, ok, okPage } from '../../lib/http';
import { fileReference, optionalText, pageQuery, queryText, toPageParams, uuidParam } from '../../lib/validation';
import * as students from '../../services/students.service';

const listQuery = pageQuery.extend({
  search: queryText,
  batch: queryText,
  classLabel: queryText,
  sortBy: z.enum(['name', 'enrollmentNo', 'classLabel', 'batch', 'rollNo']).default('name'),
  order: z.enum(['asc', 'desc']).default('asc'),
});

const profileFields = z.object({
  enrollmentNo: z.string().trim().min(1, 'Enrollment number is required').max(50),
  name: z.string().trim().min(1, 'Name is required').max(200),
  classLabel: z.string().trim().min(1, 'Class is required').max(100),
  batch: z.string().trim().min(1, 'Batch is required').max(100),
  rollNo: z.string().trim().min(1, 'Roll number is required').max(50),
  currentSem: z.coerce.number().int().min(1).max(12).default(1),
  photoUrl: fileReference.nullable().optional(),
  email: z.preprocess(
    (v) => (v === '' ? null : v),
    z.string().trim().email('Invalid email').max(200).nullable().optional(),
  ),
  mobile: optionalText(30),
  department: optionalText(200),
  mentorId: z.string().uuid('Invalid mentor').nullable().optional(),
});

const password = z.string().min(8, 'Password must be at least 8 characters').max(200);

const createBody = profileFields.extend({ password });
const updateBody = profileFields
  .extend({ currentSem: z.coerce.number().int().min(1).max(12) })
  .partial()
  .extend({ password: password.optional() });

export const list = asyncHandler(async (req, res) => {
  const { page, limit, ...filters } = listQuery.parse(req.query);
  okPage(res, await students.listStudents(toPageParams({ page, limit }), filters));
});

export const filterOptions = asyncHandler(async (_req, res) => {
  ok(res, await students.studentFilterOptions());
});

export const get = asyncHandler(async (req, res) => {
  ok(res, await students.getStudent(uuidParam.parse(req.params).id));
});

export const create = asyncHandler(async (req, res) => {
  ok(res, await students.createStudent(createBody.parse(req.body)), 201);
});

export const update = asyncHandler(async (req, res) => {
  const { id } = uuidParam.parse(req.params);
  ok(res, await students.updateStudent(id, updateBody.parse(req.body)));
});

export const remove = asyncHandler(async (req, res) => {
  await students.deleteStudent(uuidParam.parse(req.params).id);
  ok(res, { deleted: true });
});
