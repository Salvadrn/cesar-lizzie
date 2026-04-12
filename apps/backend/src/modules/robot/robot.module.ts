import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Robot } from './entities/robot.entity';
import { RobotConfig } from './entities/robot-config.entity';
import { RobotTelemetry } from './entities/robot-telemetry.entity';
import { RobotService } from './robot.service';
import { RobotController } from './robot.controller';
import { RobotGateway } from './robot.gateway';
import { Routine } from '../routines/entities/routine.entity';
import { User } from '../users/entities/user.entity';
import { UserProfile } from '../users/entities/user-profile.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Robot,
      RobotConfig,
      RobotTelemetry,
      Routine,
      User,
      UserProfile,
    ]),
  ],
  controllers: [RobotController],
  providers: [RobotService, RobotGateway],
  exports: [RobotService, RobotGateway],
})
export class RobotModule {}
