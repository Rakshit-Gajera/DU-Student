'use client';

import { CartesianGrid, Line, LineChart, XAxis, YAxis } from 'recharts';
import { ChartContainer, ChartTooltip, ChartTooltipContent, type ChartConfig } from '@/components/ui/chart';
import type { SemesterResult } from '@/lib/types';

const config = {
  cpi: { label: 'CPI', color: 'hsl(var(--chart-1))' },
} satisfies ChartConfig;

/** CPI after each semester, on the full 0-10 scale so small moves are not exaggerated. */
export function CpiTrend({ semesters }: { semesters: SemesterResult[] }) {
  const data = [...semesters]
    .sort((a, b) => a.semNo - b.semNo)
    .map((s) => ({ sem: `Sem ${s.semNo}`, cpi: s.cpi }));

  return (
    <ChartContainer config={config} className="aspect-auto h-56 w-full">
      <LineChart data={data} margin={{ left: 0, right: 16, top: 8, bottom: 0 }}>
        <CartesianGrid vertical={false} />
        <XAxis dataKey="sem" tickLine={false} axisLine={false} />
        <YAxis domain={[0, 10]} ticks={[0, 2, 4, 6, 8, 10]} width={28} tickLine={false} axisLine={false} />
        <ChartTooltip content={<ChartTooltipContent />} />
        <Line
          dataKey="cpi"
          type="linear"
          stroke="var(--color-cpi)"
          strokeWidth={2}
          isAnimationActive={false}
          dot={{ r: 4, fill: 'var(--color-cpi)', stroke: 'hsl(var(--background))', strokeWidth: 2 }}
          activeDot={{ r: 6 }}
        />
      </LineChart>
    </ChartContainer>
  );
}
