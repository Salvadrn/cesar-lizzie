import { Controller, Get, Patch, Body, UseGuards } from '@nestjs/common';
import { UsersService } from './users.service';
import { AdaptiveService } from './adaptive.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { UpdateProfileDto } from './dto/update-profile.dto';

@Controller('users')
@UseGuards(JwtAuthGuard)
export class UsersController {
  constructor(
    private usersService: UsersService,
    private adaptiveService: AdaptiveService,
  ) {}

  @Get('me')
  async getMe(@CurrentUser() user: { id: string }) {
    return this.usersService.findByIdOrFail(user.id);
  }

  @Get('me/profile')
  async getProfile(@CurrentUser() user: { id: string }) {
    return this.usersService.getProfileOrFail(user.id);
  }

  @Patch('me/profile')
  async updateProfile(
    @CurrentUser() user: { id: string },
    @Body() dto: UpdateProfileDto,
  ) {
    return this.usersService.updateProfile(user.id, dto);
  }

  @Get('me/adaptive-level')
  async getAdaptiveLevel(@CurrentUser() user: { id: string }) {
    const profile = await this.usersService.getProfileOrFail(user.id);
    return {
      currentComplexity: profile.currentComplexity,
      complexityFloor: profile.complexityFloor,
      complexityCeiling: profile.complexityCeiling,
    };
  }
}
