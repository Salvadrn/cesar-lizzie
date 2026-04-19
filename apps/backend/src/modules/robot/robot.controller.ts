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
  ForbiddenException,
} from '@nestjs/common';
import { RobotService } from './robot.service';
import { RobotGateway } from './robot.gateway';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
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

  // --- Admin only: register a new physical robot in the fleet ---
  @Post('register')
  @UseGuards(RolesGuard)
  @Roles('admin')
  async register(@Body() dto: RegisterRobotDto) {
    // Service generates apiKey server-side (never accepted from client)
    return this.robotService.register(dto);
  }

  // --- Pairing: any authenticated patient can pair their own robot ---
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
    await this.assertCanAccessRobot(id, user.id);
    return this.robotService.unpair(id, user.id);
  }

  // Admin only: regenerate the QR for a robot
  @Get(':id/pairing-qr')
  @UseGuards(RolesGuard)
  @Roles('admin')
  async getPairingQR(@Param('id') id: string) {
    return this.robotService.generatePairingQR(id);
  }

  @Get('my')
  async getMyRobot(@CurrentUser() user: { id: string }) {
    return this.robotService.findByUser(user.id);
  }

  @Get(':id/status')
  async getStatus(
    @Param('id') id: string,
    @CurrentUser() user: { id: string; role?: string },
  ) {
    await this.assertCanAccessRobot(id, user.id, user.role);
    return this.robotService.getStatus(id);
  }

  @Put(':id/config')
  async updateConfig(
    @Param('id') id: string,
    @CurrentUser() user: { id: string; role?: string },
    @Body() dto: UpdateRobotConfigDto,
  ) {
    await this.assertCanAccessRobot(id, user.id, user.role);
    const config = await this.robotService.updateConfig(id, dto);
    this.robotGateway.sendCommandToRobot(id, {
      commandType: 'update_config',
      payload: dto as Record<string, unknown>,
      issuedBy: user.id,
      issuedAt: new Date().toISOString(),
    });
    return config;
  }

  @Post(':id/command')
  async sendCommand(
    @Param('id') id: string,
    @CurrentUser() user: { id: string; role?: string },
    @Body() dto: RobotCommandDto,
  ) {
    await this.assertCanAccessRobot(id, user.id, user.role);
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
    @CurrentUser() user: { id: string; role?: string },
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
  ) {
    await this.assertCanAccessRobot(id, user.id, user.role);
    return this.robotService.getTelemetryHistory(
      id,
      limit ? parseInt(limit, 10) : 100,
      offset ? parseInt(offset, 10) : 0,
    );
  }

  // Admin only: permanently deactivate a robot
  @Delete(':id')
  @UseGuards(RolesGuard)
  @Roles('admin')
  async deactivate(@Param('id') id: string) {
    await this.robotService.deactivate(id);
    return { deactivated: true };
  }

  /**
   * Authorization check: a user can access a robot only if:
   *  - They are an admin, OR
   *  - They own the robot (robot.userId === user.id), OR
   *  - They are an authorized caregiver of the robot's patient
   */
  private async assertCanAccessRobot(
    robotId: string,
    userId: string,
    role?: string,
  ): Promise<void> {
    if (role === 'admin') return;

    const robot = await this.robotService.findById(robotId);

    if (robot.userId === userId) return;

    const isCaregiver = await this.robotService.isAuthorizedCaregiver(
      robot.userId,
      userId,
    );
    if (isCaregiver) return;

    throw new ForbiddenException('You do not have access to this robot');
  }
}
