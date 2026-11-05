import type { AdminRole } from '@prisma/client';

export interface StudentPrincipal {
  id: string;
  enrollmentNo: string;
}

export interface AdminPrincipal {
  id: string;
  username: string;
  role: AdminRole;
}

export type AccessTokenPayload =
  | { type: 'access'; kind: 'student'; sub: string; enrollmentNo: string }
  | { type: 'access'; kind: 'admin'; sub: string; username: string; role: AdminRole };

export interface RefreshTokenPayload {
  type: 'refresh';
  kind: 'student' | 'admin';
  sub: string;
  /** The student's tokenVersion when this was issued. Tokens from before it existed count as 0. */
  ver?: number;
}

export interface PageParams {
  page: number;
  limit: number;
  skip: number;
}

export interface PageMeta {
  page: number;
  limit: number;
  total: number;
  totalPages: number;
}

export interface Paged<T> {
  items: T[];
  meta: PageMeta;
}

declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  namespace Express {
    interface Request {
      student?: StudentPrincipal;
      admin?: AdminPrincipal;
    }
  }
}
