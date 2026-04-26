import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import helmet from 'helmet';
import { AppModule } from './app.module';

const WEAK_DB_PASSWORDS = new Set(['adaptai_dev', 'postgres', 'password', '']);

function validateEnv(config: ConfigService): void {
  const errors: string[] = [];
  const isProd = config.get<string>('NODE_ENV') === 'production';

  // JWT secret is mandatory in every environment to fail fast.
  const jwtSecret = config.get<string>('JWT_SECRET');
  if (!jwtSecret) errors.push('Missing required env var: JWT_SECRET');
  if (isProd && jwtSecret && jwtSecret.length < 32) {
    errors.push('JWT_SECRET must be at least 32 chars in production');
  }

  if (isProd) {
    const requiredUrls = {
      FRONTEND_URL: config.get<string>('FRONTEND_URL'),
      API_PUBLIC_URL: config.get<string>('API_PUBLIC_URL'),
    };
    for (const [key, value] of Object.entries(requiredUrls)) {
      if (!value) errors.push(`Missing required env var: ${key}`);
      else if (!value.startsWith('https://')) {
        errors.push(`${key} must use https:// in production (got: ${value})`);
      }
    }

    const dbUser = config.get<string>('DB_USER');
    const dbPass = config.get<string>('DB_PASS');
    const dbName = config.get<string>('DB_NAME');
    if (!dbUser || !dbPass || !dbName) {
      errors.push('DB_USER, DB_PASS and DB_NAME are required in production');
    } else if (WEAK_DB_PASSWORDS.has(dbPass)) {
      errors.push('DB_PASS is using a known weak default — set a strong value');
    }

    const allowed = config.get<string>('ALLOWED_ORIGINS') ?? '';
    if (!allowed.trim()) {
      errors.push('ALLOWED_ORIGINS must be set in production');
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

  app.use(helmet());

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
