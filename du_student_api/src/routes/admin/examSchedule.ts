import { Router } from 'express';
import * as exams from '../../controllers/admin/examSchedule.controller';

export const examScheduleRouter = Router();

examScheduleRouter.get('/', exams.list);
examScheduleRouter.post('/', exams.create);
examScheduleRouter.get('/:id', exams.get);
examScheduleRouter.put('/:id', exams.update);
examScheduleRouter.delete('/:id', exams.remove);
