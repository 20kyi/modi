import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, MaxLength } from 'class-validator';

export class CreateCustomConceptDto {
  @ApiProperty({ format: 'uuid' })
  @IsString()
  id!: string;

  @ApiProperty({ example: '카페 순간' })
  @IsString()
  @MaxLength(100)
  title!: string;

  @ApiProperty({ example: '☕️' })
  @IsString()
  @MaxLength(16)
  emoji!: string;

  @ApiPropertyOptional({ example: '오늘 마신 커피와 카페의 분위기를 남겨요' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  description?: string;

  @ApiProperty({ example: '커피를 찍으세요' })
  @IsString()
  @MaxLength(200)
  missionPrompt!: string;

  @ApiPropertyOptional({ example: 'F0E8E0' })
  @IsOptional()
  @IsString()
  @MaxLength(16)
  themeColorHex?: string;

  @ApiPropertyOptional({ example: 'cafe-moments' })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  sourceTemplateId?: string;
}
