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
  @ApiOperation({ summary: '내 기록 목록 조회' })
  async getMyRecords(@CurrentUser() user: User): Promise<RecordResponseDto[]> {
    const records = await this.recordsService.findMyRecords(user.id);
    return records.map((record) => RecordResponseDto.from(record));
  }

  @Post('me')
  @ApiOperation({ summary: '내 기록 저장/갱신(날짜 기준 upsert)' })
  async upsertMyRecord(
    @CurrentUser() user: User,
    @Body() dto: CreateRecordDto,
  ): Promise<RecordResponseDto> {
    const record = await this.recordsService.upsertMyRecord(user.id, dto);
    return RecordResponseDto.from(record);
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
