import { CertificateStatus } from '@prisma/client';
import { z } from 'zod';
import { asyncHandler, currentAdmin, ok, okPage } from '../../lib/http';
import { optionalText, pageQuery, queryText, toPageParams, uuidParam } from '../../lib/validation';
import * as certificates from '../../services/certificates.service';

const listQuery = pageQuery.extend({
  status: z.nativeEnum(CertificateStatus).optional(),
  studentId: z.string().uuid('Invalid studentId').optional(),
  search: queryText,
});

const fields = {
  type: z.string().trim().min(1, 'Certificate type is required').max(200),
  purpose: optionalText(200),
  copies: z.coerce.number().int().min(1).max(10),
  deliveryMode: optionalText(100),
  details: optionalText(2000),
};
const createBody = z.object({ studentId: z.string().uuid('Invalid studentId'), ...fields });
const updateBody = z.object({
  status: z.nativeEnum(CertificateStatus),
  remarks: optionalText(1000),
  type: fields.type.optional(),
  purpose: fields.purpose,
  copies: fields.copies.optional(),
  deliveryMode: fields.deliveryMode,
  details: fields.details,
});

export const create = asyncHandler(async (req, res) => {
  const { studentId, ...body } = createBody.parse(req.body);
  ok(res, await certificates.requestCertificate(studentId, body), 201);
});

export const remove = asyncHandler(async (req, res) => {
  await certificates.deleteCertificate(uuidParam.parse(req.params).id);
  ok(res, { deleted: true });
});

export const list = asyncHandler(async (req, res) => {
  const { page, limit, ...filters } = listQuery.parse(req.query);
  okPage(res, await certificates.listCertificates(toPageParams({ page, limit }), filters));
});

export const get = asyncHandler(async (req, res) => {
  ok(res, await certificates.getCertificate(uuidParam.parse(req.params).id));
});

export const update = asyncHandler(async (req, res) => {
  const { id } = uuidParam.parse(req.params);
  const body = updateBody.parse(req.body);
  ok(res, await certificates.decideCertificate(id, body, currentAdmin(req).username));
});
