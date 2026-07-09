import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  ConceptCategory,
  ConceptType,
  type Concept,
} from '../../generated/prisma/client';

export class ConceptResponseDto {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiPropertyOptional({ format: 'uuid' })
  userId!: string | null;

  @ApiProperty({ enum: ConceptType, enumName: 'ConceptType' })
  type!: ConceptType;

  @ApiProperty({ example: 'Pink Love' })
  title!: string;

  @ApiProperty({ example: '🩷' })
  emoji!: string;

  @ApiProperty({ example: '사랑스러운 분홍빛 순간을 모아요' })
  description!: string;

  @ApiProperty({ enum: ConceptCategory, enumName: 'ConceptCategory' })
  category!: ConceptCategory;

  @ApiProperty({ example: '분홍색을 찍으세요' })
  missionPrompt!: string;

  @ApiProperty({ example: 'F8DDE8' })
  themeColorHex!: string;

  @ApiPropertyOptional()
  sourceTemplateId!: string | null;

  @ApiProperty({ example: 20 })
  targetCount!: number;

  @ApiProperty()
  createdAt!: Date;

  @ApiProperty()
  updatedAt!: Date;

  static from(concept: Concept): ConceptResponseDto {
    return {
      id: concept.id,
      userId: concept.userId,
      type: concept.type,
      title: concept.title,
      emoji: concept.emoji,
      description: concept.description,
      category: concept.category,
      missionPrompt: concept.missionPrompt,
      themeColorHex: concept.themeColorHex,
      sourceTemplateId: concept.sourceTemplateId,
      targetCount: concept.targetCount,
      createdAt: concept.createdAt,
      updatedAt: concept.updatedAt,
    };
  }
}
