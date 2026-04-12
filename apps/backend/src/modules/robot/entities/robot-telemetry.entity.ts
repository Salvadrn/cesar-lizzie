import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { Robot } from './robot.entity';

@Entity('robot_telemetry')
export class RobotTelemetry {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'robot_id', type: 'uuid' })
  robotId: string;

  @Column({ length: 30, nullable: true })
  state: string | null;

  @Column({ name: 'battery_percent', type: 'int', nullable: true })
  batteryPercent: number | null;

  @Column({ name: 'ble_estimated_distance', type: 'float', nullable: true })
  bleEstimatedDistance: number | null;

  @Column({ name: 'ble_target_found', nullable: true })
  bleTargetFound: boolean | null;

  @Column({ name: 'lidar_nearest_obstacle', type: 'float', nullable: true })
  lidarNearestObstacle: number | null;

  @Column({ name: 'ultrasonic_front_left', type: 'float', nullable: true })
  ultrasonicFrontLeft: number | null;

  @Column({ name: 'ultrasonic_front_right', type: 'float', nullable: true })
  ultrasonicFrontRight: number | null;

  @Column({ name: 'motor_speed', type: 'float', nullable: true })
  motorSpeed: number | null;

  @Column({ name: 'steering_angle', type: 'float', nullable: true })
  steeringAngle: number | null;

  @Column({ name: 'wifi_rssi', type: 'int', nullable: true })
  wifiRssi: number | null;

  @Column({ name: 'cpu_temp', type: 'float', nullable: true })
  cpuTemp: number | null;

  @Column({ name: 'uptime_seconds', type: 'int', nullable: true })
  uptimeSeconds: number | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @ManyToOne(() => Robot)
  @JoinColumn({ name: 'robot_id' })
  robot: Robot;
}
