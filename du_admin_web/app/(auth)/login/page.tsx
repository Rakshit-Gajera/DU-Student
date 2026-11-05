'use client';

import { zodResolver } from '@hookform/resolvers/zod';
import { useMutation } from '@tanstack/react-query';
import { GraduationCap } from 'lucide-react';
import { useRouter } from 'next/navigation';
import { useForm } from 'react-hook-form';
import { z } from 'zod';
import { Field, SubmitButton } from '@/components/shared/common';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { useToast } from '@/hooks/use-toast';
import { apiErrorMessage } from '@/lib/api';
import { login } from '@/lib/auth';

const schema = z.object({
  identifier: z.string().trim().min(1, 'Enter your email or username'),
  password: z.string().min(1, 'Enter your password'),
});
type Values = z.infer<typeof schema>;

export default function LoginPage() {
  const router = useRouter();
  const { toast } = useToast();
  const form = useForm<Values>({
    resolver: zodResolver(schema),
    defaultValues: { identifier: '', password: '' },
  });

  const mutation = useMutation({
    mutationFn: (values: Values) => login(values.identifier, values.password),
    onSuccess: (admin) => {
      toast({ title: `Welcome back, ${admin.name}` });
      router.replace('/');
      router.refresh();
    },
    onError: (error) => {
      toast({ variant: 'destructive', title: 'Could not sign in', description: apiErrorMessage(error) });
    },
  });

  return (
    <main className="flex min-h-screen items-center justify-center bg-slate-900 p-4">
      <Card className="w-full max-w-sm">
        <CardHeader>
          <GraduationCap className="mb-2 h-7 w-7" aria-hidden />
          <CardTitle>DU Admin</CardTitle>
          <CardDescription>Sign in to manage the student portal.</CardDescription>
        </CardHeader>
        <CardContent>
          <form className="space-y-4" onSubmit={form.handleSubmit((v) => mutation.mutate(v))} noValidate>
            <Field label="Email or username" htmlFor="identifier" error={form.formState.errors.identifier?.message}>
              <Input id="identifier" autoComplete="username" autoFocus {...form.register('identifier')} />
            </Field>
            <Field label="Password" htmlFor="password" error={form.formState.errors.password?.message}>
              <Input id="password" type="password" autoComplete="current-password" {...form.register('password')} />
            </Field>
            <SubmitButton loading={mutation.isPending} className="w-full">
              Sign in
            </SubmitButton>
          </form>
        </CardContent>
      </Card>
    </main>
  );
}
