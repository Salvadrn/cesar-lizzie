import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  OneToMany,
  JoinColumn,
} from 'typeorm';
import { Routine } from '../../routines/entities/routine.entity';
import { User } from '../../users/entities/user.entity';
import { StepExecution } from './step-execution.entity';

@Entity('routine_executions')
export class RoutineExecution {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'routine_id', type: 'uuid' })
  routineId: string;

  @Column({ name: 'user_id', type: 'uuid' })
  userId: string;

  @Column({ length: 20, default: 'in_progress' })
  status: 'in_progress' | 'completed' | 'abandoned' | 'paused';

  @Column({ name: 'started_at', type: 'timestamptz', default: () => 'NOW()' })
  startedAt: Date;

  @Column({ name: 'completed_at', type: 'timestamptz', nullable: true })
  completedAt: Date | null;

  @Column({ name: 'paused_at', type: 'timestamptz', nullable: true })
  pausedAt: Date | null;

  @Column({ name: 'total_steps', type: 'int' })
  totalSteps: number;

  @Column({ name: 'completed_steps', type: 'int', default: 0 })
  completedSteps: number;

  @Column({ name: 'error_count', type: 'int', default: 0 })
  errorCount: number;

  @Column({ name: 'stall_count', type: 'int', default: 0 })
  stallCount: number;

  @Column({ name: 'complexity_at_start', type: 'int', nullable: true })
  complexityAtStart: number | null;

  @Column({ name: 'complexity_at_end', type: 'int', nullable: true })
  complexityAtEnd: number | null;

  @Column({ type: 'text', nullable: true })
  notes: string | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @ManyToOne(() => Routine)
  @JoinColumn({ name: 'routine_id' })
  routine: Routine;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'user_id' })
  user: User;

  @OneToMany(() => StepExecution, (se) => se.execution, { cascade: true })
  stepExecutions: StepExecution[];
}
