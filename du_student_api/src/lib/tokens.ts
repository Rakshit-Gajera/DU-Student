import jwt from 'jsonwebtoken';
import { config } from '../config';
import type { AccessTokenPayload, RefreshTokenPayload } from '../types';

const ALGORITHM = 'HS256';

export function signAccessToken(payload: AccessTokenPayload): string {
  return jwt.sign(payload, config.jwtSecret, {
    algorithm: ALGORITHM,
    expiresIn: config.accessTokenTtlSeconds,
  });
}

export function signRefreshToken(payload: RefreshTokenPayload): string {
  return jwt.sign(payload, config.jwtRefreshSecret, {
    algorithm: ALGORITHM,
    expiresIn: payload.kind === 'student' ? config.studentRefreshTokenTtlSeconds : config.adminRefreshTokenTtlSeconds,
  });
}

export function verifyAccessToken(token: string): AccessTokenPayload | null {
  try {
    const decoded = jwt.verify(token, config.jwtSecret, { algorithms: [ALGORITHM] });
    if (typeof decoded === 'string' || decoded.type !== 'access') return null;
    return decoded as unknown as AccessTokenPayload;
  } catch {
    return null;
  }
}

export function verifyRefreshToken(token: string): RefreshTokenPayload | null {
  try {
    const decoded = jwt.verify(token, config.jwtRefreshSecret, { algorithms: [ALGORITHM] });
    if (typeof decoded === 'string' || decoded.type !== 'refresh') return null;
    return decoded as unknown as RefreshTokenPayload;
  } catch {
    return null;
  }
}

export function bearerToken(header: string | undefined): string | null {
  if (!header) return null;
  const [scheme, token] = header.split(' ');
  return scheme?.toLowerCase() === 'bearer' && token ? token : null;
}
