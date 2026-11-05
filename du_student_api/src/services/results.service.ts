import type { Prisma } from '@prisma/client';
import { countBacklogs, isPassed, weightedAverage } from '../lib/grades';
import { notFound } from '../lib/http';
import { prisma } from '../lib/prisma';
import { pageMeta } from '../lib/validation';
import type { PageParams } from '../types';

const withCourses = {
  courses: {
    include: { subject: true },
    orderBy: { subject: { code: 'asc' } },
  },
} satisfies Prisma.SemesterResultInclude;

export interface CourseInput {
  subjectId: string;
  grade: string;
  credits: number;
  examSeason?: string | null;
  attemptNo?: number;
}

/**
 * Rewrites spi, cpi and backlogs on every semester of a student. The CPI of a
 * semester covers all courses up to and including it, so editing one semester
 * can change the CPI of later ones.
 */
export async function recalculateStudentResults(
  tx: Prisma.TransactionClient,
  studentId: string,
): Promise<void> {
  const semesters = await tx.semesterResult.findMany({
    where: { studentId },
    include: { courses: { select: { grade: true, credits: true } } },
    orderBy: { semNo: 'asc' },
  });
  const cumulative: { grade: string; credits: number }[] = [];
  for (const sem of semesters) {
    cumulative.push(...sem.courses);
    await tx.semesterResult.update({
      where: { id: sem.id },
      data: {
        spi: weightedAverage(sem.courses),
        cpi: weightedAverage(cumulative),
        backlogs: countBacklogs(sem.courses),
      },
    });
  }
}

export async function listResults(studentId: string, params: PageParams) {
  const where = { studentId };
  const [items, total] = await prisma.$transaction([
    prisma.semesterResult.findMany({
      where,
      include: withCourses,
      orderBy: { semNo: 'desc' },
      skip: params.skip,
      take: params.limit,
    }),
    prisma.semesterResult.count({ where }),
  ]);
  return { items, meta: pageMeta(params, total) };
}

export async function getResult(id: string) {
  const result = await prisma.semesterResult.findUnique({ where: { id }, include: withCourses });
  if (!result) throw notFound('Semester result');
  return result;
}

export async function createResult(data: {
  studentId: string;
  semNo: number;
  yearLabel: string;
  courses: CourseInput[];
}) {
  const { courses, ...fields } = data;
  const id = await prisma.$transaction(async (tx) => {
    const created = await tx.semesterResult.create({
      data: { ...fields, courses: { create: courses } },
    });
    await recalculateStudentResults(tx, data.studentId);
    return created.id;
  });
  return getResult(id);
}

export async function updateResult(
  id: string,
  data: { semNo?: number; yearLabel?: string; courses?: CourseInput[] },
) {
  const { courses, ...fields } = data;
  await prisma.$transaction(async (tx) => {
    const updated = await tx.semesterResult.update({ where: { id }, data: fields });
    if (courses) {
      await tx.courseResult.deleteMany({ where: { semResultId: id } });
      await tx.courseResult.createMany({
        data: courses.map((c) => ({ ...c, semResultId: id })),
      });
    }
    await recalculateStudentResults(tx, updated.studentId);
  });
  return getResult(id);
}

export async function deleteResult(id: string): Promise<void> {
  await prisma.$transaction(async (tx) => {
    const deleted = await tx.semesterResult.delete({ where: { id } });
    await recalculateStudentResults(tx, deleted.studentId);
  });
}

/** What the Flutter transcript screen shows: totals over all semesters, plus one page of them. */
export async function getStudentResults(studentId: string, params: PageParams) {
  const page = await listResults(studentId, params);
  const [latest, allCourses] = await prisma.$transaction([
    prisma.semesterResult.findFirst({
      where: { studentId },
      orderBy: { semNo: 'desc' },
      select: { cpi: true },
    }),
    prisma.courseResult.findMany({
      where: { semResult: { studentId } },
      select: { grade: true, credits: true },
    }),
  ]);

  const gradeCounts = new Map<string, number>();
  for (const { grade } of allCourses) gradeCounts.set(grade, (gradeCounts.get(grade) ?? 0) + 1);

  return {
    data: {
      cpi: latest?.cpi ?? 0,
      backlogs: countBacklogs(allCourses),
      totalSubjects: allCourses.length,
      passed: allCourses.filter((c) => isPassed(c.grade)).length,
      grades: [...gradeCounts].map(([grade, count]) => ({ grade, count })),
      semesters: page.items,
    },
    meta: page.meta,
  };
}
