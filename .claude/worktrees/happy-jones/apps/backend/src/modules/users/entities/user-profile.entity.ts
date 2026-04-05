import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  OneToOne,
  JoinColumn,
} from 'typeorm';
import { User } from './user.entity';

@Entity('user_profiles')
export class UserProfile {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id', type: 'uuid' })
  userId: string;

  // Adaptive engine state
  @Column({ name: 'current_complexity', type: 'int', default: 3 })
  currentComplexity: number;

  @Column({ name: 'avg_error_rate', type: 'float', default: 0.0 })
  avgErrorRate: number;

  @Column({ name: 'avg_completion_time', type: 'float', default: 0.0 })
  avgCompletionTime: number;

  @Column({ name: 'avg_task_completion', type: 'float', default: 0.0 })
  avgTaskCompletion: number;

  @Column({ name: 'total_sessions', type: 'int', default: 0 })
  totalSessions: number;

  // Sensory preferences
  @Column({ name: 'sensory_mode', length: 20, default: 'default' })
  sensoryMode: 'default' | 'low_stimulation' | 'high_contrast';

  @Column({ name: 'haptic_enabled', default: true })
  hapticEnabled: boolean;

  @Column({ name: 'haptic_intensity', type: 'int', default: 3 })
  hapticIntensity: number;

  @Column({ name: 'audio_enabled', default: true })
  audioEnabled: boolean;

  @Column({ name: 'audio_speed', type: 'float', default: 1.0 })
  audioSpeed: number;

  @Column({ name: 'font_scale', type: 'float', default: 1.0 })
  fontScale: number;

  @Column({ name: 'animation_enabled', default: true })
  animationEnabled: boolean;

  // Safety / Lost mode
  @Column({ name: 'lost_mode_name', length: 100, nullable: true })
  lostModeName: string | null;

  @Column({ name: 'lost_mode_address', type: 'text', nullable: true })
  lostModeAddress: string | null;

  @Column({ name: 'lost_mode_phone', length: 30, nullable: true })
  lostModePhone: string | null;

  @Column({ name: 'lost_mode_photo_url', type: 'text', nullable: true })
  lostModePhotoUrl: string | null;

  // Interface preferences
  @Column({ name: 'preferred_input', length: 20, default: 'touch' })
  preferredInput: 'touch' | 'voice' | 'switch';

  @Column({ length: 10, default: 'en' })
  language: string;

  // Complexity bounds (set by caregiver)
  @Column({ name: 'complexity_floor', type: 'int', default: 1 })
  complexityFloor: number;

  @Column({ name: 'complexity_ceiling', type: 'int', default: 5 })
  complexityCeiling: number;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;

  @OneToOne(() => User, (user) => user.profile)
  @JoinColumn({ name: 'user_id' })
  user: User;
}
