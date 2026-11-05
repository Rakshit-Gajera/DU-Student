import { prisma } from '../lib/prisma';
import { pageMeta } from '../lib/validation';
import type { PageParams } from '../types';
import { getStudent } from './students.service';

export const getProfile = (studentId: string) => getStudent(studentId);

/** Subjects of the current semester of the student. These drive the LMS screen. */
export async function listCurrentSubjects(studentId: string, params: PageParams) {
  const { currentSem } = await getStudent(studentId);
  const where = { semester: currentSem };
  const [items, total] = await prisma.$transaction([
    prisma.subject.findMany({ where, orderBy: { code: 'asc' }, skip: params.skip, take: params.limit }),
    prisma.subject.count({ where }),
  ]);
  return { items, meta: pageMeta(params, total) };
}
