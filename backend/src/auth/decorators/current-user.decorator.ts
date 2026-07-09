import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import type { User } from '../../generated/prisma/client';

export const CurrentUser = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext): User | null => {
    const request = ctx.switchToHttp().getRequest<{ user?: User }>();
    return request.user ?? null;
  },
);
