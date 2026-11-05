import type { RequestHandler } from 'express';
import { HttpError } from '../lib/http';
import { bearerToken, verifyAccessToken } from '../lib/tokens';

export const verifyStudentJWT: RequestHandler = (req, _res, next) => {
  const token = bearerToken(req.headers.authorization);
  const payload = token ? verifyAccessToken(token) : null;
  if (!payload || payload.kind !== 'student') {
    next(new HttpError(401, 'Invalid or expired token'));
    return;
  }
  req.student = { id: payload.sub, enrollmentNo: payload.enrollmentNo };
  next();
};
