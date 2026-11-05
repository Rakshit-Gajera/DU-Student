import { LmsContentType } from '@prisma/client';
import { z } from 'zod';
import { asyncHandler, ok, okPage } from '../../lib/http';
import { dateString, fileReference, optionalText, pageQuery, toPageParams, uuidParam } from '../../lib/validation';
import * as lms from '../../services/lms.service';

const listQuery = pageQuery.extend({
  studentId: z.string().uuid('Invalid studentId'),
  subjectId: z.string().uuid('Invalid subjectId').optional(),
  type: z.nativeEnum(LmsContentType).optional(),
});

const body = z.object({
  studentId: z.string().uuid('Invalid studentId'),
  subjectId: z.string().uuid('Invalid subjectId'),
  type: z.nativeEnum(LmsContentType),
  title: z.string().trim().min(1, 'Title is required').max(300),
  subtitle: optionalText(300),
  fileUrl: fileReference.nullable().optional(),
  uploadedAt: dateString.optional(),
  visible: z.boolean().optional(),
});

export const list = asyncHandler(async (req, res) => {
  const { page, limit, ...filters } = listQuery.parse(req.query);
  okPage(res, await lms.listLmsContent(toPageParams({ page, limit }), filters));
});

export const get = asyncHandler(async (req, res) => {
  ok(res, await lms.getLmsContent(uuidParam.parse(req.params).id));
});

export const create = asyncHandler(async (req, res) => {
  ok(res, await lms.createLmsContent(body.parse(req.body)), 201);
});

export const update = asyncHandler(async (req, res) => {
  const { id } = uuidParam.parse(req.params);
  ok(res, await lms.updateLmsContent(id, body.partial().parse(req.body)));
});

export const remove = asyncHandler(async (req, res) => {
  await lms.deleteLmsContent(uuidParam.parse(req.params).id);
  ok(res, { deleted: true });
});
