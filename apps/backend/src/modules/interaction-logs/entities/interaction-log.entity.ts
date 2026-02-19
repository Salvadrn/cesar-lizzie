import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';

@Entity('interaction_logs')
export class InteractionLog {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id', type: 'uuid' })
  userId: string;

  @Column({ name: 'session_id', type: 'uuid' })
  sessionId: string;

  @Column({ name: 'event_type', length: 50 })
  eventType: string;

  @Column({ length: 100, nullable: true })
  screen: string | null;

  @Column({ name: 'target_element', length: 100, nullable: true })
  targetElement: string | null;

  @Column({ name: 'tap_accuracy', type: 'float', nullable: true })
  tapAccuracy: number | null;

  @Column({ name: 'response_time', type: 'int', nullable: true })
  responseTime: number | null;

  @Column({ name: 'was_error', default: false })
  wasError: boolean;

  @Column({ name: 'error_type', length: 50, nullable: true })
  errorType: string | null;

  @Column({ name: 'complexity_level', type: 'int' })
  complexityLevel: number;

  @Column({ type: 'jsonb', nullable: true })
  metadata: Record<string, unknown> | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'user_id' })
  user: User;
}
