import { ApiProperty } from '@nestjs/swagger';

export class PresignedImageUrlDto {
  @ApiProperty({
    description: 'S3에 PUT 업로드할 Presigned URL',
    example:
      'https://modi-images.s3.ap-northeast-2.amazonaws.com/dev/users/.../original.jpg?X-Amz-Algorithm=...',
  })
  uploadUrl!: string;

  @ApiProperty({
    description: '업로드 완료 후 Record API에 저장할 S3 object key',
    example: 'dev/users/{userId}/records/2026-07-09/{uuid}-original.jpg',
  })
  key!: string;
}
