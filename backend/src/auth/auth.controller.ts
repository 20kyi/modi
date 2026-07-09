import { Body, Controller, Post } from '@nestjs/common';
import {
  ApiBody,
  ApiOkResponse,
  ApiOperation,
  ApiUnauthorizedResponse,
  ApiTags,
} from '@nestjs/swagger';
import { AuthService } from './auth.service';
import { AppleSignInDto } from './dto/apple-sign-in.dto';
import { AuthResponseDto } from './dto/auth-response.dto';

@ApiTags('auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('apple')
  @ApiOperation({ summary: 'Sign in with Apple' })
  @ApiBody({ type: AppleSignInDto })
  @ApiOkResponse({
    description: '로그인 성공 (신규 유저는 생성 후 토큰 발급)',
    type: AuthResponseDto,
  })
  @ApiUnauthorizedResponse({
    description: '유효하지 않은 Apple identityToken',
  })
  signInWithApple(@Body() dto: AppleSignInDto): Promise<AuthResponseDto> {
    return this.authService.signInWithApple(dto);
  }
}
