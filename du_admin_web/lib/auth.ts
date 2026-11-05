import { post } from './api';
import { clearSession, setProfile, setTokens } from './session';
import type { Admin, LoginResult } from './types';

export async function login(identifier: string, password: string): Promise<Admin> {
  const result = await post<LoginResult>('/api/auth/admin/login', { identifier, password });
  setTokens(result.accessToken, result.refreshToken);
  setProfile(result.admin);
  return result.admin;
}

export function logout(): void {
  clearSession();
}
