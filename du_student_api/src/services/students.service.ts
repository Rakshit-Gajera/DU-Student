import type { Prisma } from '@prisma/client';
import { notFound } from '../lib/http';
import { prisma } from '../lib/prisma';
import { pageMeta } from '../lib/validation';
import type { PageParams } from '../types';
import { hashPassword } from './auth.service';

const publicFields = {
  omit: { passwordHash: true },
  include: { mentor: true },
} as const;

export interface StudentFilters {
  search?: string;
  batch?: string;
  classLabel?: string;
  sortBy: 'name' | 'enrollmentNo' | 'classLabel' | 'batch' | 'rollNo';
  order: 'asc' | 'desc';
}

export async function listStudents(params: PageParams, filters: StudentFilters) {
  const where: Prisma.StudentWhereInput = {
    batch: filters.batch,
    classLabel: filters.classLabel,
    ...(filters.search
      ? {
          OR: [
            { name: { contains: filters.search, mode: 'insensitive' } },
            { enrollmentNo: { contains: filters.search, mode: 'insensitive' } },
            { rollNo: { contains: filters.search, mode: 'insensitive' } },
          ],
        }
      : {}),
  };
  const [items, total] = await prisma.$transaction([
    prisma.student.findMany({
      ...publicFields,
      where,
      orderBy: { [filters.sortBy]: filters.order },
      skip: params.skip,
      take: params.limit,
    }),
    prisma.student.count({ where }),
  ]);
  return { items, meta: pageMeta(params, total) };
}

/** The values the batch and class filters on the students page can offer. */
export async function studentFilterOptions() {
  const [batches, classes] = await prisma.$transaction([
    prisma.student.findMany({ distinct: ['batch'], select: { batch: true }, orderBy: { batch: 'asc' } }),
    prisma.student.findMany({
      distinct: ['classLabel'],
      select: { classLabel: true },
      orderBy: { classLabel: 'asc' },
    }),
  ]);
  return { batches: batches.map((b) => b.batch), classes: classes.map((c) => c.classLabel) };
}

export async function getStudent(id: string) {
  const student = await prisma.student.findUnique({ ...publicFields, where: { id } });
  if (!student) throw notFound('Student');
  return student;
}

type StudentFields = Omit<Prisma.StudentUncheckedCreateInput, 'id' | 'passwordHash' | 'createdAt' | 'updatedAt'>;

export async function createStudent(data: StudentFields & { password: string }) {
  const { password, ...fields } = data;
  return prisma.student.create({
    ...publicFields,
    data: { ...fields, passwordHash: await hashPassword(password) },
  });
}

export async function updateStudent(id: string, data: Partial<StudentFields> & { password?: string }) {
  const { password, ...fields } = data;
  return prisma.student.update({
    ...publicFields,
    where: { id },
    data: {
      ...fields,
      ...(password ? { passwordHash: await hashPassword(password), tokenVersion: { increment: 1 } } : {}),
    },
  });
}

export async function deleteStudent(id: string): Promise<void> {
  await prisma.student.delete({ where: { id } });
}
