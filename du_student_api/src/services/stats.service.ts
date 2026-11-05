import { prisma } from '../lib/prisma';

export async function getDashboardStats() {
  const [totalStudents, openGrievances, pendingCertificates, totalSubjects] = await prisma.$transaction([
    prisma.student.count(),
    prisma.grievance.count({ where: { status: { not: 'RESOLVED' } } }),
    prisma.certificateRequest.count({ where: { status: 'PENDING' } }),
    prisma.subject.count(),
  ]);
  return { totalStudents, openGrievances, pendingCertificates, totalSubjects };
}
