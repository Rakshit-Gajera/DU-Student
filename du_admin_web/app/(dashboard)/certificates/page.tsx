'use client';

import { zodResolver } from '@hookform/resolvers/zod';
import { keepPreviousData, useQuery } from '@tanstack/react-query';
import type { ColumnDef } from '@tanstack/react-table';
import { Check, Pencil, Plus, RotateCcw, Trash2, X } from 'lucide-react';
import { useMemo, useState } from 'react';
import { useForm } from 'react-hook-form';
import { z } from 'zod';
import { DataTable } from '@/components/data-table/DataTable';
import { ConfirmDialog, Field, PageHeader, QueryError, SimpleSelect, StatusBadge, SubmitButton } from '@/components/shared/common';
import { StudentPicker } from '@/components/shared/StudentPicker';
import { Button } from '@/components/ui/button';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { useApiMutation } from '@/hooks/useApiMutation';
import { del, getPage, post, put } from '@/lib/api';
import type { CertificateRequest, CertificateStatus, StudentSummary } from '@/lib/types';
import { formatDateTime } from '@/lib/utils';

const ALL = 'ALL';
const INVALIDATE = [['certificates'], ['stats']];

const decide = (id: string, status: CertificateStatus, remarks?: string) =>
  put<CertificateRequest>(`/api/admin/certificates/${id}`, { status, remarks });

const rejectSchema = z.object({ remarks: z.string().trim().min(1, 'Tell the student why').max(1000) });
type RejectValues = z.infer<typeof rejectSchema>;

function RejectDialog({ request, onClose }: { request: CertificateRequest; onClose: () => void }) {
  const form = useForm<RejectValues>({ resolver: zodResolver(rejectSchema), defaultValues: { remarks: '' } });
  const reject = useApiMutation((values: RejectValues) => decide(request.id, 'REJECTED', values.remarks), {
    success: 'Request rejected',
    invalidate: INVALIDATE,
    onSuccess: onClose,
  });
  return (
    <Dialog open onOpenChange={(open) => !open && onClose()}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Reject this request?</DialogTitle>
          <DialogDescription>
            {request.type} for {request.student.name}
          </DialogDescription>
        </DialogHeader>
        <form className="space-y-4" onSubmit={form.handleSubmit((v) => reject.mutate(v))} noValidate>
          <Field label="Reason" htmlFor="remarks" error={form.formState.errors.remarks?.message}>
            <Textarea id="remarks" rows={3} {...form.register('remarks')} />
          </Field>
          <DialogFooter>
            <SubmitButton loading={reject.isPending} variant="destructive">
              Reject request
            </SubmitButton>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}

const requestSchema = z.object({
  type: z.string().trim().min(1, 'Certificate type is required').max(200),
  purpose: z.string().trim().max(200),
  copies: z.number({ invalid_type_error: 'Enter a number' }).int().min(1).max(10),
  deliveryMode: z.string().trim().max(100),
  details: z.string().trim().max(2000),
});
type RequestValues = z.infer<typeof requestSchema>;

/** Add a request for a student, or edit an existing one. */
function RequestDialog({ request, onClose }: { request: CertificateRequest | null; onClose: () => void }) {
  const [student, setStudent] = useState<StudentSummary | null>(request?.student ?? null);
  const [studentError, setStudentError] = useState(false);
  const form = useForm<RequestValues>({
    resolver: zodResolver(requestSchema),
    defaultValues: {
      type: request?.type ?? '',
      purpose: request?.purpose ?? '',
      copies: request?.copies ?? 1,
      deliveryMode: request?.deliveryMode ?? '',
      details: request?.details ?? '',
    },
  });
  const { errors } = form.formState;
  const save = useApiMutation(
    (values: RequestValues & { studentId: string }) =>
      request
        ? put<CertificateRequest>(`/api/admin/certificates/${request.id}`, { ...values, status: request.status, remarks: request.remarks })
        : post<CertificateRequest>('/api/admin/certificates', values),
    { success: request ? 'Request updated' : 'Request added', invalidate: INVALIDATE, onSuccess: onClose },
  );
  return (
    <Dialog open onOpenChange={(open) => !open && onClose()}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{request ? 'Edit certificate request' : 'Add certificate request'}</DialogTitle>
        </DialogHeader>
        <form
          className="grid gap-4 sm:grid-cols-2"
          noValidate
          onSubmit={form.handleSubmit((values) => {
            if (!student) {
              setStudentError(true);
              return;
            }
            save.mutate({ ...values, studentId: student.id });
          })}
        >
          {request ? null : (
            <Field label="Student" error={studentError && !student ? 'Pick a student' : undefined} className="sm:col-span-2">
              <StudentPicker value={student} onChange={setStudent} />
            </Field>
          )}
          <Field label="Certificate type" htmlFor="certType" error={errors.type?.message} className="sm:col-span-2">
            <Input id="certType" {...form.register('type')} />
          </Field>
          <Field label="Purpose" htmlFor="certPurpose" error={errors.purpose?.message}>
            <Input id="certPurpose" {...form.register('purpose')} />
          </Field>
          <Field label="Copies" htmlFor="certCopies" error={errors.copies?.message}>
            <Input id="certCopies" type="number" min={1} max={10} {...form.register('copies', { valueAsNumber: true })} />
          </Field>
          <Field label="Delivery mode" htmlFor="certDelivery" error={errors.deliveryMode?.message}>
            <Input id="certDelivery" {...form.register('deliveryMode')} />
          </Field>
          <Field label="Details" htmlFor="certDetails" error={errors.details?.message} className="sm:col-span-2">
            <Textarea id="certDetails" rows={3} {...form.register('details')} />
          </Field>
          <DialogFooter className="sm:col-span-2">
            <SubmitButton loading={save.isPending}>{request ? 'Save changes' : 'Add request'}</SubmitButton>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}

export default function CertificatesPage() {
  const [status, setStatus] = useState(ALL);
  const [page, setPage] = useState(1);
  const [rejecting, setRejecting] = useState<CertificateRequest | null>(null);
  const [editing, setEditing] = useState<{ request: CertificateRequest | null } | null>(null);
  const [deleting, setDeleting] = useState<CertificateRequest | null>(null);

  const requests = useQuery({
    queryKey: ['certificates', { status, page }],
    queryFn: () =>
      getPage<CertificateRequest>('/api/admin/certificates', {
        page,
        limit: 20,
        status: status === ALL ? undefined : status,
      }),
    placeholderData: keepPreviousData,
    // Picks up new requests, and decisions made by other admins, while the page is open.
    refetchInterval: 30_000,
  });

  const approve = useApiMutation((id: string) => decide(id, 'APPROVED'), {
    success: 'Request approved',
    invalidate: INVALIDATE,
  });
  const reopen = useApiMutation((id: string) => decide(id, 'PENDING', ''), {
    success: 'Request moved back to pending',
    invalidate: INVALIDATE,
  });

  const remove = useApiMutation((id: string) => del(`/api/admin/certificates/${id}`), {
    success: 'Request deleted',
    invalidate: INVALIDATE,
    onSuccess: () => setDeleting(null),
  });

  const columns = useMemo<ColumnDef<CertificateRequest>[]>(
    () => [
      {
        accessorKey: 'type',
        header: 'Certificate',
        cell: ({ row }) => (
          <div>
            <div className="font-medium">{row.original.type}</div>
            <div className="text-xs text-muted-foreground">
              {[
                `${row.original.copies} ${row.original.copies === 1 ? 'copy' : 'copies'}`,
                row.original.purpose,
                row.original.deliveryMode,
              ]
                .filter(Boolean)
                .join(' · ')}
            </div>
            {row.original.details ? (
              <div className="text-xs text-muted-foreground">{row.original.details}</div>
            ) : null}
          </div>
        ),
      },
      {
        id: 'student',
        header: 'Student',
        cell: ({ row }) => (
          <div className="whitespace-nowrap">
            <div>{row.original.student.name}</div>
            <div className="text-xs text-muted-foreground">{row.original.student.enrollmentNo}</div>
          </div>
        ),
      },
      {
        accessorKey: 'requestedAt',
        header: 'Requested',
        cell: ({ row }) => <span className="whitespace-nowrap">{formatDateTime(row.original.requestedAt)}</span>,
      },
      {
        accessorKey: 'status',
        header: 'Status',
        cell: ({ row }) => (
          <div>
            <StatusBadge status={row.original.status} />
            {row.original.remarks ? (
              <div className="mt-1 max-w-52 text-xs text-muted-foreground">{row.original.remarks}</div>
            ) : null}
          </div>
        ),
      },
      {
        id: 'actions',
        header: '',
        cell: ({ row }) => (
          <div className="flex items-center justify-end gap-2 whitespace-nowrap">
            {row.original.status === 'PENDING' ? (
              <>
                <Button size="sm" disabled={approve.isPending} onClick={() => approve.mutate(row.original.id)}>
                  <Check className="mr-1 h-4 w-4" aria-hidden />
                  Approve
                </Button>
                <Button size="sm" variant="outline" onClick={() => setRejecting(row.original)}>
                  <X className="mr-1 h-4 w-4" aria-hidden />
                  Reject
                </Button>
              </>
            ) : (
              <Button size="sm" variant="ghost" disabled={reopen.isPending} onClick={() => reopen.mutate(row.original.id)}>
                <RotateCcw className="mr-1 h-4 w-4" aria-hidden />
                Reopen
              </Button>
            )}
            <Button variant="ghost" size="icon" aria-label={`Edit ${row.original.type}`} onClick={() => setEditing({ request: row.original })}>
              <Pencil className="h-4 w-4" aria-hidden />
            </Button>
            <Button variant="ghost" size="icon" aria-label={`Delete ${row.original.type}`} onClick={() => setDeleting(row.original)}>
              <Trash2 className="h-4 w-4" aria-hidden />
            </Button>
          </div>
        ),
      },
    ],
    [approve, reopen],
  );

  return (
    <>
      <PageHeader
        title="Certificates"
        description="Approve, reject, edit, add or delete each student's certificate requests."
        actions={
          <Button onClick={() => setEditing({ request: null })}>
            <Plus className="mr-2 h-4 w-4" aria-hidden />
            New request
          </Button>
        }
      />
      <div className="mb-4">
        <SimpleSelect
          aria-label="Filter by status"
          className="w-44"
          value={status}
          onChange={(v) => {
            setStatus(v);
            setPage(1);
          }}
          options={[
            { value: ALL, label: 'All statuses' },
            { value: 'PENDING', label: 'Pending' },
            { value: 'APPROVED', label: 'Approved' },
            { value: 'REJECTED', label: 'Rejected' },
          ]}
        />
      </div>
      {requests.isError ? (
        <QueryError error={requests.error} onRetry={() => void requests.refetch()} />
      ) : (
        <DataTable
          columns={columns}
          data={requests.data?.items}
          meta={requests.data?.meta}
          isLoading={requests.isLoading}
          onPageChange={setPage}
          emptyText="No certificate requests match this filter."
        />
      )}
      {rejecting ? <RejectDialog request={rejecting} onClose={() => setRejecting(null)} /> : null}
      {editing ? <RequestDialog request={editing.request} onClose={() => setEditing(null)} /> : null}
      <ConfirmDialog
        open={Boolean(deleting)}
        onOpenChange={(open) => !open && setDeleting(null)}
        title={`Delete "${deleting?.type ?? ''}"?`}
        description="The student will no longer see this request. This cannot be undone."
        loading={remove.isPending}
        onConfirm={() => deleting && remove.mutate(deleting.id)}
      />
    </>
  );
}
