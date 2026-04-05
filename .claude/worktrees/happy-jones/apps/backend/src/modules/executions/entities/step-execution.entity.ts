import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { RoutineExecution } from './routine-execution.entity';
import { RoutineStep } from '../../routines/entities/routine-step.entity';

@Entity('step_executions')
export class StepExecution {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'execution_id', type: 'uuid' })
  executionId: string;

  @Column({ name: 'step_id', type: 'uuid' })
  stepId: string;

  @Column({ length: 20, default: 'pending' })
  status: 'pending' | 'in_progress' | 'completed' | 'skipped' | 'error';

  @Column({ name: 'started_at', type: 'timestamptz', nullable: true })
  startedAt: Date | null;

  @Column({ name: 'completed_at', type: 'timestamptz', nullable: true })
  completedAt: Date | null;

  @Column({ name: 'duration_seconds', type: 'int', nullable: true })
  durationSeconds: number | null;

  @Column({ name: 'error_count', type: 'int', default: 0 })
  errorCount: number;

  @Column({ name: 'stall_count', type: 'int', default: 0 })
  stallCount: number;

  @Column({ name: 're_prompt_count', type: 'int', default: 0 })
  rePromptCount: number;

  @Column({ name: 'needed_help', default: false })
  neededHelp: boolean;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @ManyToOne(() => RoutineExecution, (exec) => exec.stepExecutions, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'execution_id' })
  execution: RoutineExecution;

  @ManyToOne(() => RoutineStep)
  @JoinColumn({ name: 'step_id' })
  step: RoutineStep;
}
