import { Router } from 'express';
import * as lms from '../../controllers/admin/lms.controller';

export const lmsRouter = Router();

lmsRouter.get('/', lms.list);
lmsRouter.post('/', lms.create);
lmsRouter.get('/:id', lms.get);
lmsRouter.put('/:id', lms.update);
lmsRouter.delete('/:id', lms.remove);
