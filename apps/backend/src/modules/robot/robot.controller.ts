import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import { RobotService } from './robot.service';
import { RobotGateway } from './robot.gateway';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { RegisterRobotDto } from './dto/register-robot.dto';
import { UpdateRobotConfigDto } from './dto/update-robot-config.dto';
import { RobotCommandDto } from './dto/robot-command.dto';
import { PairRobotDto } from './dto/pair-robot.dto';

@Controller('robot')
@UseGuards(JwtAuthGuard)
export class RobotController {
  constructor(
    private robotService: RobotService,
    private robotGateway: RobotGateway,
  ) {}

  @Post('register')
  async register(@Body() dto: RegisterRobotDto) {
    return this.robotService.register(dto);
  }

  // QR Pairing: paciente escanea QR del robot
  @Post('pair')
  async pair(
    @CurrentUser() user: { id: string },
    @Body() dto: PairRobotDto,
  ) {
    return this.robotService.pairWithUser(dto.serialNumber, dto.pairingCode, user.id);
  }

  @Post(':id/unpair')
  async unpair(
    @Param('id') id: string,
    @CurrentUser() user: { id: string },
  ) {
    return this.robotService.unpair(id, user.id);
  }

  @Get(':id/pairing-qr')
  async getPairingQR(@Param('id') id: string) {
    return this.robotService.generatePairingQR(id);
  }

  @Get('my')
  async getMyRobot(@CurrentUser() user: { id: string }) {
    return this.robotService.findByUser(user.id);
  }

  @Get(':id/status')
  async getStatus(@Param('id') id: string) {
    return this.robotService.getStatus(id);
  }

  @Put(':id/config')
  async updateConfig(
    @Param('id') id: string,
    @Body() dto: UpdateRobotConfigDto,
  ) {
    const config = await this.robotService.updateConfig(id, dto);
    this.robotGateway.sendCommandToRobot(id, {
      commandType: 'update_config',
      payload: dto as Record<string, unknown>,
      issuedBy: 'api',
      issuedAt: new Date().toISOString(),
    });
    return config;
  }

  @Post(':id/command')
  async sendCommand(
    @Param('id') id: string,
    @CurrentUser() user: { id: string },
    @Body() dto: RobotCommandDto,
  ) {
    await this.robotService.findById(id);
    const command = {
      ...dto,
      issuedBy: user.id,
      issuedAt: new Date().toISOString(),
    };
    this.robotGateway.sendCommandToRobot(id, command);
    return { sent: true, command };
  }

  @Get(':id/telemetry')
  async getTelemetry(
    @Param('id') id: string,
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
  ) {
    return this.robotService.getTelemetryHistory(
      id,
      limit ? parseInt(limit, 10) : 100,
      offset ? parseInt(offset, 10) : 0,
    );
  }

  @Delete(':id')
  async deactivate(@Param('id') id: string) {
    await this.robotService.deactivate(id);
    return { deactivated: true };
  }
}
