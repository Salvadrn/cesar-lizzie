import {
  Injectable,
  CanActivate,
  ExecutionContext,
  HttpException,
  HttpStatus,
} from '@nestjs/common';

const attempts = new Map<string, { count: number; resetAt: number }>();

@Injectable()
export class RateLimitGuard implements CanActivate {
  private readonly maxAttempts = 5;
  private readonly windowMs = 15 * 60 * 1000; // 15 minutes

  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();
    const ip = request.ip || request.connection?.remoteAddress || 'unknown';
    const key = `${ip}:${request.url}`;

    const now = Date.now();
    const entry = attempts.get(key);

    if (entry && now < entry.resetAt) {
      if (entry.count >= this.maxAttempts) {
        const retryAfter = Math.ceil((entry.resetAt - now) / 1000);
        throw new HttpException(
          `Demasiados intentos. Intenta de nuevo en ${retryAfter} segundos.`,
          HttpStatus.TOO_MANY_REQUESTS,
        );
      }
      entry.count++;
    } else {
      attempts.set(key, { count: 1, resetAt: now + this.windowMs });
    }

    return true;
  }
}
