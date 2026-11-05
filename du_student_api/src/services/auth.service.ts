import bcrypt from 'bcrypt';
import { config } from '../config';
import { HttpError } from '../lib/http';
import { prisma } from '../lib/prisma';
import { signAccessToken, signRefreshToken, verifyRefreshToken } from '../lib/tokens';
import type { AccessTokenPayload } from '../types';

export const hashPassword = (password: string): Promise<string> =>
  bcrypt.hash(password, config.bcryptCost);

// Compared against when the account does not exist, so a missing account takes
// as long as a wrong password and login cannot be used to find valid usernames.
const DUMMY_HASH = bcrypt.hashSync('not-a-real-password', config.bcryptCost);
const invalidCredentials = (): HttpError => new HttpError(401, 'Invalid credentials');

interface TokenPair {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}

function issueTokens(payload: AccessTokenPayload, tokenVersion?: number): TokenPair {
  return {
    accessToken: signAccessToken(payload),
    refreshToken: signRefreshToken({ type: 'refresh', kind: payload.kind, sub: payload.sub, ver: tokenVersion }),
    expiresIn: config.accessTokenTtlSeconds,
  };
}

/**
 * `identifier` is an email, mobile number or enrollment number. Email and mobile are
 * not unique (siblings can share a mobile), so the password decides between matches.
 */
export async function loginStudent(identifier: string, password: string) {
  const matches = await prisma.student.findMany({
    where: {
      OR: [
        { enrollmentNo: identifier },
        { mobile: identifier },
        { email: { equals: identifier, mode: 'insensitive' } },
      ],
    },
  });
  for (const student of matches) {
    if (await bcrypt.compare(password, student.passwordHash)) {
      const { enrollmentNo } = student;
      return {
        ...issueTokens({ type: 'access', kind: 'student', sub: student.id, enrollmentNo }, student.tokenVersion),
        student: { id: student.id, name: student.name, enrollmentNo },
      };
    }
  }
  if (matches.length === 0) await bcrypt.compare(password, DUMMY_HASH);
  throw invalidCredentials();
}

/** `identifier` is the username or the email of the admin. */
export async function loginAdmin(identifier: string, password: string) {
  const admin = await prisma.admin.findFirst({
    where: { OR: [{ username: identifier }, { email: identifier.toLowerCase() }] },
  });
  const valid = await bcrypt.compare(password, admin?.passwordHash ?? DUMMY_HASH);
  if (!admin || !valid) throw invalidCredentials();
  return {
    ...issueTokens({
      type: 'access',
      kind: 'admin',
      sub: admin.id,
      username: admin.username,
      role: admin.role,
    }),
    admin: {
      id: admin.id,
      username: admin.username,
      email: admin.email,
      name: admin.name,
      role: admin.role,
    },
  };
}

export async function refreshTokens(refreshToken: string): Promise<TokenPair> {
  const payload = verifyRefreshToken(refreshToken);
  if (!payload) throw new HttpError(401, 'Invalid or expired refresh token');

  // Re-read the account so a deleted user or changed role takes effect here.
  if (payload.kind === 'student') {
    const student = await prisma.student.findUnique({ where: { id: payload.sub } });
    if (!student || (payload.ver ?? 0) !== student.tokenVersion) {
      throw new HttpError(401, 'Invalid or expired refresh token');
    }
    return issueTokens(
      {
        type: 'access',
        kind: 'student',
        sub: student.id,
        enrollmentNo: student.enrollmentNo,
      },
      student.tokenVersion,
    );
  }
  const admin = await prisma.admin.findUnique({ where: { id: payload.sub } });
  if (!admin) throw new HttpError(401, 'Invalid or expired refresh token');
  return issueTokens({
    type: 'access',
    kind: 'admin',
    sub: admin.id,
    username: admin.username,
    role: admin.role,
  });
}
