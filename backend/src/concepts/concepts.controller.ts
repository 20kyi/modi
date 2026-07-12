import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiNoContentResponse,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import type { User } from '../generated/prisma/client';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { OptionalJwtAuthGuard } from '../auth/guards/optional-jwt-auth.guard';
import { ConceptResponseDto } from './dto/concept-response.dto';
import { CreateCustomConceptDto } from './dto/create-custom-concept.dto';
import { UpdateCustomConceptDto } from './dto/update-custom-concept.dto';
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

  @Get('me/custom')
  @UseGuards(JwtAuthGuard)
  @ApiOperation({ summary: '내 커스텀 컨셉 목록 조회' })
  @ApiOkResponse({
    description: '로그인 사용자의 커스텀 컨셉 목록',
    type: ConceptResponseDto,
    isArray: true,
  })
  async getMyCustomConcepts(
    @CurrentUser() user: User,
  ): Promise<ConceptResponseDto[]> {
    const concepts = await this.conceptsService.findMyCustomConcepts(user.id);
    return concepts.map((concept) => ConceptResponseDto.from(concept));
  }

  @Post('me/custom')
  @UseGuards(JwtAuthGuard)
  @ApiOperation({ summary: '커스텀 컨셉 생성 (카드 메타데이터 동기화)' })
  @ApiOkResponse({ type: ConceptResponseDto })
  async createMyCustomConcept(
    @CurrentUser() user: User,
    @Body() dto: CreateCustomConceptDto,
  ): Promise<ConceptResponseDto> {
    const concept = await this.conceptsService.createMyCustomConcept(
      user.id,
      dto,
    );
    return ConceptResponseDto.from(concept);
  }

  @Patch('me/custom/:id')
  @UseGuards(JwtAuthGuard)
  @ApiOperation({ summary: '커스텀 컨셉 수정' })
  @ApiOkResponse({ type: ConceptResponseDto })
  async updateMyCustomConcept(
    @CurrentUser() user: User,
    @Param('id') conceptId: string,
    @Body() dto: UpdateCustomConceptDto,
  ): Promise<ConceptResponseDto> {
    const concept = await this.conceptsService.updateMyCustomConcept(
      user.id,
      conceptId,
      dto,
    );
    return ConceptResponseDto.from(concept);
  }

  @Delete('me/custom/:id')
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: '커스텀 컨셉 삭제' })
  @ApiNoContentResponse({ description: '커스텀 컨셉 삭제 완료' })
  async deleteMyCustomConcept(
    @CurrentUser() user: User,
    @Param('id') conceptId: string,
  ): Promise<void> {
    await this.conceptsService.deleteMyCustomConcept(user.id, conceptId);
  }
}
