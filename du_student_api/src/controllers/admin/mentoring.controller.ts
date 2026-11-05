import { z } from 'zod';
import { asyncHandler, ok, okPage } from '../../lib/http';
import { dateString, dateTimeString, optionalText, pageQuery, toPageParams, uuidParam } from '../../lib/validation';
import * as mentoring from '../../services/mentoring.service';

const listQuery = pageQuery.extend({ studentId: z.string().uuid('Invalid studentId').optional() });

const sessionBody = z.object({
  studentId: z.string().uuid('Invalid studentId'),
  mentorName: z.string().trim().min(1, 'Mentor name is required').max(200),
  issue: z.string().trim().min(1, 'Issue is required').max(5000),
  parentsDescription: optionalText(5000),
  nextMeeting: dateTimeString.nullable().optional(),
  when: dateTimeString,
});

const mentorBody = z.object({
  name: z.string().trim().min(1, 'Name is required').max(200),
  designation: optionalText(200),
  mobile: optionalText(30),
  officeNo: optionalText(30),
  email: z.preprocess(
    (v) => (v === '' ? null : v),
    z.string().trim().email('Invalid email').max(200).nullable().optional(),
  ),
  department: optionalText(200),
});

const historyFields = z.object({
  studentId: z.string().uuid('Invalid studentId'),
  mentorName: z.string().trim().min(1, 'Mentor name is required').max(200),
  fromDate: dateString,
  toDate: dateString.nullable().optional(),
  meetings: z.number().int().min(0).optional(),
});
const historyRange = (v: { fromDate?: Date; toDate?: Date | null }): boolean =>
  !v.fromDate || !v.toDate || v.fromDate <= v.toDate;
const historyRangeError = { path: ['toDate'], message: 'End date cannot be before the start date' };
const historyQuery = z.object({ studentId: z.string().uuid('Invalid studentId') });

export const listHistory = asyncHandler(async (req, res) => {
  ok(res, await mentoring.listMentorHistory(historyQuery.parse(req.query).studentId));
});

export const createHistory = asyncHandler(async (req, res) => {
  ok(res, await mentoring.createMentorHistory(historyFields.refine(historyRange, historyRangeError).parse(req.body)), 201);
});

export const updateHistory = asyncHandler(async (req, res) => {
  const body = historyFields.partial().refine(historyRange, historyRangeError).parse(req.body);
  ok(res, await mentoring.updateMentorHistory(uuidParam.parse(req.params).id, body));
});

export const removeHistory = asyncHandler(async (req, res) => {
  await mentoring.deleteMentorHistory(uuidParam.parse(req.params).id);
  ok(res, { deleted: true });
});

export const listSessions = asyncHandler(async (req, res) => {
  const { page, limit, ...filters } = listQuery.parse(req.query);
  okPage(res, await mentoring.listSessions(toPageParams({ page, limit }), filters));
});

export const getSession = asyncHandler(async (req, res) => {
  ok(res, await mentoring.getSession(uuidParam.parse(req.params).id));
});

export const createSession = asyncHandler(async (req, res) => {
  ok(res, await mentoring.createSession(sessionBody.parse(req.body)), 201);
});

export const updateSession = asyncHandler(async (req, res) => {
  const { id } = uuidParam.parse(req.params);
  ok(res, await mentoring.updateSession(id, sessionBody.partial().parse(req.body)));
});

export const removeSession = asyncHandler(async (req, res) => {
  await mentoring.deleteSession(uuidParam.parse(req.params).id);
  ok(res, { deleted: true });
});

export const listMentors = asyncHandler(async (req, res) => {
  okPage(res, await mentoring.listMentors(toPageParams(pageQuery.parse(req.query))));
});

export const createMentor = asyncHandler(async (req, res) => {
  ok(res, await mentoring.createMentor(mentorBody.parse(req.body)), 201);
});

export const updateMentor = asyncHandler(async (req, res) => {
  const { id } = uuidParam.parse(req.params);
  ok(res, await mentoring.updateMentor(id, mentorBody.partial().parse(req.body)));
});

export const removeMentor = asyncHandler(async (req, res) => {
  await mentoring.deleteMentor(uuidParam.parse(req.params).id);
  ok(res, { deleted: true });
});
