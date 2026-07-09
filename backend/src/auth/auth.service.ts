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
    const user = await this.upsertUser(appleSub, dto.nickname);
    const accessToken = await this.jwtService.signAsync({ sub: user.id });

    return {
      accessToken,
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

  private async upsertUser(appleSub: string, nickname?: string): Promise<User> {
    const existing = await this.prisma.user.findUnique({ where: { appleSub } });

    if (existing) {
      if (nickname && nickname !== existing.nickname) {
        return this.prisma.user.update({
          where: { id: existing.id },
          data: { nickname },
        });
      }
      return existing;
    }

    return this.prisma.user.create({
      data: {
        appleSub,
        nickname: nickname ?? DEFAULT_NICKNAME,
      },
    });
  }
}
