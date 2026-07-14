import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  StoreEnvironment,
  SubscriptionPlanType,
  SubscriptionStatus,
  UserSubscription,
} from '../../generated/prisma/client';

export class SubscriptionResponseDto {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty({ example: 'com.storybuild.modiapp.plus.annual' })
  productId!: string;

  @ApiProperty({ enum: SubscriptionPlanType })
  planType!: SubscriptionPlanType;

  @ApiProperty({ enum: SubscriptionStatus })
  status!: SubscriptionStatus;

  @ApiProperty({ example: '2000000123456789' })
  transactionId!: string;

  @ApiProperty({ example: '2000000123456789' })
  originalTransactionId!: string;

  @ApiProperty()
  purchasedAt!: Date;

  @ApiPropertyOptional({ nullable: true })
  expiresAt!: Date | null;

  @ApiProperty({ enum: StoreEnvironment })
  environment!: StoreEnvironment;

  @ApiProperty()
  createdAt!: Date;

  @ApiProperty()
  updatedAt!: Date;

  static from(subscription: UserSubscription): SubscriptionResponseDto {
    return {
      id: subscription.id,
      productId: subscription.productId,
      planType: subscription.planType,
      status: subscription.status,
      transactionId: subscription.transactionId,
      originalTransactionId: subscription.originalTransactionId,
      purchasedAt: subscription.purchasedAt,
      expiresAt: subscription.expiresAt,
      environment: subscription.environment,
      createdAt: subscription.createdAt,
      updatedAt: subscription.updatedAt,
    };
  }
}

export class MySubscriptionResponseDto {
  @ApiProperty({ description: 'MODI+ 활성 여부' })
  hasPremium!: boolean;

  @ApiPropertyOptional({ type: SubscriptionResponseDto, nullable: true })
  activeSubscription!: SubscriptionResponseDto | null;

  static from(subscription: UserSubscription | null): MySubscriptionResponseDto {
    return {
      hasPremium: subscription !== null,
      activeSubscription: subscription
        ? SubscriptionResponseDto.from(subscription)
        : null,
    };
  }
}
