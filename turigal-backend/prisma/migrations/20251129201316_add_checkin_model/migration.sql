/*
  Warnings:

  - You are about to drop the `ResetPasswordToken` table. If the table is not empty, all the data it contains will be lost.
  - A unique constraint covering the columns `[telefono]` on the table `Usuario` will be added. If there are existing duplicate values, this will fail.
  - Made the column `telefono` on table `Usuario` required. This step will fail if there are existing NULL values in that column.
  - Made the column `apellido` on table `Usuario` required. This step will fail if there are existing NULL values in that column.

*/
-- CreateEnum
CREATE TYPE "CheckinStatus" AS ENUM ('PENDIENTE', 'EN_PROCESO', 'IDENTIDAD_VERIFICADA', 'COMPLETADO', 'FALLIDO');

-- DropForeignKey
ALTER TABLE "ResetPasswordToken" DROP CONSTRAINT "ResetPasswordToken_userId_fkey";

-- AlterTable
ALTER TABLE "Usuario" ALTER COLUMN "telefono" SET NOT NULL,
ALTER COLUMN "apellido" SET NOT NULL;

-- DropTable
DROP TABLE "ResetPasswordToken";

-- CreateTable
CREATE TABLE "Checkin" (
    "id" SERIAL NOT NULL,
    "reservationId" TEXT NOT NULL,
    "checkinStatus" "CheckinStatus" NOT NULL DEFAULT 'EN_PROCESO',
    "guestName" TEXT,
    "documentType" TEXT,
    "documentNumber" TEXT,
    "documentImageUrl" TEXT,
    "selfieImageUrl" TEXT,
    "acceptedTerms" BOOLEAN NOT NULL DEFAULT false,
    "signatureBase64" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Checkin_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "Checkin_reservationId_key" ON "Checkin"("reservationId");

-- CreateIndex
CREATE UNIQUE INDEX "Usuario_telefono_key" ON "Usuario"("telefono");
