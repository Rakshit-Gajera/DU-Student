import { Router } from 'express';
import * as circulars from '../../controllers/admin/circulars.controller';

export const circularsRouter = Router();

circularsRouter.get('/', circulars.list);
circularsRouter.post('/', circulars.create);
circularsRouter.get('/:id', circulars.get);
circularsRouter.put('/:id', circulars.update);
circularsRouter.delete('/:id', circulars.remove);
