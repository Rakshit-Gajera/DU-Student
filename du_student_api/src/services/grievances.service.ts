import { Prisma, type GrievanceStatus } from '@prisma/client';
import { HttpError, notFound } from '../lib/http';
import { prisma } from '../lib/prisma';
import { pageMeta } from '../lib/validation';
import type { PageParams } from '../types';

const studentSummary = { select: { id: true, name: true, enrollmentNo: true, classLabel: true } };

export async function listGrievances(
  params: PageParams,
  filters: { status?: GrievanceStatus; studentId?: string; search?: string },
) {
  const where: Prisma.GrievanceWhereInput = {
    status: filters.status,
    studentId: filters.studentId,
    ...(filters.search
      ? {
          OR: [
            { title: { contains: filters.search, mode: 'insensitive' } },
            { grievanceNo: { contains: filters.search, mode: 'insensitive' } },
            { student: { name: { contains: filters.search, mode: 'insensitive' } } },
          ],
        }
      : {}),
  };
  const [items, total] = await prisma.$transaction([
    prisma.grievance.findMany({
      where,
      include: { student: studentSummary },
      orderBy: { filedAt: 'desc' },
      skip: params.skip,
      take: params.limit,
    }),
    prisma.grievance.count({ where }),
  ]);
  return { items, meta: pageMeta(params, total) };
}

export async function getGrievance(id: string) {
  const grievance = await prisma.grievance.findUnique({ where: { id }, include: { student: studentSummary } });
  if (!grievance) throw notFound('Grievance');
  return grievance;
}

export async function deleteGrievance(id: string): Promise<void> {
  await prisma.grievance.delete({ where: { id } });
}

export async function updateGrievanceStatus(
  id: string,
  data: {
    status: GrievanceStatus;
    resolution?: string | null;
    category?: string;
    title?: string;
    description?: string;
  },
  adminName: string,
) {
  const resolved = data.status === 'RESOLVED';
  return prisma.grievance.update({
    where: { id },
    data: {
      ...data,
      resolvedAt: resolved ? new Date() : null,
      resolvedBy: resolved ? adminName : null,
    },
    include: { student: studentSummary },
  });
}

/**
 * Grievance numbers look like "2026/00031". Two students filing at once can pick
 * the same number, so a unique-constraint clash retries with the next one.
 */
export async function fileGrievance(
  studentId: string,
  data: { category: string; title: string; description: string },
) {
  const year = new Date().getUTCFullYear();
  for (let attempt = 0; attempt < 5; attempt += 1) {
    const last = await prisma.grievance.findFirst({
      where: { grievanceNo: { startsWith: `${year}/` } },
      orderBy: { grievanceNo: 'desc' },
      select: { grievanceNo: true },
    });
    const next = Number(last?.grievanceNo.split('/')[1] ?? 0) + 1;
    try {
      return await prisma.grievance.create({
        data: { ...data, studentId, grievanceNo: `${year}/${String(next).padStart(5, '0')}` },
      });
    } catch (err) {
      const clash = err instanceof Prisma.PrismaClientKnownRequestError && err.code === 'P2002';
      if (!clash) throw err;
    }
  }
  throw new HttpError(503, 'Could not file the grievance right now, please try again');
}
