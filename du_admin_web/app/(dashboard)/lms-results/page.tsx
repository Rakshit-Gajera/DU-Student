'use client';

import { zodResolver } from '@hookform/resolvers/zod';
import { keepPreviousData, useQuery } from '@tanstack/react-query';
import type { ColumnDef } from '@tanstack/react-table';
import { Pencil, Plus, Trash2 } from 'lucide-react';
import { useMemo, useState } from 'react';
import { useForm } from 'react-hook-form';
import { z } from 'zod';
import { DataTable } from '@/components/data-table/DataTable';
import { ConfirmDialog, EmptyState, Field, PageHeader, QueryError, SubmitButton } from '@/components/shared/common';
import { StudentPicker } from '@/components/shared/StudentPicker';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { useApiMutation } from '@/hooks/useApiMutation';
import { del, getPage, post, put } from '@/lib/api';
import type { LmsTestResult, StudentSummary } from '@/lib/types';
import { formatDate, toDateInput } from '@/lib/utils';

const number = (message: string) => z.number({ invalid_type_error: message }).int();

const schema = z
  .object({
    semNo: number('Enter a semester').min(1).max(12),
    course: z.string().trim().min(1, 'Course is required').max(300),
    unit: number('Enter a unit').min(1).max(50),
    testDate: z.string().min(1, 'Required'),
    attemptNo: number('Enter an attempt').min(1).max(20),
    marks: number('Enter the marks').min(0),
    maxMarks: number('Enter the maximum').min(1),
    passed: z.boolean(),
  })
  .refine((v) => v.marks <= v.maxMarks, { path: ['marks'], message: 'Cannot exceed the maximum' });
type Values = z.infer<typeof schema>;

function ResultDialog({ studentId, result, onClose }: { studentId: string; result: LmsTestResult | null; onClose: () => void }) {
  const form = useForm<Values>({
    resolver: zodResolver(schema),
    defaultValues: {
      semNo: result?.semNo ?? 1,
      course: result?.course ?? '',
      unit: result?.unit ?? 1,
      testDate: toDateInput(result?.testDate),
      attemptNo: result?.attemptNo ?? 1,
      marks: result?.marks ?? 0,
      maxMarks: result?.maxMarks ?? 30,
      passed: result?.passed ?? true,
    },
  });
  const { errors } = form.formState;
  const save = useApiMutation(
    (values: Values) => {
      const body = { ...values, studentId };
      return result ? put<LmsTestResult>(`/api/admin/lms-results/${result.id}`, body) : post<LmsTestResult>('/api/admin/lms-results', body);
    },
    { success: result ? 'Result updated' : 'Result added', invalidate: [['lms-results', studentId]], onSuccess: onClose },
  );

  return (
    <Dialog open onOpenChange={(open) => !open && onClose()}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{result ? 'Edit LMS test result' : 'Add LMS test result'}</DialogTitle>
        </DialogHeader>
        <form className="grid gap-4 sm:grid-cols-3" onSubmit={form.handleSubmit((v) => save.mutate(v))} noValidate>
          <Field label="Course" htmlFor="lrCourse" error={errors.course?.message} className="sm:col-span-3">
            <Input id="lrCourse" placeholder="DAA (2301CS402)" {...form.register('course')} />
          </Field>
          <Field label="Semester" htmlFor="lrSem" error={errors.semNo?.message}>
            <Input id="lrSem" type="number" {...form.register('semNo', { valueAsNumber: true })} />
          </Field>
          <Field label="Unit" htmlFor="lrUnit" error={errors.unit?.message}>
            <Input id="lrUnit" type="number" {...form.register('unit', { valueAsNumber: true })} />
          </Field>
          <Field label="Attempt" htmlFor="lrAttempt" error={errors.attemptNo?.message}>
            <Input id="lrAttempt" type="number" {...form.register('attemptNo', { valueAsNumber: true })} />
          </Field>
          <Field label="Date" htmlFor="lrDate" error={errors.testDate?.message}>
            <Input id="lrDate" type="date" {...form.register('testDate')} />
          </Field>
          <Field label="Marks" htmlFor="lrMarks" error={errors.marks?.message}>
            <Input id="lrMarks" type="number" {...form.register('marks', { valueAsNumber: true })} />
          </Field>
          <Field label="Out of" htmlFor="lrMax" error={errors.maxMarks?.message}>
            <Input id="lrMax" type="number" {...form.register('maxMarks', { valueAsNumber: true })} />
          </Field>
          <label className="flex items-center gap-2 text-sm sm:col-span-3">
            <input type="checkbox" className="h-4 w-4" {...form.register('passed')} />
            Passed
          </label>
          <DialogFooter className="sm:col-span-3">
            <SubmitButton loading={save.isPending}>{result ? 'Save changes' : 'Add result'}</SubmitButton>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}

function ResultList({ studentId }: { studentId: string }) {
  const [page, setPage] = useState(1);
  const [dialog, setDialog] = useState<{ result: LmsTestResult | null } | null>(null);
  const [deleting, setDeleting] = useState<LmsTestResult | null>(null);

  const results = useQuery({
    queryKey: ['lms-results', studentId, page],
    queryFn: () => getPage<LmsTestResult>('/api/admin/lms-results', { studentId, page, limit: 20 }),
    placeholderData: keepPreviousData,
  });
  const remove = useApiMutation((id: string) => del(`/api/admin/lms-results/${id}`), {
    success: 'Result deleted',
    invalidate: [['lms-results', studentId]],
    onSuccess: () => setDeleting(null),
  });

  const columns = useMemo<ColumnDef<LmsTestResult>[]>(
    () => [
      { accessorKey: 'semNo', header: 'Sem' },
      { accessorKey: 'course', header: 'Course', cell: ({ row }) => <span className="font-medium">{row.original.course}</span> },
      { accessorKey: 'unit', header: 'Unit' },
      { accessorKey: 'attemptNo', header: 'Attempt' },
      {
        accessorKey: 'testDate',
        header: 'Date',
        cell: ({ row }) => <span className="whitespace-nowrap">{formatDate(row.original.testDate)}</span>,
      },
      {
        id: 'marks',
        header: 'Marks',
        cell: ({ row }) => (
          <span className="whitespace-nowrap tabular-nums">
            {row.original.marks} / {row.original.maxMarks}
          </span>
        ),
      },
      {
        accessorKey: 'passed',
        header: 'Status',
        cell: ({ row }) => <Badge variant={row.original.passed ? 'secondary' : 'outline'}>{row.original.passed ? 'Pass' : 'Fail'}</Badge>,
      },
      {
        id: 'actions',
        header: '',
        cell: ({ row }) => (
          <div className="flex justify-end whitespace-nowrap">
            <Button variant="ghost" size="icon" aria-label={`Edit unit ${row.original.unit} of ${row.original.course}`} onClick={() => setDialog({ result: row.original })}>
              <Pencil className="h-4 w-4" aria-hidden />
            </Button>
            <Button variant="ghost" size="icon" aria-label={`Delete unit ${row.original.unit} of ${row.original.course}`} onClick={() => setDeleting(row.original)}>
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
        <Button onClick={() => setDialog({ result: null })}>
          <Plus className="mr-2 h-4 w-4" aria-hidden />
          Add result
        </Button>
      </div>
      {results.isError ? (
        <QueryError error={results.error} onRetry={() => void results.refetch()} />
      ) : (
        <DataTable
          columns={columns}
          data={results.data?.items}
          meta={results.data?.meta}
          isLoading={results.isLoading}
          onPageChange={setPage}
          emptyText="This student has no LMS test results."
        />
      )}
      {dialog ? <ResultDialog studentId={studentId} result={dialog.result} onClose={() => setDialog(null)} /> : null}
      <ConfirmDialog
        open={Boolean(deleting)}
        onOpenChange={(open) => !open && setDeleting(null)}
        title="Delete this result?"
        description="The student will no longer see this attempt. This cannot be undone."
        loading={remove.isPending}
        onConfirm={() => deleting && remove.mutate(deleting.id)}
      />
    </div>
  );
}

export default function LmsResultsPage() {
  const [student, setStudent] = useState<StudentSummary | null>(null);
  return (
    <>
      <PageHeader title="LMS test results" description="Marks for each student's unit tests and attempts." />
      <StudentPicker value={student} onChange={setStudent} />
      <div className="mt-6">
        {student ? <ResultList key={student.id} studentId={student.id} /> : <EmptyState>Pick a student to manage their results.</EmptyState>}
      </div>
    </>
  );
}
