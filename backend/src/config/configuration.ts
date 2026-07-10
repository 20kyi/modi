const resolveS3KeyPrefix = (): string => {
  if (process.env.AWS_S3_KEY_PREFIX) {
    return process.env.AWS_S3_KEY_PREFIX;
  }

  return process.env.NODE_ENV === 'production' ? 'prod' : 'dev';
};

export default () => ({
  port: parseInt(process.env.PORT ?? '3000', 10),
  nodeEnv: process.env.NODE_ENV ?? 'development',
  apiPrefix: process.env.API_PREFIX ?? 'api',
  jwt: {
    secret: process.env.JWT_SECRET ?? 'dev-only-change-me',
    expiresIn: process.env.JWT_EXPIRES_IN ?? '7d',
  },
  apple: {
    clientId: process.env.APPLE_CLIENT_ID ?? 'com.storybuild.modiapp',
  },
  aws: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
    region: process.env.AWS_REGION ?? 'ap-northeast-2',
    s3Bucket: process.env.AWS_S3_BUCKET,
    s3KeyPrefix: resolveS3KeyPrefix(),
    presignedPutUrlExpiresIn: parseInt(
      process.env.AWS_S3_PRESIGNED_PUT_URL_EXPIRES_IN ??
        process.env.AWS_S3_PRESIGNED_URL_EXPIRES_IN ??
        '900',
      10,
    ),
    presignedGetUrlExpiresIn: parseInt(
      process.env.AWS_S3_PRESIGNED_GET_URL_EXPIRES_IN ?? '3600',
      10,
    ),
  },
});
