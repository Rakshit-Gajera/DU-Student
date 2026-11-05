import { z } from 'zod';
import { HttpError, asyncHandler, ok } from '../../lib/http';
import { getDashboardStats } from '../../services/stats.service';
import { saveUpload } from '../../services/uploads.service';

export const stats = asyncHandler(async (_req, res) => {
  ok(res, await getDashboardStats());
});

const uploadQuery = z.object({ kind: z.enum(['image', 'document']) });

export const upload = asyncHandler(async (req, res) => {
  const { kind } = uploadQuery.parse(req.query);
  if (!req.file) throw new HttpError(400, 'Attach the file in a multipart field named "file"');
  ok(res, await saveUpload(kind, req.file), 201);
});
