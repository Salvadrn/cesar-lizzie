import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
  Index,
} from 'typeorm';
import { Robot } from './robot.entity';

@Entity('robot_telemetry')
@Index(['robotId', 'createdAt'])
export class RobotTelemetry {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'robot_id', type: 'uuid' })
  robotId: string;

  @Column({ length: 20 })
  state: string;

  @Column({ name: 'battery_percent', type: 'float' })
  batteryPercent: number;

  @Column({ name: 'ble_estimated_distance', type: 'float', nullable: true })
  bleEstimatedDistance: number | null;

  @Column({ name: 'ble_target_found', default: false })
  bleTargetFound: boolean;

  @Column({ name: 'lidar_nearest_obstacle', type: 'float', nullable: true })
  lidarNearestObstacle: number | null;

  @Column({ name: 'ultrasonic_front_left', type: 'float', nullable: true })
  ultrasonicFrontLeft: number | null;

  @Column({ name: 'ultrasonic_front_right', type: 'float', nullable: true })
  ultrasonicFrontRight: number | null;

  @Column({ name: 'motor_speed', type: 'float', default: 0 })
  motorSpeed: number;

  @Column({ name: 'steering_angle', type: 'float', default: 0 })
  steeringAngle: number;

  @Column({ name: 'wifi_rssi', type: 'int', default: 0 })
  wifiRssi: number;

  @Column({ name: 'cpu_temp', type: 'float', default: 0 })
  cpuTemp: number;

  @Column({ name: 'uptime_seconds', type: 'int', default: 0 })
  uptimeSeconds: number;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @ManyToOne(() => Robot)
  @JoinColumn({ name: 'robot_id' })
  robot: Robot;
}
