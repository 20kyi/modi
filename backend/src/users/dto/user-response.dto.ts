import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import type { User } from '../../generated/prisma/client';

export class UserResponseDto {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty({ example: '영임' })
  nickname!: string;

  @ApiPropertyOptional({ example: 'https://cdn.example.com/avatar.jpg' })
  profileImageUrl!: string | null;

  @ApiProperty()
  createdAt!: Date;

  @ApiProperty()
  updatedAt!: Date;

  static from(user: User): UserResponseDto {
    return {
      id: user.id,
      nickname: user.nickname,
      profileImageUrl: user.profileImageUrl,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    };
  }
}
