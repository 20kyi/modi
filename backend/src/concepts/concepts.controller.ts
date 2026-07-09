import { Controller, Get, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import type { User } from '../generated/prisma/client';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { ConceptResponseDto } from './dto/concept-response.dto';
import { ConceptsService } from './concepts.service';

@ApiTags('concepts')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('concepts')
export class ConceptsController {
  constructor(private readonly conceptsService: ConceptsService) {}

  @Get()
  @ApiOperation({ summary: '시스템 + 내 커스텀 컨셉 목록 조회' })
  async getConcepts(@CurrentUser() user: User): Promise<ConceptResponseDto[]> {
    const concepts = await this.conceptsService.findAvailableConcepts(user.id);
    return concepts.map((concept) => ConceptResponseDto.from(concept));
  }
}
