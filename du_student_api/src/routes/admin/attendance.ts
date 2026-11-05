import { Router } from 'express';
import * as attendance from '../../controllers/admin/attendance.controller';

export const attendanceRouter = Router();

attendanceRouter.get('/', attendance.grid);
attendanceRouter.post('/bulk', attendance.bulk);
attendanceRouter.get('/summary', attendance.getSummary);
attendanceRouter.put('/summary', attendance.saveSummary);
attendanceRouter.get('/past-sems', attendance.listPastSems);
attendanceRouter.put('/past-sems', attendance.savePastSem);
attendanceRouter.delete('/past-sems/:id', attendance.removePastSem);
attendanceRouter.get('/courses', attendance.listCourses);
attendanceRouter.put('/courses', attendance.saveCourse);
attendanceRouter.delete('/courses/:id', attendance.removeCourse);
