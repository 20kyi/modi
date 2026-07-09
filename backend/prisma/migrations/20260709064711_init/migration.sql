-- CreateEnum
CREATE TYPE "ConceptType" AS ENUM ('SYSTEM', 'CUSTOM');

-- CreateEnum
CREATE TYPE "ConceptCategory" AS ENUM ('COLOR', 'NATURE', 'CUSTOM');

-- CreateTable
CREATE TABLE "users" (
    "id" UUID NOT NULL,
    "nickname" TEXT NOT NULL,
    "profileImageUrl" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "concepts" (
    "id" UUID NOT NULL,
    "userId" UUID,
    "type" "ConceptType" NOT NULL,
    "title" TEXT NOT NULL,
    "emoji" TEXT NOT NULL,
    "description" TEXT NOT NULL DEFAULT '',
    "category" "ConceptCategory" NOT NULL,
    "missionPrompt" TEXT NOT NULL DEFAULT '',
    "themeColorHex" TEXT NOT NULL DEFAULT 'E8ECF0',
    "sourceTemplateId" TEXT,
    "targetCount" INTEGER NOT NULL DEFAULT 20,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "concepts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "records" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "conceptId" UUID NOT NULL,
    "originalImageUrl" TEXT NOT NULL,
    "editedImageUrl" TEXT NOT NULL,
    "recordDate" DATE NOT NULL,
    "isEdited" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "records_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "collections" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "conceptId" UUID NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "collections_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "collection_records" (
    "id" UUID NOT NULL,
    "collectionId" UUID NOT NULL,
    "recordId" UUID NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "collection_records_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "favorites" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "conceptId" UUID NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "favorites_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "concepts_userId_idx" ON "concepts"("userId");

-- CreateIndex
CREATE INDEX "concepts_type_idx" ON "concepts"("type");

-- CreateIndex
CREATE INDEX "records_userId_idx" ON "records"("userId");

-- CreateIndex
CREATE INDEX "records_conceptId_idx" ON "records"("conceptId");

-- CreateIndex
CREATE INDEX "records_recordDate_idx" ON "records"("recordDate");

-- CreateIndex
CREATE UNIQUE INDEX "records_userId_recordDate_key" ON "records"("userId", "recordDate");

-- CreateIndex
CREATE INDEX "collections_userId_idx" ON "collections"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "collections_userId_conceptId_key" ON "collections"("userId", "conceptId");

-- CreateIndex
CREATE INDEX "collection_records_recordId_idx" ON "collection_records"("recordId");

-- CreateIndex
CREATE UNIQUE INDEX "collection_records_collectionId_recordId_key" ON "collection_records"("collectionId", "recordId");

-- CreateIndex
CREATE INDEX "favorites_userId_idx" ON "favorites"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "favorites_userId_conceptId_key" ON "favorites"("userId", "conceptId");

-- AddForeignKey
ALTER TABLE "concepts" ADD CONSTRAINT "concepts_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "records" ADD CONSTRAINT "records_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "records" ADD CONSTRAINT "records_conceptId_fkey" FOREIGN KEY ("conceptId") REFERENCES "concepts"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "collections" ADD CONSTRAINT "collections_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "collections" ADD CONSTRAINT "collections_conceptId_fkey" FOREIGN KEY ("conceptId") REFERENCES "concepts"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "collection_records" ADD CONSTRAINT "collection_records_collectionId_fkey" FOREIGN KEY ("collectionId") REFERENCES "collections"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "collection_records" ADD CONSTRAINT "collection_records_recordId_fkey" FOREIGN KEY ("recordId") REFERENCES "records"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "favorites" ADD CONSTRAINT "favorites_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "favorites" ADD CONSTRAINT "favorites_conceptId_fkey" FOREIGN KEY ("conceptId") REFERENCES "concepts"("id") ON DELETE CASCADE ON UPDATE CASCADE;
