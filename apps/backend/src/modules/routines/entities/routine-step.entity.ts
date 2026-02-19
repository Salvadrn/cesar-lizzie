import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { Routine } from './routine.entity';

@Entity('routine_steps')
export class RoutineStep {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'routine_id', type: 'uuid' })
  routineId: string;

  @Column({ name: 'step_order', type: 'int' })
  stepOrder: number;

  @Column({ length: 200 })
  title: string;

  @Column({ type: 'text', nullable: true })
  instruction: string | null;

  @Column({ name: 'image_url', type: 'text', nullable: true })
  imageUrl: string | null;

  @Column({ name: 'video_url', type: 'text', nullable: true })
  videoUrl: string | null;

  @Column({ name: 'audio_url', type: 'text', nullable: true })
  audioUrl: string | null;

  @Column({ name: 'audio_tts_text', type: 'text', nullable: true })
  audioTtsText: string | null;

  @Column({ name: 'duration_hint', type: 'int', nullable: true })
  durationHint: number | null;

  @Column({ name: 'requires_confirmation', default: true })
  requiresConfirmation: boolean;

  @Column({ default: false })
  checkpoint: boolean;

  @Column({ name: 'instruction_simple', type: 'text', nullable: true })
  instructionSimple: string | null;

  @Column({ name: 'instruction_detailed', type: 'text', nullable: true })
  instructionDetailed: string | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;

  @ManyToOne(() => Routine, (routine) => routine.steps, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'routine_id' })
  routine: Routine;
}
