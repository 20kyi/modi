import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  DeleteObjectCommand,
  DeleteObjectsCommand,
  GetObjectCommand,
  HeadObjectCommand,
  ListObjectsV2Command,
  PutObjectCommand,
  S3Client,
} from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { randomUUID } from 'crypto';
import type { CreateRecordPresignedUrlsDto } from './dto/create-record-presigned-urls.dto';
import type { RecordPresignedUrlsResponseDto } from './dto/record-presigned-urls-response.dto';
import type { PresignedImageUrlDto } from './dto/presigned-image-url.dto';

@Injectable()
export class UploadService {
  private readonly logger = new Logger(UploadService.name);
  private readonly s3Client: S3Client;

  constructor(private readonly configService: ConfigService) {
    // iOS URLSession 등 외부 클라이언트는 presigned PUT 시 체크섬 헤더를 보내지 않으므로
    // 기본 CRC32 서명을 끕니다. (미설정 시 URL에 x-amz-checksum-crc32가 붙어 업로드가 실패함)
    this.s3Client = new S3Client({
      region: this.configService.getOrThrow<string>('aws.region'),
      credentials: {
        accessKeyId: this.configService.getOrThrow<string>('aws.accessKeyId'),
        secretAccessKey: this.configService.getOrThrow<string>(
          'aws.secretAccessKey',
        ),
      },
      requestChecksumCalculation: 'WHEN_REQUIRED',
      responseChecksumValidation: 'WHEN_REQUIRED',
    });
  }

  async createRecordPresignedUrls(
    userId: string,
    dto: CreateRecordPresignedUrlsDto,
  ): Promise<RecordPresignedUrlsResponseDto> {
    const expiresIn = this.configService.getOrThrow<number>(
      'aws.presignedPutUrlExpiresIn',
    );
    const recordDate = this.normalizeRecordDate(dto.recordDate);
    const uploadId = randomUUID();

    const [original, edited] = await Promise.all([
      this.createPresignedPutUrl({
        userId,
        recordDate,
        uploadId,
        imageRole: 'original',
        contentType: dto.contentType,
        expiresIn,
      }),
      this.createPresignedPutUrl({
        userId,
        recordDate,
        uploadId,
        imageRole: 'edited',
        contentType: dto.contentType,
        expiresIn,
      }),
    ]);

    return { original, edited, expiresIn };
  }

  async createPresignedGetUrl(key: string): Promise<string> {
    const bucket = this.configService.getOrThrow<string>('aws.s3Bucket');
    const expiresIn = this.configService.getOrThrow<number>(
      'aws.presignedGetUrlExpiresIn',
    );

    const command = new GetObjectCommand({
      Bucket: bucket,
      Key: key,
    });

    return getSignedUrl(this.s3Client, command, { expiresIn });
  }

  async createPresignedGetUrls(keys: string[]): Promise<string[]> {
    return Promise.all(keys.map((key) => this.createPresignedGetUrl(key)));
  }

  resolveStoredImageKey(stored: string): string | null {
    if (!stored) {
      return null;
    }

    if (stored.startsWith('data:')) {
      return null;
    }

    if (stored.startsWith('http://') || stored.startsWith('https://')) {
      try {
        const pathname = new URL(stored).pathname;
        return pathname.startsWith('/') ? pathname.slice(1) : pathname;
      } catch {
        return null;
      }
    }

    return stored;
  }

  validateRecordImageKey(userId: string, key: string): boolean {
    const prefix = this.configService.getOrThrow<string>('aws.s3KeyPrefix');
    const expectedPrefix = `${prefix}/users/${userId}/records/`;

    return key.startsWith(expectedPrefix);
  }

  async deleteStoredImageObjects(...storedKeys: string[]): Promise<void> {
    const keys = [
      ...new Set(
        storedKeys
          .map((stored) => this.resolveStoredImageKey(stored))
          .filter((key): key is string => key !== null),
      ),
    ];

    await Promise.all(keys.map((key) => this.deleteObject(key)));
  }

  async deleteAllUserObjects(userId: string): Promise<void> {
    const bucket = this.configService.getOrThrow<string>('aws.s3Bucket');
    const prefix = this.buildUserObjectPrefix(userId);
    let continuationToken: string | undefined;

    do {
      const listResponse = await this.s3Client.send(
        new ListObjectsV2Command({
          Bucket: bucket,
          Prefix: prefix,
          ContinuationToken: continuationToken,
        }),
      );

      const keys = (listResponse.Contents ?? [])
        .map((object) => object.Key)
        .filter((key): key is string => Boolean(key));

      if (keys.length > 0) {
        await this.deleteObjectsInBatch(keys);
      }

      continuationToken = listResponse.IsTruncated
        ? listResponse.NextContinuationToken
        : undefined;
    } while (continuationToken);
  }

  async verifyStoredImageObjectExists(stored: string): Promise<boolean> {
    const key = this.resolveStoredImageKey(stored);
    if (!key) {
      return false;
    }

    return this.objectExists(key);
  }

  private async objectExists(key: string): Promise<boolean> {
    const bucket = this.configService.getOrThrow<string>('aws.s3Bucket');

    try {
      await this.s3Client.send(
        new HeadObjectCommand({
          Bucket: bucket,
          Key: key,
        }),
      );
      return true;
    } catch (error) {
      if (this.isS3NotFoundError(error)) {
        return false;
      }

      throw error;
    }
  }

  private isS3NotFoundError(error: unknown): boolean {
    return (
      typeof error === 'object' &&
      error !== null &&
      'name' in error &&
      (error.name === 'NotFound' || error.name === 'NoSuchKey')
    );
  }

  private async deleteObject(key: string): Promise<void> {
    const bucket = this.configService.getOrThrow<string>('aws.s3Bucket');

    try {
      await this.s3Client.send(
        new DeleteObjectCommand({
          Bucket: bucket,
          Key: key,
        }),
      );
    } catch (error) {
      this.logger.error(
        `S3 객체 삭제 실패 (key: ${key})`,
        error instanceof Error ? error.stack : String(error),
      );
    }
  }

  private buildUserObjectPrefix(userId: string): string {
    const prefix = this.configService.getOrThrow<string>('aws.s3KeyPrefix');
    return `${prefix}/users/${userId}/`;
  }

  private async deleteObjectsInBatch(keys: string[]): Promise<void> {
    const bucket = this.configService.getOrThrow<string>('aws.s3Bucket');

    for (let i = 0; i < keys.length; i += 1000) {
      const chunk = keys.slice(i, i + 1000);
      const response = await this.s3Client.send(
        new DeleteObjectsCommand({
          Bucket: bucket,
          Delete: {
            Objects: chunk.map((Key) => ({ Key })),
            Quiet: true,
          },
        }),
      );

      if (response.Errors?.length) {
        const details = response.Errors.map(
          (error) => `${error.Key}: ${error.Message}`,
        ).join(', ');
        throw new Error(`S3 batch delete failed: ${details}`);
      }
    }
  }

  private async createPresignedPutUrl(params: {
    userId: string;
    recordDate: string;
    uploadId: string;
    imageRole: 'original' | 'edited';
    contentType: string;
    expiresIn: number;
  }): Promise<PresignedImageUrlDto> {
    const bucket = this.configService.getOrThrow<string>('aws.s3Bucket');
    const key = this.buildObjectKey({
      userId: params.userId,
      recordDate: params.recordDate,
      uploadId: params.uploadId,
      imageRole: params.imageRole,
      contentType: params.contentType,
    });

    const command = new PutObjectCommand({
      Bucket: bucket,
      Key: key,
      ContentType: params.contentType,
    });

    const uploadUrl = await getSignedUrl(this.s3Client, command, {
      expiresIn: params.expiresIn,
    });

    return { uploadUrl, key };
  }

  buildObjectKey(params: {
    userId: string;
    recordDate: string;
    uploadId: string;
    imageRole: 'original' | 'edited';
    contentType: string;
  }): string {
    const prefix = this.configService.getOrThrow<string>('aws.s3KeyPrefix');
    const extension = params.contentType === 'image/png' ? 'png' : 'jpg';

    return [
      prefix,
      'users',
      params.userId,
      'records',
      params.recordDate,
      `${params.uploadId}-${params.imageRole}.${extension}`,
    ].join('/');
  }

  private normalizeRecordDate(recordDate: string): string {
    const date = new Date(recordDate);
    const year = date.getUTCFullYear();
    const month = String(date.getUTCMonth() + 1).padStart(2, '0');
    const day = String(date.getUTCDate()).padStart(2, '0');

    return `${year}-${month}-${day}`;
  }
}
