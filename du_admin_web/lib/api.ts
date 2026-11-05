import axios, { AxiosError, type AxiosRequestConfig, type InternalAxiosRequestConfig } from 'axios';
import { clearSession, getAccessToken, getRefreshToken, setTokens } from './session';
import type { PageMeta, Paged, UploadResult } from './types';

export const API_URL = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:4000';

export const api = axios.create({ baseURL: API_URL });

interface Envelope<T> {
  success: boolean;
  data: T;
  meta?: PageMeta;
  error?: string;
}

api.interceptors.request.use((config) => {
  const token = getAccessToken();
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

// Several requests can hit an expired token at once. They all wait on one refresh.
let refreshing: Promise<string> | null = null;

async function refreshAccessToken(): Promise<string> {
  const refreshToken = getRefreshToken();
  if (!refreshToken) throw new Error('No refresh token');
  const { data } = await axios.post<Envelope<{ accessToken: string; refreshToken: string }>>(
    `${API_URL}/api/auth/refresh`,
    { refreshToken },
  );
  setTokens(data.data.accessToken, data.data.refreshToken);
  return data.data.accessToken;
}

type RetriableConfig = InternalAxiosRequestConfig & { retried?: boolean };

api.interceptors.response.use(undefined, async (error: AxiosError) => {
  const config = error.config as RetriableConfig | undefined;
  const isLogin = config?.url?.startsWith('/api/auth/');
  if (error.response?.status !== 401 || !config || config.retried || isLogin) {
    throw error;
  }
  config.retried = true;
  try {
    refreshing ??= refreshAccessToken().finally(() => {
      refreshing = null;
    });
    config.headers.Authorization = `Bearer ${await refreshing}`;
    return await api.request(config);
  } catch {
    clearSession();
    if (typeof window !== 'undefined') window.location.assign('/login');
    throw error;
  }
});

/** The message to show the user for a failed request. */
export function apiErrorMessage(error: unknown): string {
  if (axios.isAxiosError<{ error?: string }>(error)) {
    if (error.response?.data?.error) return error.response.data.error;
    if (!error.response) return 'Could not reach the server. Is the API running?';
  }
  return error instanceof Error ? error.message : 'Something went wrong';
}

type Params = AxiosRequestConfig['params'];

export async function getOne<T>(url: string, params?: Params): Promise<T> {
  const { data } = await api.get<Envelope<T>>(url, { params });
  return data.data;
}

export async function getPage<T>(url: string, params?: Params): Promise<Paged<T>> {
  const { data } = await api.get<Envelope<T[]>>(url, { params });
  return {
    items: data.data,
    meta: data.meta ?? { page: 1, limit: data.data.length, total: data.data.length, totalPages: 1 },
  };
}

/** Every row of a paginated list, for pickers that must not silently cut off at one page. */
export async function getAll<T>(url: string, params?: Record<string, unknown>): Promise<T[]> {
  const items: T[] = [];
  let page = 1;
  let totalPages = 1;
  do {
    const result = await getPage<T>(url, { ...params, page, limit: 100 });
    items.push(...result.items);
    totalPages = result.meta.totalPages;
    page += 1;
  } while (page <= totalPages);
  return items;
}

export async function post<T>(url: string, body?: unknown): Promise<T> {
  const { data } = await api.post<Envelope<T>>(url, body);
  return data.data;
}

export async function put<T>(url: string, body: unknown): Promise<T> {
  const { data } = await api.put<Envelope<T>>(url, body);
  return data.data;
}

export async function del(url: string): Promise<void> {
  await api.delete(url);
}

export function uploadFile(kind: 'image' | 'document', file: File): Promise<UploadResult> {
  const form = new FormData();
  form.append('file', file);
  return post<UploadResult>(`/api/admin/uploads?kind=${kind}`, form);
}

/** Uploads are stored as "/uploads/x.pdf", served by the API rather than this site. */
export function assetUrl(url: string | null | undefined): string | undefined {
  if (!url) return undefined;
  return url.startsWith('/uploads/') ? `${API_URL}${url}` : url;
}
