import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import appleSignin from 'apple-signin-auth';
import type { User } from '../generated/prisma/client';
import { PrismaService } from '../database/prisma.service';
import { UserResponseDto } from '../users/dto/user-response.dto';
import { AppleSignInDto } from './dto/apple-sign-in.dto';
import { AuthResponseDto } from './dto/auth-response.dto';

const DEFAULT_NICKNAME = '탐험가';

@Injectable()
export class AuthService {
  private readonly appleClientId: string;

  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
    configService: ConfigService,
  ) {
    this.appleClientId = configService.getOrThrow<string>('apple.clientId');
  }

  async signInWithApple(dto: AppleSignInDto): Promise<AuthResponseDto> {
    const appleSub = await this.verifyAppleIdentityToken(dto.identityToken);
    const { user, isNewUser } = await this.findOrCreateUser(appleSub, dto.nickname);
    const accessToken = await this.jwtService.signAsync({ sub: user.id });

    return {
      accessToken,
      tokenType: 'Bearer',
      isNewUser,
      user: UserResponseDto.from(user),
    };
  }

  private async verifyAppleIdentityToken(
    identityToken: string,
  ): Promise<string> {
    try {
      const payload = await appleSignin.verifyIdToken(identityToken, {
        audience: this.appleClientId,
        ignoreExpiration: false,
      });

      if (!payload.sub) {
        throw new UnauthorizedException('Apple 토큰에 사용자 정보가 없습니다.');
      }

      return payload.sub;
    } catch {
      throw new UnauthorizedException('Apple 로그인 토큰이 유효하지 않습니다.');
    }
  }

  private async findOrCreateUser(
    appleSub: string,
    nickname?: string,
  ): Promise<{ user: User; isNewUser: boolean }> {
    const existingUser = await this.prisma.user.findUnique({ where: { appleSub } });

    if (existingUser) {
      if (nickname && nickname !== existingUser.nickname) {
        const updatedUser = await this.prisma.user.update({
          where: { id: existingUser.id },
          data: { nickname },
        });
        return { user: updatedUser, isNewUser: false };
      }
      return { user: existingUser, isNewUser: false };
    }

    const newUser = await this.prisma.user.create({
      data: {
        appleSub,
        nickname: nickname ?? DEFAULT_NICKNAME,
      },
    });
    return { user: newUser, isNewUser: true };
  }
}
