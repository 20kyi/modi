import { ApiProperty } from '@nestjs/swagger';
import { IsDateString, IsIn } from 'class-validator';

const ALLOWED_CONTENT_TYPES = ['image/jpeg', 'image/png'] as const;

export type RecordImageContentType = (typeof ALLOWED_CONTENT_TYPES)[number];

export class CreateRecordPresignedUrlsDto {
  @ApiProperty({
    description: '기록 날짜(YYYY-MM-DD)',
    example: '2026-07-09',
  })
  @IsDateString()
  recordDate!: string;

  @ApiProperty({
    description: '업로드할 이미지 MIME 타입',
    enum: ALLOWED_CONTENT_TYPES,
    example: 'image/jpeg',
  })
  @IsIn(ALLOWED_CONTENT_TYPES)
  contentType!: RecordImageContentType;
}
