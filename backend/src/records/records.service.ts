import { Injectable, NotFoundException } from '@nestjs/common';
import { ConceptCategory, ConceptType } from '../generated/prisma/client';
import { PrismaService } from '../database/prisma.service';
import { CreateRecordDto } from './dto/create-record.dto';

@Injectable()
export class RecordsService {
  constructor(private readonly prisma: PrismaService) {}

  findMyRecords(userId: string) {
    return this.prisma.record.findMany({
      where: { userId },
      include: {
        concept: {
          select: {
            title: true,
            emoji: true,
          },
        },
      },
      orderBy: {
        createdAt: 'desc',
      },
    });
  }

  async upsertMyRecord(userId: string, dto: CreateRecordDto) {
    const date = new Date(dto.recordDate);
    const recordDate = new Date(
      Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()),
    );
    await this.ensureConceptExists(userId, dto);

    return this.prisma.record.upsert({
      where: {
        userId_recordDate: {
          userId,
          recordDate,
        },
      },
      update: {
        conceptId: dto.conceptId,
        originalImageUrl: dto.originalImageUrl,
        editedImageUrl: dto.editedImageUrl,
        isEdited: dto.isEdited,
      },
      create: {
        userId,
        conceptId: dto.conceptId,
        originalImageUrl: dto.originalImageUrl,
        editedImageUrl: dto.editedImageUrl,
        recordDate,
        isEdited: dto.isEdited,
      },
      include: {
        concept: {
          select: {
            title: true,
            emoji: true,
          },
        },
      },
    });
  }

  async deleteMyRecord(userId: string, recordId: string): Promise<void> {
    const deleted = await this.prisma.record.deleteMany({
      where: {
        id: recordId,
        userId,
      },
    });

    if (deleted.count === 0) {
      throw new NotFoundException('삭제할 기록을 찾을 수 없어요.');
    }
  }

  private async ensureConceptExists(
    userId: string,
    dto: CreateRecordDto,
  ): Promise<void> {
    const existing = await this.prisma.concept.findUnique({
      where: { id: dto.conceptId },
      select: { id: true },
    });
    if (existing) return;

    await this.prisma.concept.create({
      data: {
        id: dto.conceptId,
        userId,
        type: ConceptType.CUSTOM,
        category: ConceptCategory.CUSTOM,
        title: dto.conceptTitle,
        emoji: dto.conceptEmoji,
        description: dto.conceptTitle,
        missionPrompt: dto.conceptTitle,
        themeColorHex: 'E8ECF0',
      },
    });
  }
}
