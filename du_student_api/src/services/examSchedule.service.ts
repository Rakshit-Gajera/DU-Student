import type { ExamType, Prisma } from '@prisma/client';
import { notFound } from '../lib/http';
import { prisma } from '../lib/prisma';
import { pageMeta } from '../lib/validation';
import type { PageParams } from '../types';

const subjectSummary = { select: { id: true, code: true, name: true } };

async function list(params: PageParams, where: Prisma.ExamScheduleWhereInput) {
  const [items, total] = await prisma.$transaction([
    prisma.examSchedule.findMany({
      where,
      include: { subject: subjectSummary },
      orderBy: { startDate: 'asc' },
      skip: params.skip,
      take: params.limit,
    }),
    prisma.examSchedule.count({ where }),
  ]);
  return { items, meta: pageMeta(params, total) };
}

export const listExamSchedules = (params: PageParams, filters: { studentId: string; type?: ExamType; semester?: number }) =>
  list(params, filters);

export async function getExamSchedule(id: string) {
  const exam = await prisma.examSchedule.findUnique({ where: { id }, include: { subject: subjectSummary } });
  if (!exam) throw notFound('Exam schedule');
  return exam;
}

export const createExamSchedule = (data: Prisma.ExamScheduleUncheckedCreateInput) =>
  prisma.examSchedule.create({ data });

export const updateExamSchedule = (id: string, data: Prisma.ExamScheduleUncheckedUpdateInput) =>
  prisma.examSchedule.update({ where: { id }, data });

export async function deleteExamSchedule(id: string): Promise<void> {
  await prisma.examSchedule.delete({ where: { id } });
}
