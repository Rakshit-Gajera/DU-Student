import { Router } from 'express';
import * as certificates from '../../controllers/admin/certificates.controller';

export const certificatesRouter = Router();

certificatesRouter.get('/', certificates.list);
certificatesRouter.post('/', certificates.create);
certificatesRouter.get('/:id', certificates.get);
certificatesRouter.put('/:id', certificates.update);
certificatesRouter.delete('/:id', certificates.remove);
