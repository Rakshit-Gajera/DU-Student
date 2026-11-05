// Rewrites test/fixtures/seed.json from a running, freshly seeded API:
//   node tool/capture_fixture.mjs
import { writeFileSync } from 'node:fs';

const base = process.env.LIVE_API_URL ?? 'http://localhost:4000';

const login = await fetch(`${base}/api/auth/login`, {
  method: 'POST',
  headers: { 'content-type': 'application/json' },
  body: JSON.stringify({ identifier: '000', password: 'student123' }),
});
const { accessToken } = (await login.json()).data;

const get = async (path) => {
  const res = await fetch(`${base}/api/student/${path}`, { headers: { Authorization: `Bearer ${accessToken}` } });
  if (!res.ok) throw new Error(`${path}: ${res.status}`);
  return (await res.json()).data;
};

const subjects = await get('subjects');
const daa = subjects[0].id;
const paths = {
  profile: 'profile',
  attendance: 'attendance?limit=100',
  attendanceSummary: 'attendance/summary',
  pastSems: 'attendance/past-sems',
  courses: 'attendance/courses',
  results: 'results',
  presentations: `lms/${daa}/presentations`,
  labManuals: `lms/${daa}/lab-manuals`,
  mentoring: 'mentoring',
  transport: 'transport',
  busReceipts: 'transport/receipts',
  lmsResults: 'lms-results?limit=100',
  circulars: 'circulars',
  grievances: 'grievances',
  certificates: 'certificates',
  examEXAM: 'exam-schedule?type=EXAM',
  examIA: 'exam-schedule?type=IA',
  examLMS_TEST: 'exam-schedule?type=LMS_TEST',
};

const out = { subjects };
for (const [key, path] of Object.entries(paths)) out[key] = await get(path);
// Golden tests draw the bundled photo instead of using the network.
out.profile.photoUrl = null;

writeFileSync(new URL('../test/fixtures/seed.json', import.meta.url), `${JSON.stringify(out, null, 1)}\n`);
console.log('Wrote test/fixtures/seed.json');
