import {
  Injectable,
  NotFoundException,
  ConflictException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, LessThan } from 'typeorm';
import * as bcrypt from 'bcrypt';
import * as crypto from 'crypto';
import { Robot } from './entities/robot.entity';
import { RobotConfig } from './entities/robot-config.entity';
import { RobotTelemetry } from './entities/robot-telemetry.entity';
import { CaregiverLink } from '../caregiver/entities/caregiver-link.entity';
import { AlertsService } from '../alerts/alerts.service';
import { RegisterRobotDto } from './dto/register-robot.dto';
import { UpdateRobotConfigDto } from './dto/update-robot-config.dto';

@Injectable()
export class RobotService {
  constructor(
    @InjectRepository(Robot)
    private robotRepo: Repository<Robot>,
    @InjectRepository(RobotConfig)
    private configRepo: Repository<RobotConfig>,
    @InjectRepository(RobotTelemetry)
    private telemetryRepo: Repository<RobotTelemetry>,
    @InjectRepository(CaregiverLink)
    private caregiverLinkRepo: Repository<CaregiverLink>,
    private alertsService: AlertsService,
  ) {}

  /**
   * Returns true if `caregiverId` has an active caregiver link to `patientId`.
   * Used for authorization checks on robot endpoints.
   */
  async isAuthorizedCaregiver(
    patientId: string,
    caregiverId: string,
  ): Promise<boolean> {
    if (!patientId) return false;
    const link = await this.caregiverLinkRepo.findOne({
      where: {
        userId: patientId,
        caregiverId,
        status: 'active' as any,
      },
    });
    return !!link;
  }

  async register(dto: RegisterRobotDto) {
    const existing = await this.robotRepo.findOne({
      where: { serialNumber: dto.serialNumber },
    });
    if (existing) {
      throw new ConflictException('Robot with this serial number already exists');
    }

    const apiKey = crypto.randomBytes(32).toString('hex');
    const apiKeyHash = await bcrypt.hash(apiKey, 10);

    const robot = this.robotRepo.create({
      ...dto,
      apiKeyHash,
    });
    const saved = await this.robotRepo.save(robot);

    const config = this.configRepo.create({ robotId: saved.id });
    await this.configRepo.save(config);

    return { robot: saved, apiKey };
  }

  async findByUser(userId: string) {
    return this.robotRepo.findOne({
      where: { userId, isActive: true },
      relations: ['config'],
    });
  }

  async findById(id: string) {
    const robot = await this.robotRepo.findOne({
      where: { id },
      relations: ['config'],
    });
    if (!robot) throw new NotFoundException('Robot not found');
    return robot;
  }

  async validateApiKey(robotId: string, apiKey: string): Promise<Robot | null> {
    const robot = await this.robotRepo.findOne({ where: { id: robotId } });
    if (!robot) return null;
    const valid = await bcrypt.compare(apiKey, robot.apiKeyHash);
    return valid ? robot : null;
  }

  async getStatus(id: string) {
    const robot = await this.findById(id);
    const latestTelemetry = await this.telemetryRepo.findOne({
      where: { robotId: id },
      order: { createdAt: 'DESC' },
    });
    return { robot, latestTelemetry };
  }

  async updateConfig(id: string, dto: UpdateRobotConfigDto) {
    const config = await this.configRepo.findOne({ where: { robotId: id } });
    if (!config) throw new NotFoundException('Robot config not found');
    Object.assign(config, dto);
    return this.configRepo.save(config);
  }

  async updateStatus(id: string, status: Robot['status']) {
    await this.robotRepo.update(id, { status, lastSeenAt: new Date() });
  }

  async saveTelemetry(data: Partial<RobotTelemetry>) {
    const entry = this.telemetryRepo.create(data);
    await this.telemetryRepo.save(entry);
    await this.robotRepo.update(data.robotId!, { lastSeenAt: new Date() });
  }

  async getTelemetryHistory(robotId: string, limit = 100, offset = 0) {
    return this.telemetryRepo.find({
      where: { robotId },
      order: { createdAt: 'DESC' },
      take: limit,
      skip: offset,
    });
  }

  async handleRobotAlert(
    robotId: string,
    alertType: string,
    title: string,
    metadata?: Record<string, unknown>,
  ) {
    const robot = await this.findById(robotId);
    await this.alertsService.create({
      userId: robot.userId,
      alertType,
      severity:
        alertType === 'robot_emergency_stop'
          ? 'critical'
          : alertType === 'robot_target_lost'
            ? 'info'
            : 'warning',
      title,
      metadata: { ...metadata, robotId },
    });
  }

  async cleanupOldTelemetry(olderThanDays = 7) {
    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() - olderThanDays);
    await this.telemetryRepo.delete({ createdAt: LessThan(cutoff) });
  }

  async deactivate(id: string) {
    await this.robotRepo.update(id, { isActive: false, status: 'offline' });
  }

  // QR Pairing: robot genera un codigo, paciente lo escanea
  async pairWithUser(serialNumber: string, pairingCode: string, userId: string) {
    const robot = await this.robotRepo.findOne({
      where: { serialNumber, isActive: true },
    });
    if (!robot) {
      throw new NotFoundException('Robot not found with that serial number');
    }

    // Verify pairing code matches (stored as first 8 chars of api key hash)
    const codeValid = robot.apiKeyHash.substring(4, 12) === pairingCode;
    if (!codeValid) {
      throw new ConflictException('Invalid pairing code');
    }

    // Check if already paired to someone
    if (robot.userId && robot.userId !== userId) {
      throw new ConflictException('Robot is already paired to another user');
    }

    // Link robot to user
    robot.userId = userId;
    await this.robotRepo.save(robot);

    return {
      paired: true,
      robot: {
        id: robot.id,
        name: robot.name,
        serialNumber: robot.serialNumber,
        status: robot.status,
      },
    };
  }

  async unpair(robotId: string, userId: string) {
    const robot = await this.findById(robotId);
    if (robot.userId !== userId) {
      throw new ConflictException('This robot is not paired to you');
    }
    robot.userId = '' as any;
    robot.status = 'offline';
    await this.robotRepo.save(robot);
    return { unpaired: true };
  }

  // Generate QR payload for a robot (called during manufacturing/setup)
  async generatePairingQR(robotId: string) {
    const robot = await this.findById(robotId);
    const pairingCode = robot.apiKeyHash.substring(4, 12);

    // QR payload format: adaptai://pair?sn=SERIAL&code=CODE
    const qrPayload = `adaptai://pair?sn=${robot.serialNumber}&code=${pairingCode}`;

    return {
      qrPayload,
      serialNumber: robot.serialNumber,
      pairingCode,
      robotName: robot.name,
    };
  }
}
