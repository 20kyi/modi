import { Injectable, NotFoundException } from '@nestjs/common';
import type { User } from '../generated/prisma/client';
import { PrismaService } from '../database/prisma.service';
import { UpdateUserDto } from './dto/update-user.dto';

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  findById(id: string): Promise<User | null> {
    return this.prisma.user.findUnique({ where: { id } });
  }

  async updateProfile(userId: string, dto: UpdateUserDto): Promise<User> {
    try {
      return await this.prisma.user.update({
        where: { id: userId },
        data: {
          ...(dto.nickname !== undefined ? { nickname: dto.nickname } : {}),
          ...(dto.profileImageUrl !== undefined
            ? { profileImageUrl: dto.profileImageUrl }
            : {}),
        },
      });
    } catch {
      throw new NotFoundException('사용자를 찾을 수 없습니다.');
    }
  }

  async deleteMe(userId: string): Promise<void> {
    try {
      await this.prisma.user.delete({
        where: { id: userId },
      });
    } catch {
      throw new NotFoundException('사용자를 찾을 수 없습니다.');
    }
  }
}
