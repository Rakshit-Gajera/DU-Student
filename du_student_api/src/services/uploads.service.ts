import { randomUUID } from 'node:crypto';
import { mkdir, unlink, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { config } from '../config';
import { HttpError } from '../lib/http';

export type UploadKind = 'image' | 'document';

const MB = 1024 * 1024;
export const MAX_UPLOAD_BYTES = 25 * MB;
const MAX_BYTES: Record<UploadKind, number> = { image: 5 * MB, document: MAX_UPLOAD_BYTES };

const startsWith = (buf: Buffer, ...bytes: number[]): boolean =>
  bytes.every((b, i) => buf[i] === b);
const isZip = (buf: Buffer): boolean => startsWith(buf, 0x50, 0x4b, 0x03, 0x04);
const isOle = (buf: Buffer): boolean => startsWith(buf, 0xd0, 0xcf, 0x11, 0xe0);

interface AllowedType {
  ext: string;
  kind: UploadKind;
  matches: (buf: Buffer) => boolean;
}

const ALLOWED: Readonly<Record<string, AllowedType>> = {
  'image/jpeg': { ext: 'jpg', kind: 'image', matches: (b) => startsWith(b, 0xff, 0xd8, 0xff) },
  'image/png': { ext: 'png', kind: 'image', matches: (b) => startsWith(b, 0x89, 0x50, 0x4e, 0x47) },
  'image/webp': {
    ext: 'webp',
    kind: 'image',
    matches: (b) => b.subarray(0, 4).toString() === 'RIFF' && b.subarray(8, 12).toString() === 'WEBP',
  },
  'application/pdf': { ext: 'pdf', kind: 'document', matches: (b) => b.subarray(0, 5).toString() === '%PDF-' },
  'application/vnd.ms-powerpoint': { ext: 'ppt', kind: 'document', matches: isOle },
  'application/vnd.openxmlformats-officedocument.presentationml.presentation': {
    ext: 'pptx',
    kind: 'document',
    matches: isZip,
  },
  'application/msword': { ext: 'doc', kind: 'document', matches: isOle },
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document': {
    ext: 'docx',
    kind: 'document',
    matches: isZip,
  },
};

/**
 * The file name is generated and the content must match the declared type, so a
 * client cannot store HTML or SVG here and have it served from the API origin.
 */
export async function saveUpload(
  kind: UploadKind,
  file: { mimetype: string; size: number; buffer: Buffer },
): Promise<{ url: string; mimeType: string; size: number }> {
  const type = ALLOWED[file.mimetype];
  if (!type || type.kind !== kind) {
    throw new HttpError(415, `File type ${file.mimetype} is not allowed for a ${kind} upload`);
  }
  if (!type.matches(file.buffer)) {
    throw new HttpError(415, `File content does not match the declared type ${file.mimetype}`);
  }
  if (file.size > MAX_BYTES[kind]) {
    throw new HttpError(413, `A ${kind} upload can be at most ${MAX_BYTES[kind] / MB} MB`);
  }
  await mkdir(config.uploadDir, { recursive: true });
  const name = `${randomUUID()}.${type.ext}`;
  await writeFile(path.join(config.uploadDir, name), file.buffer);
  return { url: `/uploads/${name}`, mimeType: file.mimetype, size: file.size };
}

/** Best effort: a file that is already gone must not fail the delete that called this. */
export async function removeUploadedFile(url: string | null): Promise<void> {
  if (!url?.startsWith('/uploads/')) return;
  try {
    await unlink(path.join(config.uploadDir, path.basename(url)));
  } catch (err) {
    console.warn(`Could not remove uploaded file ${url}:`, err);
  }
}
