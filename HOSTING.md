# Hosting DU Student on Render, Neon and UptimeRobot

This puts the database, API and admin website online, so your laptop can stay off. The student app
stays on phones and just points at the new API address.

| Part | Service | Cost |
|---|---|---|
| Database | [Neon](https://neon.com) Postgres | Free plan |
| API | [Render](https://render.com) web service | Free plan |
| Admin website | Render web service | Free plan |
| Keep-awake monitor | [UptimeRobot](https://uptimerobot.com) | Free plan |

**Limits of the free plans, and what they mean for you:**

- **Render free:** the service sleeps after 15 minutes without traffic. UptimeRobot prevents that. Free
  services get 750 hours a month, which covers one service running all month.
- **Render free and uploads:** the disk is erased every time the service restarts or redeploys. Uploaded
  photos and LMS files will disappear. Read "Uploads" below before using real student data.
- **Neon free:** the database pauses after about 5 minutes without use. UptimeRobot keeps it awake. Neon
  also limits how many compute hours a month you get, and a database that never pauses uses many of them.
  Check the usage shown in the Neon console after a few days. If the hours run out, the database stays
  paused until the next month.

Everything below is done in a web browser, except the final APK build.

---

## 1. Put the code on GitHub (private)

The repository contains your name and photo, so keep it private.

```bash
git init -b main
```

```bash
git add .
```

```bash
git status
```

Check the list. It must **not** include `du_student_api/.env`, `du_admin_web/.env.local` or
`test/goldens/reference/`. They are ignored already, so stop if one appears.

```bash
git commit -m "First version"
```

```bash
gh repo create du-student-app --private --source . --push
```

---

## 2. Create the database on Neon

1. Sign up at [neon.com](https://neon.com) with GitHub.
2. Click **New project**. Name it `du-student`, choose the region closest to your students, and create it.
3. On the project dashboard, click **Connect**. Copy the connection string. It looks like:

   ```
   postgresql://USER:PASSWORD@ep-xxxx.REGION.aws.neon.tech/neondb?sslmode=require
   ```

   Use the **direct** string, not the one marked "pooled". Keep it secret. It's your `DATABASE_URL`.

Neon creates the tables for you later, when the API starts.

---

## 3. Create the API on Render

1. Sign up at [render.com](https://render.com) with GitHub.
2. Click **New** > **Blueprint**, pick the `du-student-app` repository, and click **Apply**.
   Render reads `render.yaml` and creates two services: `du-student-api` and `du-admin-web`.
   It asks you for the values marked as secret. Enter them as shown in steps 3 to 5 below.

If the blueprint doesn't appear, create the service by hand: **New** > **Web Service**, pick the repository, then set:

| Setting | Value |
|---|---|
| Root directory | `du_student_api` |
| Build command | `pnpm install --frozen-lockfile && pnpm build` |
| Start command | `pnpm start:hosted` |
| Health check path | `/health` |
| Instance type | Free |

3. Create the two secrets. Run this twice in a terminal and keep both results:

   ```bash
   node -e "console.log(require('crypto').randomBytes(48).toString('hex'))"
   ```

4. In the API service, open **Environment** and set:

   | Key | Value |
   |---|---|
   | `DATABASE_URL` | the Neon connection string from step 2 |
   | `JWT_SECRET` | first secret from step 3 |
   | `JWT_REFRESH_SECRET` | second secret from step 3 |
   | `ADMIN_PASSWORD` | a password only you know, at least 12 characters |
   | `ADMIN_EMAIL` | your email address |
   | `CORS_ORIGINS` | the admin address, filled in after step 5 |
   | `NODE_ENV` | `production` |
   | `TRUST_PROXY` | `1` |

   **Keep `JWT_REFRESH_SECRET` the same from now on.** Changing it logs every student out.

5. Click **Save**, then **Manual deploy** > **Deploy latest commit**. Wait for the logs to say the
   server is listening.
6. Copy the API address from the top of the service page. It looks like
   `https://du-student-api.onrender.com`. This is your **API address**.
7. Open `your API address/health`. You should see `"status":"ok"`.
8. Open `your API address/health/db`. You should see `"database":"ok"`. If you see an error, the
   `DATABASE_URL` is wrong.

---

## 4. Create the admin website on Render

1. If you used the blueprint, the `du-admin-web` service already exists. Otherwise: **New** > **Web
   Service**, pick the repository, and set:

   | Setting | Value |
   |---|---|
   | Root directory | `du_admin_web` |
   | Build command | `pnpm install --frozen-lockfile && pnpm build` |
   | Start command | `pnpm start` |
   | Instance type | Free |

2. In **Environment**, set:

   | Key | Value |
   |---|---|
   | `NEXT_PUBLIC_API_URL` | your API address, with no `/` at the end |

   This value is built into the site, so after changing it click **Manual deploy**.

3. Deploy. Copy the admin address, such as `https://du-admin-web.onrender.com`.
4. Go back to the API service, set `CORS_ORIGINS` to the admin address with no `/`, and save. It
   redeploys by itself.
5. Open the admin address and sign in as `admin` with your `ADMIN_PASSWORD`.

---

## 5. Keep both services and the database awake (UptimeRobot)

1. Sign up at [uptimerobot.com](https://uptimerobot.com).
2. Click **+ New monitor** and set:

   | Field | Value |
   |---|---|
   | Monitor type | HTTP(s) |
   | Friendly name | `DU API and database` |
   | URL | `your API address/health/db` |
   | Monitoring interval | 5 minutes |

   This URL queries the database, so each check keeps Neon awake as well as Render.

3. Add a second monitor for the admin site:
   - Monitor type: HTTP(s)
   - URL: your admin address
   - Interval: 5 minutes

Both monitors send you an email if a service goes down, which is useful to have.

---

## 6. Add your data

The hosted database starts with only the admin account. Choose one:

**Start fresh (for real use):** on the admin website, open **LMS** > **New subject** to add the subjects,
then **Students** > **New student** for each person.

**Or copy the demo student to try it out.** In a PowerShell window, in the `du_student_api` folder, run
this with the Neon connection string:

```powershell
$env:DATABASE_URL = 'paste the Neon connection string'; pnpm exec prisma db seed; Remove-Item Env:DATABASE_URL
```

The demo student's password is `student123`. Change it on the **Students** page, or delete that student,
before you give anyone the address.

---

## 7. Point the student app at the hosted API

From the project folder, with your API address:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://your-api-address
```

With your phone connected by USB:

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

Or send `build\app\outputs\flutter-apk\app-release.apk` to other Android phones and install it. It then
works on any network, including mobile data, with your laptop off.

---

## 8. Check everything works with your laptop off

Turn off the laptop's Wi-Fi, then check:

- [ ] `your API address/health/db` shows `"database":"ok"` in a phone browser.
- [ ] The app logs in on mobile data, using a student account.
- [ ] Close the app fully and reopen it. You're still logged in.
- [ ] On the admin website, from another device, change something for a student. Reopen that screen in the app.
- [ ] Leave the app alone for 30 minutes, then open it. It still works.

---

## Uploads (read before real use)

Photos and LMS files are saved to the API's own disk. On Render's free plan that disk is erased on every
restart and redeploy, so uploads will disappear.

Two ways to fix this:

1. **Render paid disk:** upgrade the API to a paid instance and attach a persistent disk. Set `UPLOAD_DIR`
   to the disk's mount path. Check current prices on Render's pricing page.
2. **Cloudflare R2 storage:** free for small amounts. This needs a code change so uploads go to R2
   instead of the disk. I can make that change if you want to go this way.

Until one of these is done, don't rely on uploads. Text data (students, marks, circulars) is unaffected,
because it lives in Neon.

---

## Releasing changes

Commit and push to GitHub. Render redeploys the API and admin site automatically when the `main` branch
changes.

```bash
git add .
```

```bash
git commit -m "What changed"
```

```bash
git push
```

Changes to the app itself need a new APK (step 7).

## Backups

Neon keeps history for a short time on the free plan. For a copy you control, run this on your computer
(needs PostgreSQL's `pg_dump`, installed with PostgreSQL 17):

```powershell
& 'C:\Program Files\PostgreSQL\17\bin\pg_dump.exe' 'paste the Neon connection string' -Fc -f du_backup.dump
```

Do this regularly, and before any big change.

## Before real students use it

- Don't leave the demo `student123` password in use. Give each student their own.
- Bus passes show the SAMPLE watermark. Real passes would need that decision revisited.
- Forgot Password only tells the student to contact the administration. An admin sets a new password on
  the student's page, which also logs that student out everywhere.
- Publishing the app on Google Play needs a proper signing key and developer account. Sending the APK directly does not.

## If something goes wrong

| What you see | Likely cause |
|---|---|
| Health check fails during deploy | `DATABASE_URL` is wrong, or a secret is missing. Check the logs |
| `/health/db` says "Database unreachable" | Wrong `DATABASE_URL`, or Neon is paused. Open the Neon console and check |
| "ADMIN_PASSWORD must be at least 12 characters" | Use a longer password |
| Admin site can't reach the server, browser console mentions CORS | `CORS_ORIGINS` doesn't exactly match the admin address, or has a `/` at the end |
| Admin site still calls `localhost` | `NEXT_PUBLIC_API_URL` was set after the build. Click **Manual deploy** on the admin service |
| App says "Could not reach the server" | The APK was built with the wrong address. Repeat step 7 |
| Uploads gone after a deploy | Expected on the free plan. See "Uploads" above |
| First request after a long pause is slow | The service or database was asleep. UptimeRobot should prevent this. Check its monitors |
