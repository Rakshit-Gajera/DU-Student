import { Router } from 'express';
import * as grievances from '../../controllers/admin/grievances.controller';

export const grievancesRouter = Router();

grievancesRouter.get('/', grievances.list);
grievancesRouter.post('/', grievances.create);
grievancesRouter.get('/:id', grievances.get);
grievancesRouter.put('/:id', grievances.update);
grievancesRouter.delete('/:id', grievances.remove);
