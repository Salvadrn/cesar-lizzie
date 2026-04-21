import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as bcrypt from 'bcrypt';
import * as crypto from 'crypto';
import { Robot } from './entities/robot.entity';
import { RobotConfig } from './entities/robot-config.entity';
import { RobotTelemetry } from './entities/robot-telemetry.entity';
import { Routine } from '../routines/entities/routine.entity';
import { User } from '../users/entities/user.entity';
import { UserProfile } from '../users/entities/user-profile.entity';

@Injectable()
export class RobotService {
  constructor(
    @InjectRepository(Robot)
    private robotRepo: Repository<Robot>,
    @InjectRepository(RobotConfig)
    private configRepo: Repository<RobotConfig>,
    @InjectRepository(RobotTelemetry)
    private telemetryRepo: Repository<RobotTelemetry>,
    @InjectRepository(Routine)
    private routineRepo: Repository<Routine>,
    @InjectRepository(User)
    private userRepo: Repository<User>,
    @InjectRepository(UserProfile)
    private profileRepo: Repository<UserProfile>,
  ) {}

  // MARK: - Robot CRUD

  async register(serialNumber: string, name: string) {
    const apiKey = crypto.randomBytes(32).toString('hex');
    const apiKeyHash = await bcrypt.hash(apiKey, 10);
    const robot = this.robotRepo.create({ serialNumber, name, apiKeyHash });
    const saved = await this.robotRepo.save(robot);

    const config = this.configRepo.create({ robotId: saved.id });
    await this.configRepo.save(config);

    // Return apiKey ONCE — it cannot be retrieved again
    return { ...saved, apiKey };
  }

  async pair(robotId: string, userId: string) {
    const robot = await this.robotRepo.findOneBy({ id: robotId });
    if (!robot) throw new NotFoundException('Robot no encontrado');

    robot.userId = userId;
    return this.robotRepo.save(robot);
  }

  async validateApiKey(robotId: string, apiKey: string): Promise<boolean> {
    const robot = await this.robotRepo.findOneBy({ id: robotId });
    if (!robot) return false;
    return bcrypt.compare(apiKey, robot.apiKeyHash);
  }

  async findById(robotId: string) {
    return this.robotRepo.findOne({
      where: { id: robotId },
      relations: ['config', 'user'],
    });
  }

  async findByUserId(userId: string) {
    return this.robotRepo.findOne({
      where: { userId },
      relations: ['config'],
    });
  }

  async updateStatus(robotId: string, status: Robot['status']) {
    await this.robotRepo.update(robotId, { status, lastSeenAt: new Date() });
  }

  async updateConfig(robotId: string, updates: Partial<RobotConfig>) {
    await this.configRepo.update({ robotId }, updates);
    return this.configRepo.findOneBy({ robotId });
  }

  // MARK: - Telemetry

  async saveTelemetry(robotId: string, data: Partial<RobotTelemetry>) {
    const entry = this.telemetryRepo.create({ ...data, robotId });
    await this.telemetryRepo.save(entry);

    // Update last seen
    await this.robotRepo.update(robotId, { lastSeenAt: new Date() });

    return entry;
  }

  async getLatestTelemetry(robotId: string) {
    return this.telemetryRepo.findOne({
      where: { robotId },
      order: { createdAt: 'DESC' },
    });
  }

  // MARK: - Patient Context (for robot/JARVIS to consume)

  /**
   * Returns aggregated patient data that the robot or JARVIS can use
   * for context-aware interactions.
   */
  async getPatientContext(userId: string) {
    const user = await this.userRepo.findOne({
      where: { id: userId },
      select: ['id', 'email', 'displayName', 'role'],
    });
    if (!user) throw new NotFoundException('Usuario no encontrado');

    const profile = await this.profileRepo.findOneBy({ userId });

    const routines = await this.routineRepo.find({
      where: [
        { assignedTo: userId, isActive: true },
        { createdBy: userId, isActive: true },
      ],
      relations: ['steps'],
      order: { createdAt: 'DESC' },
    });

    // Separate medication routines from regular routines
    const medicationRoutines = routines.filter(
      (r) => r.category === 'medication',
    );
    const dailyRoutines = routines.filter((r) => r.category !== 'medication');

    return {
      user: {
        id: user.id,
        displayName: user.displayName,
        email: user.email,
        role: user.role,
      },
      profile: profile
        ? {
            currentComplexity: profile.currentComplexity,
            sensoryMode: profile.sensoryMode,
            preferredInput: profile.preferredInput,
            language: profile.language,
            audioEnabled: profile.audioEnabled,
            audioSpeed: profile.audioSpeed,
            hapticEnabled: profile.hapticEnabled,
            lostModeName: profile.lostModeName,
            lostModePhone: profile.lostModePhone,
          }
        : null,
      routines: dailyRoutines.map((r) => ({
        id: r.id,
        title: r.title,
        category: r.category,
        complexity: r.complexity,
        estimatedMinutes: r.estimatedMinutes,
        scheduleType: r.scheduleType,
        scheduleConfig: r.scheduleConfig,
        stepsCount: r.steps?.length ?? 0,
      })),
      medications: medicationRoutines.map((r) => ({
        id: r.id,
        title: r.title,
        scheduleType: r.scheduleType,
        scheduleConfig: r.scheduleConfig,
        stepsCount: r.steps?.length ?? 0,
      })),
      timestamp: new Date().toISOString(),
    };
  }
}
