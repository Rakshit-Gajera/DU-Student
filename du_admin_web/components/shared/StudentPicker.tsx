'use client';

import { useQuery } from '@tanstack/react-query';
import { Loader2, Search, X } from 'lucide-react';
import { useId, useState } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { useDebounced } from '@/hooks/useDebounced';
import { getPage } from '@/lib/api';
import type { Student, StudentSummary } from '@/lib/types';

/** Search-as-you-type student selector. Searching on the server keeps it usable with many students. */
export function StudentPicker({
  value,
  onChange,
}: {
  value: StudentSummary | null;
  onChange: (student: StudentSummary | null) => void;
}) {
  const inputId = useId();
  const [search, setSearch] = useState('');
  const [open, setOpen] = useState(false);
  const debounced = useDebounced(search);

  const query = useQuery({
    queryKey: ['students', 'picker', debounced],
    queryFn: () => getPage<Student>('/api/admin/students', { search: debounced, limit: 8 }),
    enabled: open,
  });

  if (value) {
    return (
      <div className="flex max-w-md items-center justify-between gap-3 rounded-md border bg-card px-3 py-2">
        <div className="min-w-0 text-sm">
          <div className="truncate font-medium">{value.name}</div>
          <div className="truncate text-xs text-muted-foreground">
            {value.enrollmentNo}
            {value.classLabel ? ` · ${value.classLabel}` : ''}
          </div>
        </div>
        <Button type="button" variant="ghost" size="sm" onClick={() => onChange(null)}>
          <X className="mr-1 h-4 w-4" aria-hidden />
          Change
        </Button>
      </div>
    );
  }

  return (
    <div className="relative max-w-md">
      <label htmlFor={inputId} className="sr-only">
        Search for a student
      </label>
      <Search className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" aria-hidden />
      <Input
        id={inputId}
        className="pl-9"
        placeholder="Search a student by name, enrollment or roll no."
        value={search}
        autoComplete="off"
        onChange={(e) => setSearch(e.target.value)}
        onFocus={() => setOpen(true)}
        // Delayed so that a click on a result lands before the list closes.
        onBlur={() => setTimeout(() => setOpen(false), 150)}
      />
      {open ? (
        <div className="absolute z-20 mt-1 w-full overflow-hidden rounded-md border bg-popover shadow-md">
          {query.isLoading ? (
            <div className="flex items-center gap-2 p-3 text-sm text-muted-foreground">
              <Loader2 className="h-4 w-4 animate-spin" aria-hidden /> Searching
            </div>
          ) : query.data?.items.length ? (
            query.data.items.map((s) => (
              <button
                key={s.id}
                type="button"
                className="block w-full px-3 py-2 text-left text-sm hover:bg-accent focus:bg-accent focus:outline-none"
                onClick={() => {
                  onChange({
                    id: s.id,
                    name: s.name,
                    enrollmentNo: s.enrollmentNo,
                    classLabel: s.classLabel,
                  });
                  setSearch('');
                  setOpen(false);
                }}
              >
                <div className="font-medium">{s.name}</div>
                <div className="text-xs text-muted-foreground">
                  {s.enrollmentNo} · {s.classLabel} · {s.batch}
                </div>
              </button>
            ))
          ) : (
            <div className="p-3 text-sm text-muted-foreground">
              {query.isError ? 'Could not load students' : 'No students found'}
            </div>
          )}
        </div>
      ) : null}
    </div>
  );
}
