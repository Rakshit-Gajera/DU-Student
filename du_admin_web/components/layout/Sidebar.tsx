'use client';

import {
  Award,
  Bus,
  CalendarCheck,
  CalendarClock,
  ClipboardCheck,
  GraduationCap,
  LayoutDashboard,
  LibraryBig,
  type LucideIcon,
  MessageSquareWarning,
  Newspaper,
  UserRoundCheck,
  Users,
} from 'lucide-react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { cn } from '@/lib/utils';

export const NAV_ITEMS: readonly { href: string; label: string; icon: LucideIcon }[] = [
  { href: '/', label: 'Overview', icon: LayoutDashboard },
  { href: '/students', label: 'Students', icon: Users },
  { href: '/attendance', label: 'Attendance', icon: CalendarCheck },
  { href: '/results', label: 'Results', icon: GraduationCap },
  { href: '/lms', label: 'LMS', icon: LibraryBig },
  { href: '/lms-results', label: 'LMS results', icon: ClipboardCheck },
  { href: '/exam-schedule', label: 'Exam schedule', icon: CalendarClock },
  { href: '/grievances', label: 'Grievances', icon: MessageSquareWarning },
  { href: '/certificates', label: 'Certificates', icon: Award },
  { href: '/circulars', label: 'Circulars', icon: Newspaper },
  { href: '/mentoring', label: 'Mentoring', icon: UserRoundCheck },
  { href: '/transport', label: 'Transport', icon: Bus },
];

export function isNavActive(pathname: string, href: string): boolean {
  return href === '/' ? pathname === '/' : pathname === href || pathname.startsWith(`${href}/`);
}

export function SidebarContent({ onNavigate }: { onNavigate?: () => void }) {
  const pathname = usePathname();
  return (
    <div className="flex h-full flex-col bg-slate-900 text-slate-200">
      <div className="flex h-14 items-center gap-2 border-b border-slate-800 px-5 font-semibold text-white">
        <GraduationCap className="h-5 w-5" aria-hidden />
        DU Admin
      </div>
      <nav aria-label="Main" className="flex-1 space-y-1 overflow-y-auto p-3">
        {NAV_ITEMS.map(({ href, label, icon: Icon }) => {
          const active = isNavActive(pathname, href);
          return (
            <Link
              key={href}
              href={href}
              onClick={onNavigate}
              aria-current={active ? 'page' : undefined}
              className={cn(
                'flex items-center gap-3 rounded-md px-3 py-2 text-sm font-medium transition-colors',
                'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-400',
                active ? 'bg-slate-700 text-white' : 'text-slate-300 hover:bg-slate-800 hover:text-white',
              )}
            >
              <Icon className="h-4 w-4 shrink-0" aria-hidden />
              {label}
            </Link>
          );
        })}
      </nav>
    </div>
  );
}

export function Sidebar() {
  return (
    <aside className="fixed inset-y-0 left-0 hidden w-60 lg:block">
      <SidebarContent />
    </aside>
  );
}
