import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';

@Entity('caregiver_links')
export class CaregiverLink {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id', type: 'uuid' })
  userId: string;

  @Column({ name: 'caregiver_id', type: 'uuid' })
  caregiverId: string;

  @Column({ length: 50, nullable: true })
  relationship: string | null;

  @Column({ type: 'jsonb', default: { viewActivity: true, editRoutines: true, viewLocation: false } })
  permissions: {
    viewActivity: boolean;
    editRoutines: boolean;
    viewLocation: boolean;
  };

  @Column({ name: 'invite_code', length: 20, unique: true, nullable: true })
  inviteCode: string | null;

  @Column({ length: 20, default: 'pending' })
  status: 'pending' | 'active' | 'revoked';

  @Column({ name: 'linked_at', type: 'timestamptz', nullable: true })
  linkedAt: Date | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @ManyToOne(() => User, (user) => user.caregiverLinks)
  @JoinColumn({ name: 'user_id' })
  user: User;

  @ManyToOne(() => User, (user) => user.linkedUsers)
  @JoinColumn({ name: 'caregiver_id' })
  caregiver: User;
}
