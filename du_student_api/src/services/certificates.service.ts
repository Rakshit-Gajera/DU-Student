import type { CertificateStatus, Prisma } from '@prisma/client';
import { notFound } from '../lib/http';
import { prisma } from '../lib/prisma';
import { pageMeta } from '../lib/validation';
import type { PageParams } from '../types';

const studentSummary = { select: { id: true, name: true, enrollmentNo: true, classLabel: true } };

export async function listCertificates(
  params: PageParams,
  filters: { status?: CertificateStatus; studentId?: string; search?: string },
) {
  const where: Prisma.CertificateRequestWhereInput = {
    status: filters.status,
    studentId: filters.studentId,
    ...(filters.search
      ? {
          OR: [
            { type: { contains: filters.search, mode: 'insensitive' } },
            { student: { name: { contains: filters.search, mode: 'insensitive' } } },
          ],
        }
      : {}),
  };
  const [items, total] = await prisma.$transaction([
    prisma.certificateRequest.findMany({
      where,
      include: { student: studentSummary },
      orderBy: { requestedAt: 'desc' },
      skip: params.skip,
      take: params.limit,
    }),
    prisma.certificateRequest.count({ where }),
  ]);
  return { items, meta: pageMeta(params, total) };
}

export async function getCertificate(id: string) {
  const request = await prisma.certificateRequest.findUnique({
    where: { id },
    include: { student: studentSummary },
  });
  if (!request) throw notFound('Certificate request');
  return request;
}

export async function deleteCertificate(id: string): Promise<void> {
  await prisma.certificateRequest.delete({ where: { id } });
}

export function decideCertificate(
  id: string,
  data: {
    status: CertificateStatus;
    remarks?: string | null;
    type?: string;
    purpose?: string | null;
    copies?: number;
    deliveryMode?: string | null;
    details?: string | null;
  },
  adminName: string,
) {
  const decided = data.status !== 'PENDING';
  return prisma.certificateRequest.update({
    where: { id },
    data: {
      ...data,
      decidedAt: decided ? new Date() : null,
      decidedBy: decided ? adminName : null,
    },
    include: { student: studentSummary },
  });
}

export const requestCertificate = (
  studentId: string,
  data: Omit<Prisma.CertificateRequestUncheckedCreateInput, 'studentId'>,
) => prisma.certificateRequest.create({ data: { ...data, studentId } });
