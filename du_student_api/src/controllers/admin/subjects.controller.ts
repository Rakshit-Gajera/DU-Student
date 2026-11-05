import { z } from 'zod';
import { asyncHandler, ok, okPage } from '../../lib/http';
import { pageQuery, queryText, toPageParams, uuidParam } from '../../lib/validation';
import * as subjects from '../../services/subjects.service';

const listQuery = pageQuery.extend({
  search: queryText,
  semester: z.coerce.number().int().min(1).max(12).optional(),
});

const body = z.object({
  code: z.string().trim().min(1, 'Code is required').max(50),
  name: z.string().trim().min(1, 'Name is required').max(200),
  type: z.string().trim().min(1).max(50).default('Theory'),
  semester: z.coerce.number().int().min(1).max(12).nullable().optional(),
});

const updateBody = body.extend({ type: z.string().trim().min(1).max(50) }).partial();

export const list = asyncHandler(async (req, res) => {
  const { page, limit, ...filters } = listQuery.parse(req.query);
  okPage(res, await subjects.listSubjects(toPageParams({ page, limit }), filters));
});

export const get = asyncHandler(async (req, res) => {
  ok(res, await subjects.getSubject(uuidParam.parse(req.params).id));
});

export const create = asyncHandler(async (req, res) => {
  ok(res, await subjects.createSubject(body.parse(req.body)), 201);
});

export const update = asyncHandler(async (req, res) => {
  const { id } = uuidParam.parse(req.params);
  ok(res, await subjects.updateSubject(id, updateBody.parse(req.body)));
});

export const remove = asyncHandler(async (req, res) => {
  await subjects.deleteSubject(uuidParam.parse(req.params).id);
  ok(res, { deleted: true });
});
