export type RoutineCategory =
  | 'cooking'
  | 'hygiene'
  | 'laundry'
  | 'medication'
  | 'transit'
  | 'shopping'
  | 'cleaning'
  | 'social'
  | 'custom';

export type ScheduleType = 'daily' | 'weekly' | 'custom' | 'on_demand';

export interface ScheduleConfig {
  days?: string[]; // ['mon', 'tue', ...]
  time?: string; // '08:00'
  interval?: number; // days between
}

export interface Routine {
  id: string;
  title: string;
  description?: string;
  category: RoutineCategory;
  icon?: string;
  coverImageUrl?: string;
  createdBy: string;
  assignedTo?: string;
  isTemplate: boolean;
  complexity: number; // 1-5
  estimatedMinutes?: number;
  isActive: boolean;
  scheduleType?: ScheduleType;
  scheduleConfig?: ScheduleConfig;
  steps?: RoutineStep[];
  createdAt: string;
  updatedAt: string;
}

export interface RoutineStep {
  id: string;
  routineId: string;
  stepOrder: number;
  title: string;
  instruction?: string;
  imageUrl?: string;
  videoUrl?: string;
  audioUrl?: string;
  audioTtsText?: string;
  durationHint?: number; // seconds
  requiresConfirmation: boolean;
  checkpoint: boolean;
  instructionSimple?: string;
  instructionDetailed?: string;
  createdAt: string;
  updatedAt: string;
}
