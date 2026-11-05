'use client';

import { zodResolver } from '@hookform/resolvers/zod';
import { keepPreviousData, useQuery } from '@tanstack/react-query';
import { ChevronLeft, ChevronRight, Loader2, Pencil, Plus, Trash2 } from 'lucide-react';
import { useMemo, useState } from 'react';
import { useForm } from 'react-hook-form';
import { z } from 'zod';
import { AttendanceBar } from '@/components/charts/AttendanceBar';
import { EmptyState, Field, PageHeader, QueryError, SubmitButton } from '@/components/shared/common';
import { StudentPicker } from '@/components/shared/StudentPicker';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { Skeleton } from '@/components/ui/skeleton';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { useApiMutation } from '@/hooks/useApiMutation';
import { del, getAll, getOne, getPage, post, put } from '@/lib/api';
import type {
  AttendanceRow,
  AttendanceStatus,
  AttendanceSummary,
  CourseAttendance,
  PastSemester,
  StudentSummary,
} from '@/lib/types';
import { cn, formatDate } from '@/lib/utils';

const NONE = '';
const MIN_SLOTS = 5;
const STATUS_OPTIONS: readonly { value: AttendanceStatus | typeof NONE; label: string }[] = [
  { value: NONE, label: '-' },
  { value: 'P', label: 'P' },
  { value: 'A', label: 'A' },
  { value: 'AE', label: 'A (e)' },
  { value: 'NA', label: 'NA' },
];
const STATUS_CLASS: Record<AttendanceStatus | typeof NONE, string> = {
  [NONE]: 'bg-background text-muted-foreground',
  P: 'border-emerald-300 bg-emerald-50 text-emerald-900',
  A: 'border-red-300 bg-red-50 text-red-900',
  AE: 'border-amber-300 bg-amber-50 text-amber-900',
  NA: 'border-slate-300 bg-slate-100 text-slate-700',
};

const WEEKDAYS = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
const editKey = (date: string, slot: number): string => `${date}|${slot}`;

// ------------------------------------------------------------ Daily grid

function DailyGrid({ studentId }: { studentId: string }) {
  const [page, setPage] = useState(1);
  const [edits, setEdits] = useState<Record<string, AttendanceStatus | null>>({});
  const [newDates, setNewDates] = useState<string[]>([]);
  const [dateToAdd, setDateToAdd] = useState('');

  const grid = useQuery({
    queryKey: ['attendance', studentId, 'grid', page],
    queryFn: () => getPage<AttendanceRow>('/api/admin/attendance', { studentId, page, limit: 15 }),
    placeholderData: keepPreviousData,
  });

  const rows = useMemo<AttendanceRow[]>(() => {
    const loaded = grid.data?.items ?? [];
    const added = newDates
      .filter((date) => !loaded.some((r) => r.date === date))
      .map((date) => ({
        date,
        day: WEEKDAYS[new Date(`${date}T00:00:00Z`).getUTCDay()] ?? '',
        slots: [] as (AttendanceStatus | null)[],
      }));
    return [...added, ...loaded];
  }, [grid.data, newDates]);

  const slotCount = Math.max(MIN_SLOTS, ...rows.map((r) => r.slots.length));
  const pendingCount = Object.keys(edits).length;

  const save = useApiMutation(
    () =>
      post<{ saved: number }>('/api/admin/attendance/bulk', {
        records: Object.entries(edits).map(([key, status]) => {
          const [date, slot] = key.split('|');
          return { studentId, date, slot: Number(slot), status };
        }),
      }),
    {
      success: (r) => `Saved ${r.saved} attendance ${r.saved === 1 ? 'change' : 'changes'}`,
      invalidate: [['attendance', studentId, 'grid']],
      onSuccess: () => {
        setEdits({});
        setNewDates([]);
      },
    },
  );

  function setCell(row: AttendanceRow, slot: number, value: AttendanceStatus | typeof NONE) {
    const next = value === NONE ? null : value;
    const original = row.slots[slot - 1] ?? null;
    setEdits((current) => {
      const updated = { ...current };
      const key = editKey(row.date, slot);
      // Changing a cell back to its saved value is no longer a pending edit.
      if (next === original) delete updated[key];
      else updated[key] = next;
      return updated;
    });
  }

  function addDate() {
    if (!dateToAdd) return;
    setNewDates((d) => (d.includes(dateToAdd) ? d : [dateToAdd, ...d]));
    setDateToAdd('');
  }

  return (
    <div className="space-y-3">
      <div className="flex flex-wrap items-end justify-between gap-3">
        <div className="flex items-end gap-2">
          <Field label="Add a date" htmlFor="add-date">
            <Input id="add-date" type="date" value={dateToAdd} onChange={(e) => setDateToAdd(e.target.value)} />
          </Field>
          <Button variant="outline" onClick={addDate} disabled={!dateToAdd}>
            <Plus className="mr-1 h-4 w-4" aria-hidden />
            Add
          </Button>
        </div>
        <div className="flex gap-2">
          <Button
            variant="outline"
            disabled={pendingCount === 0 && newDates.length === 0}
            onClick={() => {
              setEdits({});
              setNewDates([]);
            }}
          >
            Discard
          </Button>
          <Button disabled={pendingCount === 0 || save.isPending} onClick={() => save.mutate()}>
            {save.isPending ? <Loader2 className="mr-2 h-4 w-4 animate-spin" aria-hidden /> : null}
            Save changes{pendingCount ? ` (${pendingCount})` : ''}
          </Button>
        </div>
      </div>

      {grid.isError ? (
        <QueryError error={grid.error} onRetry={() => void grid.refetch()} />
      ) : grid.isLoading ? (
        <Skeleton className="h-64 w-full" />
      ) : rows.length === 0 ? (
        <EmptyState>No attendance recorded yet. Add a date to start.</EmptyState>
      ) : (
        <div className="overflow-x-auto rounded-md border bg-card">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="min-w-36">Date</TableHead>
                {Array.from({ length: slotCount }, (_, i) => (
                  <TableHead key={i} className="text-center">
                    Slot {i + 1}
                  </TableHead>
                ))}
              </TableRow>
            </TableHeader>
            <TableBody>
              {rows.map((row) => (
                <TableRow key={row.date}>
                  <TableCell className="whitespace-nowrap font-medium">
                    {formatDate(row.date)} <span className="text-muted-foreground">{row.day}</span>
                  </TableCell>
                  {Array.from({ length: slotCount }, (_, i) => {
                    const slot = i + 1;
                    const key = editKey(row.date, slot);
                    const edited = key in edits;
                    const value = (edited ? edits[key] : row.slots[i]) ?? NONE;
                    return (
                      <TableCell key={slot} className="p-1.5 text-center">
                        <select
                          aria-label={`${row.date} slot ${slot}`}
                          value={value}
                          onChange={(e) => setCell(row, slot, e.target.value as AttendanceStatus | typeof NONE)}
                          className={cn(
                            'h-8 w-16 cursor-pointer rounded border text-center text-xs font-medium focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring',
                            STATUS_CLASS[value],
                            edited && 'ring-2 ring-blue-500 ring-offset-1',
                          )}
                        >
                          {STATUS_OPTIONS.map((o) => (
                            <option key={o.value} value={o.value}>
                              {o.label}
                            </option>
                          ))}
                        </select>
                      </TableCell>
                    );
                  })}
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
      )}

      {grid.data ? (
        <div className="flex flex-wrap items-center justify-between gap-2 text-sm text-muted-foreground">
          <span>
            P present · A absent · A (e) excused · NA not applicable · - no lecture. Edits are kept when you change
            page.
          </span>
          <div className="flex items-center gap-2">
            <Button variant="outline" size="sm" disabled={page <= 1} onClick={() => setPage(page - 1)}>
              <ChevronLeft className="h-4 w-4" aria-hidden />
              <span className="sr-only">Previous page</span>
            </Button>
            <span>
              {grid.data.meta.page} / {grid.data.meta.totalPages}
            </span>
            <Button
              variant="outline"
              size="sm"
              disabled={page >= grid.data.meta.totalPages}
              onClick={() => setPage(page + 1)}
            >
              <ChevronRight className="h-4 w-4" aria-hidden />
              <span className="sr-only">Next page</span>
            </Button>
          </div>
        </div>
      ) : null}
    </div>
  );
}

// ------------------------------------------------------------ Past semesters

const pastSchema = z.object({
  semNo: z.number({ invalid_type_error: 'Enter a semester' }).int().min(1).max(12),
  yearLabel: z.string().trim().min(1, 'Year label is required'),
  percent: z.number({ invalid_type_error: 'Enter a percentage' }).min(0).max(100),
});
type PastValues = z.infer<typeof pastSchema>;

function PastSemesterDialog({
  studentId,
  semester,
  onClose,
}: {
  studentId: string;
  semester: PastSemester | null;
  onClose: () => void;
}) {
  const form = useForm<PastValues>({
    resolver: zodResolver(pastSchema),
    defaultValues: semester
      ? { semNo: semester.semNo, yearLabel: semester.yearLabel, percent: semester.percent }
      : { semNo: 1, yearLabel: '', percent: 0 },
  });
  const { errors } = form.formState;
  const invalidate = [['attendance', studentId, 'past']];
  const save = useApiMutation(
    (values: PastValues) => put<PastSemester>('/api/admin/attendance/past-sems', { ...values, studentId }),
    { success: 'Past semester saved', invalidate, onSuccess: onClose },
  );
  const remove = useApiMutation(
    () => del(`/api/admin/attendance/past-sems/${semester?.id ?? ''}`),
    { success: 'Past semester removed', invalidate, onSuccess: onClose },
  );

  return (
    <Dialog open onOpenChange={(open) => !open && onClose()}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{semester ? `Edit semester ${semester.semNo}` : 'Add past semester'}</DialogTitle>
        </DialogHeader>
        <form className="grid gap-4 sm:grid-cols-2" onSubmit={form.handleSubmit((v) => save.mutate(v))} noValidate>
          <Field label="Semester" htmlFor="semNo" error={errors.semNo?.message}>
            <Input id="semNo" type="number" disabled={Boolean(semester)} {...form.register('semNo', { valueAsNumber: true })} />
          </Field>
          <Field label="Attendance %" htmlFor="percent" error={errors.percent?.message}>
            <Input id="percent" type="number" step="0.01" {...form.register('percent', { valueAsNumber: true })} />
          </Field>
          <Field label="Year" htmlFor="yearLabel" error={errors.yearLabel?.message} className="sm:col-span-2">
            <Input id="yearLabel" placeholder="2025-26 - Even" {...form.register('yearLabel')} />
          </Field>
          <DialogFooter className="gap-2 sm:col-span-2">
            {semester ? (
              <Button
                type="button"
                variant="outline"
                className="mr-auto text-destructive"
                disabled={remove.isPending}
                onClick={() => remove.mutate()}
              >
                <Trash2 className="mr-2 h-4 w-4" aria-hidden />
                Remove
              </Button>
            ) : null}
            <SubmitButton loading={save.isPending}>Save</SubmitButton>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}

function PastSemesters({ studentId }: { studentId: string }) {
  const [dialog, setDialog] = useState<{ semester: PastSemester | null } | null>(null);
  const query = useQuery({
    queryKey: ['attendance', studentId, 'past'],
    queryFn: () => getAll<PastSemester>('/api/admin/attendance/past-sems', { studentId }),
  });

  return (
    <section aria-labelledby="past-heading" className="space-y-3">
      <div className="flex items-center justify-between">
        <h2 id="past-heading" className="text-base font-semibold">
          Past semesters
        </h2>
        <Button variant="outline" size="sm" onClick={() => setDialog({ semester: null })}>
          <Plus className="mr-1 h-4 w-4" aria-hidden />
          Add
        </Button>
      </div>
      {query.isError ? (
        <QueryError error={query.error} onRetry={() => void query.refetch()} />
      ) : query.isLoading ? (
        <Skeleton className="h-24 w-full" />
      ) : query.data?.length ? (
        <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
          {query.data.map((s) => (
            <Card key={s.id}>
              <CardContent className="flex items-start justify-between p-4">
                <div>
                  <div className="text-sm text-muted-foreground">
                    Sem {s.semNo} · {s.yearLabel}
                  </div>
                  <div className="mt-1 text-2xl font-semibold tabular-nums">{s.percent.toFixed(2)}%</div>
                </div>
                <Button
                  variant="ghost"
                  size="icon"
                  aria-label={`Edit semester ${s.semNo}`}
                  onClick={() => setDialog({ semester: s })}
                >
                  <Pencil className="h-4 w-4" aria-hidden />
                </Button>
              </CardContent>
            </Card>
          ))}
        </div>
      ) : (
        <EmptyState>No past semesters recorded.</EmptyState>
      )}
      {dialog ? (
        <PastSemesterDialog studentId={studentId} semester={dialog.semester} onClose={() => setDialog(null)} />
      ) : null}
    </section>
  );
}

// ------------------------------------------------------------ Current semester totals

const countField = z.number({ invalid_type_error: 'Enter a number' }).int().min(0);
const summarySchema = z.object({
  yearLabel: z.string().trim().min(1, 'Year is required'),
  percent: z.number({ invalid_type_error: 'Enter a number' }).min(0).max(100),
  present: countField,
  absent: countField,
  pending: countField,
  noAttendance: countField,
  total: countField,
});
type SummaryValues = z.infer<typeof summarySchema>;

const SUMMARY_COUNTS = [
  ['present', 'Present'],
  ['absent', 'Absent'],
  ['pending', 'Pending'],
  ['noAttendance', 'No attendance'],
  ['total', 'Total'],
] as const;

function CurrentSummary({ studentId }: { studentId: string }) {
  const query = useQuery({
    queryKey: ['attendance', studentId, 'summary'],
    queryFn: () => getOne<AttendanceSummary | null>('/api/admin/attendance/summary', { studentId }),
  });
  if (query.isError) return <QueryError error={query.error} onRetry={() => void query.refetch()} />;
  if (query.isLoading) return <Skeleton className="h-40 w-full" />;
  // Keyed so the form picks up the saved values once they arrive.
  return <SummaryForm key={query.dataUpdatedAt} studentId={studentId} summary={query.data ?? null} />;
}

function SummaryForm({ studentId, summary }: { studentId: string; summary: AttendanceSummary | null }) {
  const form = useForm<SummaryValues>({
    resolver: zodResolver(summarySchema),
    defaultValues: {
      yearLabel: summary?.yearLabel ?? '',
      percent: summary?.percent ?? 0,
      present: summary?.present ?? 0,
      absent: summary?.absent ?? 0,
      pending: summary?.pending ?? 0,
      noAttendance: summary?.noAttendance ?? 0,
      total: summary?.total ?? 0,
    },
  });
  const { errors } = form.formState;
  const save = useApiMutation(
    (values: SummaryValues) => put<AttendanceSummary>('/api/admin/attendance/summary', { ...values, studentId }),
    { success: 'Attendance totals saved', invalidate: [['attendance', studentId, 'summary']] },
  );

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">Current semester totals</CardTitle>
      </CardHeader>
      <CardContent>
        <form className="grid gap-4 sm:grid-cols-4" onSubmit={form.handleSubmit((v) => save.mutate(v))} noValidate>
          <Field label="Year" htmlFor="summaryYear" error={errors.yearLabel?.message} className="sm:col-span-2">
            <Input id="summaryYear" placeholder="2026-27 - Odd" {...form.register('yearLabel')} />
          </Field>
          <Field label="Attendance %" htmlFor="summaryPercent" error={errors.percent?.message}>
            <Input id="summaryPercent" type="number" step="0.01" {...form.register('percent', { valueAsNumber: true })} />
          </Field>
          {SUMMARY_COUNTS.map(([name, label]) => (
            <Field key={name} label={label} htmlFor={`summary-${name}`} error={errors[name]?.message}>
              <Input id={`summary-${name}`} type="number" {...form.register(name, { valueAsNumber: true })} />
            </Field>
          ))}
          <div className="flex items-end justify-end">
            <SubmitButton loading={save.isPending}>Save totals</SubmitButton>
          </div>
        </form>
      </CardContent>
    </Card>
  );
}

// ------------------------------------------------------------ Course-wise

const courseSchema = z
  .object({
    course: z.string().trim().min(1, 'Course is required'),
    total: z.number({ invalid_type_error: 'Enter a number' }).int().min(0),
    present: z.number({ invalid_type_error: 'Enter a number' }).int().min(0),
  })
  .refine((c) => c.present <= c.total, { path: ['present'], message: 'Cannot exceed total' });
type CourseValues = z.infer<typeof courseSchema>;

function CourseDialog({
  studentId,
  course,
  onClose,
}: {
  studentId: string;
  course: CourseAttendance | null;
  onClose: () => void;
}) {
  const form = useForm<CourseValues>({
    resolver: zodResolver(courseSchema),
    defaultValues: course
      ? { course: course.course, total: course.total, present: course.present }
      : { course: '', total: 0, present: 0 },
  });
  const { errors } = form.formState;
  const save = useApiMutation(
    (values: CourseValues) => put<CourseAttendance>('/api/admin/attendance/courses', { ...values, studentId }),
    { success: 'Course attendance saved', invalidate: [['attendance', studentId, 'courses']], onSuccess: onClose },
  );
  return (
    <Dialog open onOpenChange={(open) => !open && onClose()}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{course ? 'Edit course attendance' : 'Add course attendance'}</DialogTitle>
        </DialogHeader>
        <form className="grid gap-4 sm:grid-cols-2" onSubmit={form.handleSubmit((v) => save.mutate(v))} noValidate>
          <Field label="Course" htmlFor="course" error={errors.course?.message} className="sm:col-span-2">
            <Input
              id="course"
              disabled={Boolean(course)}
              placeholder="2301CS401 - Database Management System - II - Theory"
              {...form.register('course')}
            />
          </Field>
          <Field label="Total classes" htmlFor="total" error={errors.total?.message}>
            <Input id="total" type="number" min={0} {...form.register('total', { valueAsNumber: true })} />
          </Field>
          <Field label="Present" htmlFor="present" error={errors.present?.message}>
            <Input id="present" type="number" min={0} {...form.register('present', { valueAsNumber: true })} />
          </Field>
          <DialogFooter className="sm:col-span-2">
            <SubmitButton loading={save.isPending}>Save</SubmitButton>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}

function CourseWise({ studentId }: { studentId: string }) {
  const [dialog, setDialog] = useState<{ course: CourseAttendance | null } | null>(null);
  const query = useQuery({
    queryKey: ['attendance', studentId, 'courses'],
    queryFn: () => getAll<CourseAttendance>('/api/admin/attendance/courses', { studentId }),
  });
  const remove = useApiMutation((id: string) => del(`/api/admin/attendance/courses/${id}`), {
    success: 'Course attendance removed',
    invalidate: [['attendance', studentId, 'courses']],
  });

  if (query.isError) return <QueryError error={query.error} onRetry={() => void query.refetch()} />;
  if (query.isLoading) return <Skeleton className="h-64 w-full" />;
  const courses = query.data ?? [];

  return (
    <div className="space-y-4">
      {courses.length ? (
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Attendance % by course</CardTitle>
          </CardHeader>
          <CardContent>
            <AttendanceBar courses={courses} />
          </CardContent>
        </Card>
      ) : null}
      <div className="flex justify-end">
        <Button variant="outline" size="sm" onClick={() => setDialog({ course: null })}>
          <Plus className="mr-1 h-4 w-4" aria-hidden />
          Add course
        </Button>
      </div>
      {courses.length ? (
        <div className="overflow-x-auto rounded-md border bg-card">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Course</TableHead>
                <TableHead className="text-right">Total</TableHead>
                <TableHead className="text-right">Present</TableHead>
                <TableHead className="text-right">%</TableHead>
                <TableHead className="w-24" />
              </TableRow>
            </TableHeader>
            <TableBody>
              {courses.map((c) => (
                <TableRow key={c.id}>
                  <TableCell>{c.course}</TableCell>
                  <TableCell className="text-right tabular-nums">{c.total}</TableCell>
                  <TableCell className="text-right tabular-nums">{c.present}</TableCell>
                  <TableCell className="text-right tabular-nums">{c.percent.toFixed(2)}</TableCell>
                  <TableCell className="whitespace-nowrap text-right">
                    <Button variant="ghost" size="icon" aria-label={`Edit ${c.course}`} onClick={() => setDialog({ course: c })}>
                      <Pencil className="h-4 w-4" aria-hidden />
                    </Button>
                    <Button
                      variant="ghost"
                      size="icon"
                      aria-label={`Delete ${c.course}`}
                      disabled={remove.isPending}
                      onClick={() => remove.mutate(c.id)}
                    >
                      <Trash2 className="h-4 w-4" aria-hidden />
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
      ) : (
        <EmptyState>No course attendance recorded.</EmptyState>
      )}
      {dialog ? <CourseDialog studentId={studentId} course={dialog.course} onClose={() => setDialog(null)} /> : null}
    </div>
  );
}

// ------------------------------------------------------------ Page

export default function AttendancePage() {
  const [student, setStudent] = useState<StudentSummary | null>(null);
  return (
    <>
      <PageHeader title="Attendance" description="Edit a student's daily grid, course-wise totals and past semesters." />
      <StudentPicker value={student} onChange={setStudent} />
      {student ? (
        // Keyed so unsaved edits never carry over to a different student.
        <div key={student.id} className="mt-6 space-y-6">
          <CurrentSummary studentId={student.id} />
          <PastSemesters studentId={student.id} />
          <Tabs defaultValue="grid">
            <TabsList>
              <TabsTrigger value="grid">Daily grid</TabsTrigger>
              <TabsTrigger value="courses">Course-wise</TabsTrigger>
            </TabsList>
            {/* forceMount keeps unsaved grid edits when switching tabs */}
            <TabsContent value="grid" forceMount className="data-[state=inactive]:hidden">
              <DailyGrid studentId={student.id} />
            </TabsContent>
            <TabsContent value="courses">
              <CourseWise studentId={student.id} />
            </TabsContent>
          </Tabs>
        </div>
      ) : (
        <div className="mt-6">
          <EmptyState>Pick a student to view and edit their attendance.</EmptyState>
        </div>
      )}
    </>
  );
}
