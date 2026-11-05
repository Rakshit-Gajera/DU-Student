import { NextResponse, type NextRequest } from 'next/server';

// Literal rather than imported from lib/session, which pulls js-cookie into the edge bundle.
const REFRESH_COOKIE = 'du_admin_refresh';

/**
 * Keeps signed-out visitors off the dashboard pages. This is a navigation guard,
 * not the security boundary: the API verifies the JWT on every admin request.
 */
export function middleware(request: NextRequest): NextResponse {
  const hasSession = request.cookies.has(REFRESH_COOKIE);
  const isLogin = request.nextUrl.pathname === '/login';

  if (!hasSession && !isLogin) return NextResponse.redirect(new URL('/login', request.url));
  if (hasSession && isLogin) return NextResponse.redirect(new URL('/', request.url));
  return NextResponse.next();
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico).*)'],
};
