import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsDateString, IsEnum, IsOptional, IsString } from 'class-validator';
import {
  StoreEnvironment,
  SubscriptionPlanType,
  SubscriptionStatus,
} from '../../generated/prisma/client';

export class SyncSubscriptionDto {
  @ApiProperty({ example: 'com.storybuild.modiapp.plus.annual' })
  @IsString()
  productId!: string;

  @ApiProperty({ enum: SubscriptionPlanType, example: SubscriptionPlanType.ANNUAL })
  @IsEnum(SubscriptionPlanType)
  planType!: SubscriptionPlanType;

  @ApiProperty({ example: '2000000123456789' })
  @IsString()
  transactionId!: string;

  @ApiProperty({ example: '2000000123456789' })
  @IsString()
  originalTransactionId!: string;

  @ApiProperty({ example: '2026-07-14T05:01:00.000Z' })
  @IsDateString()
  purchasedAt!: string;

  @ApiPropertyOptional({ example: '2026-08-14T05:01:00.000Z', nullable: true })
  @IsOptional()
  @IsDateString()
  expiresAt?: string | null;

  @ApiPropertyOptional({ enum: StoreEnvironment, example: StoreEnvironment.SANDBOX })
  @IsOptional()
  @IsEnum(StoreEnvironment)
  environment?: StoreEnvironment;

  @ApiPropertyOptional({ enum: SubscriptionStatus, example: SubscriptionStatus.ACTIVE })
  @IsOptional()
  @IsEnum(SubscriptionStatus)
  status?: SubscriptionStatus;
}
