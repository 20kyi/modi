import { Module } from '@nestjs/common';
import { DatabaseHealthModule } from './health/database-health.module';

@Module({
  imports: [DatabaseHealthModule],
})
export class DatabaseModule {}
