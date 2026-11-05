import { z } from 'zod';
import { asyncHandler, ok, okPage } from '../../lib/http';
import { dateString, studentPageQuery, toPageParams, uuidParam } from '../../lib/validation';
import * as lmsResults from '../../services/lmsResults.service';

const fields = z.object({
  studentId: z.string().uuid('Invalid studentId'),
  semNo: z.number().int().min(1).max(12),
  course: z.string().trim().min(1, 'Course is required').max(300),
  position: z.number().int().min(0).optional(),
  unit: z.number().int().min(1).max(50),
  testDate: dateString,
  attemptNo: z.number().int().min(1).max(20).optional(),
  marks: z.number().int().min(0),
  maxMarks: z.number().int().min(1).optional(),
  passed: z.boolean().optional(),
});

export const list = asyncHandler(async (req, res) => {
  const { studentId, page, limit } = studentPageQuery.parse(req.query);
  okPage(res, await lmsResults.listLmsResults(studentId, toPageParams({ page, limit })));
});

export const create = asyncHandler(async (req, res) => {
  ok(res, await lmsResults.createLmsResult(fields.parse(req.body)), 201);
});

export const update = asyncHandler(async (req, res) => {
  const { id } = uuidParam.parse(req.params);
  ok(res, await lmsResults.updateLmsResult(id, fields.partial().parse(req.body)));
});

export const remove = asyncHandler(async (req, res) => {
  await lmsResults.deleteLmsResult(uuidParam.parse(req.params).id);
  ok(res, { deleted: true });
});
