import { Body, Controller, Post, UseGuards } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import type { User } from '../generated/prisma/client';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CreateRecordPresignedUrlsDto } from './dto/create-record-presigned-urls.dto';
import { RecordPresignedUrlsResponseDto } from './dto/record-presigned-urls-response.dto';
import { UploadService } from './upload.service';

@ApiTags('upload')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('upload')
export class UploadController {
  constructor(private readonly uploadService: UploadService) {}

  @Post('records/presigned-urls')
  @ApiOperation({
    summary: '기록 이미지 S3 업로드용 Presigned URL 발급',
    description:
      '원본/편집 이미지 각각에 대한 Presigned PUT URL을 발급합니다. ' +
      '클라이언트는 이미지 바이너리를 NestJS 서버가 아닌 S3에 직접 업로드한 뒤, ' +
      '응답의 key를 Record API에 전달합니다.',
  })
  async createRecordPresignedUrls(
    @CurrentUser() user: User,
    @Body() dto: CreateRecordPresignedUrlsDto,
  ): Promise<RecordPresignedUrlsResponseDto> {
    return this.uploadService.createRecordPresignedUrls(user.id, dto);
  }
}
