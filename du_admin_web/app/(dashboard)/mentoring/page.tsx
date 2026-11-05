'use client';

import { zodResolver } from '@hookform/resolvers/zod';
import { keepPreviousData, useQuery } from '@tanstack/react-query';
import type { ColumnDef } from '@tanstack/react-table';
import { Pencil, Plus, Trash2, UserPlus } from 'lucide-react';
import { useMemo, useState } from 'react';
import { useForm } from 'react-hook-form';
import { z } from 'zod';
import { DataTable } from '@/components/data-table/DataTable';
import { ConfirmDialog, EmptyState, Field, PageHeader, QueryError, SimpleSelect, SubmitButton } from '@/components/shared/common';
import { StudentPicker } from '@/components/shared/StudentPicker';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { useApiMutation } from '@/hooks/useApiMutation';
import { del, getAll, getOne, getPage, post, put } from '@/lib/api';
import type { Mentor, MentorHistoryRow, MentoringSession, Student, StudentSummary } from '@/lib/types';
import { formatDateTime, fromDateTimeInput, toDateTimeInput } from '@/lib/utils';

const NO_MENTOR = 'NONE';

const mentorSchema = z.object({
  name: z.string().trim().min(1, 'Name is required'),
  designation: z.string().trim(),
  mobile: z.string().trim(),
  officeNo: z.string().trim(),
  email: z.union([z.literal(''), z.string().trim().email('Invalid email')]),
  department: z.string().trim(),
});
type MentorValues = z.infer<typeof mentorSchema>;

function NewMentorDialog({ onClose, onCreated }: { onClose: () => void; onCreated: (mentor: Mentor) => void }) {
  const form = useForm<MentorValues>({
    resolver: zodResolver(mentorSchema),
    defaultValues: { name: '', designation: '', mobile: '', officeNo: '', email: '', department: '' },
  });
  const { errors } = form.formState;
  const create = useApiMutation((values: MentorValues) => post<Mentor>('/api/admin/mentoring/mentors', values), {
    success: 'Mentor created',
    invalidate: [['mentors']],
    onSuccess: (mentor) => {
      onCreated(mentor);
      onClose();
    },
  });
  return (
    <Dialog open onOpenChange={(open) => !open && onClose()}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>New mentor</DialogTitle>
        </DialogHeader>
        <form className="grid gap-4 sm:grid-cols-2" onSubmit={form.handleSubmit((v) => create.mutate(v))} noValidate>
          <Field label="Name" htmlFor="mentor-name" error={errors.name?.message} className="sm:col-span-2">
            <Input id="mentor-name" {...form.register('name')} />
          </Field>
          <Field label="Designation" htmlFor="mentor-designation">
            <Input id="mentor-designation" {...form.register('designation')} />
          </Field>
          <Field label="Department" htmlFor="mentor-department">
            <Input id="mentor-department" {...form.register('department')} />
          </Field>
          <Field label="Mobile" htmlFor="mentor-mobile">
            <Input id="mentor-mobile" {...form.register('mobile')} />
          </Field>
          <Field label="Office no." htmlFor="mentor-office">
            <Input id="mentor-office" {...form.register('officeNo')} />
          </Field>
          <Field label="Email" htmlFor="mentor-email" error={errors.email?.message} className="sm:col-span-2">
            <Input id="mentor-email" type="email" {...form.register('email')} />
          </Field>
          <DialogFooter className="sm:col-span-2">
            <SubmitButton loading={create.isPending}>Create mentor</SubmitButton>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}

function MentorCard({ studentId }: { studentId: string }) {
  const [creating, setCreating] = useState(false);
  const student = useQuery({
    queryKey: ['students', 'detail', studentId],
    queryFn: () => getOne<Student>(`/api/admin/students/${studentId}`),
  });
  const mentors = useQuery({
    queryKey: ['mentors'],
    queryFn: () => getAll<Mentor>('/api/admin/mentoring/mentors'),
  });
  const assign = useApiMutation(
    (mentorId: string | null) => put<Student>(`/api/admin/students/${studentId}`, { mentorId }),
    { success: 'Mentor updated', invalidate: [['students']] },
  );
  const mentor = student.data?.mentor;

  return (
    <Card>
      <CardHeader className="flex flex-row flex-wrap items-center justify-between gap-2 space-y-0">
        <CardTitle className="text-base">Current mentor</CardTitle>
        <Button variant="outline" size="sm" onClick={() => setCreating(true)}>
          <UserPlus className="mr-1 h-4 w-4" aria-hidden />
          New mentor
        </Button>
      </CardHeader>
      <CardContent className="space-y-3">
        {student.isError ? <QueryError error={student.error} onRetry={() => void student.refetch()} /> : null}
        <SimpleSelect
          aria-label="Assign a mentor"
          className="max-w-md"
          disabled={student.isLoading || assign.isPending}
          value={student.data ? student.data.mentorId ?? NO_MENTOR : ''}
          onChange={(v) => assign.mutate(v === NO_MENTOR ? null : v)}
          options={[
            { value: NO_MENTOR, label: 'No mentor' },
            ...(mentors.data ?? []).map((m) => ({ value: m.id, label: m.name })),
          ]}
        />
        {mentor ? (
          <p className="text-sm text-muted-foreground">
            {[mentor.designation, mentor.department, mentor.email, mentor.mobile].filter(Boolean).join(' · ')}
          </p>
        ) : null}
      </CardContent>
      {creating ? <NewMentorDialog onClose={() => setCreating(false)} onCreated={(m) => assign.mutate(m.id)} /> : null}
    </Card>
  );
}

const sessionSchema = z.object({
  mentorName: z.string().trim().min(1, 'Mentor name is required'),
  when: z.string().min(1, 'Date and time are required'),
  issue: z.string().trim().min(1, 'Describe what was discussed'),
  parentsDescription: z.string().trim(),
  nextMeeting: z.string(),
});
type SessionValues = z.infer<typeof sessionSchema>;

function SessionDialog({
  studentId,
  session,
  defaultMentor,
  onClose,
}: {
  studentId: string;
  session: MentoringSession | null;
  defaultMentor: string;
  onClose: () => void;
}) {
  const form = useForm<SessionValues>({
    resolver: zodResolver(sessionSchema),
    defaultValues: {
      mentorName: session?.mentorName ?? defaultMentor,
      when: toDateTimeInput(session?.when ?? new Date().toISOString()),
      issue: session?.issue ?? '',
      parentsDescription: session?.parentsDescription ?? '',
      nextMeeting: toDateTimeInput(session?.nextMeeting),
    },
  });
  const { errors } = form.formState;
  const save = useApiMutation(
    (values: SessionValues) => {
      const body = {
        ...values,
        studentId,
        when: fromDateTimeInput(values.when),
        nextMeeting: values.nextMeeting ? fromDateTimeInput(values.nextMeeting) : null,
      };
      return session
        ? put<MentoringSession>(`/api/admin/mentoring/${session.id}`, body)
        : post<MentoringSession>('/api/admin/mentoring', body);
    },
    {
      success: session ? 'Session updated' : 'Session added',
      invalidate: [['mentoring', studentId]],
      onSuccess: onClose,
    },
  );

  return (
    <Dialog open onOpenChange={(open) => !open && onClose()}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{session ? 'Edit session' : 'Add mentoring session'}</DialogTitle>
        </DialogHeader>
        <form className="grid gap-4 sm:grid-cols-2" onSubmit={form.handleSubmit((v) => save.mutate(v))} noValidate>
          <Field label="Mentor" htmlFor="mentorName" error={errors.mentorName?.message}>
            <Input id="mentorName" {...form.register('mentorName')} />
          </Field>
          <Field label="When" htmlFor="when" error={errors.when?.message}>
            <Input id="when" type="datetime-local" {...form.register('when')} />
          </Field>
          <Field label="Issue discussed" htmlFor="issue" error={errors.issue?.message} className="sm:col-span-2">
            <Textarea id="issue" rows={3} {...form.register('issue')} />
          </Field>
          <Field label="Parents description" htmlFor="parentsDescription" className="sm:col-span-2">
            <Textarea id="parentsDescription" rows={2} {...form.register('parentsDescription')} />
          </Field>
          <Field label="Next meeting" htmlFor="nextMeeting">
            <Input id="nextMeeting" type="datetime-local" {...form.register('nextMeeting')} />
          </Field>
          <DialogFooter className="sm:col-span-2">
            <SubmitButton loading={save.isPending}>Save session</SubmitButton>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}

function Sessions({ studentId }: { studentId: string }) {
  const [page, setPage] = useState(1);
  const [dialog, setDialog] = useState<{ session: MentoringSession | null } | null>(null);
  const [deleting, setDeleting] = useState<MentoringSession | null>(null);

  const sessions = useQuery({
    queryKey: ['mentoring', studentId, page],
    queryFn: () => getPage<MentoringSession>('/api/admin/mentoring', { studentId, page, limit: 10 }),
    placeholderData: keepPreviousData,
  });
  const student = useQuery({
    queryKey: ['students', 'detail', studentId],
    queryFn: () => getOne<Student>(`/api/admin/students/${studentId}`),
  });
  const remove = useApiMutation((id: string) => del(`/api/admin/mentoring/${id}`), {
    success: 'Session deleted',
    invalidate: [['mentoring', studentId]],
    onSuccess: () => setDeleting(null),
  });

  const columns = useMemo<ColumnDef<MentoringSession>[]>(
    () => [
      {
        accessorKey: 'when',
        header: 'When',
        cell: ({ row }) => <span className="whitespace-nowrap">{formatDateTime(row.original.when)}</span>,
      },
      { accessorKey: 'mentorName', header: 'Mentor' },
      {
        accessorKey: 'issue',
        header: 'Issue discussed',
        cell: ({ row }) => <span className="whitespace-pre-wrap">{row.original.issue}</span>,
      },
      {
        accessorKey: 'nextMeeting',
        header: 'Next meeting',
        cell: ({ row }) => <span className="whitespace-nowrap">{formatDateTime(row.original.nextMeeting)}</span>,
      },
      {
        id: 'actions',
        header: '',
        cell: ({ row }) => (
          <div className="flex justify-end whitespace-nowrap">
            <Button variant="ghost" size="icon" aria-label="Edit session" onClick={() => setDialog({ session: row.original })}>
              <Pencil className="h-4 w-4" aria-hidden />
            </Button>
            <Button variant="ghost" size="icon" aria-label="Delete session" onClick={() => setDeleting(row.original)}>
              <Trash2 className="h-4 w-4" aria-hidden />
            </Button>
          </div>
        ),
      },
    ],
    [],
  );

  return (
    <section aria-labelledby="sessions-heading" className="space-y-3">
      <div className="flex items-center justify-between">
        <h2 id="sessions-heading" className="text-base font-semibold">
          Sessions
        </h2>
        <Button onClick={() => setDialog({ session: null })}>
          <Plus className="mr-2 h-4 w-4" aria-hidden />
          Add session
        </Button>
      </div>
      {sessions.isError ? (
        <QueryError error={sessions.error} onRetry={() => void sessions.refetch()} />
      ) : (
        <DataTable
          columns={columns}
          data={sessions.data?.items}
          meta={sessions.data?.meta}
          isLoading={sessions.isLoading}
          onPageChange={setPage}
          emptyText="No mentoring sessions recorded."
        />
      )}
      {dialog ? (
        <SessionDialog
          studentId={studentId}
          session={dialog.session}
          defaultMentor={student.data?.mentor?.name ?? ''}
          onClose={() => setDialog(null)}
        />
      ) : null}
      <ConfirmDialog
        open={Boolean(deleting)}
        onOpenChange={(open) => !open && setDeleting(null)}
        title="Delete this session?"
        description="The mentoring record is removed for the student too. This cannot be undone."
        loading={remove.isPending}
        onConfirm={() => deleting && remove.mutate(deleting.id)}
      />
    </section>
  );
}

const historySchema = z.object({
  mentorName: z.string().trim().min(1, 'Mentor name is required'),
  fromDate: z.string().min(1, 'Required'),
  toDate: z.string(),
  meetings: z.number({ invalid_type_error: 'Enter a number' }).int().min(0),
});
type HistoryValues = z.infer<typeof historySchema>;

function HistoryDialog({
  studentId,
  row,
  onClose,
}: {
  studentId: string;
  row: MentorHistoryRow | null;
  onClose: () => void;
}) {
  const form = useForm<HistoryValues>({
    resolver: zodResolver(historySchema),
    defaultValues: {
      mentorName: row?.mentorName ?? '',
      fromDate: row?.fromDate.slice(0, 10) ?? '',
      toDate: row?.toDate?.slice(0, 10) ?? '',
      meetings: row?.meetings ?? 0,
    },
  });
  const { errors } = form.formState;
  const invalidate = [['mentoring', studentId, 'history']];
  const save = useApiMutation(
    (values: HistoryValues) => {
      const body = { ...values, studentId, toDate: values.toDate || null };
      return row
        ? put<MentorHistoryRow>(`/api/admin/mentoring/history/${row.id}`, body)
        : post<MentorHistoryRow>('/api/admin/mentoring/history', body);
    },
    { success: 'Mentor history saved', invalidate, onSuccess: onClose },
  );
  const remove = useApiMutation(() => del(`/api/admin/mentoring/history/${row?.id ?? ''}`), {
    success: 'Mentor history removed',
    invalidate,
    onSuccess: onClose,
  });

  return (
    <Dialog open onOpenChange={(open) => !open && onClose()}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{row ? 'Edit mentor history' : 'Add mentor history'}</DialogTitle>
        </DialogHeader>
        <form className="grid gap-4 sm:grid-cols-2" onSubmit={form.handleSubmit((v) => save.mutate(v))} noValidate>
          <Field label="Mentor" htmlFor="historyMentor" error={errors.mentorName?.message} className="sm:col-span-2">
            <Input id="historyMentor" {...form.register('mentorName')} />
          </Field>
          <Field label="From" htmlFor="historyFrom" error={errors.fromDate?.message}>
            <Input id="historyFrom" type="date" {...form.register('fromDate')} />
          </Field>
          <Field label="To (empty if current)" htmlFor="historyTo">
            <Input id="historyTo" type="date" {...form.register('toDate')} />
          </Field>
          <Field label="Meetings" htmlFor="historyMeetings" error={errors.meetings?.message}>
            <Input id="historyMeetings" type="number" {...form.register('meetings', { valueAsNumber: true })} />
          </Field>
          <DialogFooter className="gap-2 sm:col-span-2">
            {row ? (
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

function MentorHistory({ studentId }: { studentId: string }) {
  const [dialog, setDialog] = useState<{ row: MentorHistoryRow | null } | null>(null);
  const query = useQuery({
    queryKey: ['mentoring', studentId, 'history'],
    queryFn: () => getOne<MentorHistoryRow[]>('/api/admin/mentoring/history', { studentId }),
  });

  return (
    <section aria-labelledby="history-heading" className="space-y-3">
      <div className="flex items-center justify-between">
        <h2 id="history-heading" className="text-base font-semibold">
          Mentor history
        </h2>
        <Button variant="outline" size="sm" onClick={() => setDialog({ row: null })}>
          <Plus className="mr-1 h-4 w-4" aria-hidden />
          Add
        </Button>
      </div>
      {query.isError ? (
        <QueryError error={query.error} onRetry={() => void query.refetch()} />
      ) : query.data?.length ? (
        <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
          {query.data.map((row) => (
            <Card key={row.id}>
              <CardContent className="flex items-start justify-between p-4">
                <div>
                  <div className="font-medium">{row.mentorName}</div>
                  <div className="text-sm text-muted-foreground">
                    {row.fromDate.slice(0, 10)} to {row.toDate?.slice(0, 10) ?? 'now'} · {row.meetings} meetings
                  </div>
                </div>
                <Button
                  variant="ghost"
                  size="icon"
                  aria-label={`Edit history of ${row.mentorName}`}
                  onClick={() => setDialog({ row })}
                >
                  <Pencil className="h-4 w-4" aria-hidden />
                </Button>
              </CardContent>
            </Card>
          ))}
        </div>
      ) : query.isLoading ? null : (
        <EmptyState>No mentor history recorded.</EmptyState>
      )}
      {dialog ? <HistoryDialog studentId={studentId} row={dialog.row} onClose={() => setDialog(null)} /> : null}
    </section>
  );
}

export default function MentoringPage() {
  const [student, setStudent] = useState<StudentSummary | null>(null);
  return (
    <>
      <PageHeader title="Mentoring" description="Assign mentors and record mentoring sessions per student." />
      <StudentPicker value={student} onChange={setStudent} />
      <div className="mt-6">
        {student ? (
          <div key={student.id} className="space-y-6">
            <MentorCard studentId={student.id} />
            <MentorHistory studentId={student.id} />
            <Sessions studentId={student.id} />
          </div>
        ) : (
          <EmptyState>Pick a student to view their mentoring sessions.</EmptyState>
        )}
      </div>
    </>
  );
}
