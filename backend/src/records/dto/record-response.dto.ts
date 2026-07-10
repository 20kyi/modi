import { ApiProperty } from '@nestjs/swagger';
import type { Record as ModiRecord } from '../../generated/prisma/client';

export class RecordResponseDto {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty({ format: 'uuid' })
  conceptId!: string;

  @ApiProperty()
  conceptTitle!: string;

  @ApiProperty()
  conceptEmoji!: string;

  @ApiProperty({
    description: '원본 이미지 Presigned GET URL',
  })
  originalImageUrl!: string;

  @ApiProperty({
    description: '편집 이미지 Presigned GET URL',
  })
  editedImageUrl!: string;

  @ApiProperty()
  recordDate!: Date;

  @ApiProperty()
  isEdited!: boolean;

  @ApiProperty()
  createdAt!: Date;

  @ApiProperty()
  updatedAt!: Date;

  static from(
    record: ModiRecord & { concept: { title: string; emoji: string } },
    imageUrls: { originalImageUrl: string; editedImageUrl: string },
  ): RecordResponseDto {
    return {
      id: record.id,
      conceptId: record.conceptId,
      conceptTitle: record.concept.title,
      conceptEmoji: record.concept.emoji,
      originalImageUrl: imageUrls.originalImageUrl,
      editedImageUrl: imageUrls.editedImageUrl,
      recordDate: record.recordDate,
      isEdited: record.isEdited,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
    };
  }
}
