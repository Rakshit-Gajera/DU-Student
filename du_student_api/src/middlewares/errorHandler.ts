import { Prisma } from '@prisma/client';
import type { ErrorRequestHandler, RequestHandler } from 'express';
import { MulterError } from 'multer';
import { ZodError } from 'zod';
import { HttpError } from '../lib/http';

export const notFoundHandler: RequestHandler = (req, res) => {
  res.status(404).json({ success: false, error: `No route for ${req.method} ${req.path}` });
};

function describeZodError(err: ZodError): string {
  return err.issues
    .map((i) => (i.path.length ? `${i.path.join('.')}: ${i.message}` : i.message))
    .join('; ');
}

export const errorHandler: ErrorRequestHandler = (err: unknown, _req, res, _next) => {
  if (err instanceof HttpError) {
    res.status(err.status).json({ success: false, error: err.message });
    return;
  }
  if (err instanceof ZodError) {
    res.status(400).json({ success: false, error: describeZodError(err) });
    return;
  }
  if (err instanceof MulterError) {
    const status = err.code === 'LIMIT_FILE_SIZE' ? 413 : 400;
    res.status(status).json({ success: false, error: err.message });
    return;
  }
  if (err instanceof Prisma.PrismaClientKnownRequestError) {
    if (err.code === 'P2002') {
      res.status(409).json({ success: false, error: 'A record with these unique values already exists' });
      return;
    }
    if (err.code === 'P2025') {
      res.status(404).json({ success: false, error: 'Record not found' });
      return;
    }
    if (err.code === 'P2003') {
      res.status(409).json({ success: false, error: 'This refers to a record that does not exist or is still in use' });
      return;
    }
  }
  // body-parser errors (malformed JSON, payload too large) carry their own status.
  if (err instanceof Error && 'status' in err && typeof err.status === 'number' && err.status < 500) {
    res.status(err.status).json({ success: false, error: err.message });
    return;
  }
  console.error(err);
  res.status(500).json({ success: false, error: 'Internal server error' });
};
