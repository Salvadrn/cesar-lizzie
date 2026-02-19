export type ExecutionStatus = 'in_progress' | 'completed' | 'abandoned' | 'paused';

export type StepExecutionStatus = 'pending' | 'in_progress' | 'completed' | 'skipped' | 'error';

export interface RoutineExecution {
  id: string;
  routineId: string;
  userId: string;
  status: ExecutionStatus;
  startedAt: string;
  completedAt?: string;
  pausedAt?: string;
  totalSteps: number;
  completedSteps: number;
  errorCount: number;
  stallCount: number;
  complexityAtStart: number;
  complexityAtEnd?: number;
  notes?: string;
  createdAt: string;
}

export interface StepExecution {
  id: string;
  executionId: string;
  stepId: string;
  status: StepExecutionStatus;
  startedAt?: string;
  completedAt?: string;
  durationSeconds?: number;
  errorCount: number;
  stallCount: number;
  rePromptCount: number;
  neededHelp: boolean;
  createdAt: string;
}
