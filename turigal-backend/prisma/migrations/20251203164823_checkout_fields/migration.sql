-- AlterTable
ALTER TABLE "Reservation" ADD COLUMN     "scheduledCheckOutAt" TIMESTAMP(3),
ALTER COLUMN "uploadedPhotos" SET DEFAULT ARRAY[]::TEXT[];
