import { Router } from 'express';
import * as results from '../../controllers/admin/results.controller';

export const resultsRouter = Router();

resultsRouter.get('/', results.list);
resultsRouter.post('/', results.create);
resultsRouter.get('/:id', results.get);
resultsRouter.put('/:id', results.update);
resultsRouter.delete('/:id', results.remove);
