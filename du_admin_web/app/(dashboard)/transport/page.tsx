'use client';

import { zodResolver } from '@hookform/resolvers/zod';
import { keepPreviousData, useQuery } from '@tanstack/react-query';
import type { ColumnDef } from '@tanstack/react-table';
import { Pencil, Plus, Search, Trash2 } from 'lucide-react';
import { useState } from 'react';
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
import { useDebounced } from '@/hooks/useDebounced';
import { del, getPage, post, put } from '@/lib/api';
import type { BusReceipt, StudentSummary, Transport } from '@/lib/types';
import { formatDate, toDateInput } from '@/lib/utils';

const INVALIDATE = [['transport']];

const columns: ColumnDef<Transport>[] = [
  { accessorKey: 'passNo', header: 'Pass no.', cell: ({ row }) => <span className="font-medium">{row.original.passNo}</span> },
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
  { accessorKey: 'busRoute', header: 'Route' },
  { accessorKey: 'pickupPoint', header: 'Pickup point', cell: ({ row }) => row.original.pickupPoint ?? '-' },
  {
    id: 'valid',
    header: 'Valid',
    cell: ({ row }) => (
      <span className="whitespace-nowrap">
        {formatDate(row.original.validFrom)} to {formatDate(row.original.validTo)}
      </span>
    ),
  },
  {
    id: 'pending',
    header: 'Pending fees',
    cell: ({ row }) => (
      <span className="tabular-nums">₹ {Math.max(0, row.original.feesAmount - row.original.feesPaid)}</span>
    ),
  },
  {
    accessorKey: 'active',
    header: 'Status',
    cell: ({ row }) => (
      <Badge variant={row.original.active ? 'secondary' : 'outline'}>{row.original.active ? 'Active' : 'Inactive'}</Badge>
    ),
  },
];

const schema = z
  .object({
    passNo: z.string().trim().min(1, 'Pass number is required'),
    batchCode: z.string().trim(),
    busCode: z.string().trim(),
    pickupAddress: z.string().trim().max(500),
    busRoute: z.string().trim().min(1, 'Route is required'),
    pickupPoint: z.string().trim(),
    shift: z.string().trim(),
    validFrom: z.string().min(1, 'Required'),
    validTo: z.string().min(1, 'Required'),
    feesAmount: z.number({ invalid_type_error: 'Enter an amount' }).int().min(0),
    feesPaid: z.number({ invalid_type_error: 'Enter an amount' }).int().min(0),
    active: z.boolean(),
  })
  .refine((v) => !v.validFrom || !v.validTo || v.validFrom <= v.validTo, {
    path: ['validTo'],
    message: 'Cannot be before the valid-from date',
  });
type Values = z.infer<typeof schema>;

function PassDialog({ pass, onClose }: { pass: Transport | null; onClose: () => void }) {
  const [student, setStudent] = useState<StudentSummary | null>(pass?.student ?? null);
  const [studentError, setStudentError] = useState(false);
  const [confirming, setConfirming] = useState(false);
  const form = useForm<Values>({
    resolver: zodResolver(schema),
    defaultValues: {
      passNo: pass?.passNo ?? '',
      batchCode: pass?.batchCode ?? '',
      busCode: pass?.busCode ?? '',
      pickupAddress: pass?.pickupAddress ?? '',
      busRoute: pass?.busRoute ?? '',
      pickupPoint: pass?.pickupPoint ?? '',
      shift: pass?.shift ?? '',
      validFrom: toDateInput(pass?.validFrom),
      validTo: toDateInput(pass?.validTo),
      feesAmount: pass?.feesAmount ?? 0,
      feesPaid: pass?.feesPaid ?? 0,
      active: pass?.active ?? true,
    },
  });
  const { errors } = form.formState;

  const save = useApiMutation(
    (values: Values & { studentId: string }) =>
      pass ? put<Transport>(`/api/admin/transport/${pass.id}`, values) : post<Transport>('/api/admin/transport', values),
    { success: pass ? 'Bus pass saved' : 'Bus pass created', invalidate: INVALIDATE, onSuccess: onClose },
  );
  const remove = useApiMutation(() => del(`/api/admin/transport/${pass?.id ?? ''}`), {
    success: 'Bus pass deleted',
    invalidate: INVALIDATE,
    onSuccess: onClose,
  });

  return (
    <Dialog open onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="max-h-[90vh] overflow-y-auto sm:max-w-2xl">
        <DialogHeader>
          <DialogTitle>{pass ? `Bus pass ${pass.passNo}` : 'New bus pass'}</DialogTitle>
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
          <Field label="Student" error={studentError && !student ? 'Pick a student' : undefined} className="sm:col-span-2">
            <StudentPicker value={student} onChange={setStudent} />
          </Field>
          <Field label="Pass no." htmlFor="passNo" error={errors.passNo?.message}>
            <Input id="passNo" {...form.register('passNo')} />
          </Field>
          <Field label="Batch code" htmlFor="batchCode">
            <Input id="batchCode" {...form.register('batchCode')} />
          </Field>
          <Field label="Bus code" htmlFor="busCode">
            <Input id="busCode" {...form.register('busCode')} />
          </Field>
          <Field label="Route" htmlFor="busRoute" error={errors.busRoute?.message}>
            <Input id="busRoute" {...form.register('busRoute')} />
          </Field>
          <Field label="Pickup point" htmlFor="pickupPoint">
            <Input id="pickupPoint" {...form.register('pickupPoint')} />
          </Field>
          <Field label="Pickup address" htmlFor="pickupAddress" className="sm:col-span-2">
            <Input id="pickupAddress" {...form.register('pickupAddress')} />
          </Field>
          <Field label="Shift and timings" htmlFor="shift">
            <Input id="shift" {...form.register('shift')} />
          </Field>
          <Field label="Valid from" htmlFor="validFrom" error={errors.validFrom?.message}>
            <Input id="validFrom" type="date" {...form.register('validFrom')} />
          </Field>
          <Field label="Valid to" htmlFor="validTo" error={errors.validTo?.message}>
            <Input id="validTo" type="date" {...form.register('validTo')} />
          </Field>
          <Field label="Fees amount (₹)" htmlFor="feesAmount" error={errors.feesAmount?.message}>
            <Input id="feesAmount" type="number" min={0} {...form.register('feesAmount', { valueAsNumber: true })} />
          </Field>
          <Field label="Fees paid (₹)" htmlFor="feesPaid" error={errors.feesPaid?.message}>
            <Input id="feesPaid" type="number" min={0} {...form.register('feesPaid', { valueAsNumber: true })} />
          </Field>
          <label className="flex items-center gap-2 text-sm sm:col-span-2">
            <input type="checkbox" className="h-4 w-4" {...form.register('active')} />
            Pass is active
          </label>
          <DialogFooter className="gap-2 sm:col-span-2">
            {pass ? (
              <Button type="button" variant="outline" className="mr-auto text-destructive" onClick={() => setConfirming(true)}>
                <Trash2 className="mr-2 h-4 w-4" aria-hidden />
                Delete
              </Button>
            ) : null}
            <SubmitButton loading={save.isPending}>{pass ? 'Save changes' : 'Create pass'}</SubmitButton>
          </DialogFooter>
        </form>
        <ConfirmDialog
          open={confirming}
          onOpenChange={setConfirming}
          title={`Delete bus pass ${pass?.passNo ?? ''}?`}
          description="The student will no longer see this pass. This cannot be undone."
          loading={remove.isPending}
          onConfirm={() => remove.mutate()}
        />
      </DialogContent>
    </Dialog>
  );
}

// ------------------------------------------------------------ Fee receipts

const receiptSchema = z.object({
  receiptNo: z.string().trim().min(1, 'Receipt number is required').max(100),
  paidOn: z.string().min(1, 'Required'),
  amount: z.number({ invalid_type_error: 'Enter an amount' }).int().min(0),
  description: z.string().trim().max(500),
});
type ReceiptValues = z.infer<typeof receiptSchema>;

function ReceiptDialog({ studentId, receipt, onClose }: { studentId: string; receipt: BusReceipt | null; onClose: () => void }) {
  const form = useForm<ReceiptValues>({
    resolver: zodResolver(receiptSchema),
    defaultValues: {
      receiptNo: receipt?.receiptNo ?? '',
      paidOn: toDateInput(receipt?.paidOn),
      amount: receipt?.amount ?? 0,
      description: receipt?.description ?? '',
    },
  });
  const { errors } = form.formState;
  const invalidate = [['receipts', studentId]];
  const save = useApiMutation(
    (values: ReceiptValues) => {
      const body = { ...values, studentId };
      return receipt ? put<BusReceipt>(`/api/admin/transport/receipts/${receipt.id}`, body) : post<BusReceipt>('/api/admin/transport/receipts', body);
    },
    { success: 'Receipt saved', invalidate, onSuccess: onClose },
  );
  const remove = useApiMutation(() => del(`/api/admin/transport/receipts/${receipt?.id ?? ''}`), {
    success: 'Receipt deleted',
    invalidate,
    onSuccess: onClose,
  });

  return (
    <Dialog open onOpenChange={(open) => !open && onClose()}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{receipt ? `Receipt ${receipt.receiptNo}` : 'Add receipt'}</DialogTitle>
        </DialogHeader>
        <form className="grid gap-4 sm:grid-cols-2" onSubmit={form.handleSubmit((v) => save.mutate(v))} noValidate>
          <Field label="Receipt no." htmlFor="receiptNo" error={errors.receiptNo?.message}>
            <Input id="receiptNo" {...form.register('receiptNo')} />
          </Field>
          <Field label="Paid on" htmlFor="paidOn" error={errors.paidOn?.message}>
            <Input id="paidOn" type="date" {...form.register('paidOn')} />
          </Field>
          <Field label="Amount (₹)" htmlFor="amount" error={errors.amount?.message}>
            <Input id="amount" type="number" min={0} {...form.register('amount', { valueAsNumber: true })} />
          </Field>
          <Field label="Description" htmlFor="receiptDescription" error={errors.description?.message}>
            <Input id="receiptDescription" {...form.register('description')} />
          </Field>
          <DialogFooter className="gap-2 sm:col-span-2">
            {receipt ? (
              <Button type="button" variant="outline" className="mr-auto text-destructive" disabled={remove.isPending} onClick={() => remove.mutate()}>
                <Trash2 className="mr-2 h-4 w-4" aria-hidden />
                Delete
              </Button>
            ) : null}
            <SubmitButton loading={save.isPending}>Save</SubmitButton>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}

function Receipts() {
  const [student, setStudent] = useState<StudentSummary | null>(null);
  const [dialog, setDialog] = useState<{ receipt: BusReceipt | null } | null>(null);
  const receipts = useQuery({
    queryKey: ['receipts', student?.id],
    queryFn: () => getPage<BusReceipt>('/api/admin/transport/receipts', { studentId: student?.id, limit: 100 }),
    enabled: Boolean(student),
  });

  return (
    <section aria-labelledby="receipts-heading" className="mt-8 space-y-3">
      <div className="flex items-center justify-between">
        <h2 id="receipts-heading" className="text-base font-semibold">
          Fee receipts
        </h2>
        {student ? (
          <Button variant="outline" size="sm" onClick={() => setDialog({ receipt: null })}>
            <Plus className="mr-1 h-4 w-4" aria-hidden />
            Add receipt
          </Button>
        ) : null}
      </div>
      <StudentPicker value={student} onChange={setStudent} />
      {!student ? (
        <EmptyState>Pick a student to manage their receipts.</EmptyState>
      ) : receipts.isError ? (
        <QueryError error={receipts.error} onRetry={() => void receipts.refetch()} />
      ) : receipts.data?.items.length ? (
        <div className="divide-y rounded-md border bg-card">
          {receipts.data.items.map((r) => (
            <div key={r.id} className="flex items-center justify-between gap-3 px-4 py-3 text-sm">
              <div className="min-w-0">
                <div className="font-medium">{r.receiptNo}</div>
                <div className="truncate text-xs text-muted-foreground">
                  {formatDate(r.paidOn)}
                  {r.description ? ` · ${r.description}` : ''}
                </div>
              </div>
              <div className="flex shrink-0 items-center gap-2">
                <span className="tabular-nums">₹ {r.amount}</span>
                <Button variant="ghost" size="icon" aria-label={`Edit receipt ${r.receiptNo}`} onClick={() => setDialog({ receipt: r })}>
                  <Pencil className="h-4 w-4" aria-hidden />
                </Button>
              </div>
            </div>
          ))}
        </div>
      ) : receipts.isLoading ? null : (
        <EmptyState>This student has no receipts.</EmptyState>
      )}
      {dialog && student ? <ReceiptDialog studentId={student.id} receipt={dialog.receipt} onClose={() => setDialog(null)} /> : null}
    </section>
  );
}

export default function TransportPage() {
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);
  const [dialog, setDialog] = useState<{ pass: Transport | null } | null>(null);
  const debounced = useDebounced(search);

  const passes = useQuery({
    queryKey: ['transport', { debounced, page }],
    queryFn: () => getPage<Transport>('/api/admin/transport', { page, limit: 20, search: debounced }),
    placeholderData: keepPreviousData,
  });

  return (
    <>
      <PageHeader
        title="Transport"
        description="View and edit each student's bus pass."
        actions={
          <Button onClick={() => setDialog({ pass: null })}>
            <Plus className="mr-2 h-4 w-4" aria-hidden />
            New bus pass
          </Button>
        }
      />
      <div className="relative mb-4 max-w-sm">
        <Search className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" aria-hidden />
        <Input
          className="pl-9"
          aria-label="Search bus passes"
          placeholder="Search pass no., route or student"
          value={search}
          onChange={(e) => {
            setSearch(e.target.value);
            setPage(1);
          }}
        />
      </div>
      {passes.isError ? (
        <QueryError error={passes.error} onRetry={() => void passes.refetch()} />
      ) : (
        <DataTable
          columns={columns}
          data={passes.data?.items}
          meta={passes.data?.meta}
          isLoading={passes.isLoading}
          onPageChange={setPage}
          onRowClick={(pass) => setDialog({ pass })}
          rowLabel={(p) => `Edit bus pass ${p.passNo}`}
          emptyText="No bus passes found."
        />
      )}
      {dialog ? <PassDialog pass={dialog.pass} onClose={() => setDialog(null)} /> : null}
      <Receipts />
    </>
  );
}
