import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  OneToOne,
  JoinColumn,
  UpdateDateColumn,
} from 'typeorm';
import { Robot } from './robot.entity';

@Entity('robot_configs')
export class RobotConfig {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'robot_id', type: 'uuid', unique: true })
  robotId: string;

  @Column({ name: 'follow_distance_m', type: 'float', default: 1.5 })
  followDistanceM: number;

  @Column({ name: 'max_speed', type: 'float', default: 0.5 })
  maxSpeed: number;

  @Column({ name: 'emergency_stop_cm', type: 'int', default: 30 })
  emergencyStopCm: number;

  @Column({ name: 'telemetry_rate_hz', type: 'int', default: 2 })
  telemetryRateHz: number;

  @Column({ name: 'ble_target_uuid', length: 100, nullable: true })
  bleTargetUuid: string | null;

  @Column({ name: 'lidar_enabled', default: true })
  lidarEnabled: boolean;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;

  @OneToOne(() => Robot, (robot) => robot.config)
  @JoinColumn({ name: 'robot_id' })
  robot: Robot;
}
