import type { NextFunction, Request, RequestHandler, Response } from 'express';
import type { AdminPrincipal, PageMeta, Paged, StudentPrincipal } from '../types';

export class HttpError extends Error {
  constructor(
    public readonly status: number,
    message: string,
  ) {
    super(message);
    this.name = 'HttpError';
  }
}

export const notFound = (what: string): HttpError => new HttpError(404, `${what} not found`);

export function ok<T>(res: Response, data: T, status = 200): void {
  res.status(status).json({ success: true, data });
}

export function okPage<T>(res: Response, page: Paged<T>): void {
  res.status(200).json({ success: true, data: page.items, meta: page.meta });
}

/** For responses that wrap a paginated list in a larger object. */
export function okWithMeta<T>(res: Response, data: T, meta: PageMeta): void {
  res.status(200).json({ success: true, data, meta });
}

/** Express 4 does not catch rejected promises, so async handlers go through this. */
export function asyncHandler(
  fn: (req: Request, res: Response, next: NextFunction) => Promise<void>,
): RequestHandler {
  return (req, res, next) => {
    fn(req, res, next).catch(next);
  };
}

/** The student id always comes from the verified JWT, never from the request. */
export function currentStudent(req: Request): StudentPrincipal {
  if (!req.student) throw new HttpError(401, 'Authentication required');
  return req.student;
}

export function currentAdmin(req: Request): AdminPrincipal {
  if (!req.admin) throw new HttpError(401, 'Authentication required');
  return req.admin;
}
