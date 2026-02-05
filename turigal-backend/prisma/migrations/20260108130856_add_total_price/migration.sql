/*
  Warnings:

  - You are about to drop the column `documentImageUrl` on the `Checkin` table. All the data in the column will be lost.
  - You are about to drop the column `selfieImageUrl` on the `Checkin` table. All the data in the column will be lost.
  - You are about to drop the column `scheduledCheckOutAt` on the `Reservation` table. All the data in the column will be lost.
  - You are about to drop the column `submissionDate` on the `Review` table. All the data in the column will be lost.
  - You are about to drop the `Usuario` table. If the table is not empty, all the data it contains will be lost.
  - Added the required column `checkInDate` to the `Reservation` table without a default value. This is not possible if the table is not empty.
  - Added the required column `checkOutDate` to the `Reservation` table without a default value. This is not possible if the table is not empty.
  - Added the required column `guests` to the `Reservation` table without a default value. This is not possible if the table is not empty.
  - Added the required column `propertyName` to the `Reservation` table without a default value. This is not possible if the table is not empty.

*/
-- AlterEnum
ALTER TYPE "CheckinStatus" ADD VALUE 'INICIADO';

-- AlterEnum
ALTER TYPE "ReservationStatus" ADD VALUE 'PENDIENTE';

-- DropForeignKey
ALTER TABLE "Reservation" DROP CONSTRAINT "Reservation_userId_fkey";

-- DropForeignKey
ALTER TABLE "ResetPasswordToken" DROP CONSTRAINT "ResetPasswordToken_userId_fkey";

-- DropForeignKey
ALTER TABLE "Review" DROP CONSTRAINT "Review_userId_fkey";

-- AlterTable
ALTER TABLE "Checkin" DROP COLUMN "documentImageUrl",
DROP COLUMN "selfieImageUrl",
ADD COLUMN     "documentPhoto" TEXT,
ADD COLUMN     "selfiePhoto" TEXT;

-- AlterTable
ALTER TABLE "Reservation" DROP COLUMN "scheduledCheckOutAt",
ADD COLUMN     "apellido" TEXT,
ADD COLUMN     "checkInDate" TIMESTAMP(3) NOT NULL,
ADD COLUMN     "checkOutDate" TIMESTAMP(3) NOT NULL,
ADD COLUMN     "checkOutDateReal" TIMESTAMP(3),
ADD COLUMN     "guestName" TEXT,
ADD COLUMN     "guests" INTEGER NOT NULL,
ADD COLUMN     "location" TEXT,
ADD COLUMN     "nombre" TEXT,
ADD COLUMN     "propertyName" TEXT NOT NULL,
ADD COLUMN     "totalPrice" DOUBLE PRECISION NOT NULL DEFAULT 0.0,
ALTER COLUMN "userId" DROP NOT NULL;

-- AlterTable
ALTER TABLE "Review" DROP COLUMN "submissionDate",
ADD COLUMN     "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP;

-- DropTable
DROP TABLE "Usuario";

-- CreateTable
CREATE TABLE "users" (
    "id" SERIAL NOT NULL,
    "email" TEXT NOT NULL,
    "password" TEXT NOT NULL,
    "nombre" TEXT NOT NULL,
    "apellido" TEXT NOT NULL,
    "telefono" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE UNIQUE INDEX "users_telefono_key" ON "users"("telefono");

-- AddForeignKey
ALTER TABLE "ResetPasswordToken" ADD CONSTRAINT "ResetPasswordToken_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Reservation" ADD CONSTRAINT "Reservation_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ChatMessage" ADD CONSTRAINT "ChatMessage_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Review" ADD CONSTRAINT "Review_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
