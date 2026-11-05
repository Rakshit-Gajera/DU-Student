'use client';

import { zodResolver } from '@hookform/resolvers/zod';
import { keepPreviousData, useQuery } from '@tanstack/react-query';
import type { ColumnDef } from '@tanstack/react-table';
import { Pencil, Plus, Trash2 } from 'lucide-react';
import { useMemo, useState } from 'react';
import { Controller, useForm } from 'react-hook-form';
import { z } from 'zod';
import { DataTable } from '@/components/data-table/DataTable';
import { ConfirmDialog, EmptyState, Field, PageHeader, QueryError, SimpleSelect, SubmitButton } from '@/components/shared/common';
import { StudentPicker } from '@/components/shared/StudentPicker';
import { Button } from '@/components/ui/button';
import { Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { useApiMutation } from '@/hooks/useApiMutation';
import { del, getPage, post, put } from '@/lib/api';
import type { ExamSchedule, ExamType, StudentSummary } from '@/lib/types';
import { formatDate, toDateInput } from '@/lib/utils';

const TYPE_OPTIONS: readonly { value: ExamType; label: string }[] = [
  { value: 'EXAM', label: 'Exam' },
  { value: 'IA', label: 'IA' },
  { value: 'LMS_TEST', label: 'LMS test' },
];
const typeLabel = (type: ExamType): string => TYPE_OPTIONS.find((o) => o.value === type)?.label ?? type;

const schema = z
  .object({
    type: z.enum(['EXAM', 'IA', 'LMS_TEST']),
    title: z.string().trim().min(1, 'Title is required').max(300),
    startDate: z.string().min(1, 'Required'),
    endDate: z.string(),
    venue: z.string().trim().max(200),
  })
  .refine((v) => !v.endDate || v.startDate <= v.endDate, {
    path: ['endDate'],
    message: 'Cannot be before the start date',
  });
type Values = z.infer<typeof schema>;

function ExamDialog({ studentId, exam, onClose }: { studentId: string; exam: ExamSchedule | null; onClose: () => void }) {
  const form = useForm<Values>({
    resolver: zodResolver(schema),
    defaultValues: {
      type: exam?.type ?? 'EXAM',
      title: exam?.title ?? '',
      startDate: toDateInput(exam?.startDate),
      endDate: toDateInput(exam?.endDate),
      venue: exam?.venue ?? '',
    },
  });
  const { errors } = form.formState;
  const save = useApiMutation(
    (values: Values) => {
      const body = { ...values, studentId, endDate: values.endDate || null };
      return exam ? put<ExamSchedule>(`/api/admin/exam-schedule/${exam.id}`, body) : post<ExamSchedule>('/api/admin/exam-schedule', body);
    },
    { success: exam ? 'Exam updated' : 'Exam added', invalidate: [['exam-schedule', studentId]], onSuccess: onClose },
  );

  return (
    <Dialog open onOpenChange={(open) => !open && onClose()}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{exam ? 'Edit exam' : 'Add exam'}</DialogTitle>
        </DialogHeader>
        <form className="grid gap-4 sm:grid-cols-2" onSubmit={form.handleSubmit((v) => save.mutate(v))} noValidate>
          <Field label="Title" htmlFor="examTitle" error={errors.title?.message} className="sm:col-span-2">
            <Input id="examTitle" {...form.register('title')} />
          </Field>
          <Field label="Type" htmlFor="examType">
            <Controller
              control={form.control}
              name="type"
              render={({ field }) => <SimpleSelect id="examType" value={field.value} onChange={field.onChange} options={TYPE_OPTIONS} />}
            />
          </Field>
          <Field label="Venue" htmlFor="examVenue" error={errors.venue?.message}>
            <Input id="examVenue" {...form.register('venue')} />
          </Field>
          <Field label="Start date" htmlFor="examStart" error={errors.startDate?.message}>
            <Input id="examStart" type="date" {...form.register('startDate')} />
          </Field>
          <Field label="End date (optional)" htmlFor="examEnd" error={errors.endDate?.message}>
            <Input id="examEnd" type="date" {...form.register('endDate')} />
          </Field>
          <DialogFooter className="sm:col-span-2">
            <SubmitButton loading={save.isPending}>{exam ? 'Save changes' : 'Add exam'}</SubmitButton>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}

function ExamList({ studentId }: { studentId: string }) {
  const [page, setPage] = useState(1);
  const [dialog, setDialog] = useState<{ exam: ExamSchedule | null } | null>(null);
  const [deleting, setDeleting] = useState<ExamSchedule | null>(null);

  const exams = useQuery({
    queryKey: ['exam-schedule', studentId, page],
    queryFn: () => getPage<ExamSchedule>('/api/admin/exam-schedule', { studentId, page, limit: 20 }),
    placeholderData: keepPreviousData,
  });
  const remove = useApiMutation((id: string) => del(`/api/admin/exam-schedule/${id}`), {
    success: 'Exam deleted',
    invalidate: [['exam-schedule', studentId]],
    onSuccess: () => setDeleting(null),
  });

  const columns = useMemo<ColumnDef<ExamSchedule>[]>(
    () => [
      { accessorKey: 'title', header: 'Title', cell: ({ row }) => <span className="font-medium">{row.original.title}</span> },
      { accessorKey: 'type', header: 'Type', cell: ({ row }) => typeLabel(row.original.type) },
      {
        id: 'dates',
        header: 'Dates',
        cell: ({ row }) => (
          <span className="whitespace-nowrap">
            {formatDate(row.original.startDate)}
            {row.original.endDate ? ` to ${formatDate(row.original.endDate)}` : ''}
          </span>
        ),
      },
      { accessorKey: 'venue', header: 'Venue', cell: ({ row }) => row.original.venue ?? '-' },
      {
        id: 'actions',
        header: '',
        cell: ({ row }) => (
          <div className="flex justify-end whitespace-nowrap">
            <Button variant="ghost" size="icon" aria-label={`Edit ${row.original.title}`} onClick={() => setDialog({ exam: row.original })}>
              <Pencil className="h-4 w-4" aria-hidden />
            </Button>
            <Button variant="ghost" size="icon" aria-label={`Delete ${row.original.title}`} onClick={() => setDeleting(row.original)}>
              <Trash2 className="h-4 w-4" aria-hidden />
            </Button>
          </div>
        ),
      },
    ],
    [],
  );

  return (
    <div className="space-y-4">
      <div className="flex justify-end">
        <Button onClick={() => setDialog({ exam: null })}>
          <Plus className="mr-2 h-4 w-4" aria-hidden />
          Add exam
        </Button>
      </div>
      {exams.isError ? (
        <QueryError error={exams.error} onRetry={() => void exams.refetch()} />
      ) : (
        <DataTable
          columns={columns}
          data={exams.data?.items}
          meta={exams.data?.meta}
          isLoading={exams.isLoading}
          onPageChange={setPage}
          emptyText="This student has no exams scheduled."
        />
      )}
      {dialog ? <ExamDialog studentId={studentId} exam={dialog.exam} onClose={() => setDialog(null)} /> : null}
      <ConfirmDialog
        open={Boolean(deleting)}
        onOpenChange={(open) => !open && setDeleting(null)}
        title={`Delete "${deleting?.title ?? ''}"?`}
        description="The student will no longer see this exam. This cannot be undone."
        loading={remove.isPending}
        onConfirm={() => deleting && remove.mutate(deleting.id)}
      />
    </div>
  );
}

export default function ExamSchedulePage() {
  const [student, setStudent] = useState<StudentSummary | null>(null);
  return (
    <>
      <PageHeader title="Exam schedule" description="Each student has their own exams, IA and LMS test schedule." />
      <StudentPicker value={student} onChange={setStudent} />
      <div className="mt-6">
        {student ? <ExamList key={student.id} studentId={student.id} /> : <EmptyState>Pick a student to manage their schedule.</EmptyState>}
      </div>
    </>
  );
}
