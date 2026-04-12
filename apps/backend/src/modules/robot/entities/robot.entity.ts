import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  OneToOne,
  JoinColumn,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { RobotConfig } from './robot-config.entity';

@Entity('robots')
export class Robot {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id', type: 'uuid', nullable: true })
  userId: string | null;

  @Column({ name: 'serial_number', length: 100, unique: true })
  serialNumber: string;

  @Column({ length: 100, default: 'Swerve Robot' })
  name: string;

  @Column({ name: 'api_key_hash', length: 255 })
  apiKeyHash: string;

  @Column({ length: 20, default: 'offline' })
  status: 'online' | 'offline' | 'error' | 'emergency_stop';

  @Column({ name: 'last_seen_at', type: 'timestamptz', nullable: true })
  lastSeenAt: Date | null;

  @Column({ name: 'firmware_version', length: 50, nullable: true })
  firmwareVersion: string | null;

  @Column({ name: 'is_active', default: true })
  isActive: boolean;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;

  @ManyToOne(() => User, { nullable: true })
  @JoinColumn({ name: 'user_id' })
  user: User;

  @OneToOne(() => RobotConfig, (config) => config.robot, { cascade: true })
  config: RobotConfig;
}
