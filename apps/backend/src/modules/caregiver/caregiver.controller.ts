import {
  Controller,
  Get,
  Post,
  Patch,
  Param,
  Body,
  ForbiddenException,
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

  // Only the patient ('user' role) generates an invite for themselves.
  @Post('generate-invite')
  @Roles('user')
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
  @Roles('caregiver', 'user')
  async updatePermissions(
    @CurrentUser() user: { id: string; role: string },
    @Param('linkId') linkId: string,
    @Body() body: { permissions: any },
  ) {
    const link = await this.caregiverService.getLink(linkId);
    // Only the patient owning the link can change permissions; caregivers
    // must not be able to escalate their own access.
    if (user.role !== 'user' || link.userId !== user.id) {
      throw new ForbiddenException('Not allowed to modify this link');
    }
    return this.caregiverService.updatePermissions(linkId, body.permissions);
  }
}
