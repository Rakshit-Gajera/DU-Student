-- Circulars, LMS content and exam schedules become per student. Every existing row
-- is copied to each student, keeping who has seen which LMS item.

-- AlterTable
ALTER TABLE "circulars" ADD COLUMN     "student_id" UUID;

-- AlterTable
ALTER TABLE "exam_schedules" ADD COLUMN     "student_id" UUID;

-- AlterTable
ALTER TABLE "lms_content" ADD COLUMN     "student_id" UUID;

INSERT INTO "circulars" ("id", "student_id", "title", "content", "published_at", "pinned", "created_at", "updated_at")
SELECT gen_random_uuid(), s."id", c."title", c."content", c."published_at", c."pinned", c."created_at", c."updated_at"
FROM "circulars" c CROSS JOIN "students" s
WHERE c."student_id" IS NULL;
DELETE FROM "circulars" WHERE "student_id" IS NULL;

INSERT INTO "exam_schedules" ("id", "student_id", "subject_id", "type", "title", "start_date", "end_date", "semester", "venue", "created_at", "updated_at")
SELECT gen_random_uuid(), s."id", e."subject_id", e."type", e."title", e."start_date", e."end_date", e."semester", e."venue", e."created_at", e."updated_at"
FROM "exam_schedules" e CROSS JOIN "students" s
WHERE e."student_id" IS NULL;
DELETE FROM "exam_schedules" WHERE "student_id" IS NULL;

CREATE TEMP TABLE "_lms_copy" ON COMMIT DROP AS
SELECT c."id" AS "old_id", s."id" AS "student_id", gen_random_uuid() AS "new_id"
FROM "lms_content" c CROSS JOIN "students" s
WHERE c."student_id" IS NULL;

INSERT INTO "lms_content" ("id", "student_id", "subject_id", "type", "title", "subtitle", "file_url", "uploaded_at", "visible", "created_at", "updated_at")
SELECT m."new_id", m."student_id", c."subject_id", c."type", c."title", c."subtitle", c."file_url", c."uploaded_at", c."visible", c."created_at", c."updated_at"
FROM "_lms_copy" m JOIN "lms_content" c ON c."id" = m."old_id";

INSERT INTO "lms_content_views" ("student_id", "content_id", "seen_at")
SELECT v."student_id", m."new_id", v."seen_at"
FROM "lms_content_views" v JOIN "_lms_copy" m ON m."old_id" = v."content_id" AND m."student_id" = v."student_id";

DELETE FROM "lms_content" WHERE "student_id" IS NULL;

ALTER TABLE "circulars" ALTER COLUMN "student_id" SET NOT NULL;
ALTER TABLE "exam_schedules" ALTER COLUMN "student_id" SET NOT NULL;
ALTER TABLE "lms_content" ALTER COLUMN "student_id" SET NOT NULL;

-- AlterTable
ALTER TABLE "transport" ADD COLUMN     "bus_code" TEXT,
ADD COLUMN     "pickup_address" TEXT;

-- CreateTable
CREATE TABLE "lms_test_results" (
    "id" UUID NOT NULL,
    "student_id" UUID NOT NULL,
    "sem_no" INTEGER NOT NULL,
    "course" TEXT NOT NULL,
    "position" INTEGER NOT NULL DEFAULT 0,
    "unit" INTEGER NOT NULL,
    "test_date" DATE NOT NULL,
    "attempt_no" INTEGER NOT NULL DEFAULT 1,
    "marks" INTEGER NOT NULL,
    "max_marks" INTEGER NOT NULL DEFAULT 30,
    "passed" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "lms_test_results_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "bus_receipts" (
    "id" UUID NOT NULL,
    "student_id" UUID NOT NULL,
    "receipt_no" TEXT NOT NULL,
    "paid_on" DATE NOT NULL,
    "amount" INTEGER NOT NULL,
    "description" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "bus_receipts_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "lms_test_results_student_id_sem_no_idx" ON "lms_test_results"("student_id", "sem_no");

-- CreateIndex
CREATE INDEX "bus_receipts_student_id_idx" ON "bus_receipts"("student_id");

-- CreateIndex
CREATE INDEX "circulars_student_id_idx" ON "circulars"("student_id");

-- CreateIndex
CREATE INDEX "exam_schedules_student_id_idx" ON "exam_schedules"("student_id");

-- CreateIndex
CREATE INDEX "lms_content_student_id_subject_id_type_idx" ON "lms_content"("student_id", "subject_id", "type");

-- AddForeignKey
ALTER TABLE "exam_schedules" ADD CONSTRAINT "exam_schedules_student_id_fkey" FOREIGN KEY ("student_id") REFERENCES "students"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "lms_content" ADD CONSTRAINT "lms_content_student_id_fkey" FOREIGN KEY ("student_id") REFERENCES "students"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "lms_test_results" ADD CONSTRAINT "lms_test_results_student_id_fkey" FOREIGN KEY ("student_id") REFERENCES "students"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bus_receipts" ADD CONSTRAINT "bus_receipts_student_id_fkey" FOREIGN KEY ("student_id") REFERENCES "students"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "circulars" ADD CONSTRAINT "circulars_student_id_fkey" FOREIGN KEY ("student_id") REFERENCES "students"("id") ON DELETE CASCADE ON UPDATE CASCADE;
