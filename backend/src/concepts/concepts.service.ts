import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { ConceptCategory, ConceptType, type Concept } from '../generated/prisma/client';
import { PrismaService } from '../database/prisma.service';
import { CreateCustomConceptDto } from './dto/create-custom-concept.dto';
import { UpdateCustomConceptDto } from './dto/update-custom-concept.dto';

@Injectable()
export class ConceptsService {
  constructor(private readonly prisma: PrismaService) {}

  findSystemConcepts(): Promise<Concept[]> {
    return this.prisma.concept.findMany({
      where: { type: ConceptType.SYSTEM },
      orderBy: { createdAt: 'asc' },
    });
  }

  findAvailableConcepts(userId: string): Promise<Concept[]> {
    return this.prisma.concept.findMany({
      where: {
        OR: [{ type: ConceptType.SYSTEM }, { userId, type: ConceptType.CUSTOM }],
      },
      orderBy: [{ type: 'asc' }, { createdAt: 'asc' }],
    });
  }

  /**
   * 향후 `/concepts/me/custom` 등 사용자 커스텀 컨셉 전용 API에 재사용할 수 있는 조회 메서드.
   */
  findMyCustomConcepts(userId: string): Promise<Concept[]> {
    return this.prisma.concept.findMany({
      where: { userId, type: ConceptType.CUSTOM },
      orderBy: { createdAt: 'asc' },
    });
  }

  async createMyCustomConcept(
    userId: string,
    dto: CreateCustomConceptDto,
  ): Promise<Concept> {
    const existing = await this.prisma.concept.findUnique({
      where: { id: dto.id },
    });

    if (existing) {
      if (existing.userId !== userId || existing.type !== ConceptType.CUSTOM) {
        throw new ConflictException('이미 사용 중인 컨셉 ID예요.');
      }

      return this.prisma.concept.update({
        where: { id: dto.id },
        data: this.customConceptDataFromCreateDto(dto),
      });
    }

    return this.prisma.concept.create({
      data: {
        id: dto.id,
        userId,
        type: ConceptType.CUSTOM,
        category: ConceptCategory.CUSTOM,
        ...this.customConceptDataFromCreateDto(dto),
      },
    });
  }

  async updateMyCustomConcept(
    userId: string,
    conceptId: string,
    dto: UpdateCustomConceptDto,
  ): Promise<Concept> {
    const concept = await this.findOwnedCustomConcept(userId, conceptId);

    return this.prisma.concept.update({
      where: { id: concept.id },
      data: {
        ...(dto.title !== undefined ? { title: dto.title } : {}),
        ...(dto.emoji !== undefined ? { emoji: dto.emoji } : {}),
        ...(dto.description !== undefined ? { description: dto.description } : {}),
        ...(dto.missionPrompt !== undefined ? { missionPrompt: dto.missionPrompt } : {}),
        ...(dto.themeColorHex !== undefined ? { themeColorHex: dto.themeColorHex } : {}),
        ...(dto.sourceTemplateId !== undefined
          ? { sourceTemplateId: dto.sourceTemplateId }
          : {}),
      },
    });
  }

  async deleteMyCustomConcept(userId: string, conceptId: string): Promise<void> {
    const concept = await this.findOwnedCustomConcept(userId, conceptId);

    const recordCount = await this.prisma.record.count({
      where: { conceptId: concept.id, userId },
    });

    if (recordCount > 0) {
      throw new BadRequestException(
        '기록이 있는 커스텀 컨셉은 삭제할 수 없어요. 기록을 먼저 삭제해주세요.',
      );
    }

    await this.prisma.concept.delete({
      where: { id: concept.id },
    });
  }

  private async findOwnedCustomConcept(
    userId: string,
    conceptId: string,
  ): Promise<Concept> {
    const concept = await this.prisma.concept.findFirst({
      where: {
        id: conceptId,
        userId,
        type: ConceptType.CUSTOM,
      },
    });

    if (!concept) {
      throw new NotFoundException('커스텀 컨셉을 찾을 수 없어요.');
    }

    return concept;
  }

  private customConceptDataFromCreateDto(dto: CreateCustomConceptDto) {
    return {
      title: dto.title,
      emoji: dto.emoji,
      description: dto.description ?? '',
      missionPrompt: dto.missionPrompt,
      themeColorHex: dto.themeColorHex ?? 'E8ECF0',
      sourceTemplateId: dto.sourceTemplateId ?? null,
    };
  }
}
