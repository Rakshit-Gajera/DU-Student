import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';

export function cn(...inputs: ClassValue[]): string {
  return twMerge(clsx(inputs));
}

/** "2026-10-09" or an ISO timestamp, shown as "09 Oct 2026". Date-only values stay on their calendar day. */
export function formatDate(value: string | null | undefined): string {
  if (!value) return '-';
  return new Date(value).toLocaleDateString('en-GB', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
    timeZone: 'UTC',
  });
}

export function formatDateTime(value: string | null | undefined): string {
  if (!value) return '-';
  return new Date(value).toLocaleString('en-GB', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
    hour12: true,
  });
}

/** The first 10 characters of an API date, for a date input. */
export const toDateInput = (value: string | null | undefined): string => value?.slice(0, 10) ?? '';

/** ISO timestamp to the local "YYYY-MM-DDTHH:mm" a datetime-local input expects. */
export function toDateTimeInput(value: string | null | undefined): string {
  if (!value) return '';
  const d = new Date(value);
  const offsetMs = d.getTimezoneOffset() * 60_000;
  return new Date(d.getTime() - offsetMs).toISOString().slice(0, 16);
}

/** Local datetime-local value to the ISO timestamp the API expects. */
export const fromDateTimeInput = (value: string): string => new Date(value).toISOString();
