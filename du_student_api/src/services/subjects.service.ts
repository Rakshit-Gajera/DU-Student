import type { Prisma } from '@prisma/client';
import { HttpError, notFound } from '../lib/http';
import { prisma } from '../lib/prisma';
import { pageMeta } from '../lib/validation';
import type { PageParams } from '../types';

export async function listSubjects(params: PageParams, filters: { search?: string; semester?: number }) {
  const where: Prisma.SubjectWhereInput = {
    semester: filters.semester,
    ...(filters.search
      ? {
          OR: [
            { name: { contains: filters.search, mode: 'insensitive' } },
            { code: { contains: filters.search, mode: 'insensitive' } },
          ],
        }
      : {}),
  };
  const [items, total] = await prisma.$transaction([
    prisma.subject.findMany({
      where,
      orderBy: [{ semester: { sort: 'desc', nulls: 'last' } }, { code: 'asc' }],
      skip: params.skip,
      take: params.limit,
    }),
    prisma.subject.count({ where }),
  ]);
  return { items, meta: pageMeta(params, total) };
}

export async function getSubject(id: string) {
  const subject = await prisma.subject.findUnique({ where: { id } });
  if (!subject) throw notFound('Subject');
  return subject;
}

export const createSubject = (data: Prisma.SubjectUncheckedCreateInput) => prisma.subject.create({ data });

export const updateSubject = (id: string, data: Prisma.SubjectUncheckedUpdateInput) =>
  prisma.subject.update({ where: { id }, data });

export async function deleteSubject(id: string): Promise<void> {
  // Checked here because the error code for the foreign key RESTRICT differs across Postgres versions.
  const results = await prisma.courseResult.count({ where: { subjectId: id } });
  if (results > 0) {
    throw new HttpError(409, `This subject is used by ${results} course result(s) and cannot be deleted`);
  }
  await prisma.subject.delete({ where: { id } });
}
