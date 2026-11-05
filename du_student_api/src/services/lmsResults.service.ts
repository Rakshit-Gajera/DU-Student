import type { Prisma } from '@prisma/client';
import { prisma } from '../lib/prisma';
import { pageMeta } from '../lib/validation';
import type { PageParams } from '../types';

export async function listLmsResults(studentId: string, params: PageParams) {
  const where = { studentId };
  const [items, total] = await prisma.$transaction([
    prisma.lmsTestResult.findMany({
      where,
      orderBy: [{ semNo: 'desc' }, { position: 'asc' }, { course: 'asc' }, { unit: 'asc' }, { attemptNo: 'asc' }],
      skip: params.skip,
      take: params.limit,
    }),
    prisma.lmsTestResult.count({ where }),
  ]);
  return { items, meta: pageMeta(params, total) };
}

export const createLmsResult = (data: Prisma.LmsTestResultUncheckedCreateInput) => prisma.lmsTestResult.create({ data });

export const updateLmsResult = (id: string, data: Prisma.LmsTestResultUncheckedUpdateInput) =>
  prisma.lmsTestResult.update({ where: { id }, data });

export async function deleteLmsResult(id: string): Promise<void> {
  await prisma.lmsTestResult.delete({ where: { id } });
}
