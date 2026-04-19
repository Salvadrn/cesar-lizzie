import { Controller, Post, Body, UseGuards, Request } from '@nestjs/common';
import { AuthService } from './auth.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { LocalAuthGuard } from './guards/local-auth.guard';
import { RateLimitGuard } from './guards/rate-limit.guard';
import { RateLimit } from '../common/decorators/rate-limit.decorator';

@Controller('auth')
@UseGuards(RateLimitGuard)
export class AuthController {
  constructor(private authService: AuthService) {}

  // 5 registrations per IP per 15 minutes
  @Post('register')
  @RateLimit({ max: 5, windowMs: 15 * 60 * 1000 })
  async register(@Body() dto: RegisterDto) {
    return this.authService.register(dto);
  }

  // 5 login attempts per IP per 15 minutes (brute-force protection)
  @UseGuards(LocalAuthGuard)
  @Post('login')
  @RateLimit({ max: 5, windowMs: 15 * 60 * 1000 })
  async login(@Request() req: { user: any }, @Body() _dto: LoginDto) {
    return this.authService.login(req.user);
  }

  // 20 refreshes per IP per 5 minutes
  @Post('refresh')
  @RateLimit({ max: 20, windowMs: 5 * 60 * 1000 })
  async refresh(@Body('refreshToken') refreshToken: string) {
    return this.authService.refreshToken(refreshToken);
  }
}
