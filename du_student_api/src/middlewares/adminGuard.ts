import type { AdminRole } from '@prisma/client';
import type { RequestHandler } from 'express';
import { HttpError } from '../lib/http';
import { bearerToken, verifyAccessToken } from '../lib/tokens';

export const verifyAdminJWT: RequestHandler = (req, _res, next) => {
  const token = bearerToken(req.headers.authorization);
  const payload = token ? verifyAccessToken(token) : null;
  if (!payload || payload.kind !== 'admin') {
    next(new HttpError(401, 'Invalid or expired token'));
    return;
  }
  req.admin = { id: payload.sub, username: payload.username, role: payload.role };
  next();
};

/** Use after verifyAdminJWT. */
export function requireRole(...roles: AdminRole[]): RequestHandler {
  return (req, _res, next) => {
    if (!req.admin || !roles.includes(req.admin.role)) {
      next(new HttpError(403, 'You do not have permission to do this'));
      return;
    }
    next();
  };
}
