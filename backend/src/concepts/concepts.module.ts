import { Module } from '@nestjs/common';
import { PrismaModule } from '../database/prisma.module';
import { ConceptsController } from './concepts.controller';
import { ConceptsService } from './concepts.service';

@Module({
  imports: [PrismaModule],
  controllers: [ConceptsController],
  providers: [ConceptsService],
})
export class ConceptsModule {}
