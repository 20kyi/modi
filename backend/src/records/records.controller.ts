import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiParam,
  ApiTags,
} from '@nestjs/swagger';
import type { User } from '../generated/prisma/client';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CreateRecordDto } from './dto/create-record.dto';
import { RecordResponseDto } from './dto/record-response.dto';
import { RecordsService } from './records.service';

@ApiTags('records')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('records')
export class RecordsController {
  constructor(private readonly recordsService: RecordsService) {}

  @Get('me')
  @ApiOperation({
    summary: '내 기록 목록 조회',
    description:
      'DB에 저장된 S3 object key를 기반으로 이미지 Presigned GET URL을 생성해 반환합니다.',
  })
  async getMyRecords(@CurrentUser() user: User): Promise<RecordResponseDto[]> {
    return this.recordsService.findMyRecords(user.id);
  }

  @Post('me')
  @ApiOperation({
    summary: '내 기록 저장/갱신(날짜 기준 upsert)',
    description:
      '요청에는 S3 object key를 전달하고, 응답에는 이미지 조회용 Presigned GET URL을 반환합니다.',
  })
  async upsertMyRecord(
    @CurrentUser() user: User,
    @Body() dto: CreateRecordDto,
  ): Promise<RecordResponseDto> {
    return this.recordsService.upsertMyRecord(user.id, dto);
  }

  @Delete('me/:recordId')
  @ApiOperation({ summary: '내 기록 삭제' })
  @ApiParam({ name: 'recordId', format: 'uuid' })
  async deleteMyRecord(
    @CurrentUser() user: User,
    @Param('recordId') recordId: string,
  ): Promise<void> {
    await this.recordsService.deleteMyRecord(user.id, recordId);
  }
}
