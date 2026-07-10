import { ApiProperty } from '@nestjs/swagger';
import { PresignedImageUrlDto } from './presigned-image-url.dto';

export class RecordPresignedUrlsResponseDto {
  @ApiProperty({ type: PresignedImageUrlDto })
  original!: PresignedImageUrlDto;

  @ApiProperty({ type: PresignedImageUrlDto })
  edited!: PresignedImageUrlDto;

  @ApiProperty({
    description: 'Presigned URL 만료 시간(초)',
    example: 900,
  })
  expiresIn!: number;
}
