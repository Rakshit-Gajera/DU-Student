import { Router } from 'express';
import * as lmsResults from '../../controllers/admin/lmsResults.controller';

export const lmsResultsRouter = Router();

lmsResultsRouter.get('/', lmsResults.list);
lmsResultsRouter.post('/', lmsResults.create);
lmsResultsRouter.put('/:id', lmsResults.update);
lmsResultsRouter.delete('/:id', lmsResults.remove);
