-- AlterTable
ALTER TABLE "semester_results" ADD COLUMN     "exam_name" TEXT;

-- AlterTable
ALTER TABLE "transport" ADD COLUMN     "batch_code" TEXT;

-- CreateTable
CREATE TABLE "attendance_summaries" (
    "student_id" UUID NOT NULL,
    "year_label" TEXT NOT NULL,
    "percent" DOUBLE PRECISION NOT NULL,
    "present" INTEGER NOT NULL,
    "absent" INTEGER NOT NULL,
    "pending" INTEGER NOT NULL DEFAULT 0,
    "no_attendance" INTEGER NOT NULL DEFAULT 0,
    "total" INTEGER NOT NULL,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "attendance_summaries_pkey" PRIMARY KEY ("student_id")
);

-- CreateTable
CREATE TABLE "mentor_history" (
    "id" UUID NOT NULL,
    "student_id" UUID NOT NULL,
    "mentor_name" TEXT NOT NULL,
    "from_date" DATE NOT NULL,
    "to_date" DATE,
    "meetings" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "mentor_history_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "mentor_history_student_id_idx" ON "mentor_history"("student_id");

-- AddForeignKey
ALTER TABLE "attendance_summaries" ADD CONSTRAINT "attendance_summaries_student_id_fkey" FOREIGN KEY ("student_id") REFERENCES "students"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "mentor_history" ADD CONSTRAINT "mentor_history_student_id_fkey" FOREIGN KEY ("student_id") REFERENCES "students"("id") ON DELETE CASCADE ON UPDATE CASCADE;
