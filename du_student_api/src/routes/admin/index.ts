import { Router } from 'express';
import multer from 'multer';
import * as misc from '../../controllers/admin/misc.controller';
import { verifyAdminJWT } from '../../middlewares/adminGuard';
import { MAX_UPLOAD_BYTES } from '../../services/uploads.service';
import { attendanceRouter } from './attendance';
import { certificatesRouter } from './certificates';
import { circularsRouter } from './circulars';
import { examScheduleRouter } from './examSchedule';
import { grievancesRouter } from './grievances';
import { lmsRouter } from './lms';
import { lmsResultsRouter } from './lmsResults';
import { mentoringRouter } from './mentoring';
import { resultsRouter } from './results';
import { studentsRouter } from './students';
import { subjectsRouter } from './subjects';
import { transportRouter } from './transport';

const uploadParser = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: MAX_UPLOAD_BYTES, files: 1 },
});

export const adminRouter = Router();

// Applied to the whole router, so a new route below cannot be left unprotected.
adminRouter.use(verifyAdminJWT);

adminRouter.get('/stats', misc.stats);
adminRouter.post('/uploads', uploadParser.single('file'), misc.upload);
adminRouter.use('/students', studentsRouter);
adminRouter.use('/subjects', subjectsRouter);
adminRouter.use('/attendance', attendanceRouter);
adminRouter.use('/results', resultsRouter);
adminRouter.use('/lms', lmsRouter);
adminRouter.use('/lms-results', lmsResultsRouter);
adminRouter.use('/grievances', grievancesRouter);
adminRouter.use('/certificates', certificatesRouter);
adminRouter.use('/circulars', circularsRouter);
adminRouter.use('/mentoring', mentoringRouter);
adminRouter.use('/transport', transportRouter);
adminRouter.use('/exam-schedule', examScheduleRouter);
