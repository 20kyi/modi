import {
  Injectable,
  InternalServerErrorException,
  NotFoundException,
} from '@nestjs/common';
import type { User } from '../generated/prisma/client';
import { PrismaService } from '../database/prisma.service';
import { UploadService } from '../upload/upload.service';
import { UpdateUserDto } from './dto/update-user.dto';

@Injectable()
export class UsersService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly uploadService: UploadService,
  ) {}

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
    const user = await this.findById(userId);
    if (!user) {
      throw new NotFoundException('사용자를 찾을 수 없습니다.');
    }

    try {
      await this.uploadService.deleteAllUserObjects(userId);
    } catch (error) {
      throw new InternalServerErrorException(
        '회원 탈퇴 처리 중 오류가 발생했어요.',
        { cause: error },
      );
    }

    await this.prisma.user.delete({
      where: { id: userId },
    });
  }
}
