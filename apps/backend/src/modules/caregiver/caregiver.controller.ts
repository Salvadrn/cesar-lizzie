import {
  Controller,
  Get,
  Post,
  Patch,
  Param,
  Body,
  UseGuards,
} from '@nestjs/common';
import { CaregiverService } from './caregiver.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@Controller('caregiver')
@UseGuards(JwtAuthGuard, RolesGuard)
export class CaregiverController {
  constructor(private caregiverService: CaregiverService) {}

  @Post('generate-invite')
  async generateInvite(@CurrentUser() user: { id: string }) {
    const code = await this.caregiverService.generateInviteCode(user.id);
    return { inviteCode: code };
  }

  @Post('accept-invite')
  @Roles('caregiver')
  async acceptInvite(
    @CurrentUser() user: { id: string },
    @Body() body: { inviteCode: string; relationship?: string },
  ) {
    return this.caregiverService.acceptInvite(
      user.id,
      body.inviteCode,
      body.relationship,
    );
  }

  @Get('linked-users')
  @Roles('caregiver')
  async getLinkedUsers(@CurrentUser() user: { id: string }) {
    return this.caregiverService.getLinkedUsers(user.id);
  }

  @Patch('links/:linkId')
  @Roles('caregiver')
  async updatePermissions(
    @CurrentUser() user: { id: string },
    @Param('linkId') linkId: string,
    @Body() body: { permissions: any },
  ) {
    return this.caregiverService.updatePermissions(linkId, body.permissions, user.id);
  }
}
