import type { Prisma } from '@prisma/client';
import { notFound } from '../lib/http';
import { prisma } from '../lib/prisma';
import { pageMeta } from '../lib/validation';
import type { PageParams } from '../types';

const newestPinnedFirst = [
  { pinned: 'desc' },
  { publishedAt: 'desc' },
] satisfies Prisma.CircularOrderByWithRelationInput[];

export async function listCirculars(params: PageParams, filters: { studentId: string; publishedOnly: boolean }) {
  const where: Prisma.CircularWhereInput = {
    studentId: filters.studentId,
    ...(filters.publishedOnly ? { publishedAt: { lte: new Date() } } : {}),
  };
  const [items, total] = await prisma.$transaction([
    prisma.circular.findMany({ where, orderBy: newestPinnedFirst, skip: params.skip, take: params.limit }),
    prisma.circular.count({ where }),
  ]);
  return { items, meta: pageMeta(params, total) };
}

export async function getCircular(id: string) {
  const circular = await prisma.circular.findUnique({ where: { id } });
  if (!circular) throw notFound('Circular');
  return circular;
}

export const createCircular = (data: Prisma.CircularUncheckedCreateInput) => prisma.circular.create({ data });

export const updateCircular = (id: string, data: Prisma.CircularUncheckedUpdateInput) =>
  prisma.circular.update({ where: { id }, data });

export async function deleteCircular(id: string): Promise<void> {
  await prisma.circular.delete({ where: { id } });
}
