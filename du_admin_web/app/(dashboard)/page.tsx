'use client';

import { useQuery } from '@tanstack/react-query';
import { Award, BookOpen, type LucideIcon, MessageSquareWarning, Users } from 'lucide-react';
import Link from 'next/link';
import { PageHeader, QueryError } from '@/components/shared/common';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';
import { getOne } from '@/lib/api';
import type { DashboardStats } from '@/lib/types';

const CARDS: readonly {
  key: keyof DashboardStats;
  label: string;
  href: string;
  icon: LucideIcon;
}[] = [
  { key: 'totalStudents', label: 'Total students', href: '/students', icon: Users },
  { key: 'openGrievances', label: 'Open grievances', href: '/grievances', icon: MessageSquareWarning },
  { key: 'pendingCertificates', label: 'Pending certificates', href: '/certificates', icon: Award },
  { key: 'totalSubjects', label: 'Total subjects', href: '/lms', icon: BookOpen },
];

export default function OverviewPage() {
  const stats = useQuery({
    queryKey: ['stats'],
    queryFn: () => getOne<DashboardStats>('/api/admin/stats'),
  });

  return (
    <>
      <PageHeader title="Overview" description="What needs attention across the student portal." />
      {stats.isError ? <QueryError error={stats.error} onRetry={() => void stats.refetch()} /> : null}
      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        {CARDS.map(({ key, label, href, icon: Icon }) => (
          <Link
            key={key}
            href={href}
            className="rounded-lg focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
          >
            <Card className="h-full transition-shadow hover:shadow-md">
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium text-muted-foreground">{label}</CardTitle>
                <Icon className="h-4 w-4 text-muted-foreground" aria-hidden />
              </CardHeader>
              <CardContent>
                {stats.isLoading ? (
                  <Skeleton className="h-8 w-16" />
                ) : (
                  <div className="text-3xl font-semibold tabular-nums">{stats.data?.[key] ?? '-'}</div>
                )}
              </CardContent>
            </Card>
          </Link>
        ))}
      </div>
    </>
  );
}
