import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AppModule } from './app.module';

/**
 * Validates required environment variables and enforces HTTPS in production.
 * Fails fast on boot if misconfigured.
 */
function validateEnv(config: ConfigService): void {
  const isProd = config.get<string>('NODE_ENV') === 'production';
  if (!isProd) return;

  const requiredUrls = {
    FRONTEND_URL: config.get<string>('FRONTEND_URL'),
    API_PUBLIC_URL: config.get<string>('API_PUBLIC_URL'),
  };

  const errors: string[] = [];
  for (const [key, value] of Object.entries(requiredUrls)) {
    if (!value) {
      errors.push(`Missing required env var: ${key}`);
      continue;
    }
    if (!value.startsWith('https://')) {
      errors.push(`${key} must use https:// in production (got: ${value})`);
    }
  }

  if (errors.length > 0) {
    throw new Error('Environment validation failed:\n' + errors.join('\n'));
  }
}

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const logger = new Logger('Bootstrap');
  const configService = app.get(ConfigService);
  const isProd = configService.get<string>('NODE_ENV') === 'production';

  validateEnv(configService);

  app.setGlobalPrefix('api/v1');

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  // Build allowed origins from env + dev defaults
  const corsOrigins = (configService.get<string>('ALLOWED_ORIGINS') ?? '')
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean);
  if (!isProd) {
    corsOrigins.push('http://localhost:3000', 'http://localhost:8081');
  }

  app.enableCors({
    origin: corsOrigins,
    credentials: true,
  });

  const port = configService.get<number>('BACKEND_PORT', 3001);

  await app.listen(port);
  logger.log(`Adapt AI Backend running on port ${port} (${isProd ? 'prod' : 'dev'})`);
}
bootstrap();
