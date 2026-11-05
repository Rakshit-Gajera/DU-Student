import { Router } from 'express';
import * as transport from '../../controllers/admin/transport.controller';

export const transportRouter = Router();

// Registered before /:id so "receipts" is not read as a pass id.
transportRouter.get('/receipts', transport.listReceipts);
transportRouter.post('/receipts', transport.createReceipt);
transportRouter.put('/receipts/:id', transport.updateReceipt);
transportRouter.delete('/receipts/:id', transport.removeReceipt);

transportRouter.get('/', transport.list);
transportRouter.post('/', transport.create);
transportRouter.get('/:id', transport.get);
transportRouter.put('/:id', transport.update);
transportRouter.delete('/:id', transport.remove);
