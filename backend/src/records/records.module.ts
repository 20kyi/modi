import { Module } from '@nestjs/common';
import { PrismaModule } from '../database/prisma.module';
import { UploadModule } from '../upload/upload.module';
import { RecordsController } from './records.controller';
import { RecordsService } from './records.service';

@Module({
  imports: [PrismaModule, UploadModule],
  controllers: [RecordsController],
  providers: [RecordsService],
  exports: [RecordsService],
})
export class RecordsModule {}
