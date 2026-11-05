/**
 * Grade points, matching du_student_api/src/lib/grades.ts. The API computes the
 * stored SPI and CPI. This copy only powers the live preview while editing.
 */
export const GRADE_POINTS: Readonly<Record<string, number | null>> = {
  'A++': 10,
  'A+': 9,
  A: 8,
  'B+': 7,
  B: 6,
  'C+': 5,
  C: 4,
  D: 3,
  P: null,
  F: 0,
  AB: 0,
};

export const GRADES = Object.keys(GRADE_POINTS);

export function weightedAverage(courses: readonly { grade: string; credits: number }[]): number {
  let points = 0;
  let credits = 0;
  for (const { grade, credits: c } of courses) {
    const gp = GRADE_POINTS[grade];
    if (gp === null || gp === undefined || !Number.isFinite(c)) continue;
    points += gp * c;
    credits += c;
  }
  return credits === 0 ? 0 : Math.round((points / credits) * 100) / 100;
}
