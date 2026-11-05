import { GrievanceStatus } from '@prisma/client';
import { z } from 'zod';
import { asyncHandler, currentAdmin, ok, okPage } from '../../lib/http';
import { optionalText, pageQuery, queryText, toPageParams, uuidParam } from '../../lib/validation';
import * as grievances from '../../services/grievances.service';

const listQuery = pageQuery.extend({
  status: z.nativeEnum(GrievanceStatus).optional(),
  studentId: z.string().uuid('Invalid studentId').optional(),
  search: queryText,
});

const text = {
  category: z.string().trim().min(1, 'Category is required').max(100),
  title: z.string().trim().min(1, 'Title is required').max(200),
  description: z.string().trim().min(1, 'Description is required').max(5000),
};
const createBody = z.object({ studentId: z.string().uuid('Invalid studentId'), ...text });
const updateBody = z.object({
  status: z.nativeEnum(GrievanceStatus),
  resolution: optionalText(2000),
  category: text.category.optional(),
  title: text.title.optional(),
  description: text.description.optional(),
});

export const create = asyncHandler(async (req, res) => {
  const { studentId, ...body } = createBody.parse(req.body);
  ok(res, await grievances.fileGrievance(studentId, body), 201);
});

export const remove = asyncHandler(async (req, res) => {
  await grievances.deleteGrievance(uuidParam.parse(req.params).id);
  ok(res, { deleted: true });
});

export const list = asyncHandler(async (req, res) => {
  const { page, limit, ...filters } = listQuery.parse(req.query);
  okPage(res, await grievances.listGrievances(toPageParams({ page, limit }), filters));
});

export const get = asyncHandler(async (req, res) => {
  ok(res, await grievances.getGrievance(uuidParam.parse(req.params).id));
});

export const update = asyncHandler(async (req, res) => {
  const { id } = uuidParam.parse(req.params);
  const body = updateBody.parse(req.body);
  ok(res, await grievances.updateGrievanceStatus(id, body, currentAdmin(req).username));
});
