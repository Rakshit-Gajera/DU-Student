import type { AttendanceStatus, Prisma } from '@prisma/client';
import { round2 } from '../lib/grades';
import { prisma } from '../lib/prisma';
import { pageMeta } from '../lib/validation';
import type { PageParams } from '../types';

/** The app always draws at least this many slot columns. */
const MIN_SLOTS = 5;
const WEEKDAYS = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

export interface AttendanceGridRow {
  date: string;
  day: string;
  /** Index 0 is slot 1. null means no lecture in that slot. */
  slots: (AttendanceStatus | null)[];
}

/** One page of the daily grid, newest date first. Pagination counts dates, not records. */
export async function getAttendanceGrid(studentId: string, params: PageParams) {
  const where: Prisma.AttendanceRecordWhereInput = { studentId };
  const allDates = await prisma.attendanceRecord.findMany({
    where,
    distinct: ['date'],
    select: { date: true },
    orderBy: { date: 'desc' },
  });
  const dates = allDates.slice(params.skip, params.skip + params.limit).map((d) => d.date);
  const records = await prisma.attendanceRecord.findMany({
    where: { studentId, date: { in: dates } },
    select: { date: true, slot: true, status: true },
  });

  const slotCount = Math.max(MIN_SLOTS, ...records.map((r) => r.slot));
  const items: AttendanceGridRow[] = dates.map((date) => {
    const slots = new Array<AttendanceStatus | null>(slotCount).fill(null);
    for (const r of records) {
      if (r.date.getTime() === date.getTime()) slots[r.slot - 1] = r.status;
    }
    return {
      date: date.toISOString().slice(0, 10),
      day: WEEKDAYS[date.getUTCDay()] ?? '',
      slots,
    };
  });
  return { items, meta: pageMeta(params, allDates.length) };
}

export interface BulkAttendanceItem {
  studentId: string;
  date: Date;
  slot: number;
  /** null clears the slot. */
  status: AttendanceStatus | null;
  subjectId?: string | null;
}

export async function bulkSaveAttendance(items: readonly BulkAttendanceItem[]) {
  await prisma.$transaction(
    items.map((item) => {
      const key = { studentId: item.studentId, date: item.date, slot: item.slot };
      if (item.status === null) return prisma.attendanceRecord.deleteMany({ where: key });
      return prisma.attendanceRecord.upsert({
        where: { studentId_date_slot: key },
        create: { ...key, status: item.status, subjectId: item.subjectId },
        update: { status: item.status, subjectId: item.subjectId },
      });
    }),
  );
  return { saved: items.length };
}

// ------------------------------------------------------------ Current semester totals

export const getAttendanceSummary = (studentId: string) =>
  prisma.attendanceSummary.findUnique({ where: { studentId } });

export function saveAttendanceSummary(data: {
  studentId: string;
  yearLabel: string;
  percent: number;
  present: number;
  absent: number;
  pending: number;
  noAttendance: number;
  total: number;
}) {
  const { studentId, ...fields } = data;
  return prisma.attendanceSummary.upsert({ where: { studentId }, create: data, update: fields });
}

// ------------------------------------------------------------ Past semesters

export async function listPastSemesters(studentId: string, params: PageParams) {
  const where = { studentId };
  const [items, total] = await prisma.$transaction([
    prisma.pastSemesterAttendance.findMany({
      where,
      orderBy: { semNo: 'desc' },
      skip: params.skip,
      take: params.limit,
    }),
    prisma.pastSemesterAttendance.count({ where }),
  ]);
  return { items, meta: pageMeta(params, total) };
}

export function savePastSemester(data: {
  studentId: string;
  semNo: number;
  yearLabel: string;
  percent: number;
}) {
  const { studentId, semNo, ...fields } = data;
  return prisma.pastSemesterAttendance.upsert({
    where: { studentId_semNo: { studentId, semNo } },
    create: data,
    update: fields,
  });
}

export async function deletePastSemester(id: string): Promise<void> {
  await prisma.pastSemesterAttendance.delete({ where: { id } });
}

// ------------------------------------------------------------ Course-wise

const withPercent = <T extends { total: number; present: number }>(row: T) => ({
  ...row,
  percent: row.total === 0 ? 0 : round2((row.present / row.total) * 100),
});

export async function listCourseAttendance(studentId: string, params: PageParams) {
  const where = { studentId };
  const [items, total] = await prisma.$transaction([
    prisma.courseAttendance.findMany({
      where,
      orderBy: { course: 'asc' },
      skip: params.skip,
      take: params.limit,
    }),
    prisma.courseAttendance.count({ where }),
  ]);
  return { items: items.map(withPercent), meta: pageMeta(params, total) };
}

export async function saveCourseAttendance(data: {
  studentId: string;
  course: string;
  total: number;
  present: number;
}) {
  const { studentId, course, ...fields } = data;
  const row = await prisma.courseAttendance.upsert({
    where: { studentId_course: { studentId, course } },
    create: data,
    update: fields,
  });
  return withPercent(row);
}

export async function deleteCourseAttendance(id: string): Promise<void> {
  await prisma.courseAttendance.delete({ where: { id } });
}
