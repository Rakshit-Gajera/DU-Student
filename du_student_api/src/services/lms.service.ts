import type { LmsContentType, Prisma } from '@prisma/client';
import { notFound } from '../lib/http';
import { prisma } from '../lib/prisma';
import { pageMeta } from '../lib/validation';
import type { PageParams } from '../types';
import { removeUploadedFile } from './uploads.service';

export async function listLmsContent(
  params: PageParams,
  filters: { studentId: string; subjectId?: string; type?: LmsContentType },
) {
  const where: Prisma.LmsContentWhereInput = filters;
  const [items, total] = await prisma.$transaction([
    prisma.lmsContent.findMany({
      where,
      include: { subject: { select: { id: true, code: true, name: true } } },
      orderBy: [{ uploadedAt: 'desc' }, { createdAt: 'asc' }],
      skip: params.skip,
      take: params.limit,
    }),
    prisma.lmsContent.count({ where }),
  ]);
  return { items, meta: pageMeta(params, total) };
}

export async function getLmsContent(id: string) {
  const content = await prisma.lmsContent.findUnique({ where: { id } });
  if (!content) throw notFound('LMS content');
  return content;
}

export const createLmsContent = (data: Prisma.LmsContentUncheckedCreateInput) =>
  prisma.lmsContent.create({ data });

export const updateLmsContent = (id: string, data: Prisma.LmsContentUncheckedUpdateInput) =>
  prisma.lmsContent.update({ where: { id }, data });

export async function deleteLmsContent(id: string): Promise<void> {
  const deleted = await prisma.lmsContent.delete({ where: { id } });
  await removeUploadedFile(deleted.fileUrl);
}

/** Student view: hides items the admin has unpublished and adds the per-student seen flag. */
export async function listContentForStudent(
  studentId: string,
  subjectId: string,
  type: LmsContentType,
  params: PageParams,
) {
  const where: Prisma.LmsContentWhereInput = { studentId, subjectId, type, visible: true };
  const [rows, total] = await prisma.$transaction([
    prisma.lmsContent.findMany({
      where,
      include: { views: { where: { studentId }, select: { seenAt: true } } },
      orderBy: [{ uploadedAt: 'desc' }, { createdAt: 'asc' }],
      skip: params.skip,
      take: params.limit,
    }),
    prisma.lmsContent.count({ where }),
  ]);
  const items = rows.map(({ views, ...content }) => ({
    ...content,
    seen: views.length > 0,
    seenAt: views[0]?.seenAt ?? null,
  }));
  return { items, meta: pageMeta(params, total) };
}

export async function markContentSeen(studentId: string, contentId: string): Promise<void> {
  const content = await prisma.lmsContent.findFirst({ where: { id: contentId, studentId, visible: true } });
  if (!content) throw notFound('LMS content');
  await prisma.lmsContentView.upsert({
    where: { studentId_contentId: { studentId, contentId } },
    create: { studentId, contentId },
    update: {},
  });
}
