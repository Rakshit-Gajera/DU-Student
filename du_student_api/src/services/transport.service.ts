import type { Prisma } from '@prisma/client';
import { notFound } from '../lib/http';
import { prisma } from '../lib/prisma';
import { pageMeta } from '../lib/validation';
import type { PageParams } from '../types';

export async function listTransport(params: PageParams, filters: { studentId?: string; search?: string }) {
  const where: Prisma.TransportWhereInput = {
    studentId: filters.studentId,
    ...(filters.search
      ? {
          OR: [
            { passNo: { contains: filters.search, mode: 'insensitive' } },
            { busRoute: { contains: filters.search, mode: 'insensitive' } },
            { student: { name: { contains: filters.search, mode: 'insensitive' } } },
          ],
        }
      : {}),
  };
  const [items, total] = await prisma.$transaction([
    prisma.transport.findMany({
      where,
      include: { student: { select: { id: true, name: true, enrollmentNo: true } } },
      orderBy: { validTo: 'desc' },
      skip: params.skip,
      take: params.limit,
    }),
    prisma.transport.count({ where }),
  ]);
  return { items, meta: pageMeta(params, total) };
}

export async function getTransport(id: string) {
  const transport = await prisma.transport.findUnique({ where: { id } });
  if (!transport) throw notFound('Bus pass');
  return transport;
}

export const createTransport = (data: Prisma.TransportUncheckedCreateInput) =>
  prisma.transport.create({ data });

export const updateTransport = (id: string, data: Prisma.TransportUncheckedUpdateInput) =>
  prisma.transport.update({ where: { id }, data });

export async function deleteTransport(id: string): Promise<void> {
  await prisma.transport.delete({ where: { id } });
}

// ------------------------------------------------------------ Fee receipts

export async function listReceipts(studentId: string, params: PageParams) {
  const where = { studentId };
  const [items, total] = await prisma.$transaction([
    prisma.busReceipt.findMany({ where, orderBy: { paidOn: 'desc' }, skip: params.skip, take: params.limit }),
    prisma.busReceipt.count({ where }),
  ]);
  return { items, meta: pageMeta(params, total) };
}

export const createReceipt = (data: Prisma.BusReceiptUncheckedCreateInput) => prisma.busReceipt.create({ data });

export const updateReceipt = (id: string, data: Prisma.BusReceiptUncheckedUpdateInput) =>
  prisma.busReceipt.update({ where: { id }, data });

export async function deleteReceipt(id: string): Promise<void> {
  await prisma.busReceipt.delete({ where: { id } });
}
