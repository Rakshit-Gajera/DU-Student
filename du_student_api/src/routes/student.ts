import { Router } from 'express';
import * as student from '../controllers/student.controller';
import { verifyStudentJWT } from '../middlewares/auth';

export const studentRouter = Router();

studentRouter.use(verifyStudentJWT);

studentRouter.get('/profile', student.profile);
studentRouter.get('/subjects', student.subjects);
studentRouter.get('/attendance', student.attendanceGrid);
studentRouter.get('/attendance/summary', student.attendanceSummary);
studentRouter.get('/attendance/past-sems', student.pastSemesters);
studentRouter.get('/attendance/courses', student.courseAttendance);
studentRouter.get('/results', student.getResults);
studentRouter.get('/lms/:subjectId/presentations', student.presentations);
studentRouter.get('/lms/:subjectId/lab-manuals', student.labManuals);
studentRouter.post('/lms/content/:id/seen', student.markLmsSeen);
studentRouter.get('/mentoring', student.getMentoring);
studentRouter.get('/lms-results', student.lmsTestResults);
studentRouter.get('/transport', student.getTransport);
studentRouter.get('/transport/receipts', student.busReceipts);
studentRouter.get('/circulars', student.getCirculars);
studentRouter.get('/grievances', student.listGrievances);
studentRouter.post('/grievances', student.fileGrievance);
studentRouter.get('/certificates', student.listCertificates);
studentRouter.post('/certificates', student.requestCertificate);
studentRouter.get('/exam-schedule', student.examSchedule);
