import { z } from 'zod';
import { asyncHandler, ok } from '../lib/http';
import * as authService from '../services/auth.service';

const studentLoginBody = z.object({
  identifier: z.string().trim().min(1, 'Email, mobile or enrollment number is required'),
  password: z.string().min(1, 'Password is required').max(200),
});

const adminLoginBody = z.object({
  identifier: z.string().trim().min(1, 'Email or username is required'),
  password: z.string().min(1, 'Password is required').max(200),
});

const refreshBody = z.object({ refreshToken: z.string().min(1, 'refreshToken is required') });

export const studentLogin = asyncHandler(async (req, res) => {
  const { identifier, password } = studentLoginBody.parse(req.body);
  ok(res, await authService.loginStudent(identifier, password));
});

export const adminLogin = asyncHandler(async (req, res) => {
  const { identifier, password } = adminLoginBody.parse(req.body);
  ok(res, await authService.loginAdmin(identifier, password));
});

export const refresh = asyncHandler(async (req, res) => {
  const { refreshToken } = refreshBody.parse(req.body);
  ok(res, await authService.refreshTokens(refreshToken));
});
