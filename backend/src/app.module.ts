import { Module } from '@nestjs/common';
import { ConfigModule } from './config/config.module';
import { DatabaseModule } from './database/database.module';
import { PrismaModule } from './database/prisma.module';
import { CommonModule } from './common/common.module';
import { HealthModule } from './health/health.module';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { RecordsModule } from './records/records.module';
import { ConceptsModule } from './concepts/concepts.module';
import { CollectionsModule } from './collections/collections.module';
import { UploadModule } from './upload/upload.module';

@Module({
  imports: [
    ConfigModule,
    DatabaseModule,
    PrismaModule,
    CommonModule,
    HealthModule,
    AuthModule,
    UsersModule,
    RecordsModule,
    ConceptsModule,
    CollectionsModule,
    UploadModule,
  ],
})
export class AppModule {}
