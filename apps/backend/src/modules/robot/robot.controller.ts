import {
  Controller,
  Get,
  Post,
  Put,
  Body,
  Param,
  UseGuards,
} from '@nestjs/common';
import { RobotService } from './robot.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { RegisterRobotDto } from './dto/register-robot.dto';
import { PairRobotDto } from './dto/pair-robot.dto';
import { UpdateRobotConfigDto } from './dto/update-robot-config.dto';
import { RobotCommandDto } from './dto/robot-command.dto';

@Controller('robot')
@UseGuards(JwtAuthGuard)
export class RobotController {
  constructor(private robotService: RobotService) {}

  @Post('register')
  async register(@Body() dto: RegisterRobotDto) {
    return this.robotService.register(dto.serialNumber, dto.name, dto.apiKey);
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
  async getStatus(@Param('id') id: string) {
    return this.robotService.findById(id);
  }

  @Put(':id/config')
  async updateConfig(
    @Param('id') id: string,
    @Body() dto: UpdateRobotConfigDto,
  ) {
    return this.robotService.updateConfig(id, dto);
  }

  @Get(':id/telemetry')
  async getTelemetry(@Param('id') id: string) {
    return this.robotService.getLatestTelemetry(id);
  }

  @Post(':id/command')
  async sendCommand(
    @Param('id') id: string,
    @CurrentUser() user: { id: string },
    @Body() dto: RobotCommandDto,
  ) {
    // Command is relayed via Socket.IO gateway
    return { robotId: id, command: dto, issuedBy: user.id };
  }

  /**
   * Patient context endpoint — returns aggregated patient data
   * for the robot/JARVIS to use in interactions.
   */
  @Get('context/:userId')
  async getPatientContext(@Param('userId') userId: string) {
    return this.robotService.getPatientContext(userId);
  }

  /**
   * Shortcut: get context for the currently authenticated user's patient.
   */
  @Get('my-context')
  async getMyContext(@CurrentUser() user: { id: string }) {
    return this.robotService.getPatientContext(user.id);
  }
}
