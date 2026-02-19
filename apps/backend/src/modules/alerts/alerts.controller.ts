import { Controller, Get, Patch, Param, UseGuards } from '@nestjs/common';
import { AlertsService } from './alerts.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@Controller('alerts')
@UseGuards(JwtAuthGuard)
export class AlertsController {
  constructor(private alertsService: AlertsService) {}

  @Get()
  async findAll(@CurrentUser() user: { id: string; role: string }) {
    if (user.role === 'caregiver') {
      return this.alertsService.findForCaregiver(user.id);
    }
    return this.alertsService.findByUser(user.id);
  }

  @Get('unread-count')
  async getUnreadCount(@CurrentUser() user: { id: string }) {
    return { count: await this.alertsService.getUnreadCount(user.id) };
  }

  @Patch(':id/read')
  async markRead(@Param('id') id: string) {
    await this.alertsService.markRead(id);
    return { success: true };
  }

  @Patch(':id/acknowledge')
  async acknowledge(@Param('id') id: string) {
    await this.alertsService.acknowledge(id);
    return { success: true };
  }
}
