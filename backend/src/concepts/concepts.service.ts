import { Injectable } from '@nestjs/common';
import { ConceptType, type Concept } from '../generated/prisma/client';
import { PrismaService } from '../database/prisma.service';

@Injectable()
export class ConceptsService {
  constructor(private readonly prisma: PrismaService) {}

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
}
