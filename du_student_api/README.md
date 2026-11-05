# du_student_api

REST API for the DU student app (Flutter) and the admin website (`../du_admin_web`).
Built with Node.js, TypeScript, Express, Prisma, PostgreSQL, Zod and JWT.

## Prerequisites

- Node.js 20+
- PostgreSQL 14+ (local, or a hosted one such as Supabase, Railway or Render)
- pnpm

The database must use UTF-8, because the demo data contains `₹`. If your server defaults to
another encoding, which can happen on Windows, create it explicitly:

```sql
CREATE DATABASE du_student_db ENCODING 'UTF8' TEMPLATE template0;
```

## Setup

```bash
pnpm install
```

```bash
cp .env.example .env
```

Set `DATABASE_URL` in `.env`, and replace both JWT secrets with long random values that differ from each other.

```bash
pnpm exec prisma migrate dev
```

```bash
pnpm exec prisma db seed
```

```bash
pnpm dev
```

The API listens on `http://localhost:4000`.

### Demo logins created by the seed

Change these before deploying anywhere public.

| Who | Login | Password |
|---|---|---|
| Admin (SUPERADMIN) | `admin` or `admin@example.com` | `admin123` |
| Student | enrollment no. `000` | `student123` |

The seed can be re-run. It upserts accounts and reference data and never resets an existing
password, but it **replaces everything belonging to the demo student**, including circulars, LMS
content and exams. Other students are not touched.

## Scripts

| Script | What it does |
|---|---|
| `pnpm dev` | Runs the API and restarts on changes |
| `pnpm build` | Compiles TypeScript to `dist/` |
| `pnpm start` | Runs the compiled build |
| `pnpm start:hosted` | Applies migrations, sets up the admin account, then runs the compiled build |
| `pnpm typecheck` | Type-checks without emitting |
| `pnpm prisma:generate` | Regenerates the Prisma client |
| `pnpm prisma:migrate` | Creates and applies a migration (development) |
| `pnpm prisma:deploy` | Applies existing migrations (production) |
| `pnpm prisma:seed` | Inserts the demo data |
| `pnpm prisma:studio` | Opens Prisma Studio |

## Environment

| Variable | Required | Notes |
|---|---|---|
| `DATABASE_URL` | yes | PostgreSQL connection string |
| `JWT_SECRET` | yes | At least 16 characters. Signs access tokens (15 minutes) |
| `JWT_REFRESH_SECRET` | yes | At least 16 characters, different from the above. Signs refresh tokens (students 10 years, admins 7 days) |
| `PORT` | no | Default `4000` |
| `CORS_ORIGINS` | no | Comma-separated. Default `http://localhost:3000` |
| `TRUST_PROXY` | no | Number of proxies in front of the API. Set to `1` on Railway or Render so rate limiting sees real client IPs |
| `UPLOAD_DIR` | no | Default `uploads` |
| `ADMIN_PASSWORD` | hosted | Used by `pnpm start:hosted` to create or update the admin account. At least 12 characters |
| `ADMIN_USERNAME`, `ADMIN_EMAIL` | no | Defaults `admin` and `admin@example.com` |

## API conventions

- Success: `{ "success": true, "data": ... }`. Lists add `"meta": { "page", "limit", "total", "totalPages" }`.
- Failure: `{ "success": false, "error": "..." }` with a matching HTTP status.
- Every list takes `?page=` and `?limit=` (default 20, maximum 100).
- Send `Authorization: Bearer <accessToken>`. When it expires (401), call `/api/auth/refresh`.
- Calendar dates are `YYYY-MM-DD`. Date-times are ISO 8601 with an offset.

## Routes

### Auth

| Method | Route | Body |
|---|---|---|
| POST | `/api/auth/login` | `{ identifier, password }` where identifier is the email, mobile or enrollment number |
| POST | `/api/auth/admin/login` | `{ identifier, password }` where identifier is the username or email |
| POST | `/api/auth/refresh` | `{ refreshToken }` |

### Student (Flutter app)

The student is always taken from the JWT. No route accepts a student id.

| Method | Route | Description |
|---|---|---|
| GET | `/api/student/profile` | Profile and mentor |
| GET | `/api/student/subjects` | Subjects of the current semester, to drive the LMS screen |
| GET | `/api/student/attendance` | Daily grid. Pages count dates. Slots are `P`, `A`, `A (e)`, `NA`, `-` |
| GET | `/api/student/attendance/summary` | Current semester totals, or `null` if none are recorded |
| GET | `/api/student/attendance/past-sems` | Past semester percentages |
| GET | `/api/student/attendance/courses` | Per-course attendance |
| GET | `/api/student/results` | CPI, backlogs, grade counts and semesters |
| GET | `/api/student/lms/:subjectId/presentations` | Visible presentations, with `seen` and `seenAt` |
| GET | `/api/student/lms/:subjectId/lab-manuals` | Visible lab manuals, with `seen` and `seenAt` |
| POST | `/api/student/lms/content/:id/seen` | Marks an item as seen |
| GET | `/api/student/mentoring` | Mentor, sessions and mentor history |
| GET | `/api/student/transport` | Bus passes |
| GET | `/api/student/transport/receipts` | Bus fee receipts |
| GET | `/api/student/lms-results` | LMS test attempts, newest semester first |
| GET | `/api/student/circulars` | Published circulars, pinned first. `content` is Markdown |
| GET, POST | `/api/student/grievances` | List own, or file a new one |
| GET, POST | `/api/student/certificates` | List own, or submit a new request |
| GET | `/api/student/exam-schedule` | Takes `?type=EXAM`, `IA` or `LMS_TEST` |

### Admin (admin website)

All of these require an admin JWT, enforced on the whole router.

| Method | Route | Description |
|---|---|---|
| GET | `/api/admin/stats` | Dashboard counts |
| POST | `/api/admin/uploads?kind=image` or `document` | Multipart field `file`. Returns `{ url }` |
| GET, POST | `/api/admin/students` | List (`search`, `batch`, `classLabel`, `sortBy`, `order`), create |
| GET | `/api/admin/students/filters` | Available batches and classes |
| GET, PUT | `/api/admin/students/:id` | Read, update |
| DELETE | `/api/admin/students/:id` | **SUPERADMIN only.** Deletes all of the student's data too |
| GET, POST | `/api/admin/subjects` | List, create |
| GET, PUT, DELETE | `/api/admin/subjects/:id` | Read, update, delete. Delete returns 409 while results use the subject |
| GET | `/api/admin/attendance?studentId=` | Daily grid |
| POST | `/api/admin/attendance/bulk` | `{ records: [{ studentId, date, slot, status }] }`. Status `null` clears the slot |
| GET, PUT | `/api/admin/attendance/summary` | Read by `studentId`, upsert the current semester totals |
| GET, PUT | `/api/admin/attendance/past-sems` | List by `studentId`, upsert |
| DELETE | `/api/admin/attendance/past-sems/:id` | Delete |
| GET, PUT | `/api/admin/attendance/courses` | List by `studentId`, upsert |
| DELETE | `/api/admin/attendance/courses/:id` | Delete |
| GET, POST | `/api/admin/results` | List by `studentId`, create a semester |
| GET, PUT, DELETE | `/api/admin/results/:id` | Read, update, delete. Recalculates SPI, CPI and backlogs |
| GET, POST | `/api/admin/lms-results` | List by `studentId`, add a test attempt |
| PUT, DELETE | `/api/admin/lms-results/:id` | Update, delete a test attempt |
| GET, POST | `/api/admin/lms` | List (`studentId`, `subjectId`, `type`), create |
| GET, PUT, DELETE | `/api/admin/lms/:id` | Read, update, delete. Delete also removes an uploaded file |
| GET, POST | `/api/admin/grievances` | List (`status`, `studentId`, `search`), file for a student |
| GET, PUT, DELETE | `/api/admin/grievances/:id` | Read, update, delete |
| GET, POST | `/api/admin/certificates` | List (`status`, `studentId`, `search`), request for a student |
| GET, PUT, DELETE | `/api/admin/certificates/:id` | Read, update or decide, delete |
| GET, POST | `/api/admin/circulars` | List by `studentId`, create |
| GET, PUT, DELETE | `/api/admin/circulars/:id` | Read, update, delete |
| GET, POST | `/api/admin/mentoring` | List (`studentId`), create a session |
| GET, PUT, DELETE | `/api/admin/mentoring/:id` | Read, update, delete a session |
| GET, POST | `/api/admin/mentoring/mentors` | List, create a mentor |
| PUT, DELETE | `/api/admin/mentoring/mentors/:id` | Update, delete a mentor |
| GET, POST | `/api/admin/mentoring/history` | List by `studentId`, add a mentor history row |
| PUT, DELETE | `/api/admin/mentoring/history/:id` | Update, delete a mentor history row |
| GET, POST | `/api/admin/transport/receipts` | List by `studentId`, add a receipt |
| PUT, DELETE | `/api/admin/transport/receipts/:id` | Update, delete a receipt |
| GET, POST | `/api/admin/transport` | List (`studentId`, `search`), create a pass |
| GET, PUT, DELETE | `/api/admin/transport/:id` | Read, update, delete a pass |
| GET, POST | `/api/admin/exam-schedule` | List by `studentId` (and `type`, `semester`), create |
| GET, PUT, DELETE | `/api/admin/exam-schedule/:id` | Read, update, delete |

## How SPI and CPI are calculated

Both are credit-weighted averages, implemented in `src/lib/grades.ts`.

| Grade | A++ | A+ | A | B+ | B | C+ | C | D | F, AB | P |
|---|---|---|---|---|---|---|---|---|---|---|
| Points | 10 | 9 | 8 | 7 | 6 | 5 | 4 | 3 | 0 | not counted |

`F` and `AB` count as backlogs. **Confirm this scale against the university's scheme.** It is an
assumption, not something the app specified. Likewise, the seeded credits are inferred: the app
has no credits, so they are values that reproduce its SPI and CPI exactly.

## Security notes

- Passwords use bcrypt with cost 12. Login routes are rate limited, on failed attempts.
- A student stays logged in until they log out. Changing their password on the admin site ends all
  of their sessions, within 15 minutes for a device that is in use. Admin sessions last 7 days, and a
  password change does not end them.
- Uploads are checked by declared type, by file content and by size (images 5 MB, documents 25 MB),
  and saved under generated names.
- Files under `/uploads` are **public** to anyone with the URL. Names are random, but there is no
  login check, so do not upload anything confidential.
- Uploads are stored on local disk, which is wiped on each deploy on hosts such as Railway and
  Render. Attach a persistent volume, or move `src/services/uploads.service.ts` to Supabase Storage or S3.
- Use HTTPS in production. The API does not terminate TLS itself.
