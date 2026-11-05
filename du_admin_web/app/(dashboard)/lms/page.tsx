'use client';

import { zodResolver } from '@hookform/resolvers/zod';
import { keepPreviousData, useQuery } from '@tanstack/react-query';
import type { ColumnDef } from '@tanstack/react-table';
import { CheckCircle2, ExternalLink, Eye, EyeOff, Pencil, Plus, Trash2 } from 'lucide-react';
import { useMemo, useState } from 'react';
import { useForm } from 'react-hook-form';
import { z } from 'zod';
import { DataTable } from '@/components/data-table/DataTable';
import { ConfirmDialog, EmptyState, Field, PageHeader, QueryError, SimpleSelect, SubmitButton } from '@/components/shared/common';
import { FileDrop } from '@/components/shared/FileDrop';
import { StudentPicker } from '@/components/shared/StudentPicker';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { Skeleton } from '@/components/ui/skeleton';
import { Tabs, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { useApiMutation } from '@/hooks/useApiMutation';
import { assetUrl, del, getAll, getPage, post, put, uploadFile } from '@/lib/api';
import type { LmsContent, LmsContentType, StudentSummary, Subject } from '@/lib/types';
import { formatDate, toDateInput } from '@/lib/utils';

const TYPE_LABEL: Record<LmsContentType, string> = { PRESENTATION: 'Presentation', LAB_MANUAL: 'Lab manual' };

const contentSchema = z.object({
  title: z.string().trim().min(1, 'Title is required'),
  subtitle: z.string().trim(),
  fileUrl: z.union([z.literal(''), z.string().trim().regex(/^(https?:\/\/\S+|\/uploads\/[\w.-]+)$/i, 'Enter an http(s) link')]),
  uploadedAt: z.string().min(1, 'Date is required'),
});
type ContentValues = z.infer<typeof contentSchema>;

function ContentDialog({
  studentId,
  subjectId,
  type,
  content,
  onClose,
}: {
  studentId: string;
  subjectId: string;
  type: LmsContentType;
  content: LmsContent | null;
  onClose: () => void;
}) {
  const form = useForm<ContentValues>({
    resolver: zodResolver(contentSchema),
    defaultValues: {
      title: content?.title ?? '',
      subtitle: content?.subtitle ?? '',
      fileUrl: content?.fileUrl ?? '',
      uploadedAt: content ? toDateInput(content.uploadedAt) : new Date().toISOString().slice(0, 10),
    },
  });
  const { errors } = form.formState;
  const fileUrl = form.watch('fileUrl');
  const invalidate = [['lms', studentId, subjectId]];

  const upload = useApiMutation((file: File) => uploadFile('document', file), {
    success: 'File uploaded. Save to attach it',
    onSuccess: ({ url }) => form.setValue('fileUrl', url, { shouldValidate: true }),
  });

  const save = useApiMutation(
    (values: ContentValues) => {
      const body = { ...values, fileUrl: values.fileUrl || null };
      return content
        ? put<LmsContent>(`/api/admin/lms/${content.id}`, body)
        : post<LmsContent>('/api/admin/lms', { ...body, studentId, subjectId, type, visible: true });
    },
    { success: content ? 'Content updated' : 'Content added', invalidate, onSuccess: onClose },
  );

  return (
    <Dialog open onOpenChange={(open) => !open && onClose()}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{content ? `Edit ${TYPE_LABEL[content.type].toLowerCase()}` : `Add ${TYPE_LABEL[type].toLowerCase()}`}</DialogTitle>
        </DialogHeader>
        <form className="space-y-4" onSubmit={form.handleSubmit((v) => save.mutate(v))} noValidate>
          <Field label="Title" htmlFor="title" error={errors.title?.message}>
            <Input id="title" {...form.register('title')} />
          </Field>
          <Field label="Subtitle" htmlFor="subtitle" error={errors.subtitle?.message}>
            <Input id="subtitle" {...form.register('subtitle')} />
          </Field>
          <Field label="Date" htmlFor="uploadedAt" error={errors.uploadedAt?.message}>
            <Input id="uploadedAt" type="date" {...form.register('uploadedAt')} />
          </Field>
          <FileDrop
            accept=".pdf,.ppt,.pptx,.doc,.docx"
            hint="PDF, PPT, PPTX, DOC or DOCX, up to 25 MB"
            busy={upload.isPending}
            onFile={(file) => upload.mutate(file)}
          />
          {fileUrl.startsWith('/uploads/') ? (
            <p className="flex items-center gap-1.5 text-xs text-emerald-800">
              <CheckCircle2 className="h-3.5 w-3.5" aria-hidden />
              File attached.{' '}
              <a href={assetUrl(fileUrl)} target="_blank" rel="noreferrer" className="underline">
                Open
              </a>
            </p>
          ) : null}
          <Field label="Or paste a link" htmlFor="fileUrl" error={errors.fileUrl?.message}>
            <Input id="fileUrl" placeholder="https://" {...form.register('fileUrl')} />
          </Field>
          <DialogFooter>
            <SubmitButton loading={save.isPending} disabled={upload.isPending}>
              Save
            </SubmitButton>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}

const subjectSchema = z.object({
  code: z.string().trim().min(1, 'Code is required'),
  name: z.string().trim().min(1, 'Name is required'),
  type: z.string().trim().min(1, 'Type is required'),
  semester: z.number({ invalid_type_error: 'Enter a semester' }).int().min(1).max(12),
});
type SubjectValues = z.infer<typeof subjectSchema>;

function NewSubjectDialog({
  onClose,
  onCreated,
}: {
  onClose: () => void;
  onCreated: (subject: Subject) => void;
}) {
  const form = useForm<SubjectValues>({
    resolver: zodResolver(subjectSchema),
    defaultValues: { code: '', name: '', type: 'Theory', semester: 1 },
  });
  const { errors } = form.formState;
  const create = useApiMutation((values: SubjectValues) => post<Subject>('/api/admin/subjects', values), {
    success: 'Subject created',
    invalidate: [['subjects'], ['stats']],
    onSuccess: (subject) => {
      onCreated(subject);
      onClose();
    },
  });
  return (
    <Dialog open onOpenChange={(open) => !open && onClose()}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>New subject</DialogTitle>
        </DialogHeader>
        <form className="grid gap-4 sm:grid-cols-2" onSubmit={form.handleSubmit((v) => create.mutate(v))} noValidate>
          <Field label="Name" htmlFor="subject-name" error={errors.name?.message} className="sm:col-span-2">
            <Input id="subject-name" {...form.register('name')} />
          </Field>
          <Field label="Code" htmlFor="subject-code" error={errors.code?.message}>
            <Input id="subject-code" placeholder="2301CS402" {...form.register('code')} />
          </Field>
          <Field label="Type" htmlFor="subject-type" error={errors.type?.message}>
            <Input id="subject-type" {...form.register('type')} />
          </Field>
          <Field label="Semester" htmlFor="subject-sem" error={errors.semester?.message}>
            <Input id="subject-sem" type="number" min={1} max={12} {...form.register('semester', { valueAsNumber: true })} />
          </Field>
          <DialogFooter className="sm:col-span-2">
            <SubmitButton loading={create.isPending}>Create subject</SubmitButton>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}

function ContentList({ studentId, subjectId }: { studentId: string; subjectId: string }) {
  const [type, setType] = useState<LmsContentType>('PRESENTATION');
  const [page, setPage] = useState(1);
  const [dialog, setDialog] = useState<{ content: LmsContent | null } | null>(null);
  const [deleting, setDeleting] = useState<LmsContent | null>(null);
  const invalidate = [['lms', studentId, subjectId]];

  const content = useQuery({
    queryKey: ['lms', studentId, subjectId, type, page],
    queryFn: () => getPage<LmsContent>('/api/admin/lms', { studentId, subjectId, type, page, limit: 20 }),
    placeholderData: keepPreviousData,
  });

  const toggleVisible = useApiMutation(
    (item: LmsContent) => put<LmsContent>(`/api/admin/lms/${item.id}`, { visible: !item.visible }),
    {
      success: (updated) => (updated.visible ? 'Now visible to students' : 'Hidden from students'),
      invalidate,
    },
  );

  const remove = useApiMutation((id: string) => del(`/api/admin/lms/${id}`), {
    success: 'Content deleted',
    invalidate,
    onSuccess: () => setDeleting(null),
  });

  const columns = useMemo<ColumnDef<LmsContent>[]>(
    () => [
      {
        accessorKey: 'title',
        header: 'Title',
        cell: ({ row }) => (
          <div>
            <div className="font-medium">{row.original.title}</div>
            {row.original.subtitle ? (
              <div className="text-xs text-muted-foreground">{row.original.subtitle}</div>
            ) : null}
          </div>
        ),
      },
      {
        accessorKey: 'uploadedAt',
        header: 'Date',
        cell: ({ row }) => <span className="whitespace-nowrap">{formatDate(row.original.uploadedAt)}</span>,
      },
      {
        accessorKey: 'fileUrl',
        header: 'File',
        cell: ({ row }) =>
          row.original.fileUrl ? (
            <a
              href={assetUrl(row.original.fileUrl)}
              target="_blank"
              rel="noreferrer"
              className="inline-flex items-center gap-1 text-sm underline"
            >
              Open
              <ExternalLink className="h-3.5 w-3.5" aria-hidden />
            </a>
          ) : (
            <span className="text-muted-foreground">None</span>
          ),
      },
      {
        accessorKey: 'visible',
        header: 'Status',
        cell: ({ row }) => (
          <Badge variant={row.original.visible ? 'secondary' : 'outline'}>
            {row.original.visible ? 'Visible' : 'Hidden'}
          </Badge>
        ),
      },
      {
        id: 'actions',
        header: '',
        cell: ({ row }) => (
          <div className="flex justify-end whitespace-nowrap">
            <Button
              variant="ghost"
              size="icon"
              aria-label={row.original.visible ? `Hide ${row.original.title}` : `Show ${row.original.title}`}
              disabled={toggleVisible.isPending}
              onClick={() => toggleVisible.mutate(row.original)}
            >
              {row.original.visible ? <EyeOff className="h-4 w-4" aria-hidden /> : <Eye className="h-4 w-4" aria-hidden />}
            </Button>
            <Button
              variant="ghost"
              size="icon"
              aria-label={`Edit ${row.original.title}`}
              onClick={() => setDialog({ content: row.original })}
            >
              <Pencil className="h-4 w-4" aria-hidden />
            </Button>
            <Button
              variant="ghost"
              size="icon"
              aria-label={`Delete ${row.original.title}`}
              onClick={() => setDeleting(row.original)}
            >
              <Trash2 className="h-4 w-4" aria-hidden />
            </Button>
          </div>
        ),
      },
    ],
    [toggleVisible],
  );

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <Tabs
          value={type}
          onValueChange={(v) => {
            setType(v as LmsContentType);
            setPage(1);
          }}
        >
          <TabsList>
            <TabsTrigger value="PRESENTATION">Presentations</TabsTrigger>
            <TabsTrigger value="LAB_MANUAL">Lab manuals</TabsTrigger>
          </TabsList>
        </Tabs>
        <Button onClick={() => setDialog({ content: null })}>
          <Plus className="mr-2 h-4 w-4" aria-hidden />
          Add {TYPE_LABEL[type].toLowerCase()}
        </Button>
      </div>

      {content.isError ? (
        <QueryError error={content.error} onRetry={() => void content.refetch()} />
      ) : (
        <DataTable
          columns={columns}
          data={content.data?.items}
          meta={content.data?.meta}
          isLoading={content.isLoading}
          onPageChange={setPage}
          emptyText={`No ${TYPE_LABEL[type].toLowerCase()}s for this subject yet.`}
        />
      )}

      {dialog ? (
        <ContentDialog studentId={studentId} subjectId={subjectId} type={type} content={dialog.content} onClose={() => setDialog(null)} />
      ) : null}
      <ConfirmDialog
        open={Boolean(deleting)}
        onOpenChange={(open) => !open && setDeleting(null)}
        title={`Delete "${deleting?.title ?? ''}"?`}
        description="The student will no longer see it, and an uploaded file is permanently removed."
        loading={remove.isPending}
        onConfirm={() => deleting && remove.mutate(deleting.id)}
      />
    </div>
  );
}

export default function LmsPage() {
  const [student, setStudent] = useState<StudentSummary | null>(null);
  const [subjectId, setSubjectId] = useState('');
  const [creating, setCreating] = useState(false);
  const subjects = useQuery({
    queryKey: ['subjects', 'all'],
    queryFn: () => getAll<Subject>('/api/admin/subjects'),
  });

  return (
    <>
      <PageHeader
        title="LMS"
        description="Each student has their own presentations and lab manuals, per subject."
        actions={
          <Button variant="outline" onClick={() => setCreating(true)}>
            <Plus className="mr-2 h-4 w-4" aria-hidden />
            New subject
          </Button>
        }
      />
      <StudentPicker value={student} onChange={setStudent} />
      <div className="mt-3" />
      {subjects.isError ? (
        <QueryError error={subjects.error} onRetry={() => void subjects.refetch()} />
      ) : subjects.isLoading ? (
        <Skeleton className="h-10 w-full max-w-md" />
      ) : (
        <SimpleSelect
          aria-label="Subject"
          className="max-w-md"
          value={subjectId}
          onChange={setSubjectId}
          placeholder="Pick a subject"
          options={(subjects.data ?? []).map((s) => ({
            value: s.id,
            label: `${s.code} - ${s.name}${s.semester ? ` (Sem ${s.semester})` : ''}`,
          }))}
        />
      )}
      <div className="mt-6">
        {student && subjectId ? (
          <ContentList key={`${student.id}-${subjectId}`} studentId={student.id} subjectId={subjectId} />
        ) : (
          <EmptyState>Pick a student and a subject to manage their content.</EmptyState>
        )}
      </div>
      {creating ? <NewSubjectDialog onClose={() => setCreating(false)} onCreated={(s) => setSubjectId(s.id)} /> : null}
    </>
  );
}
