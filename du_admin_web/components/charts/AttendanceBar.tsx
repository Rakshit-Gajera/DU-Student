'use client';

import { Bar, BarChart, CartesianGrid, XAxis, YAxis } from 'recharts';
import { ChartContainer, ChartTooltip, ChartTooltipContent, type ChartConfig } from '@/components/ui/chart';
import type { CourseAttendance } from '@/lib/types';

const config = {
  percent: { label: 'Attendance %', color: 'hsl(var(--chart-1))' },
} satisfies ChartConfig;

const ROW_HEIGHT = 30;

/**
 * "2301CS401 - Database Management System - II - Theory" becomes "2301CS401 · Theory".
 * Plain truncation would cut off Theory/Practical, the one thing that tells paired rows
 * apart. The tooltip and the table below the chart show the full name.
 */
function shorten(label: string): string {
  const parts = label.split(' - ');
  return parts.length >= 3 ? `${parts[0]} · ${parts[parts.length - 1]}` : label;
}

/** Attendance % per course. Horizontal bars, because course names are long. */
export function AttendanceBar({ courses }: { courses: CourseAttendance[] }) {
  return (
    <ChartContainer
      config={config}
      className="aspect-auto w-full"
      style={{ height: courses.length * ROW_HEIGHT + 40 }}
    >
      <BarChart data={courses} layout="vertical" margin={{ left: 8, right: 16 }} barCategoryGap={8}>
        <CartesianGrid horizontal={false} />
        <XAxis
          type="number"
          domain={[0, 100]}
          tickFormatter={(v: number) => `${v}%`}
          tickLine={false}
          axisLine={false}
        />
        <YAxis
          type="category"
          dataKey="course"
          width={170}
          interval={0}
          tickLine={false}
          axisLine={false}
          tickFormatter={shorten}
        />
        <ChartTooltip cursor={false} content={<ChartTooltipContent />} />
        <Bar dataKey="percent" fill="var(--color-percent)" radius={[0, 4, 4, 0]} maxBarSize={14} isAnimationActive={false} />
      </BarChart>
    </ChartContainer>
  );
}
