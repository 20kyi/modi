import { Controller, Get, ServiceUnavailableException } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { PrismaService } from '../prisma.service';

@ApiTags('database-health')
@Controller('database/health')
export class DatabaseHealthController {
  constructor(private readonly prisma: PrismaService) {}

  @Get()
  @ApiOperation({ summary: '데이터베이스 연결 상태 확인' })
  async check() {
    try {
      await this.prisma.$queryRaw`SELECT 1`;
      return { status: 'ok' };
    } catch (error) {
      throw new ServiceUnavailableException(
        error instanceof Error ? error.message : 'Database connection failed',
      );
    }
  }
}
