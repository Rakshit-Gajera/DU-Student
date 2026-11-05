import { z } from 'zod';
import type { PageMeta, PageParams } from '../types';

export const uuidParam = z.object({ id: z.string().uuid('Invalid id') });

export const pageQuery = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

export function toPageParams(q: { page: number; limit: number }): PageParams {
  return { page: q.page, limit: q.limit, skip: (q.page - 1) * q.limit };
}

export function pageMeta(params: PageParams, total: number): PageMeta {
  return {
    page: params.page,
    limit: params.limit,
    total,
    totalPages: Math.max(1, Math.ceil(total / params.limit)),
  };
}

/** Calendar date "YYYY-MM-DD", stored at UTC midnight so it never shifts by timezone. */
export const dateString = z
  .string()
  .regex(/^\d{4}-\d{2}-\d{2}$/, 'Expected a date as YYYY-MM-DD')
  .refine((s) => {
    const d = new Date(`${s}T00:00:00.000Z`);
    return !Number.isNaN(d.getTime()) && d.toISOString().startsWith(s);
  }, 'Not a real calendar date')
  .transform((s) => new Date(`${s}T00:00:00.000Z`));

export const dateTimeString = z
  .string()
  .datetime({ offset: true, message: 'Expected an ISO 8601 date-time' })
  .transform((s) => new Date(s));

/**
 * A stored file reference: our own upload or an http(s) link. This excludes
 * schemes such as javascript:, because the value ends up in an href or src.
 */
export const fileReference = z
  .string()
  .trim()
  .max(2048)
  .refine(
    (v) => /^\/uploads\/[\w.-]+$/.test(v) || /^https?:\/\/\S+$/i.test(v),
    'Must be an http(s) URL or an uploaded file path',
  );

/** Query string filter: `?batch=` means no filter, not "batch is empty". */
export const queryText = z
  .string()
  .trim()
  .optional()
  .transform((v) => v || undefined);

/** Pagination plus a required student, for admin lists scoped to one student. */
export const studentPageQuery = pageQuery.extend({ studentId: z.string().uuid('Invalid studentId') });

/** Optional text from a form: an empty string means "clear this field". */
export const optionalText = (max = 500) =>
  z.preprocess(
    (v) => (typeof v === 'string' && v.trim() === '' ? null : v),
    z.string().trim().max(max).nullable().optional(),
  );
