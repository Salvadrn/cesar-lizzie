import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { RoutineExecution } from './entities/routine-execution.entity';
import { StepExecution } from './entities/step-execution.entity';
import { RoutinesService } from '../routines/routines.service';
import { AdaptiveService, AdaptiveMetrics } from '../users/adaptive.service';
import { AlertsService } from '../alerts/alerts.service';

@Injectable()
export class ExecutionsService {
  constructor(
    @InjectRepository(RoutineExecution)
    private execRepo: Repository<RoutineExecution>,
    @InjectRepository(StepExecution)
    private stepExecRepo: Repository<StepExecution>,
    private routinesService: RoutinesService,
    private adaptiveService: AdaptiveService,
    private alertsService: AlertsService,
  ) {}

  async start(routineId: string, userId: string, complexityLevel: number) {
    const routine = await this.routinesService.findById(routineId);
    const totalSteps = routine.steps?.length ?? 0;

    const execution = this.execRepo.create({
      routineId,
      userId,
      totalSteps,
      complexityAtStart: complexityLevel,
    });
    const saved = await this.execRepo.save(execution);

    // Create pending step executions
    if (routine.steps) {
      const stepExecs = routine.steps.map((step) =>
        this.stepExecRepo.create({
          executionId: saved.id,
          stepId: step.id,
          status: 'pending',
        }),
      );
      await this.stepExecRepo.save(stepExecs);
    }

    return saved;
  }

  async findById(id: string): Promise<RoutineExecution> {
    const exec = await this.execRepo.findOne({
      where: { id },
      relations: ['stepExecutions'],
    });
    if (!exec) throw new NotFoundException('Execution not found');
    return exec;
  }

  async startStep(executionId: string, stepId: string) {
    const stepExec = await this.stepExecRepo.findOne({
      where: { executionId, stepId },
    });
    if (!stepExec) throw new NotFoundException('Step execution not found');

    stepExec.status = 'in_progress';
    stepExec.startedAt = new Date();
    return this.stepExecRepo.save(stepExec);
  }

  async completeStep(executionId: string, stepId: string, metrics?: {
    errorCount?: number;
    stallCount?: number;
    rePromptCount?: number;
    neededHelp?: boolean;
  }) {
    const stepExec = await this.stepExecRepo.findOne({
      where: { executionId, stepId },
    });
    if (!stepExec) throw new NotFoundException('Step execution not found');

    stepExec.status = 'completed';
    stepExec.completedAt = new Date();
    if (stepExec.startedAt) {
      stepExec.durationSeconds = Math.floor(
        (stepExec.completedAt.getTime() - stepExec.startedAt.getTime()) / 1000,
      );
    }
    if (metrics) {
      Object.assign(stepExec, metrics);
    }
    await this.stepExecRepo.save(stepExec);

    // Update parent execution
    const execution = await this.findById(executionId);
    execution.completedSteps += 1;
    execution.errorCount += metrics?.errorCount ?? 0;
    execution.stallCount += metrics?.stallCount ?? 0;

    // Check if all steps completed
    if (execution.completedSteps >= execution.totalSteps) {
      execution.status = 'completed';
      execution.completedAt = new Date();
      await this.execRepo.save(execution);

      // Trigger adaptive recalculation
      await this.triggerAdaptiveRecalculation(execution);
    } else {
      await this.execRepo.save(execution);
    }

    return stepExec;
  }

  async abandon(executionId: string) {
    const execution = await this.findById(executionId);
    execution.status = 'abandoned';
    await this.execRepo.save(execution);

    // Alert caregiver
    await this.alertsService.create({
      userId: execution.userId,
      alertType: 'routine_abandoned',
      severity: 'warning',
      title: 'Routine abandoned',
      metadata: { executionId, routineId: execution.routineId },
    });

    return execution;
  }

  async pause(executionId: string) {
    const execution = await this.findById(executionId);
    execution.status = 'paused';
    execution.pausedAt = new Date();
    return this.execRepo.save(execution);
  }

  async getHistory(userId: string, limit = 20, offset = 0) {
    return this.execRepo.find({
      where: { userId },
      order: { startedAt: 'DESC' },
      take: limit,
      skip: offset,
      relations: ['routine'],
    });
  }

  async getStats(userId: string) {
    const executions = await this.execRepo.find({
      where: { userId },
      order: { startedAt: 'DESC' },
      take: 100,
    });

    const completed = executions.filter((e) => e.status === 'completed');
    const totalExecutions = executions.length;
    const completionRate = totalExecutions > 0 ? completed.length / totalExecutions : 0;
    const avgErrors = completed.length > 0
      ? completed.reduce((sum, e) => sum + e.errorCount, 0) / completed.length
      : 0;

    return {
      totalExecutions,
      completedCount: completed.length,
      completionRate,
      avgErrorsPerExecution: avgErrors,
      recentExecutions: executions.slice(0, 10),
    };
  }

  private async triggerAdaptiveRecalculation(execution: RoutineExecution) {
    const stepExecs = await this.stepExecRepo.find({
      where: { executionId: execution.id },
    });

    const totalSteps = stepExecs.length;
    if (totalSteps === 0) return;

    const completedSteps = stepExecs.filter((s) => s.status === 'completed');
    const totalErrors = stepExecs.reduce((sum, s) => sum + s.errorCount, 0);
    const totalStalls = stepExecs.reduce((sum, s) => sum + s.stallCount, 0);
    const totalInteractions = totalSteps * 3; // rough estimate
    const avgDuration = completedSteps.length > 0
      ? completedSteps.reduce((sum, s) => sum + (s.durationSeconds ?? 0), 0) / completedSteps.length
      : 0;

    const metrics: AdaptiveMetrics = {
      errorRate: totalInteractions > 0 ? totalErrors / totalInteractions : 0,
      avgResponseTime: avgDuration * 1000, // convert to ms
      taskCompletionRate: totalSteps > 0 ? completedSteps.length / totalSteps : 0,
      stallRate: totalSteps > 0 ? totalStalls / totalSteps : 0,
      avgSessionDuration: avgDuration / 60, // convert to minutes
      tapAccuracy: 20, // default, will be populated from interaction logs
    };

    await this.adaptiveService.recalculate(execution.userId, metrics);
  }
}
