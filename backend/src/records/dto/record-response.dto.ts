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

  @ApiProperty()
  originalImageUrl!: string;

  @ApiProperty()
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
  ): RecordResponseDto {
    return {
      id: record.id,
      conceptId: record.conceptId,
      conceptTitle: record.concept.title,
      conceptEmoji: record.concept.emoji,
      originalImageUrl: record.originalImageUrl,
      editedImageUrl: record.editedImageUrl,
      recordDate: record.recordDate,
      isEdited: record.isEdited,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
    };
  }
}
