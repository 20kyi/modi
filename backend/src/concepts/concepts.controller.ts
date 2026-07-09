import { Controller, Get, UseGuards } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import type { User } from '../generated/prisma/client';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { OptionalJwtAuthGuard } from '../auth/guards/optional-jwt-auth.guard';
import { ConceptResponseDto } from './dto/concept-response.dto';
import { ConceptsService } from './concepts.service';

@ApiTags('concepts')
@ApiBearerAuth()
@Controller('concepts')
export class ConceptsController {
  constructor(private readonly conceptsService: ConceptsService) {}

  @Get()
  @UseGuards(OptionalJwtAuthGuard)
  @ApiOperation({ summary: '시스템 컨셉 조회 (로그인 시 내 커스텀 컨셉 포함)' })
  @ApiOkResponse({
    description: '게스트는 시스템 컨셉만, 로그인 사용자는 시스템 + 내 커스텀 컨셉',
    type: ConceptResponseDto,
    isArray: true,
  })
  async getConcepts(
    @CurrentUser() user: User | null,
  ): Promise<ConceptResponseDto[]> {
    const concepts = user
      ? await this.conceptsService.findAvailableConcepts(user.id)
      : await this.conceptsService.findSystemConcepts();
    return concepts.map((concept) => ConceptResponseDto.from(concept));
  }
}
