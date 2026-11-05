import cors from 'cors';
import express from 'express';
import rateLimit from 'express-rate-limit';
import helmet from 'helmet';
import { config } from './config';
import { prisma } from './lib/prisma';
import { errorHandler, notFoundHandler } from './middlewares/errorHandler';
import { adminRouter } from './routes/admin';
import { authRouter } from './routes/auth';
import { studentRouter } from './routes/student';

export function createApp(): express.Express {
  const app = express();

  app.set('trust proxy', config.trustProxy);
  // Uploaded photos and PDFs are embedded by the admin site, which is another origin.
  app.use(helmet({ crossOriginResourcePolicy: { policy: 'cross-origin' } }));
  app.use(cors({ origin: config.corsOrigins }));
  app.use(express.json({ limit: '1mb' }));
  app.use(
    rateLimit({
      windowMs: 60 * 1000,
      limit: 300,
      standardHeaders: 'draft-7',
      legacyHeaders: false,
      message: { success: false, error: 'Too many requests, please slow down' },
    }),
  );

  app.get('/health', (_req, res) => {
    res.json({ success: true, data: { status: 'ok' } });
  });
  // Queries the database, so an uptime monitor pinging it also keeps a sleeping database awake.
  app.get('/health/db', async (_req, res) => {
    try {
      await prisma.$queryRaw`SELECT 1`;
      res.json({ success: true, data: { status: 'ok', database: 'ok' } });
    } catch {
      res.status(503).json({ success: false, error: 'Database unreachable' });
    }
  });
  app.use(
    '/uploads',
    express.static(config.uploadDir, { index: false, dotfiles: 'ignore', maxAge: '1d' }),
  );

  app.use('/api/auth', authRouter);
  app.use('/api/student', studentRouter);
  app.use('/api/admin', adminRouter);

  app.use(notFoundHandler);
  app.use(errorHandler);
  return app;
}
