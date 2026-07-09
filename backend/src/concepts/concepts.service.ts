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
}
