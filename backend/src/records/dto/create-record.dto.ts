import { ApiProperty } from '@nestjs/swagger';
import { IsBoolean, IsDateString, IsString } from 'class-validator';

export class CreateRecordDto {
  @ApiProperty({ format: 'uuid' })
  // iOS의 시스템 컨셉 UUID는 RFC 버전 비트를 따르지 않는 케이스가 있어 문자열로 검증합니다.
  // 실제 UUID 파싱/유효성은 DB 레이어에서 보장됩니다.
  @IsString()
  conceptId!: string;

  @ApiProperty({ description: '컨셉 제목' })
  @IsString()
  conceptTitle!: string;

  @ApiProperty({ description: '컨셉 이모지' })
  @IsString()
  conceptEmoji!: string;

  @ApiProperty({ description: '원본 이미지 data URL 문자열' })
  @IsString()
  originalImageUrl!: string;

  @ApiProperty({ description: '편집 이미지 data URL 문자열' })
  @IsString()
  editedImageUrl!: string;

  @ApiProperty({ description: '발견 날짜(YYYY-MM-DD 또는 ISO)', example: '2026-07-09' })
  @IsDateString()
  recordDate!: string;

  @ApiProperty({ default: false })
  @IsBoolean()
  isEdited!: boolean;
}
