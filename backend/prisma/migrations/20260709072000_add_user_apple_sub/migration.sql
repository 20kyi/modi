/*
  Warnings:

  - A unique constraint covering the columns `[appleSub]` on the table `users` will be added. If there are existing duplicate values, this will fail.
  - Added the required column `appleSub` to the `users` table without a default value. This is not possible if the table is not empty.

*/
-- AlterTable
ALTER TABLE "users" ADD COLUMN "appleSub" TEXT;

-- CreateIndex
CREATE UNIQUE INDEX "users_appleSub_key" ON "users"("appleSub");

-- AlterTable
ALTER TABLE "users" ALTER COLUMN "appleSub" SET NOT NULL;
