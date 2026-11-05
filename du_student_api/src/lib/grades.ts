/** Grade points on the 10-point scale. A null value means the grade is not counted in SPI/CPI. */
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
const FAILING_GRADES = new Set(['F', 'AB']);

export interface GradedCourse {
  grade: string;
  credits: number;
}

export const round2 = (value: number): number => Math.round(value * 100) / 100;

/** Credit-weighted grade point average, ignoring non-counted grades such as P. */
export function weightedAverage(courses: readonly GradedCourse[]): number {
  let points = 0;
  let credits = 0;
  for (const { grade, credits: c } of courses) {
    const gp = GRADE_POINTS[grade];
    if (gp === null || gp === undefined) continue;
    points += gp * c;
    credits += c;
  }
  return credits === 0 ? 0 : round2(points / credits);
}

export const countBacklogs = (courses: readonly GradedCourse[]): number =>
  courses.filter((c) => FAILING_GRADES.has(c.grade)).length;

export const isPassed = (grade: string): boolean => !FAILING_GRADES.has(grade);
