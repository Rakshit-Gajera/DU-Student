'use client';

import { zodResolver } from '@hookform/resolvers/zod';
import { useQuery } from '@tanstack/react-query';
import { ArrowLeft, Trash2 } from 'lucide-react';
import Link from 'next/link';
import { useParams, useRouter } from 'next/navigation';
import { useState } from 'react';
import { Controller, useForm } from 'react-hook-form';
import { z } from 'zod';
import { ConfirmDialog, Field, PageHeader, QueryError, SimpleSelect, SubmitButton } from '@/components/shared/common';
import { FileDrop } from '@/components/shared/FileDrop';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Skeleton } from '@/components/ui/skeleton';
import { useApiMutation } from '@/hooks/useApiMutation';
import { assetUrl, del, getAll, getOne, put, uploadFile } from '@/lib/api';
import type { Mentor, Student } from '@/lib/types';

const NO_MENTOR = 'NONE';

const schema = z.object({
  name: z.string().trim().min(1, 'Name is required'),
  enrollmentNo: z.string().trim().min(1, 'Enrollment number is required'),
  classLabel: z.string().trim().min(1, 'Class is required'),
  batch: z.string().trim().min(1, 'Batch is required'),
  rollNo: z.string().trim().min(1, 'Roll number is required'),
  currentSem: z.number({ invalid_type_error: 'Enter a semester' }).int().min(1).max(12),
  email: z.union([z.literal(''), z.string().trim().email('Invalid email')]),
  mobile: z.string().trim(),
  department: z.string().trim(),
  mentorId: z.string(),
  password: z.union([z.literal(''), z.string().min(8, 'At least 8 characters')]),
});
type Values = z.infer<typeof schema>;

function StudentForm({ student }: { student: Student }) {
  const router = useRouter();
  const [confirming, setConfirming] = useState(false);
  const form = useForm<Values>({
    resolver: zodResolver(schema),
    defaultValues: {
      name: student.name,
      enrollmentNo: student.enrollmentNo,
      classLabel: student.classLabel,
      batch: student.batch,
      rollNo: student.rollNo,
      currentSem: student.currentSem,
      email: student.email ?? '',
      mobile: student.mobile ?? '',
      department: student.department ?? '',
      mentorId: student.mentorId ?? NO_MENTOR,
      password: '',
    },
  });
  const { errors } = form.formState;
  const invalidate = [['students'], ['stats']];
  const url = `/api/admin/students/${student.id}`;

  const mentors = useQuery({
    queryKey: ['mentors'],
    queryFn: () => getAll<Mentor>('/api/admin/mentoring/mentors'),
  });

  const save = useApiMutation(
    ({ password, mentorId, ...values }: Values) =>
      put<Student>(url, {
        ...values,
        mentorId: mentorId === NO_MENTOR ? null : mentorId,
        ...(password ? { password } : {}),
      }),
    {
      success: 'Student saved',
      invalidate,
      onSuccess: () => form.resetField('password'),
    },
  );

  const uploadPhoto = useApiMutation(
    async (file: File) => {
      const { url: photoUrl } = await uploadFile('image', file);
      return put<Student>(url, { photoUrl });
    },
    { success: 'Photo updated', invalidate },
  );

  const removePhoto = useApiMutation(() => put<Student>(url, { photoUrl: null }), {
    success: 'Photo removed',
    invalidate,
  });

  const remove = useApiMutation(() => del(url), {
    success: `${student.name} deleted`,
    invalidate,
    onSuccess: () => router.replace('/students'),
  });

  return (
    <div className="grid gap-6 lg:grid-cols-3">
      <Card className="h-fit">
        <CardHeader>
          <CardTitle className="text-base">Photo</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <Avatar className="mx-auto h-28 w-28">
            <AvatarImage src={assetUrl(student.photoUrl)} alt={student.name} className="object-cover" />
            <AvatarFallback className="text-2xl">{student.name.charAt(0)}</AvatarFallback>
          </Avatar>
          <FileDrop
            accept="image/jpeg,image/png,image/webp"
            hint="JPG, PNG or WebP, up to 5 MB"
            busy={uploadPhoto.isPending}
            onFile={(file) => uploadPhoto.mutate(file)}
          />
          {student.photoUrl ? (
            <Button
              variant="outline"
              size="sm"
              className="w-full"
              disabled={removePhoto.isPending}
              onClick={() => removePhoto.mutate()}
            >
              Remove photo
            </Button>
          ) : null}
        </CardContent>
      </Card>

      <Card className="lg:col-span-2">
        <CardHeader>
          <CardTitle className="text-base">Profile</CardTitle>
        </CardHeader>
        <CardContent>
          <form className="grid gap-4 sm:grid-cols-2" onSubmit={form.handleSubmit((v) => save.mutate(v))} noValidate>
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
              <Input id="classLabel" {...form.register('classLabel')} />
            </Field>
            <Field label="Batch" htmlFor="batch" error={errors.batch?.message}>
              <Input id="batch" {...form.register('batch')} />
            </Field>
            <Field label="Current semester" htmlFor="currentSem" error={errors.currentSem?.message}>
              <Input id="currentSem" type="number" min={1} max={12} {...form.register('currentSem', { valueAsNumber: true })} />
            </Field>
            <Field label="Department" htmlFor="department" error={errors.department?.message}>
              <Input id="department" {...form.register('department')} />
            </Field>
            <Field label="Email" htmlFor="email" error={errors.email?.message}>
              <Input id="email" type="email" {...form.register('email')} />
            </Field>
            <Field label="Mobile" htmlFor="mobile" error={errors.mobile?.message}>
              <Input id="mobile" {...form.register('mobile')} />
            </Field>
            <Field label="Mentor" htmlFor="mentorId">
              <Controller
                control={form.control}
                name="mentorId"
                render={({ field }) => (
                  <SimpleSelect
                    id="mentorId"
                    value={field.value}
                    onChange={field.onChange}
                    options={[
                      { value: NO_MENTOR, label: 'No mentor' },
                      ...(mentors.data ?? []).map((m) => ({ value: m.id, label: m.name })),
                    ]}
                  />
                )}
              />
            </Field>
            <Field
              label="New password"
              htmlFor="password"
              error={errors.password?.message}
              hint="Leave empty to keep the current password."
            >
              <Input id="password" type="password" autoComplete="new-password" {...form.register('password')} />
            </Field>
            <div className="flex flex-wrap justify-between gap-2 sm:col-span-2">
              <Button type="button" variant="outline" className="text-destructive" onClick={() => setConfirming(true)}>
                <Trash2 className="mr-2 h-4 w-4" aria-hidden />
                Delete student
              </Button>
              <SubmitButton loading={save.isPending}>Save changes</SubmitButton>
            </div>
          </form>
        </CardContent>
      </Card>

      <ConfirmDialog
        open={confirming}
        onOpenChange={setConfirming}
        title={`Delete ${student.name}?`}
        description="This permanently deletes the student and their attendance, results, mentoring records, bus passes, grievances and certificate requests."
        loading={remove.isPending}
        onConfirm={() => remove.mutate()}
      />
    </div>
  );
}

export default function StudentDetailPage() {
  const { id } = useParams<{ id: string }>();
  const student = useQuery({
    queryKey: ['students', 'detail', id],
    queryFn: () => getOne<Student>(`/api/admin/students/${id}`),
  });

  return (
    <>
      <Link href="/students" className="mb-3 inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground">
        <ArrowLeft className="h-4 w-4" aria-hidden />
        All students
      </Link>
      <PageHeader title={student.data?.name ?? 'Student'} description={student.data?.enrollmentNo} />
      {student.isLoading ? (
        <Skeleton className="h-96 w-full" />
      ) : student.isError ? (
        <QueryError error={student.error} onRetry={() => void student.refetch()} />
      ) : student.data ? (
        // Remounts the form if a different student loads, so it never shows stale values.
        <StudentForm key={student.data.id} student={student.data} />
      ) : null}
    </>
  );
}
