import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { ConceptCategory, ConceptType } from '../generated/prisma/client';
import { PrismaService } from '../database/prisma.service';
import { UploadService } from '../upload/upload.service';
import { CreateRecordDto } from './dto/create-record.dto';
import { RecordResponseDto } from './dto/record-response.dto';

type RecordWithConcept = Awaited<
  ReturnType<RecordsService['findMyRecordEntities']>
>[number];

@Injectable()
export class RecordsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly uploadService: UploadService,
  ) {}

  async findMyRecords(userId: string): Promise<RecordResponseDto[]> {
    const records = await this.findMyRecordEntities(userId);

    return Promise.all(
      records.map((record) => this.toRecordResponseDto(record)),
    );
  }

  async upsertMyRecord(
    userId: string,
    dto: CreateRecordDto,
  ): Promise<RecordResponseDto> {
    this.validateImageKeys(userId, dto);

    const date = new Date(dto.recordDate);
    const recordDate = new Date(
      Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()),
    );

    const existingRecord = await this.prisma.record.findUnique({
      where: {
        userId_recordDate: {
          userId,
          recordDate,
        },
      },
      select: {
        originalImageUrl: true,
        editedImageUrl: true,
      },
    });

    if (existingRecord) {
      await this.ensureReplacedImagesUploaded(dto, existingRecord);
    }

    await this.ensureConceptExists(userId, dto);

    const record = await this.prisma.record.upsert({
      where: {
        userId_recordDate: {
          userId,
          recordDate,
        },
      },
      update: {
        conceptId: dto.conceptId,
        originalImageUrl: dto.originalImageKey,
        editedImageUrl: dto.editedImageKey,
        isEdited: dto.isEdited,
      },
      create: {
        userId,
        conceptId: dto.conceptId,
        originalImageUrl: dto.originalImageKey,
        editedImageUrl: dto.editedImageKey,
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

    if (existingRecord) {
      const replacedImageKeys = this.collectReplacedStoredImageKeys(
        existingRecord,
        dto,
      );
      await this.uploadService.deleteStoredImageObjects(...replacedImageKeys);
    }

    return this.toRecordResponseDto(record);
  }

  async deleteMyRecord(userId: string, recordId: string): Promise<void> {
    const record = await this.prisma.record.findFirst({
      where: {
        id: recordId,
        userId,
      },
      select: {
        originalImageUrl: true,
        editedImageUrl: true,
      },
    });

    if (!record) {
      throw new NotFoundException('삭제할 기록을 찾을 수 없어요.');
    }

    await this.prisma.record.delete({
      where: { id: recordId },
    });

    await this.uploadService.deleteStoredImageObjects(
      record.originalImageUrl,
      record.editedImageUrl,
    );
  }

  private findMyRecordEntities(userId: string) {
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

  private async toRecordResponseDto(
    record: RecordWithConcept,
  ): Promise<RecordResponseDto> {
    const imageUrls = await this.createPresignedImageUrls(record);

    return RecordResponseDto.from(record, imageUrls);
  }

  private async createPresignedImageUrls(record: RecordWithConcept): Promise<{
    originalImageUrl: string;
    editedImageUrl: string;
  }> {
    const [originalImageUrl, editedImageUrl] = await Promise.all([
      this.resolveImageUrl(record.originalImageUrl),
      this.resolveImageUrl(record.editedImageUrl),
    ]);

    return { originalImageUrl, editedImageUrl };
  }

  private async resolveImageUrl(stored: string): Promise<string> {
    if (stored.startsWith('data:')) {
      return stored;
    }

    const key = this.uploadService.resolveStoredImageKey(stored);
    if (!key) {
      throw new BadRequestException('저장된 이미지 키를 확인할 수 없어요.');
    }

    return this.uploadService.createPresignedGetUrl(key);
  }

  private validateImageKeys(userId: string, dto: CreateRecordDto): void {
    const keys = [dto.originalImageKey, dto.editedImageKey];

    for (const key of keys) {
      if (!this.uploadService.validateRecordImageKey(userId, key)) {
        throw new BadRequestException('유효하지 않은 이미지 키예요.');
      }
    }
  }

  private async ensureReplacedImagesUploaded(
    dto: CreateRecordDto,
    existingRecord: {
      originalImageUrl: string;
      editedImageUrl: string;
    },
  ): Promise<void> {
    const checks: Promise<boolean>[] = [];

    if (
      this.hasImageKeyChanged(
        existingRecord.originalImageUrl,
        dto.originalImageKey,
      )
    ) {
      checks.push(
        this.uploadService.verifyStoredImageObjectExists(dto.originalImageKey),
      );
    }

    if (
      this.hasImageKeyChanged(
        existingRecord.editedImageUrl,
        dto.editedImageKey,
      )
    ) {
      checks.push(
        this.uploadService.verifyStoredImageObjectExists(dto.editedImageKey),
      );
    }

    if (checks.length === 0) {
      return;
    }

    const results = await Promise.all(checks);
    if (results.some((exists) => !exists)) {
      throw new BadRequestException('새 이미지 업로드가 완료되지 않았어요.');
    }
  }

  private collectReplacedStoredImageKeys(
    existingRecord: {
      originalImageUrl: string;
      editedImageUrl: string;
    },
    dto: CreateRecordDto,
  ): string[] {
    const replaced: string[] = [];

    if (
      this.hasImageKeyChanged(
        existingRecord.originalImageUrl,
        dto.originalImageKey,
      )
    ) {
      replaced.push(existingRecord.originalImageUrl);
    }

    if (
      this.hasImageKeyChanged(existingRecord.editedImageUrl, dto.editedImageKey)
    ) {
      replaced.push(existingRecord.editedImageUrl);
    }

    return replaced;
  }

  private hasImageKeyChanged(stored: string, nextKey: string): boolean {
    const currentKey =
      this.uploadService.resolveStoredImageKey(stored) ?? stored;
    const resolvedNextKey =
      this.uploadService.resolveStoredImageKey(nextKey) ?? nextKey;

    return currentKey !== resolvedNextKey;
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
