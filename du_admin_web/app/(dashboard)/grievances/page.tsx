'use client';

import { zodResolver } from '@hookform/resolvers/zod';
import { keepPreviousData, useQuery } from '@tanstack/react-query';
import type { ColumnDef } from '@tanstack/react-table';
import { Plus, Search, Trash2 } from 'lucide-react';
import { useState } from 'react';
import { Controller, useForm } from 'react-hook-form';
import { z } from 'zod';
import { DataTable } from '@/components/data-table/DataTable';
import { ConfirmDialog, Field, PageHeader, QueryError, SimpleSelect, StatusBadge, SubmitButton } from '@/components/shared/common';
import { StudentPicker } from '@/components/shared/StudentPicker';
import { Button } from '@/components/ui/button';
import { Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { Sheet, SheetContent, SheetDescription, SheetHeader, SheetTitle } from '@/components/ui/sheet';
import { Textarea } from '@/components/ui/textarea';
import { useApiMutation } from '@/hooks/useApiMutation';
import { useDebounced } from '@/hooks/useDebounced';
import { del, getPage, post, put } from '@/lib/api';
import type { Grievance, GrievanceStatus, StudentSummary } from '@/lib/types';
import { formatDateTime } from '@/lib/utils';

const ALL = 'ALL';
const STATUS_OPTIONS: readonly { value: GrievanceStatus; label: string }[] = [
  { value: 'PENDING', label: 'Pending' },
  { value: 'IN_PROGRESS', label: 'In Progress' },
  { value: 'RESOLVED', label: 'Resolved' },
];

const columns: ColumnDef<Grievance>[] = [
  { accessorKey: 'grievanceNo', header: 'No.' },
  { accessorKey: 'title', header: 'Title', cell: ({ row }) => <span className="font-medium">{row.original.title}</span> },
  { id: 'student', header: 'Student', cell: ({ row }) => row.original.student.name },
  { accessorKey: 'category', header: 'Category' },
  {
    accessorKey: 'filedAt',
    header: 'Filed',
    cell: ({ row }) => <span className="whitespace-nowrap">{formatDateTime(row.original.filedAt)}</span>,
  },
  { accessorKey: 'status', header: 'Status', cell: ({ row }) => <StatusBadge status={row.original.status} /> },
];

const INVALIDATE = [['grievances'], ['stats']];

const textFields = {
  category: z.string().trim().min(1, 'Category is required').max(100),
  title: z.string().trim().min(1, 'Title is required').max(200),
  description: z.string().trim().min(1, 'Description is required').max(5000),
};
const schema = z.object({
  ...textFields,
  status: z.enum(['PENDING', 'IN_PROGRESS', 'RESOLVED']),
  resolution: z.string().trim().max(2000),
});
type Values = z.infer<typeof schema>;

const newSchema = z.object(textFields);
type NewValues = z.infer<typeof newSchema>;

function NewGrievanceDialog({ onClose }: { onClose: () => void }) {
  const [student, setStudent] = useState<StudentSummary | null>(null);
  const [studentError, setStudentError] = useState(false);
  const form = useForm<NewValues>({
    resolver: zodResolver(newSchema),
    defaultValues: { category: '', title: '', description: '' },
  });
  const { errors } = form.formState;
  const create = useApiMutation(
    (values: NewValues & { studentId: string }) => post<Grievance>('/api/admin/grievances', values),
    { success: 'Grievance filed', invalidate: INVALIDATE, onSuccess: onClose },
  );
  return (
    <Dialog open onOpenChange={(open) => !open && onClose()}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>File a grievance for a student</DialogTitle>
        </DialogHeader>
        <form
          className="space-y-4"
          noValidate
          onSubmit={form.handleSubmit((values) => {
            if (!student) {
              setStudentError(true);
              return;
            }
            create.mutate({ ...values, studentId: student.id });
          })}
        >
          <Field label="Student" error={studentError && !student ? 'Pick a student' : undefined}>
            <StudentPicker value={student} onChange={setStudent} />
          </Field>
          <Field label="Category" htmlFor="newCategory" error={errors.category?.message}>
            <Input id="newCategory" {...form.register('category')} />
          </Field>
          <Field label="Title" htmlFor="newTitle" error={errors.title?.message}>
            <Input id="newTitle" {...form.register('title')} />
          </Field>
          <Field label="Description" htmlFor="newDescription" error={errors.description?.message}>
            <Textarea id="newDescription" rows={4} {...form.register('description')} />
          </Field>
          <DialogFooter>
            <SubmitButton loading={create.isPending}>File grievance</SubmitButton>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}

function GrievanceDetails({ grievance, onClose }: { grievance: Grievance; onClose: () => void }) {
  const form = useForm<Values>({
    resolver: zodResolver(schema),
    defaultValues: {
      category: grievance.category,
      title: grievance.title,
      description: grievance.description,
      status: grievance.status,
      resolution: grievance.resolution ?? '',
    },
  });
  const { errors } = form.formState;
  const [confirming, setConfirming] = useState(false);
  const save = useApiMutation((values: Values) => put<Grievance>(`/api/admin/grievances/${grievance.id}`, values), {
    success: 'Grievance updated',
    invalidate: INVALIDATE,
    onSuccess: onClose,
  });
  const remove = useApiMutation(() => del(`/api/admin/grievances/${grievance.id}`), {
    success: 'Grievance deleted',
    invalidate: INVALIDATE,
    onSuccess: onClose,
  });

  return (
    <Sheet open onOpenChange={(open) => !open && onClose()}>
      <SheetContent className="w-full overflow-y-auto sm:max-w-md">
        <SheetHeader>
          <SheetTitle>{grievance.title}</SheetTitle>
          <SheetDescription>Grievance no. {grievance.grievanceNo}</SheetDescription>
        </SheetHeader>
        <dl className="mt-5 space-y-3 text-sm">
          <div>
            <dt className="text-xs text-muted-foreground">Student</dt>
            <dd>
              {grievance.student.name} ({grievance.student.enrollmentNo})
            </dd>
          </div>
          <div>
            <dt className="text-xs text-muted-foreground">Filed</dt>
            <dd>{formatDateTime(grievance.filedAt)}</dd>
          </div>
          {grievance.resolvedAt ? (
            <div>
              <dt className="text-xs text-muted-foreground">Resolved</dt>
              <dd>
                {formatDateTime(grievance.resolvedAt)} by {grievance.resolvedBy}
              </dd>
            </div>
          ) : null}
        </dl>
        <form className="mt-6 space-y-4 border-t pt-5" onSubmit={form.handleSubmit((v) => save.mutate(v))} noValidate>
          <Field label="Title" htmlFor="title" error={errors.title?.message}>
            <Input id="title" {...form.register('title')} />
          </Field>
          <Field label="Category" htmlFor="category" error={errors.category?.message}>
            <Input id="category" {...form.register('category')} />
          </Field>
          <Field label="Description" htmlFor="description" error={errors.description?.message}>
            <Textarea id="description" rows={5} {...form.register('description')} />
          </Field>
          <Field label="Status" htmlFor="status">
            <Controller
              control={form.control}
              name="status"
              render={({ field }) => (
                <SimpleSelect id="status" value={field.value} onChange={field.onChange} options={STATUS_OPTIONS} />
              )}
            />
          </Field>
          <Field label="Resolution note" htmlFor="resolution" error={form.formState.errors.resolution?.message}>
            <Textarea id="resolution" rows={4} {...form.register('resolution')} />
          </Field>
          <SubmitButton loading={save.isPending} className="w-full">
            Save
          </SubmitButton>
          <Button type="button" variant="outline" className="w-full text-destructive" onClick={() => setConfirming(true)}>
            <Trash2 className="mr-2 h-4 w-4" aria-hidden />
            Delete grievance
          </Button>
        </form>
        <ConfirmDialog
          open={confirming}
          onOpenChange={setConfirming}
          title={`Delete grievance ${grievance.grievanceNo}?`}
          description="The student will no longer see it. This cannot be undone."
          loading={remove.isPending}
          onConfirm={() => remove.mutate()}
        />
      </SheetContent>
    </Sheet>
  );
}

export default function GrievancesPage() {
  const [search, setSearch] = useState('');
  const [status, setStatus] = useState(ALL);
  const [page, setPage] = useState(1);
  const [selected, setSelected] = useState<Grievance | null>(null);
  const [creating, setCreating] = useState(false);
  const debounced = useDebounced(search);

  const grievances = useQuery({
    queryKey: ['grievances', { debounced, status, page }],
    queryFn: () =>
      getPage<Grievance>('/api/admin/grievances', {
        page,
        limit: 20,
        search: debounced,
        status: status === ALL ? undefined : status,
      }),
    placeholderData: keepPreviousData,
  });

  return (
    <>
      <PageHeader
        title="Grievances"
        description="Review, edit, file or delete each student's grievances."
        actions={
          <Button onClick={() => setCreating(true)}>
            <Plus className="mr-2 h-4 w-4" aria-hidden />
            New grievance
          </Button>
        }
      />
      <div className="mb-4 flex flex-wrap gap-3">
        <div className="relative min-w-60 flex-1 sm:max-w-sm">
          <Search className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" aria-hidden />
          <Input
            className="pl-9"
            aria-label="Search grievances"
            placeholder="Search title, number or student"
            value={search}
            onChange={(e) => {
              setSearch(e.target.value);
              setPage(1);
            }}
          />
        </div>
        <SimpleSelect
          aria-label="Filter by status"
          className="w-44"
          value={status}
          onChange={(v) => {
            setStatus(v);
            setPage(1);
          }}
          options={[{ value: ALL, label: 'All statuses' }, ...STATUS_OPTIONS]}
        />
      </div>
      {grievances.isError ? (
        <QueryError error={grievances.error} onRetry={() => void grievances.refetch()} />
      ) : (
        <DataTable
          columns={columns}
          data={grievances.data?.items}
          meta={grievances.data?.meta}
          isLoading={grievances.isLoading}
          onPageChange={setPage}
          onRowClick={setSelected}
          rowLabel={(g) => `Open grievance ${g.grievanceNo}`}
          emptyText="No grievances match these filters."
        />
      )}
      {selected ? <GrievanceDetails key={selected.id} grievance={selected} onClose={() => setSelected(null)} /> : null}
      {creating ? <NewGrievanceDialog onClose={() => setCreating(false)} /> : null}
    </>
  );
}
