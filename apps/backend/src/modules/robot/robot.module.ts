import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { RobotController } from './robot.controller';
import { RobotService } from './robot.service';
import { RobotGateway } from './robot.gateway';
import { Robot } from './entities/robot.entity';
import { RobotConfig } from './entities/robot-config.entity';
import { RobotTelemetry } from './entities/robot-telemetry.entity';
import { AlertsModule } from '../alerts/alerts.module';
import { EventsModule } from '../../gateway/events.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([Robot, RobotConfig, RobotTelemetry]),
    AlertsModule,
    EventsModule,
  ],
  controllers: [RobotController],
  providers: [RobotService, RobotGateway],
  exports: [RobotService, RobotGateway],
})
export class RobotModule {}
