# du_admin_web

Admin website for the DU student portal. Built with Next.js 14 (App Router), TypeScript, Tailwind
CSS, shadcn/ui, TanStack Query, TanStack Table, React Hook Form, Zod and Recharts.

It talks to the API in `../du_student_api`, which must be running.

## Prerequisites

- Node.js 20+
- pnpm
- PostgreSQL 14+ and a running `du_student_api` (see its README)

## Setup

Set up the API first, including the migration and seed. Then:

```bash
pnpm install
```

```bash
cp .env.local.example .env.local
```

```bash
pnpm dev
```

Open `http://localhost:3000` and sign in with `admin` / `admin123`, the seeded demo login.

`NEXT_PUBLIC_API_URL` is the only variable the site reads. Because of the `NEXT_PUBLIC_` prefix,
it is built into the bundle, so rebuild after changing it. The API's `CORS_ORIGINS` must include
the site's address.

## Scripts

| Script | What it does |
|---|---|
| `pnpm dev` | Development server on port 3000 |
| `pnpm build` | Production build |
| `pnpm start` | Serves the production build |
| `pnpm lint` | ESLint |
| `pnpm typecheck` | Type-checks without emitting |

## Pages

| Route | What it does |
|---|---|
| `/login` | Sign in with email or username, and password |
| `/` | Stat cards: students, open grievances, pending certificates, subjects |
| `/students` | Table with search, batch and class filters, server-side sorting and paging. Create a student |
| `/students/[id]` | Edit the profile, photo, mentor and password. Delete the student (SUPERADMIN) |
| `/attendance` | Pick a student. Editable daily grid, past semester cards, course-wise table and chart |
| `/results` | Pick a student. CPI chart and per-semester grade editors. SPI and CPI are calculated automatically |
| `/lms` | Pick a student and subject. Presentations and lab manuals: upload a file or paste a link, edit, hide, delete. Create a subject |
| `/lms-results` | Pick a student. Add, edit and delete LMS test attempts |
| `/exam-schedule` | Pick a student. Add, edit and delete exams, IA and LMS tests |
| `/grievances` | Table with status filter and search. Click a row to edit or delete it. File one for a student |
| `/certificates` | Table with approve, reject, reopen, edit and delete. Add one for a student. Refreshes every 30 seconds |
| `/circulars` | Pick a student. List, and create or edit with a Markdown editor, publish date and pin. Delete |
| `/mentoring` | Pick a student. Assign or create a mentor. Add, edit and delete sessions |
| `/transport` | Table of bus passes with search. Create, edit and delete. Fee receipts per student |

## How it is put together

- `lib/api.ts`: the axios instance. Adds the JWT, and on a 401 refreshes once and retries. If that
  fails, it clears the session and redirects to `/login`.
- `lib/auth.ts`, `lib/session.ts`, `hooks/useAuth.ts`: login, logout and the session cookies.
- `middleware.ts`: sends signed-out visitors to `/login`. It only checks that a session cookie
  exists. The API verifies the token on every request.
- `hooks/useApiMutation.ts`: `useMutation` plus toasts and query invalidation. All writes use it.
- `components/data-table/DataTable.tsx`: the reusable TanStack Table wrapper.
- `components/shared/`: form field, select, student picker, file drop, status badge, and the
  confirm dialog.
- `lib/types.ts`: TypeScript types mirroring the API responses.

## Notes

- **Session handling:** this uses a simple JWT cookie approach rather than next-auth, so the
  `NEXTAUTH_*` values in `.env.local.example` are unused. The tokens are in JavaScript-readable,
  `SameSite=Strict` cookies, which means a cross-site scripting bug could read them. For stricter
  handling, proxy API calls through Next.js route handlers and use `HttpOnly` cookies.
- **Circular bodies are Markdown:** the editor has a formatting toolbar and preview, and stores
  Markdown because it renders safely and the Flutter app can display it with a Markdown package.
  Raw HTML is shown as text, never run.
