# DU Student

To put this online so your computer doesn't have to stay on, see [HOSTING.md](HOSTING.md).

| Folder | What it is |
|---|---|
| `lib/` | Student app (Flutter). Reads everything below from the API |
| `du_student_api/` | REST API (Express, Prisma, PostgreSQL, JWT). See its README |
| `du_admin_web/` | Admin website (Next.js). See its README |

## Run everything on this computer

You need Flutter, Node.js 20+, pnpm and PostgreSQL. On this computer PostgreSQL 17 is installed as a
Windows service that starts with the PC, and `du_student_api\.env` holds its connection string.

Install the dependencies once:

```bash
pnpm --dir du_student_api install
```

```bash
pnpm --dir du_admin_web install
```

Start the API and the admin site:

```bash
powershell -ExecutionPolicy Bypass -File tool\run_stack.ps1
```

Run the student app:

```bash
flutter run -d windows
```

| What | Where | Demo login |
|---|---|---|
| Student app | `flutter run` | enrollment no. `000`, password `student123` |
| Admin site | http://localhost:3000 | `admin` / `admin123` |
| API | http://localhost:4000 | |

Stop them, or restore the demo student's data:

```bash
powershell -ExecutionPolicy Bypass -File tool\run_stack.ps1 -Stop
```

```bash
powershell -ExecutionPolicy Bypass -File tool\run_stack.ps1 -Seed
```

Logs are in `.stack-logs/`.

### Other devices

The app calls `http://localhost:4000`, or `http://10.0.2.2:4000` on the Android emulator. For a real
phone, or a deployed API, pass the address:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:4000
```

## Managing students

Everything belongs to one student, so the admin site changes each person separately: pick the student
at the top of the page, then add, edit or delete. A student logs in with their enrollment number, email
or mobile number. Create students, set their passwords and delete them on the Students page.

Circulars, LMS content and exam schedules are per student too, so a notice for everyone has to be added
to each student. Subjects (the course list for a semester) and mentors are shared: a mentor edit shows
for every student assigned to that mentor.

## How a change reaches the student

The admin saves, and the API writes to the database. The app reads again each time a screen opens.
The dashboard stays open under other screens, so pull it down to refresh it.

## Tests

All checks against the real stack. This re-seeds the demo data:

```bash
powershell -ExecutionPolicy Bypass -File tool\run_e2e.ps1
```

| Test | What it covers | Needs the stack |
|---|---|---|
| `test/screens_golden_test.dart` | Every screen, pixel for pixel | no |
| `test/screen_states_test.dart` | Skeleton, error card and retry on each screen; login and logout | no |
| `test/forms_test.dart` | Grievance and certificate forms, search, filter, opening LMS files | no |
| `test/api_client_test.dart` | Silent token refresh and session expiry | no |
| `test/live_api_test.dart` | The real client against the API; screens drawn from the API must match the goldens | set `LIVE_API_URL` |
| `integration_test/live_app_test.dart` | The real Windows app, used through its UI | yes |
| `integration_test/admin_to_app_test.dart` | Admin changes appear in the app; app requests reach the admin and come back answered | yes |
| `integration_test/stay_logged_in_*_test.dart` | Log in, close the app, reopen it: still logged in until logout | yes |
| `integration_test/two_students_test.dart` | Two students see only their own data; add, edit and delete affect one person; login by email and mobile | yes |

After changing the seed, refresh the data the goldens are drawn from with
`node tool/capture_fixture.mjs`, then review and update the goldens that changed.

## Not connected yet

These have no API behind them, so they show fixed demo content to every student:

- Time table, academic calendar, upcoming activities and mentor timetable
- Data change requests and feedback
- Fees, hostel, notifications and the other menu items with no screen

Also not built: Forgot Password only tells the student to contact the administration (a real reset
needs an email or SMS service), changing a password in the app, attaching files to grievances, the search box in
picker sheets, and showing a result after picking an exam on the Result tab.
