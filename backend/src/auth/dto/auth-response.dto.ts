import { ApiProperty } from '@nestjs/swagger';
import { UserResponseDto } from '../../users/dto/user-response.dto';

export class AuthResponseDto {
  @ApiProperty({ description: 'API 접근용 JWT' })
  accessToken!: string;

  @ApiProperty({ description: 'Bearer 고정 토큰 타입', example: 'Bearer' })
  tokenType!: 'Bearer';

  @ApiProperty({
    description: 'Apple 로그인으로 신규 생성된 유저인지 여부',
    example: true,
  })
  isNewUser!: boolean;

  @ApiProperty({ type: UserResponseDto })
  user!: UserResponseDto;
}
