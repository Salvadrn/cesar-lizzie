import { Controller, Post, Get, Body, Param, UseGuards } from '@nestjs/common';
import { InteractionLogsService } from './interaction-logs.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@Controller('interactions')
@UseGuards(JwtAuthGuard)
export class InteractionLogsController {
  constructor(private logsService: InteractionLogsService) {}

  @Post('batch')
  async submitBatch(
    @CurrentUser() user: { id: string },
    @Body() body: { sessionId: string; events: any[] },
  ) {
    return this.logsService.submitBatch(user.id, body.sessionId, body.events);
  }

  @Get('summary/:userId')
  async getSummary(@Param('userId') userId: string) {
    return this.logsService.getSummary(userId);
  }
}
