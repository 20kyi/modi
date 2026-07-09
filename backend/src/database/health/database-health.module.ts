import { Module } from '@nestjs/common';
import { DatabaseHealthController } from './database-health.controller';

@Module({
  controllers: [DatabaseHealthController],
})
export class DatabaseHealthModule {}
