'use client';

import { zodResolver } from '@hookform/resolvers/zod';
import { useQuery } from '@tanstack/react-query';
import { Bold, ChevronLeft, ChevronRight, Heading2, Italic, Link2, List, Pencil, Pin, Plus, Trash2 } from 'lucide-react';
import { useRef, useState } from 'react';
import { Controller, useForm } from 'react-hook-form';
import Markdown from 'react-markdown';
import { z } from 'zod';
import { ConfirmDialog, EmptyState, Field, PageHeader, QueryError, SubmitButton } from '@/components/shared/common';
import { StudentPicker } from '@/components/shared/StudentPicker';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { Skeleton } from '@/components/ui/skeleton';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Textarea } from '@/components/ui/textarea';
import { useApiMutation } from '@/hooks/useApiMutation';
import { del, getPage, post, put } from '@/lib/api';
import type { Circular, StudentSummary } from '@/lib/types';
import { formatDateTime, fromDateTimeInput, toDateTimeInput } from '@/lib/utils';

/** Renders the stored Markdown. react-markdown ignores raw HTML, so a circular cannot inject markup. */
function CircularBody({ source }: { source: string }) {
  return (
    <div className="space-y-2 text-sm leading-relaxed [&_a]:underline [&_h1]:text-lg [&_h1]:font-semibold [&_h2]:text-base [&_h2]:font-semibold [&_h3]:font-semibold [&_ol]:list-decimal [&_ol]:pl-5 [&_ul]:list-disc [&_ul]:pl-5">
      <Markdown>{source}</Markdown>
    </div>
  );
}

const TOOLBAR = [
  { label: 'Bold', icon: Bold, before: '**', after: '**', placeholder: 'bold text' },
  { label: 'Italic', icon: Italic, before: '_', after: '_', placeholder: 'italic text' },
  { label: 'Heading', icon: Heading2, before: '## ', after: '', placeholder: 'Heading' },
  { label: 'List item', icon: List, before: '- ', after: '', placeholder: 'List item' },
  { label: 'Link', icon: Link2, before: '[', after: '](https://)', placeholder: 'link text' },
] as const;

function RichTextEditor({
  id,
  value,
  onChange,
  invalid,
}: {
  id: string;
  value: string;
  onChange: (value: string) => void;
  invalid: boolean;
}) {
  const textarea = useRef<HTMLTextAreaElement | null>(null);

  function applyFormat(before: string, after: string, placeholder: string) {
    const el = textarea.current;
    const start = el?.selectionStart ?? value.length;
    const end = el?.selectionEnd ?? value.length;
    const selected = value.slice(start, end) || placeholder;
    onChange(`${value.slice(0, start)}${before}${selected}${after}${value.slice(end)}`);
    requestAnimationFrame(() => {
      el?.focus();
      el?.setSelectionRange(start + before.length, start + before.length + selected.length);
    });
  }

  return (
    <Tabs defaultValue="write">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <TabsList>
          <TabsTrigger value="write">Write</TabsTrigger>
          <TabsTrigger value="preview">Preview</TabsTrigger>
        </TabsList>
        <div className="flex" role="toolbar" aria-label="Formatting">
          {TOOLBAR.map(({ label, icon: Icon, before, after, placeholder }) => (
            <Button
              key={label}
              type="button"
              variant="ghost"
              size="icon"
              aria-label={label}
              title={label}
              onClick={() => applyFormat(before, after, placeholder)}
            >
              <Icon className="h-4 w-4" aria-hidden />
            </Button>
          ))}
        </div>
      </div>
      <TabsContent value="write">
        <Textarea
          id={id}
          ref={textarea}
          rows={9}
          aria-invalid={invalid}
          value={value}
          onChange={(e) => onChange(e.target.value)}
        />
      </TabsContent>
      <TabsContent value="preview">
        <div className="min-h-[200px] rounded-md border p-3">
          {value.trim() ? <CircularBody source={value} /> : <p className="text-sm text-muted-foreground">Nothing to preview yet.</p>}
        </div>
      </TabsContent>
    </Tabs>
  );
}

const schema = z.object({
  title: z.string().trim().min(1, 'Title is required').max(300),
  content: z.string().trim().min(1, 'Body is required'),
  publishedAt: z.string().min(1, 'Publish date is required'),
  pinned: z.boolean(),
});
type Values = z.infer<typeof schema>;

function CircularDialog({ studentId, circular, onClose }: { studentId: string; circular: Circular | null; onClose: () => void }) {
  const form = useForm<Values>({
    resolver: zodResolver(schema),
    defaultValues: {
      title: circular?.title ?? '',
      content: circular?.content ?? '',
      publishedAt: toDateTimeInput(circular?.publishedAt ?? new Date().toISOString()),
      pinned: circular?.pinned ?? false,
    },
  });
  const { errors } = form.formState;
  const save = useApiMutation(
    (values: Values) => {
      const body = { ...values, studentId, publishedAt: fromDateTimeInput(values.publishedAt) };
      return circular
        ? put<Circular>(`/api/admin/circulars/${circular.id}`, body)
        : post<Circular>('/api/admin/circulars', body);
    },
    { success: circular ? 'Circular updated' : 'Circular created', invalidate: [['circulars', studentId]], onSuccess: onClose },
  );

  return (
    <Dialog open onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="max-h-[90vh] overflow-y-auto sm:max-w-2xl">
        <DialogHeader>
          <DialogTitle>{circular ? 'Edit circular' : 'New circular'}</DialogTitle>
        </DialogHeader>
        <form className="space-y-4" onSubmit={form.handleSubmit((v) => save.mutate(v))} noValidate>
          <Field label="Title" htmlFor="title" error={errors.title?.message}>
            <Input id="title" {...form.register('title')} />
          </Field>
          <Field label="Body" htmlFor="content" error={errors.content?.message}>
            <Controller
              control={form.control}
              name="content"
              render={({ field }) => (
                <RichTextEditor id="content" value={field.value} onChange={field.onChange} invalid={Boolean(errors.content)} />
              )}
            />
          </Field>
          <div className="grid items-end gap-4 sm:grid-cols-2">
            <Field
              label="Publish date"
              htmlFor="publishedAt"
              error={errors.publishedAt?.message}
              hint="Students see it from this time."
            >
              <Input id="publishedAt" type="datetime-local" {...form.register('publishedAt')} />
            </Field>
            <label className="flex h-10 items-center gap-2 text-sm">
              <input type="checkbox" className="h-4 w-4" {...form.register('pinned')} />
              Pin to the top of the list
            </label>
          </div>
          <DialogFooter>
            <SubmitButton loading={save.isPending}>{circular ? 'Save changes' : 'Create circular'}</SubmitButton>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}

function CircularList({ studentId }: { studentId: string }) {
  const [page, setPage] = useState(1);
  const [dialog, setDialog] = useState<{ circular: Circular | null } | null>(null);
  const [deleting, setDeleting] = useState<Circular | null>(null);

  const circulars = useQuery({
    queryKey: ['circulars', studentId, page],
    queryFn: () => getPage<Circular>('/api/admin/circulars', { studentId, page, limit: 10 }),
  });
  const remove = useApiMutation((id: string) => del(`/api/admin/circulars/${id}`), {
    success: 'Circular deleted',
    invalidate: [['circulars', studentId]],
    onSuccess: () => setDeleting(null),
  });
  const meta = circulars.data?.meta;

  return (
    <>
      <div className="mb-4 flex justify-end">
        <Button onClick={() => setDialog({ circular: null })}>
          <Plus className="mr-2 h-4 w-4" aria-hidden />
          New circular
        </Button>
      </div>
      {circulars.isError ? (
        <QueryError error={circulars.error} onRetry={() => void circulars.refetch()} />
      ) : circulars.isLoading ? (
        <div className="space-y-3">
          <Skeleton className="h-32 w-full" />
          <Skeleton className="h-32 w-full" />
        </div>
      ) : circulars.data?.items.length ? (
        <div className="space-y-3">
          {circulars.data.items.map((c) => (
            <Card key={c.id}>
              <CardHeader className="flex flex-row items-start justify-between gap-3 space-y-0 pb-2">
                <div className="min-w-0">
                  <CardTitle className="flex flex-wrap items-center gap-2 text-base">
                    {c.title}
                    {c.pinned ? (
                      <Badge variant="secondary" className="gap-1">
                        <Pin className="h-3 w-3" aria-hidden />
                        Pinned
                      </Badge>
                    ) : null}
                    {new Date(c.publishedAt) > new Date() ? <Badge variant="outline">Scheduled</Badge> : null}
                  </CardTitle>
                  <p className="mt-1 text-xs text-muted-foreground">{formatDateTime(c.publishedAt)}</p>
                </div>
                <div className="flex shrink-0">
                  <Button variant="ghost" size="icon" aria-label={`Edit ${c.title}`} onClick={() => setDialog({ circular: c })}>
                    <Pencil className="h-4 w-4" aria-hidden />
                  </Button>
                  <Button variant="ghost" size="icon" aria-label={`Delete ${c.title}`} onClick={() => setDeleting(c)}>
                    <Trash2 className="h-4 w-4" aria-hidden />
                  </Button>
                </div>
              </CardHeader>
              <CardContent>
                <CircularBody source={c.content} />
              </CardContent>
            </Card>
          ))}
          {meta && meta.totalPages > 1 ? (
            <div className="flex items-center justify-end gap-2 text-sm text-muted-foreground">
              <Button variant="outline" size="sm" disabled={page <= 1} onClick={() => setPage(page - 1)}>
                <ChevronLeft className="mr-1 h-4 w-4" aria-hidden />
                Previous
              </Button>
              <span>
                {meta.page} / {meta.totalPages}
              </span>
              <Button variant="outline" size="sm" disabled={page >= meta.totalPages} onClick={() => setPage(page + 1)}>
                Next
                <ChevronRight className="ml-1 h-4 w-4" aria-hidden />
              </Button>
            </div>
          ) : null}
        </div>
      ) : (
        <EmptyState>This student has no circulars yet.</EmptyState>
      )}

      {dialog ? <CircularDialog studentId={studentId} circular={dialog.circular} onClose={() => setDialog(null)} /> : null}
      <ConfirmDialog
        open={Boolean(deleting)}
        onOpenChange={(open) => !open && setDeleting(null)}
        title={`Delete "${deleting?.title ?? ''}"?`}
        description="The student will no longer see this circular. This cannot be undone."
        loading={remove.isPending}
        onConfirm={() => deleting && remove.mutate(deleting.id)}
      />
    </>
  );
}

export default function CircularsPage() {
  const [student, setStudent] = useState<StudentSummary | null>(null);
  return (
    <>
      <PageHeader title="Circulars" description="Each student has their own circulars." />
      <StudentPicker value={student} onChange={setStudent} />
      <div className="mt-6">
        {student ? <CircularList key={student.id} studentId={student.id} /> : <EmptyState>Pick a student to manage their circulars.</EmptyState>}
      </div>
    </>
  );
}
