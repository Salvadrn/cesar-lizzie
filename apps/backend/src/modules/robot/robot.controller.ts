import {
  Controller,
  Get,
  Post,
  Put,
  Body,
  Param,
  UseGuards,
  ForbiddenException,
} from '@nestjs/common';
import { RobotService } from './robot.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { PairRobotDto } from './dto/pair-robot.dto';
import { UpdateRobotConfigDto } from './dto/update-robot-config.dto';
import { RobotCommandDto } from './dto/robot-command.dto';

@Controller('robot')
@UseGuards(JwtAuthGuard, RolesGuard)
export class RobotController {
  constructor(private robotService: RobotService) {}

  @Post('register')
  @Roles('admin')
  async register(@Body() body: { serialNumber: string; name: string }) {
    return this.robotService.register(body.serialNumber, body.name);
  }

  @Post('pair')
  async pair(
    @CurrentUser() user: { id: string },
    @Body() dto: PairRobotDto,
  ) {
    return this.robotService.pair(dto.robotId, user.id);
  }

  @Get('mine')
  async getMyRobot(@CurrentUser() user: { id: string }) {
    return this.robotService.findByUserId(user.id);
  }

  @Get(':id/status')
  async getStatus(
    @Param('id') id: string,
    @CurrentUser() user: { id: string; role: string },
  ) {
    await this.assertRobotOwnership(id, user);
    return this.robotService.findById(id);
  }

  @Put(':id/config')
  async updateConfig(
    @Param('id') id: string,
    @CurrentUser() user: { id: string; role: string },
    @Body() dto: UpdateRobotConfigDto,
  ) {
    await this.assertRobotOwnership(id, user);
    return this.robotService.updateConfig(id, dto);
  }

  @Get(':id/telemetry')
  async getTelemetry(
    @Param('id') id: string,
    @CurrentUser() user: { id: string; role: string },
  ) {
    await this.assertRobotOwnership(id, user);
    return this.robotService.getLatestTelemetry(id);
  }

  @Post(':id/command')
  async sendCommand(
    @Param('id') id: string,
    @CurrentUser() user: { id: string; role: string },
    @Body() dto: RobotCommandDto,
  ) {
    await this.assertRobotOwnership(id, user);
    return { robotId: id, command: dto, issuedBy: user.id };
  }

  @Get('context/:userId')
  async getPatientContext(
    @Param('userId') userId: string,
    @CurrentUser() user: { id: string; role: string },
  ) {
    if (user.id !== userId && user.role !== 'admin' && user.role !== 'caregiver') {
      throw new ForbiddenException('No tienes permiso para ver este contexto');
    }
    return this.robotService.getPatientContext(userId);
  }

  @Get('my-context')
  async getMyContext(@CurrentUser() user: { id: string }) {
    return this.robotService.getPatientContext(user.id);
  }

  private async assertRobotOwnership(
    robotId: string,
    user: { id: string; role: string },
  ) {
    if (user.role === 'admin') return;

    const robot = await this.robotService.findById(robotId);
    if (!robot || robot.userId !== user.id) {
      throw new ForbiddenException('No tienes acceso a este robot');
    }
  }
}
