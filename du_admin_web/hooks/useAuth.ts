'use client';

import { useQueryClient } from '@tanstack/react-query';
import { useRouter } from 'next/navigation';
import { useCallback, useMemo, useSyncExternalStore } from 'react';
import { logout as clearAuth } from '@/lib/auth';
import { getProfileCookie } from '@/lib/session';
import type { Admin } from '@/lib/types';

const noSubscription = () => () => undefined;

export function useAuth() {
  const router = useRouter();
  const queryClient = useQueryClient();
  // Null while server rendering, then the cookie value, without a hydration mismatch.
  const raw = useSyncExternalStore(noSubscription, getProfileCookie, () => null);
  const admin = useMemo<Admin | null>(() => {
    if (!raw) return null;
    try {
      return JSON.parse(raw) as Admin;
    } catch {
      return null;
    }
  }, [raw]);

  const logout = useCallback(() => {
    clearAuth();
    queryClient.clear();
    router.replace('/login');
    router.refresh();
  }, [queryClient, router]);

  return { admin, logout };
}
