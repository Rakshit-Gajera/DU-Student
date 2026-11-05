'use client';

import { zodResolver } from '@hookform/resolvers/zod';
import { useQuery } from '@tanstack/react-query';
import { Plus, Trash2 } from 'lucide-react';
import { useState } from 'react';
import { Controller, useFieldArray, useForm, useWatch } from 'react-hook-form';
import { z } from 'zod';
import { CpiTrend } from '@/components/charts/CpiTrend';
import { ConfirmDialog, EmptyState, Field, PageHeader, QueryError, SimpleSelect, SubmitButton } from '@/components/shared/common';
import { StudentPicker } from '@/components/shared/StudentPicker';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { Skeleton } from '@/components/ui/skeleton';
import { useApiMutation } from '@/hooks/useApiMutation';
import { del, getAll, post, put } from '@/lib/api';
import { GRADES, weightedAverage } from '@/lib/grades';
import type { SemesterResult, StudentSummary, Subject } from '@/lib/types';

const GRADE_OPTIONS = GRADES.map((g) => ({ value: g, label: g }));

const semesterSchema = z.object({
  yearLabel: z.string().trim().min(1, 'Required'),
  courses: z
    .array(
      z.object({
        subjectId: z.string().min(1, 'Pick a subject'),
        grade: z.string().min(1, 'Pick a grade'),
        credits: z.number({ invalid_type_error: 'Required' }).int().min(0).max(30),
        examSeason: z.string().trim(),
        attemptNo: z.number({ invalid_type_error: 'Required' }).int().min(1).max(20),
      }),
    )
    .refine((c) => new Set(c.map((x) => x.subjectId)).size === c.length, {
      message: 'A subject can appear only once per semester',
    }),
});
type SemesterValues = z.infer<typeof semesterSchema>;

function SemesterCard({
  semester,
  subjects,
  studentId,
}: {
  semester: SemesterResult;
  subjects: Subject[];
  studentId: string;
}) {
  const form = useForm<SemesterValues>({
    resolver: zodResolver(semesterSchema),
    defaultValues: {
      yearLabel: semester.yearLabel,
      courses: semester.courses.map((c) => ({
        subjectId: c.subjectId,
        grade: c.grade,
        credits: c.credits,
        examSeason: c.examSeason ?? '',
        attemptNo: c.attemptNo,
      })),
    },
  });
  const { fields, append, remove: removeCourse } = useFieldArray({ control: form.control, name: 'courses' });
  const [confirming, setConfirming] = useState(false);
  const remove = useApiMutation(() => del(`/api/admin/results/${semester.id}`), {
    success: 'Semester deleted',
    invalidate: [['results', studentId]],
  });
  const liveCourses = useWatch({ control: form.control, name: 'courses' });
  const liveSpi = weightedAverage(liveCourses ?? []);
  const { errors } = form.formState;

  const save = useApiMutation(
    (values: SemesterValues) => put<SemesterResult>(`/api/admin/results/${semester.id}`, values),
    {
      success: `Semester ${semester.semNo} saved. SPI and CPI recalculated`,
      invalidate: [['results', studentId]],
    },
  );

  const subjectOptions = subjects.map((s) => ({ value: s.id, label: `${s.code} - ${s.name}` }));

  return (
    <Card>
      <CardHeader className="flex flex-row flex-wrap items-center justify-between gap-3 space-y-0">
        <CardTitle className="text-base">Semester {semester.semNo}</CardTitle>
        <dl className="flex gap-5 text-sm">
          <div>
            <dt className="text-xs text-muted-foreground">SPI</dt>
            <dd className="font-semibold tabular-nums">{liveSpi.toFixed(2)}</dd>
          </div>
          <div>
            <dt className="text-xs text-muted-foreground">CPI</dt>
            <dd className="font-semibold tabular-nums">{semester.cpi.toFixed(2)}</dd>
          </div>
          <div>
            <dt className="text-xs text-muted-foreground">Backlogs</dt>
            <dd className="font-semibold tabular-nums">{semester.backlogs}</dd>
          </div>
        </dl>
      </CardHeader>
      <CardContent>
        <form className="space-y-3" onSubmit={form.handleSubmit((v) => save.mutate(v))} noValidate>
          <Field label="Exam season" htmlFor={`year-${semester.id}`} error={errors.yearLabel?.message} className="max-w-52">
            <Input id={`year-${semester.id}`} {...form.register('yearLabel')} />
          </Field>

          <div className="overflow-x-auto">
            <div className="min-w-[680px] space-y-2">
              <div className="grid grid-cols-[1fr_90px_70px_120px_70px_40px] gap-2 text-xs font-medium text-muted-foreground">
                <span>Subject</span>
                <span>Grade</span>
                <span>Credits</span>
                <span>Season</span>
                <span>Attempt</span>
                <span />
              </div>
              {fields.map((field, index) => {
                const rowErrors = errors.courses?.[index];
                return (
                  <div key={field.id} className="grid grid-cols-[1fr_90px_70px_120px_70px_40px] items-start gap-2">
                    <div>
                      <Controller
                        control={form.control}
                        name={`courses.${index}.subjectId`}
                        render={({ field: f }) => (
                          <SimpleSelect
                            aria-label={`Subject, row ${index + 1}`}
                            value={f.value}
                            onChange={f.onChange}
                            options={subjectOptions}
                            placeholder="Pick a subject"
                          />
                        )}
                      />
                      {rowErrors?.subjectId ? (
                        <p className="mt-1 text-xs text-destructive">{rowErrors.subjectId.message}</p>
                      ) : null}
                    </div>
                    <Controller
                      control={form.control}
                      name={`courses.${index}.grade`}
                      render={({ field: f }) => (
                        <SimpleSelect
                          aria-label={`Grade, row ${index + 1}`}
                          value={f.value}
                          onChange={f.onChange}
                          options={GRADE_OPTIONS}
                        />
                      )}
                    />
                    <Input
                      aria-label={`Credits, row ${index + 1}`}
                      aria-invalid={Boolean(rowErrors?.credits)}
                      type="number"
                      min={0}
                      {...form.register(`courses.${index}.credits`, { valueAsNumber: true })}
                    />
                    <Input aria-label={`Season, row ${index + 1}`} {...form.register(`courses.${index}.examSeason`)} />
                    <Input
                      aria-label={`Attempt, row ${index + 1}`}
                      aria-invalid={Boolean(rowErrors?.attemptNo)}
                      type="number"
                      min={1}
                      {...form.register(`courses.${index}.attemptNo`, { valueAsNumber: true })}
                    />
                    <Button
                      type="button"
                      variant="ghost"
                      size="icon"
                      aria-label={`Remove row ${index + 1}`}
                      onClick={() => removeCourse(index)}
                    >
                      <Trash2 className="h-4 w-4" aria-hidden />
                    </Button>
                  </div>
                );
              })}
            </div>
          </div>
          {errors.courses?.root?.message ? (
            <p role="alert" className="text-xs font-medium text-destructive">
              {errors.courses.root.message}
            </p>
          ) : null}

          <div className="flex flex-wrap items-center justify-between gap-2 pt-1">
            <Button
              type="button"
              variant="outline"
              size="sm"
              onClick={() =>
                append({ subjectId: '', grade: 'A', credits: 4, examSeason: form.getValues('yearLabel'), attemptNo: 1 })
              }
            >
              <Plus className="mr-1 h-4 w-4" aria-hidden />
              Add course
            </Button>
            <div className="flex gap-2">
              <Button type="button" variant="outline" size="sm" className="text-destructive" onClick={() => setConfirming(true)}>
                <Trash2 className="mr-1 h-4 w-4" aria-hidden />
                Delete semester
              </Button>
              <SubmitButton loading={save.isPending} size="sm">
                Save semester
              </SubmitButton>
            </div>
          </div>
        </form>
        <ConfirmDialog
          open={confirming}
          onOpenChange={setConfirming}
          title={`Delete semester ${semester.semNo}?`}
          description="Its courses are removed and the CPI of later semesters is recalculated. This cannot be undone."
          loading={remove.isPending}
          onConfirm={() => remove.mutate()}
        />
      </CardContent>
    </Card>
  );
}

const newSemesterSchema = z.object({
  semNo: z.number({ invalid_type_error: 'Enter a semester' }).int().min(1).max(12),
  yearLabel: z.string().trim().min(1, 'Exam season is required'),
});
type NewSemesterValues = z.infer<typeof newSemesterSchema>;

function NewSemesterDialog({
  studentId,
  nextSem,
  onClose,
}: {
  studentId: string;
  nextSem: number;
  onClose: () => void;
}) {
  const form = useForm<NewSemesterValues>({
    resolver: zodResolver(newSemesterSchema),
    defaultValues: { semNo: nextSem, yearLabel: '' },
  });
  const { errors } = form.formState;
  const create = useApiMutation(
    (values: NewSemesterValues) => post<SemesterResult>('/api/admin/results', { ...values, studentId, courses: [] }),
    { success: 'Semester added', invalidate: [['results', studentId]], onSuccess: onClose },
  );
  return (
    <Dialog open onOpenChange={(open) => !open && onClose()}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Add semester result</DialogTitle>
        </DialogHeader>
        <form className="grid gap-4 sm:grid-cols-2" onSubmit={form.handleSubmit((v) => create.mutate(v))} noValidate>
          <Field label="Semester" htmlFor="semNo" error={errors.semNo?.message}>
            <Input id="semNo" type="number" min={1} max={12} {...form.register('semNo', { valueAsNumber: true })} />
          </Field>
          <Field label="Exam season" htmlFor="yearLabel" error={errors.yearLabel?.message}>
            <Input id="yearLabel" placeholder="Winter-2026" {...form.register('yearLabel')} />
          </Field>
          <DialogFooter className="sm:col-span-2">
            <SubmitButton loading={create.isPending}>Add semester</SubmitButton>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}

function StudentResults({ studentId }: { studentId: string }) {
  const [adding, setAdding] = useState(false);
  const results = useQuery({
    queryKey: ['results', studentId],
    queryFn: () => getAll<SemesterResult>('/api/admin/results', { studentId }),
  });
  const subjects = useQuery({
    queryKey: ['subjects', 'all'],
    queryFn: () => getAll<Subject>('/api/admin/subjects'),
  });

  if (results.isError) return <QueryError error={results.error} onRetry={() => void results.refetch()} />;
  if (subjects.isError) return <QueryError error={subjects.error} onRetry={() => void subjects.refetch()} />;
  if (results.isLoading || subjects.isLoading) return <Skeleton className="h-96 w-full" />;

  const semesters = results.data ?? [];
  const latest = semesters[0];
  const totalBacklogs = semesters.reduce((sum, s) => sum + s.backlogs, 0);
  const totalCourses = semesters.reduce((sum, s) => sum + s.courses.length, 0);

  return (
    <div className="space-y-6">
      <div className="flex justify-end">
        <Button onClick={() => setAdding(true)}>
          <Plus className="mr-2 h-4 w-4" aria-hidden />
          Add semester
        </Button>
      </div>

      {semesters.length === 0 ? (
        <EmptyState>No semester results yet.</EmptyState>
      ) : (
        <>
          <div className="grid gap-4 lg:grid-cols-3">
            <div className="grid grid-cols-3 gap-3 lg:grid-cols-1">
              {[
                { label: 'Current CPI', value: latest?.cpi.toFixed(2) ?? '-' },
                { label: 'Backlogs', value: totalBacklogs },
                { label: 'Subjects', value: totalCourses },
              ].map((stat) => (
                <Card key={stat.label}>
                  <CardContent className="p-4">
                    <div className="text-xs text-muted-foreground">{stat.label}</div>
                    <div className="text-2xl font-semibold tabular-nums">{stat.value}</div>
                  </CardContent>
                </Card>
              ))}
            </div>
            <Card className="lg:col-span-2">
              <CardHeader>
                <CardTitle className="text-base">CPI by semester</CardTitle>
              </CardHeader>
              <CardContent>
                <CpiTrend semesters={semesters} />
              </CardContent>
            </Card>
          </div>
          <p className="text-xs text-muted-foreground">
            SPI and CPI are credit-weighted and calculated when you save. Grades of P do not count towards them. The SPI
            shown updates as you edit. CPI updates after saving.
          </p>
          {semesters.map((s) => (
            // updatedAt in the key resets the form to the saved values after each save.
            <SemesterCard key={`${s.id}-${s.updatedAt}`} semester={s} subjects={subjects.data ?? []} studentId={studentId} />
          ))}
        </>
      )}

      {adding ? (
        <NewSemesterDialog
          studentId={studentId}
          nextSem={Math.min(12, (latest?.semNo ?? 0) + 1)}
          onClose={() => setAdding(false)}
        />
      ) : null}
    </div>
  );
}

export default function ResultsPage() {
  const [student, setStudent] = useState<StudentSummary | null>(null);
  return (
    <>
      <PageHeader title="Results" description="Edit grades per course. SPI and CPI are calculated automatically." />
      <StudentPicker value={student} onChange={setStudent} />
      <div className="mt-6">
        {student ? (
          <StudentResults key={student.id} studentId={student.id} />
        ) : (
          <EmptyState>Pick a student to view and edit their results.</EmptyState>
        )}
      </div>
    </>
  );
}
