import {
  Injectable,
  CanActivate,
  ExecutionContext,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';

export const RATE_LIMIT_KEY = 'rateLimit';
export interface RateLimitOptions {
  max: number;
  windowMs: number;
}

/**
 * Simple in-memory rate limiter.
 * Tracks request counts per IP + route. Resets when window expires.
 * For production, replace with Redis-backed throttler (@nestjs/throttler).
 */
@Injectable()
export class RateLimitGuard implements CanActivate {
  private readonly buckets = new Map<string, { count: number; resetAt: number }>();

  constructor(private reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const options = this.reflector.getAllAndOverride<RateLimitOptions>(RATE_LIMIT_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (!options) return true;

    const req = context.switchToHttp().getRequest();
    const ip =
      req.headers['x-forwarded-for']?.split(',')[0].trim() ||
      req.ip ||
      req.connection?.remoteAddress ||
      'unknown';
    const route = `${req.method}:${req.route?.path ?? req.url}`;
    const key = `${ip}::${route}`;

    const now = Date.now();
    const bucket = this.buckets.get(key);

    if (!bucket || now > bucket.resetAt) {
      this.buckets.set(key, { count: 1, resetAt: now + options.windowMs });
      return true;
    }

    if (bucket.count >= options.max) {
      const retryAfterSec = Math.ceil((bucket.resetAt - now) / 1000);
      throw new HttpException(
        {
          statusCode: HttpStatus.TOO_MANY_REQUESTS,
          message: `Demasiados intentos. Intenta de nuevo en ${retryAfterSec} segundos.`,
          retryAfter: retryAfterSec,
        },
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }

    bucket.count++;
    return true;
  }
}
