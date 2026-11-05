import { ExamType } from '@prisma/client';
import { z } from 'zod';
import { asyncHandler, ok, okPage } from '../../lib/http';
import { dateString, optionalText, pageQuery, toPageParams, uuidParam } from '../../lib/validation';
import * as exams from '../../services/examSchedule.service';

const listQuery = pageQuery.extend({
  studentId: z.string().uuid('Invalid studentId'),
  type: z.nativeEnum(ExamType).optional(),
  semester: z.coerce.number().int().min(1).max(12).optional(),
});

const body = z.object({
  studentId: z.string().uuid('Invalid studentId'),
  subjectId: z.string().uuid('Invalid subjectId').nullable().optional(),
  type: z.nativeEnum(ExamType).optional(),
  title: z.string().trim().min(1, 'Title is required').max(300),
  startDate: dateString,
  endDate: dateString.nullable().optional(),
  semester: z.number().int().min(1).max(12).nullable().optional(),
  venue: optionalText(200),
});

export const list = asyncHandler(async (req, res) => {
  const { page, limit, ...filters } = listQuery.parse(req.query);
  okPage(res, await exams.listExamSchedules(toPageParams({ page, limit }), filters));
});

export const get = asyncHandler(async (req, res) => {
  ok(res, await exams.getExamSchedule(uuidParam.parse(req.params).id));
});

export const create = asyncHandler(async (req, res) => {
  ok(res, await exams.createExamSchedule(body.parse(req.body)), 201);
});

export const update = asyncHandler(async (req, res) => {
  const { id } = uuidParam.parse(req.params);
  ok(res, await exams.updateExamSchedule(id, body.partial().parse(req.body)));
});

export const remove = asyncHandler(async (req, res) => {
  await exams.deleteExamSchedule(uuidParam.parse(req.params).id);
  ok(res, { deleted: true });
});
