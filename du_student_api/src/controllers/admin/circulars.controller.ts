import { z } from 'zod';
import { asyncHandler, ok, okPage } from '../../lib/http';
import { dateTimeString, studentPageQuery, toPageParams, uuidParam } from '../../lib/validation';
import * as circulars from '../../services/circulars.service';

const body = z.object({
  studentId: z.string().uuid('Invalid studentId'),
  title: z.string().trim().min(1, 'Title is required').max(300),
  content: z.string().trim().min(1, 'Body is required').max(50000),
  publishedAt: dateTimeString,
  pinned: z.boolean().optional(),
});

export const list = asyncHandler(async (req, res) => {
  const { studentId, page, limit } = studentPageQuery.parse(req.query);
  okPage(res, await circulars.listCirculars(toPageParams({ page, limit }), { studentId, publishedOnly: false }));
});

export const get = asyncHandler(async (req, res) => {
  ok(res, await circulars.getCircular(uuidParam.parse(req.params).id));
});

export const create = asyncHandler(async (req, res) => {
  ok(res, await circulars.createCircular(body.parse(req.body)), 201);
});

export const update = asyncHandler(async (req, res) => {
  const { id } = uuidParam.parse(req.params);
  ok(res, await circulars.updateCircular(id, body.partial().parse(req.body)));
});

export const remove = asyncHandler(async (req, res) => {
  await circulars.deleteCircular(uuidParam.parse(req.params).id);
  ok(res, { deleted: true });
});
