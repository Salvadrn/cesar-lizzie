import {
  Controller,
  Get,
  Post,
  Patch,
  Param,
  Body,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ExecutionsService } from './executions.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@Controller('executions')
@UseGuards(JwtAuthGuard)
export class ExecutionsController {
  constructor(private executionsService: ExecutionsService) {}

  @Post()
  async start(
    @CurrentUser() user: { id: string },
    @Body() body: { routineId: string; complexityLevel: number },
  ) {
    return this.executionsService.start(body.routineId, user.id, body.complexityLevel);
  }

  @Get(':id')
  async findById(@Param('id') id: string) {
    return this.executionsService.findById(id);
  }

  @Patch(':id')
  async updateStatus(
    @Param('id') id: string,
    @Body() body: { action: 'pause' | 'abandon' },
  ) {
    if (body.action === 'pause') return this.executionsService.pause(id);
    if (body.action === 'abandon') return this.executionsService.abandon(id);
  }

  @Post(':id/steps/:stepId/start')
  async startStep(
    @Param('id') executionId: string,
    @Param('stepId') stepId: string,
  ) {
    return this.executionsService.startStep(executionId, stepId);
  }

  @Post(':id/steps/:stepId/complete')
  async completeStep(
    @Param('id') executionId: string,
    @Param('stepId') stepId: string,
    @Body() metrics?: {
      errorCount?: number;
      stallCount?: number;
      rePromptCount?: number;
      neededHelp?: boolean;
    },
  ) {
    return this.executionsService.completeStep(executionId, stepId, metrics);
  }

  @Get('history')
  async getHistory(
    @CurrentUser() user: { id: string },
    @Query('limit') limit?: number,
    @Query('offset') offset?: number,
  ) {
    return this.executionsService.getHistory(user.id, limit, offset);
  }

  @Get('stats')
  async getStats(@CurrentUser() user: { id: string }) {
    return this.executionsService.getStats(user.id);
  }
}
