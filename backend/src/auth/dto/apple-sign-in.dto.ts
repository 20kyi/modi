import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsNotEmpty, IsOptional, IsString, MaxLength } from 'class-validator';

export class AppleSignInDto {
  @ApiProperty({
    description: 'Sign in with Apple identityToken (JWT)',
    example: 'eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...',
  })
  @IsString()
  @IsNotEmpty()
  identityToken!: string;

  @ApiPropertyOptional({
    description: '첫 로그인 시 Apple에서 받은 닉네임 (없으면 기본값 사용)',
    example: '영임',
  })
  @IsOptional()
  @IsString()
  @MaxLength(50)
  nickname?: string;
}
