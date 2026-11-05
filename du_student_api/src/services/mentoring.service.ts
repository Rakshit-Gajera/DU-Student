import type { Prisma } from '@prisma/client';
import { notFound } from '../lib/http';
import { prisma } from '../lib/prisma';
import { pageMeta } from '../lib/validation';
import type { PageParams } from '../types';

// ------------------------------------------------------------ Sessions

export async function listSessions(params: PageParams, filters: { studentId?: string }) {
  const where: Prisma.MentoringSessionWhereInput = filters;
  const [items, total] = await prisma.$transaction([
    prisma.mentoringSession.findMany({
      where,
      include: { student: { select: { id: true, name: true, enrollmentNo: true } } },
      orderBy: { when: 'desc' },
      skip: params.skip,
      take: params.limit,
    }),
    prisma.mentoringSession.count({ where }),
  ]);
  return { items, meta: pageMeta(params, total) };
}

export async function getSession(id: string) {
  const session = await prisma.mentoringSession.findUnique({ where: { id } });
  if (!session) throw notFound('Mentoring session');
  return session;
}

export const createSession = (data: Prisma.MentoringSessionUncheckedCreateInput) =>
  prisma.mentoringSession.create({ data });

export const updateSession = (id: string, data: Prisma.MentoringSessionUncheckedUpdateInput) =>
  prisma.mentoringSession.update({ where: { id }, data });

export async function deleteSession(id: string): Promise<void> {
  await prisma.mentoringSession.delete({ where: { id } });
}

// ------------------------------------------------------------ Mentors

export async function listMentors(params: PageParams) {
  const [items, total] = await prisma.$transaction([
    prisma.mentor.findMany({ orderBy: { name: 'asc' }, skip: params.skip, take: params.limit }),
    prisma.mentor.count(),
  ]);
  return { items, meta: pageMeta(params, total) };
}

export const createMentor = (data: Prisma.MentorUncheckedCreateInput) => prisma.mentor.create({ data });

export const updateMentor = (id: string, data: Prisma.MentorUncheckedUpdateInput) =>
  prisma.mentor.update({ where: { id }, data });

export async function deleteMentor(id: string): Promise<void> {
  await prisma.mentor.delete({ where: { id } });
}

// ------------------------------------------------------------ Mentor history

export const listMentorHistory = (studentId: string) =>
  prisma.mentorHistory.findMany({ where: { studentId }, orderBy: { fromDate: 'desc' } });

export const createMentorHistory = (data: Prisma.MentorHistoryUncheckedCreateInput) =>
  prisma.mentorHistory.create({ data });

export const updateMentorHistory = (id: string, data: Prisma.MentorHistoryUncheckedUpdateInput) =>
  prisma.mentorHistory.update({ where: { id }, data });

export async function deleteMentorHistory(id: string): Promise<void> {
  await prisma.mentorHistory.delete({ where: { id } });
}

// ------------------------------------------------------------ Student view

export async function getMentoringForStudent(studentId: string, params: PageParams) {
  const [student, page, history] = await Promise.all([
    prisma.student.findUnique({ where: { id: studentId }, select: { mentor: true } }),
    listSessions(params, { studentId }),
    listMentorHistory(studentId),
  ]);
  return { data: { mentor: student?.mentor ?? null, sessions: page.items, history }, meta: page.meta };
}
