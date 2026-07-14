import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import type { User } from '../generated/prisma/client';
import { MySubscriptionResponseDto, SubscriptionResponseDto } from './dto/subscription-response.dto';
import { SyncSubscriptionDto } from './dto/sync-subscription.dto';
import { SubscriptionsService } from './subscriptions.service';

@ApiTags('subscriptions')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('subscriptions')
export class SubscriptionsController {
  constructor(private readonly subscriptionsService: SubscriptionsService) {}

  @Get('me')
  @ApiOperation({ summary: '내 MODI+ 구독 상태 조회' })
  async getMySubscription(
    @CurrentUser() user: User,
  ): Promise<MySubscriptionResponseDto> {
    const subscription = await this.subscriptionsService.findActiveForUser(user.id);
    return MySubscriptionResponseDto.from(subscription);
  }

  @Post('me/sync')
  @ApiOperation({ summary: '내 MODI+ 구매 정보 동기화' })
  async syncMySubscription(
    @CurrentUser() user: User,
    @Body() dto: SyncSubscriptionDto,
  ): Promise<SubscriptionResponseDto> {
    const subscription = await this.subscriptionsService.syncForUser(user.id, dto);
    return SubscriptionResponseDto.from(subscription);
  }
}
