'use client';

import { zodResolver } from '@hookform/resolvers/zod';
import { keepPreviousData, useQuery } from '@tanstack/react-query';
import type { ColumnDef, SortingState } from '@tanstack/react-table';
import { Plus, Search } from 'lucide-react';
import { useRouter } from 'next/navigation';
import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { z } from 'zod';
import { DataTable } from '@/components/data-table/DataTable';
import { Field, PageHeader, QueryError, SimpleSelect, SubmitButton } from '@/components/shared/common';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { Button } from '@/components/ui/button';
import { Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { useApiMutation } from '@/hooks/useApiMutation';
import { useDebounced } from '@/hooks/useDebounced';
import { assetUrl, getOne, getPage, post } from '@/lib/api';
import type { Student } from '@/lib/types';

const ALL = 'ALL';

const columns: ColumnDef<Student>[] = [
  {
    accessorKey: 'name',
    header: 'Name',
    cell: ({ row }) => (
      <div className="flex items-center gap-3">
        <Avatar className="h-8 w-8">
          <AvatarImage src={assetUrl(row.original.photoUrl)} alt="" className="object-cover" />
          <AvatarFallback className="text-xs">{row.original.name.charAt(0)}</AvatarFallback>
        </Avatar>
        <span className="font-medium">{row.original.name}</span>
      </div>
    ),
  },
  { accessorKey: 'enrollmentNo', header: 'Enrollment no.' },
  { accessorKey: 'classLabel', header: 'Class' },
  { accessorKey: 'batch', header: 'Batch' },
  { accessorKey: 'rollNo', header: 'Roll no.' },
];

const schema = z.object({
  name: z.string().trim().min(1, 'Name is required'),
  enrollmentNo: z.string().trim().min(1, 'Enrollment number is required'),
  classLabel: z.string().trim().min(1, 'Class is required'),
  batch: z.string().trim().min(1, 'Batch is required'),
  rollNo: z.string().trim().min(1, 'Roll number is required'),
  currentSem: z.number({ invalid_type_error: 'Enter a semester' }).int().min(1).max(12),
  password: z.string().min(8, 'At least 8 characters'),
});
type Values = z.infer<typeof schema>;

function NewStudentDialog({ open, onOpenChange }: { open: boolean; onOpenChange: (open: boolean) => void }) {
  const router = useRouter();
  const form = useForm<Values>({
    resolver: zodResolver(schema),
    defaultValues: { name: '', enrollmentNo: '', classLabel: '', batch: '', rollNo: '', currentSem: 1, password: '' },
  });
  const { errors } = form.formState;
  const create = useApiMutation((values: Values) => post<Student>('/api/admin/students', values), {
    success: 'Student created',
    invalidate: [['students'], ['stats']],
    onSuccess: (student) => router.push(`/students/${student.id}`),
  });

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>New student</DialogTitle>
        </DialogHeader>
        <form className="grid gap-4 sm:grid-cols-2" onSubmit={form.handleSubmit((v) => create.mutate(v))} noValidate>
          <Field label="Name" htmlFor="name" error={errors.name?.message} className="sm:col-span-2">
            <Input id="name" {...form.register('name')} />
          </Field>
          <Field label="Enrollment no." htmlFor="enrollmentNo" error={errors.enrollmentNo?.message}>
            <Input id="enrollmentNo" {...form.register('enrollmentNo')} />
          </Field>
          <Field label="Roll no." htmlFor="rollNo" error={errors.rollNo?.message}>
            <Input id="rollNo" {...form.register('rollNo')} />
          </Field>
          <Field label="Class" htmlFor="classLabel" error={errors.classLabel?.message}>
            <Input id="classLabel" placeholder="BTech+Hons-5B" {...form.register('classLabel')} />
          </Field>
          <Field label="Batch" htmlFor="batch" error={errors.batch?.message}>
            <Input id="batch" placeholder="Batch 2" {...form.register('batch')} />
          </Field>
          <Field label="Current semester" htmlFor="currentSem" error={errors.currentSem?.message}>
            <Input id="currentSem" type="number" min={1} max={12} {...form.register('currentSem', { valueAsNumber: true })} />
          </Field>
          <Field label="Initial password" htmlFor="password" error={errors.password?.message}>
            <Input id="password" type="password" autoComplete="new-password" {...form.register('password')} />
          </Field>
          <DialogFooter className="sm:col-span-2">
            <Button type="button" variant="outline" onClick={() => onOpenChange(false)}>
              Cancel
            </Button>
            <SubmitButton loading={create.isPending}>Create student</SubmitButton>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}

export default function StudentsPage() {
  const router = useRouter();
  const [search, setSearch] = useState('');
  const [batch, setBatch] = useState(ALL);
  const [classLabel, setClassLabel] = useState(ALL);
  const [page, setPage] = useState(1);
  const [sorting, setSorting] = useState<SortingState>([{ id: 'name', desc: false }]);
  const [creating, setCreating] = useState(false);
  const debouncedSearch = useDebounced(search);

  const filters = useQuery({
    queryKey: ['students', 'filters'],
    queryFn: () => getOne<{ batches: string[]; classes: string[] }>('/api/admin/students/filters'),
  });

  const sort = sorting[0];
  const students = useQuery({
    queryKey: ['students', 'list', { debouncedSearch, batch, classLabel, page, sort }],
    queryFn: () =>
      getPage<Student>('/api/admin/students', {
        page,
        limit: 20,
        search: debouncedSearch,
        batch: batch === ALL ? undefined : batch,
        classLabel: classLabel === ALL ? undefined : classLabel,
        sortBy: sort?.id,
        order: sort?.desc ? 'desc' : 'asc',
      }),
    placeholderData: keepPreviousData,
  });

  return (
    <>
      <PageHeader
        title="Students"
        description="Search, filter and open student records."
        actions={
          <Button onClick={() => setCreating(true)}>
            <Plus className="mr-2 h-4 w-4" aria-hidden />
            New student
          </Button>
        }
      />
      <div className="mb-4 flex flex-wrap gap-3">
        <div className="relative min-w-60 flex-1 sm:max-w-sm">
          <Search className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" aria-hidden />
          <Input
            className="pl-9"
            aria-label="Search students"
            placeholder="Search name, enrollment or roll no."
            value={search}
            onChange={(e) => {
              setSearch(e.target.value);
              setPage(1);
            }}
          />
        </div>
        <SimpleSelect
          aria-label="Filter by batch"
          className="w-44"
          value={batch}
          onChange={(v) => {
            setBatch(v);
            setPage(1);
          }}
          options={[
            { value: ALL, label: 'All batches' },
            ...(filters.data?.batches ?? []).map((b) => ({ value: b, label: b })),
          ]}
        />
        <SimpleSelect
          aria-label="Filter by class"
          className="w-52"
          value={classLabel}
          onChange={(v) => {
            setClassLabel(v);
            setPage(1);
          }}
          options={[
            { value: ALL, label: 'All classes' },
            ...(filters.data?.classes ?? []).map((c) => ({ value: c, label: c })),
          ]}
        />
      </div>

      {students.isError ? (
        <QueryError error={students.error} onRetry={() => void students.refetch()} />
      ) : (
        <DataTable
          columns={columns}
          data={students.data?.items}
          meta={students.data?.meta}
          isLoading={students.isLoading}
          onPageChange={setPage}
          sorting={sorting}
          onSortingChange={(s) => {
            setSorting(s);
            setPage(1);
          }}
          onRowClick={(s) => router.push(`/students/${s.id}`)}
          rowLabel={(s) => `Open ${s.name}`}
          emptyText="No students match these filters."
        />
      )}

      {creating ? <NewStudentDialog open onOpenChange={setCreating} /> : null}
    </>
  );
}
