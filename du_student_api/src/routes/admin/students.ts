import { Router } from 'express';
import * as students from '../../controllers/admin/students.controller';
import { requireRole } from '../../middlewares/adminGuard';

export const studentsRouter = Router();

studentsRouter.get('/', students.list);
studentsRouter.post('/', students.create);
studentsRouter.get('/filters', students.filterOptions);
studentsRouter.get('/:id', students.get);
studentsRouter.put('/:id', students.update);
// Deleting a student also deletes their attendance, results and requests.
studentsRouter.delete('/:id', requireRole('SUPERADMIN'), students.remove);
