-- CreateEnum
CREATE TYPE "AdminRole" AS ENUM ('ADMIN', 'SUPERADMIN');

-- CreateEnum
CREATE TYPE "AttendanceStatus" AS ENUM ('P', 'A', 'AE', 'NA');

-- CreateEnum
CREATE TYPE "LmsContentType" AS ENUM ('PRESENTATION', 'LAB_MANUAL');

-- CreateEnum
CREATE TYPE "GrievanceStatus" AS ENUM ('PENDING', 'IN_PROGRESS', 'RESOLVED');

-- CreateEnum
CREATE TYPE "CertificateStatus" AS ENUM ('PENDING', 'APPROVED', 'REJECTED');

-- CreateEnum
CREATE TYPE "ExamType" AS ENUM ('EXAM', 'IA', 'LMS_TEST');

-- CreateTable
CREATE TABLE "admins" (
    "id" UUID NOT NULL,
    "username" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "password_hash" TEXT NOT NULL,
    "role" "AdminRole" NOT NULL DEFAULT 'ADMIN',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "admins_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "mentors" (
    "id" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "designation" TEXT,
    "mobile" TEXT,
    "office_no" TEXT,
    "email" TEXT,
    "department" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "mentors_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "students" (
    "id" UUID NOT NULL,
    "enrollment_no" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "photo_url" TEXT,
    "class_label" TEXT NOT NULL,
    "batch" TEXT NOT NULL,
    "roll_no" TEXT NOT NULL,
    "current_sem" INTEGER NOT NULL DEFAULT 1,
    "email" TEXT,
    "mobile" TEXT,
    "department" TEXT,
    "password_hash" TEXT NOT NULL,
    "mentor_id" UUID,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "students_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "subjects" (
    "id" UUID NOT NULL,
    "code" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "type" TEXT NOT NULL DEFAULT 'Theory',
    "semester" INTEGER,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "subjects_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "attendance_records" (
    "id" UUID NOT NULL,
    "student_id" UUID NOT NULL,
    "subject_id" UUID,
    "date" DATE NOT NULL,
    "slot" INTEGER NOT NULL,
    "status" "AttendanceStatus" NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "attendance_records_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "past_semester_attendance" (
    "id" UUID NOT NULL,
    "student_id" UUID NOT NULL,
    "sem_no" INTEGER NOT NULL,
    "year_label" TEXT NOT NULL,
    "percent" DOUBLE PRECISION NOT NULL,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "past_semester_attendance_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "course_attendance" (
    "id" UUID NOT NULL,
    "student_id" UUID NOT NULL,
    "course" TEXT NOT NULL,
    "total" INTEGER NOT NULL,
    "present" INTEGER NOT NULL,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "course_attendance_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "semester_results" (
    "id" UUID NOT NULL,
    "student_id" UUID NOT NULL,
    "sem_no" INTEGER NOT NULL,
    "year_label" TEXT NOT NULL,
    "spi" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "cpi" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "backlogs" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "semester_results_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "course_results" (
    "id" UUID NOT NULL,
    "sem_result_id" UUID NOT NULL,
    "subject_id" UUID NOT NULL,
    "grade" TEXT NOT NULL,
    "credits" INTEGER NOT NULL,
    "exam_season" TEXT,
    "attempt_no" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "course_results_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "exam_schedules" (
    "id" UUID NOT NULL,
    "subject_id" UUID,
    "type" "ExamType" NOT NULL DEFAULT 'EXAM',
    "title" TEXT NOT NULL,
    "start_date" DATE NOT NULL,
    "end_date" DATE,
    "semester" INTEGER,
    "venue" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "exam_schedules_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "lms_content" (
    "id" UUID NOT NULL,
    "subject_id" UUID NOT NULL,
    "type" "LmsContentType" NOT NULL,
    "title" TEXT NOT NULL,
    "subtitle" TEXT,
    "file_url" TEXT,
    "uploaded_at" DATE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "visible" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "lms_content_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "lms_content_views" (
    "student_id" UUID NOT NULL,
    "content_id" UUID NOT NULL,
    "seen_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "lms_content_views_pkey" PRIMARY KEY ("student_id","content_id")
);

-- CreateTable
CREATE TABLE "mentoring_sessions" (
    "id" UUID NOT NULL,
    "student_id" UUID NOT NULL,
    "mentor_name" TEXT NOT NULL,
    "issue" TEXT NOT NULL,
    "parents_description" TEXT,
    "next_meeting" TIMESTAMP(3),
    "when" TIMESTAMP(3) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "mentoring_sessions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "transport" (
    "id" UUID NOT NULL,
    "student_id" UUID NOT NULL,
    "bus_route" TEXT NOT NULL,
    "pass_no" TEXT NOT NULL,
    "pickup_point" TEXT,
    "shift" TEXT,
    "valid_from" DATE NOT NULL,
    "valid_to" DATE NOT NULL,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "fees_amount" INTEGER NOT NULL DEFAULT 0,
    "fees_paid" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "transport_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "circulars" (
    "id" UUID NOT NULL,
    "title" TEXT NOT NULL,
    "content" TEXT NOT NULL,
    "published_at" TIMESTAMP(3) NOT NULL,
    "pinned" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "circulars_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "grievances" (
    "id" UUID NOT NULL,
    "student_id" UUID NOT NULL,
    "grievance_no" TEXT NOT NULL,
    "category" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "status" "GrievanceStatus" NOT NULL DEFAULT 'PENDING',
    "filed_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "resolved_at" TIMESTAMP(3),
    "resolved_by" TEXT,
    "resolution" TEXT,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "grievances_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "certificate_requests" (
    "id" UUID NOT NULL,
    "student_id" UUID NOT NULL,
    "type" TEXT NOT NULL,
    "purpose" TEXT,
    "copies" INTEGER NOT NULL DEFAULT 1,
    "delivery_mode" TEXT,
    "details" TEXT,
    "status" "CertificateStatus" NOT NULL DEFAULT 'PENDING',
    "remarks" TEXT,
    "requested_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "decided_at" TIMESTAMP(3),
    "decided_by" TEXT,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "certificate_requests_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "admins_username_key" ON "admins"("username");

-- CreateIndex
CREATE UNIQUE INDEX "admins_email_key" ON "admins"("email");

-- CreateIndex
CREATE UNIQUE INDEX "students_enrollment_no_key" ON "students"("enrollment_no");

-- CreateIndex
CREATE INDEX "students_batch_idx" ON "students"("batch");

-- CreateIndex
CREATE INDEX "students_class_label_idx" ON "students"("class_label");

-- CreateIndex
CREATE UNIQUE INDEX "subjects_code_key" ON "subjects"("code");

-- CreateIndex
CREATE INDEX "subjects_semester_idx" ON "subjects"("semester");

-- CreateIndex
CREATE INDEX "attendance_records_student_id_date_idx" ON "attendance_records"("student_id", "date");

-- CreateIndex
CREATE UNIQUE INDEX "attendance_records_student_id_date_slot_key" ON "attendance_records"("student_id", "date", "slot");

-- CreateIndex
CREATE UNIQUE INDEX "past_semester_attendance_student_id_sem_no_key" ON "past_semester_attendance"("student_id", "sem_no");

-- CreateIndex
CREATE UNIQUE INDEX "course_attendance_student_id_course_key" ON "course_attendance"("student_id", "course");

-- CreateIndex
CREATE UNIQUE INDEX "semester_results_student_id_sem_no_key" ON "semester_results"("student_id", "sem_no");

-- CreateIndex
CREATE UNIQUE INDEX "course_results_sem_result_id_subject_id_key" ON "course_results"("sem_result_id", "subject_id");

-- CreateIndex
CREATE INDEX "exam_schedules_start_date_idx" ON "exam_schedules"("start_date");

-- CreateIndex
CREATE INDEX "lms_content_subject_id_type_idx" ON "lms_content"("subject_id", "type");

-- CreateIndex
CREATE INDEX "mentoring_sessions_student_id_when_idx" ON "mentoring_sessions"("student_id", "when");

-- CreateIndex
CREATE UNIQUE INDEX "transport_pass_no_key" ON "transport"("pass_no");

-- CreateIndex
CREATE INDEX "transport_student_id_idx" ON "transport"("student_id");

-- CreateIndex
CREATE INDEX "circulars_published_at_idx" ON "circulars"("published_at");

-- CreateIndex
CREATE UNIQUE INDEX "grievances_grievance_no_key" ON "grievances"("grievance_no");

-- CreateIndex
CREATE INDEX "grievances_status_idx" ON "grievances"("status");

-- CreateIndex
CREATE INDEX "grievances_student_id_idx" ON "grievances"("student_id");

-- CreateIndex
CREATE INDEX "certificate_requests_status_idx" ON "certificate_requests"("status");

-- CreateIndex
CREATE INDEX "certificate_requests_student_id_idx" ON "certificate_requests"("student_id");

-- AddForeignKey
ALTER TABLE "students" ADD CONSTRAINT "students_mentor_id_fkey" FOREIGN KEY ("mentor_id") REFERENCES "mentors"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "attendance_records" ADD CONSTRAINT "attendance_records_student_id_fkey" FOREIGN KEY ("student_id") REFERENCES "students"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "attendance_records" ADD CONSTRAINT "attendance_records_subject_id_fkey" FOREIGN KEY ("subject_id") REFERENCES "subjects"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "past_semester_attendance" ADD CONSTRAINT "past_semester_attendance_student_id_fkey" FOREIGN KEY ("student_id") REFERENCES "students"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "course_attendance" ADD CONSTRAINT "course_attendance_student_id_fkey" FOREIGN KEY ("student_id") REFERENCES "students"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "semester_results" ADD CONSTRAINT "semester_results_student_id_fkey" FOREIGN KEY ("student_id") REFERENCES "students"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "course_results" ADD CONSTRAINT "course_results_sem_result_id_fkey" FOREIGN KEY ("sem_result_id") REFERENCES "semester_results"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "course_results" ADD CONSTRAINT "course_results_subject_id_fkey" FOREIGN KEY ("subject_id") REFERENCES "subjects"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "exam_schedules" ADD CONSTRAINT "exam_schedules_subject_id_fkey" FOREIGN KEY ("subject_id") REFERENCES "subjects"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "lms_content" ADD CONSTRAINT "lms_content_subject_id_fkey" FOREIGN KEY ("subject_id") REFERENCES "subjects"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "lms_content_views" ADD CONSTRAINT "lms_content_views_student_id_fkey" FOREIGN KEY ("student_id") REFERENCES "students"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "lms_content_views" ADD CONSTRAINT "lms_content_views_content_id_fkey" FOREIGN KEY ("content_id") REFERENCES "lms_content"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "mentoring_sessions" ADD CONSTRAINT "mentoring_sessions_student_id_fkey" FOREIGN KEY ("student_id") REFERENCES "students"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "transport" ADD CONSTRAINT "transport_student_id_fkey" FOREIGN KEY ("student_id") REFERENCES "students"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "grievances" ADD CONSTRAINT "grievances_student_id_fkey" FOREIGN KEY ("student_id") REFERENCES "students"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "certificate_requests" ADD CONSTRAINT "certificate_requests_student_id_fkey" FOREIGN KEY ("student_id") REFERENCES "students"("id") ON DELETE CASCADE ON UPDATE CASCADE;
