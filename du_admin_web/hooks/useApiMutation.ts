'use client';

import { useMutation, useQueryClient, type QueryKey } from '@tanstack/react-query';
import { useToast } from '@/hooks/use-toast';
import { apiErrorMessage } from '@/lib/api';

interface Options<TData, TVariables> {
  /** Toast shown on success. A function can word it from the result. */
  success: string | ((data: TData, variables: TVariables) => string);
  /** Query keys to refetch after success. */
  invalidate?: QueryKey[];
  onSuccess?: (data: TData, variables: TVariables) => void;
}

/** A TanStack mutation that toasts on success and failure and refreshes the affected queries. */
export function useApiMutation<TData, TVariables = void>(
  mutationFn: (variables: TVariables) => Promise<TData>,
  { success, invalidate = [], onSuccess }: Options<TData, TVariables>,
) {
  const queryClient = useQueryClient();
  const { toast } = useToast();

  return useMutation<TData, unknown, TVariables>({
    mutationFn,
    onSuccess: async (data, variables) => {
      await Promise.all(invalidate.map((queryKey) => queryClient.invalidateQueries({ queryKey })));
      toast({ title: typeof success === 'function' ? success(data, variables) : success });
      onSuccess?.(data, variables);
    },
    onError: (error) => {
      toast({ variant: 'destructive', title: 'Could not save', description: apiErrorMessage(error) });
    },
  });
}
