import Cookies from 'js-cookie';
import type { Admin } from './types';

/** Also read by middleware.ts, which only checks that a session exists. The API verifies tokens. */
export const REFRESH_COOKIE = 'du_admin_refresh';
const ACCESS_COOKIE = 'du_admin_access';
const PROFILE_COOKIE = 'du_admin_profile';

const SESSION_DAYS = 7;

const options = (): Cookies.CookieAttributes => ({
  expires: SESSION_DAYS,
  sameSite: 'strict',
  secure: typeof window !== 'undefined' && window.location.protocol === 'https:',
  path: '/',
});

export const getAccessToken = (): string | undefined => Cookies.get(ACCESS_COOKIE);
export const getRefreshToken = (): string | undefined => Cookies.get(REFRESH_COOKIE);
export const getProfileCookie = (): string | null => Cookies.get(PROFILE_COOKIE) ?? null;

export function setTokens(accessToken: string, refreshToken: string): void {
  Cookies.set(ACCESS_COOKIE, accessToken, options());
  Cookies.set(REFRESH_COOKIE, refreshToken, options());
}

export function setProfile(admin: Admin): void {
  Cookies.set(PROFILE_COOKIE, JSON.stringify(admin), options());
}

export function clearSession(): void {
  for (const name of [ACCESS_COOKIE, REFRESH_COOKIE, PROFILE_COOKIE]) {
    Cookies.remove(name, { path: '/' });
  }
}
