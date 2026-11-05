import { Router } from 'express';
import * as mentoring from '../../controllers/admin/mentoring.controller';

export const mentoringRouter = Router();

// Registered before /:id so "mentors" is not read as a session id.
mentoringRouter.get('/mentors', mentoring.listMentors);
mentoringRouter.post('/mentors', mentoring.createMentor);
mentoringRouter.put('/mentors/:id', mentoring.updateMentor);
mentoringRouter.delete('/mentors/:id', mentoring.removeMentor);

mentoringRouter.get('/history', mentoring.listHistory);
mentoringRouter.post('/history', mentoring.createHistory);
mentoringRouter.put('/history/:id', mentoring.updateHistory);
mentoringRouter.delete('/history/:id', mentoring.removeHistory);

mentoringRouter.get('/', mentoring.listSessions);
mentoringRouter.post('/', mentoring.createSession);
mentoringRouter.get('/:id', mentoring.getSession);
mentoringRouter.put('/:id', mentoring.updateSession);
mentoringRouter.delete('/:id', mentoring.removeSession);
