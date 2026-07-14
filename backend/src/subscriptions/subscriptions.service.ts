import { Injectable } from '@nestjs/common';
import {
  StoreEnvironment,
  SubscriptionStatus,
  UserSubscription,
} from '../generated/prisma/client';
import { PrismaService } from '../database/prisma.service';
import { SyncSubscriptionDto } from './dto/sync-subscription.dto';

@Injectable()
export class SubscriptionsService {
  constructor(private readonly prisma: PrismaService) {}

  async findActiveForUser(userId: string): Promise<UserSubscription | null> {
    const now = new Date();
    const subscriptions = await this.prisma.userSubscription.findMany({
      where: {
        userId,
        status: SubscriptionStatus.ACTIVE,
        OR: [{ expiresAt: null }, { expiresAt: { gt: now } }],
      },
      orderBy: [{ expiresAt: 'desc' }, { purchasedAt: 'desc' }],
    });

    return subscriptions.sort((lhs, rhs) => {
      return (
        this.planPriority(rhs.productId) - this.planPriority(lhs.productId)
      );
    })[0] ?? null;
  }

  async syncForUser(
    userId: string,
    dto: SyncSubscriptionDto,
  ): Promise<UserSubscription> {
    const purchasedAt = new Date(dto.purchasedAt);
    const expiresAt = dto.expiresAt ? new Date(dto.expiresAt) : null;
    const status = dto.status ?? this.resolveStatus(expiresAt);

    return this.prisma.userSubscription.upsert({
      where: { originalTransactionId: dto.originalTransactionId },
      create: {
        userId,
        productId: dto.productId,
        planType: dto.planType,
        status,
        transactionId: dto.transactionId,
        originalTransactionId: dto.originalTransactionId,
        purchasedAt,
        expiresAt,
        environment: dto.environment ?? StoreEnvironment.UNKNOWN,
      },
      update: {
        userId,
        productId: dto.productId,
        planType: dto.planType,
        status,
        transactionId: dto.transactionId,
        purchasedAt,
        expiresAt,
        environment: dto.environment ?? StoreEnvironment.UNKNOWN,
      },
    });
  }

  private resolveStatus(expiresAt: Date | null): SubscriptionStatus {
    if (expiresAt !== null && expiresAt <= new Date()) {
      return SubscriptionStatus.EXPIRED;
    }

    return SubscriptionStatus.ACTIVE;
  }

  private planPriority(productId: string): number {
    if (productId.endsWith('.lifetime')) {
      return 3;
    }
    if (productId.endsWith('.annual')) {
      return 2;
    }
    if (productId.endsWith('.monthly')) {
      return 1;
    }
    return 0;
  }
}
