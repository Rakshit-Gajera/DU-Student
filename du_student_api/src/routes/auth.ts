import { Router } from 'express';
import rateLimit from 'express-rate-limit';
import * as auth from '../controllers/auth.controller';

const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 20,
  skipSuccessfulRequests: true,
  standardHeaders: 'draft-7',
  legacyHeaders: false,
  message: { success: false, error: 'Too many failed login attempts, try again later' },
});

export const authRouter = Router();

authRouter.post('/login', loginLimiter, auth.studentLogin);
authRouter.post('/admin/login', loginLimiter, auth.adminLogin);
authRouter.post('/refresh', loginLimiter, auth.refresh);
