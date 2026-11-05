import { Router } from 'express';
import * as subjects from '../../controllers/admin/subjects.controller';

export const subjectsRouter = Router();

subjectsRouter.get('/', subjects.list);
subjectsRouter.post('/', subjects.create);
subjectsRouter.get('/:id', subjects.get);
subjectsRouter.put('/:id', subjects.update);
subjectsRouter.delete('/:id', subjects.remove);
