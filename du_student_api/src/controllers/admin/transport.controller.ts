import { z } from 'zod';
import { asyncHandler, ok, okPage } from '../../lib/http';
import { dateString, optionalText, pageQuery, queryText, studentPageQuery, toPageParams, uuidParam } from '../../lib/validation';
import * as transport from '../../services/transport.service';

const listQuery = pageQuery.extend({
  studentId: z.string().uuid('Invalid studentId').optional(),
  search: queryText,
});

const fields = z.object({
  studentId: z.string().uuid('Invalid studentId'),
  busRoute: z.string().trim().min(1, 'Route is required').max(300),
  passNo: z.string().trim().min(1, 'Pass number is required').max(100),
  batchCode: optionalText(100),
  busCode: optionalText(100),
  pickupAddress: optionalText(500),
  pickupPoint: optionalText(300),
  shift: optionalText(300),
  validFrom: dateString,
  validTo: dateString,
  active: z.boolean().optional(),
  feesAmount: z.number().int().min(0).optional(),
  feesPaid: z.number().int().min(0).optional(),
});

const validRange = (v: { validFrom?: Date; validTo?: Date }): boolean =>
  !v.validFrom || !v.validTo || v.validFrom <= v.validTo;
const rangeError = { path: ['validTo'], message: 'Valid-to date cannot be before valid-from' };

const createBody = fields.refine(validRange, rangeError);
const updateBody = fields.partial().refine(validRange, rangeError);

const receiptBody = z.object({
  studentId: z.string().uuid('Invalid studentId'),
  receiptNo: z.string().trim().min(1, 'Receipt number is required').max(100),
  paidOn: dateString,
  amount: z.number().int().min(0),
  description: optionalText(500),
});

export const listReceipts = asyncHandler(async (req, res) => {
  const { studentId, page, limit } = studentPageQuery.parse(req.query);
  okPage(res, await transport.listReceipts(studentId, toPageParams({ page, limit })));
});

export const createReceipt = asyncHandler(async (req, res) => {
  ok(res, await transport.createReceipt(receiptBody.parse(req.body)), 201);
});

export const updateReceipt = asyncHandler(async (req, res) => {
  const { id } = uuidParam.parse(req.params);
  ok(res, await transport.updateReceipt(id, receiptBody.partial().parse(req.body)));
});

export const removeReceipt = asyncHandler(async (req, res) => {
  await transport.deleteReceipt(uuidParam.parse(req.params).id);
  ok(res, { deleted: true });
});

export const list = asyncHandler(async (req, res) => {
  const { page, limit, ...filters } = listQuery.parse(req.query);
  okPage(res, await transport.listTransport(toPageParams({ page, limit }), filters));
});

export const get = asyncHandler(async (req, res) => {
  ok(res, await transport.getTransport(uuidParam.parse(req.params).id));
});

export const create = asyncHandler(async (req, res) => {
  ok(res, await transport.createTransport(createBody.parse(req.body)), 201);
});

export const update = asyncHandler(async (req, res) => {
  const { id } = uuidParam.parse(req.params);
  ok(res, await transport.updateTransport(id, updateBody.parse(req.body)));
});

export const remove = asyncHandler(async (req, res) => {
  await transport.deleteTransport(uuidParam.parse(req.params).id);
  ok(res, { deleted: true });
});
