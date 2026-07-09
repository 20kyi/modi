import { Body, Controller, Post } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { AuthService } from './auth.service';
import { AppleSignInDto } from './dto/apple-sign-in.dto';
import { AuthResponseDto } from './dto/auth-response.dto';

@ApiTags('auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('apple')
  @ApiOperation({ summary: 'Sign in with Apple' })
  signInWithApple(@Body() dto: AppleSignInDto): Promise<AuthResponseDto> {
    return this.authService.signInWithApple(dto);
  }
}
