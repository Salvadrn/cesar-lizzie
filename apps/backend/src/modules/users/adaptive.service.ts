import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { UserProfile } from './entities/user-profile.entity';
import {
  ADAPTIVE_SMOOTHING_FACTOR,
  MAX_LEVEL_CHANGE_PER_SESSION,
  MIN_COMPLEXITY,
  MAX_COMPLEXITY,
} from '@neuronav/shared-constants';

/**
 * AdaptiveService — The intellectual core of Adapt AI.
 *
 * Computes the optimal UI complexity level (1-5) for a user
 * based on their interaction metrics. The system:
 *
 * 1. Collects metrics from interaction logs and step executions
 * 2. Applies heuristic rules to compute a raw complexity score
 * 3. Smooths the score with exponential moving average
 * 4. Clamps to floor/ceiling set by caregiver
 * 5. Limits change to 1 level per session to avoid disorientation
 */

export interface AdaptiveMetrics {
  errorRate: number;          // errors / total_interactions (0.0-1.0)
  avgResponseTime: number;    // milliseconds
  taskCompletionRate: number; // completed_steps / total_steps (0.0-1.0)
  stallRate: number;          // stalls / total_steps (0.0-1.0)
  avgSessionDuration: number; // minutes
  tapAccuracy: number;        // average distance from target center (pixels)
}

export interface AdaptivePrediction {
  level: number;
  previousLevel: number;
  confidence: number;
  suggestedModifications: string[];
}

@Injectable()
export class AdaptiveService {
  private readonly logger = new Logger(AdaptiveService.name);

  constructor(
    @InjectRepository(UserProfile)
    private profileRepo: Repository<UserProfile>,
  ) {}

  /**
   * Compute the raw complexity score from interaction metrics.
   * Score starts at 3 (Standard) and adjusts based on user behavior.
   */
  computeRawScore(metrics: AdaptiveMetrics): number {
    let score = 3;

    // Error rate adjustments
    if (metrics.errorRate > 0.4) score -= 2;
    else if (metrics.errorRate > 0.25) score -= 1;
    else if (metrics.errorRate < 0.05) score += 1;

    // Response time (slow may need simpler UI)
    if (metrics.avgResponseTime > 8000) score -= 1;
    else if (metrics.avgResponseTime < 2000) score += 1;

    // Task completion rate
    if (metrics.taskCompletionRate < 0.5) score -= 1;
    else if (metrics.taskCompletionRate > 0.9) score += 1;

    // Stall rate (user gets stuck)
    if (metrics.stallRate > 0.3) score -= 1;

    // Tap accuracy (poor motor control = need larger targets)
    if (metrics.tapAccuracy > 50) score -= 1;

    return Math.max(MIN_COMPLEXITY, Math.min(MAX_COMPLEXITY, score));
  }

  /**
   * Identify specific UI modifications based on metrics.
   */
  computeModifications(metrics: AdaptiveMetrics): string[] {
    const mods: string[] = [];

    if (metrics.tapAccuracy > 40) mods.push('increase_button_size');
    if (metrics.avgResponseTime > 6000) mods.push('enable_audio_prompts');
    if (metrics.errorRate > 0.3) mods.push('reduce_options_per_screen');
    if (metrics.stallRate > 0.2) mods.push('add_visual_cues');
    if (metrics.taskCompletionRate < 0.6) mods.push('simplify_instructions');

    return mods;
  }

  /**
   * Apply smoothing: weighted average between current and computed level.
   * newLevel = (1 - alpha) * currentLevel + alpha * computedLevel
   */
  smoothLevel(currentLevel: number, computedLevel: number): number {
    const alpha = ADAPTIVE_SMOOTHING_FACTOR;
    return Math.round((1 - alpha) * currentLevel + alpha * computedLevel);
  }

  /**
   * Clamp the level change to max 1 step per session, and respect floor/ceiling.
   */
  clampLevel(
    currentLevel: number,
    newLevel: number,
    floor: number,
    ceiling: number,
  ): number {
    // Limit change to 1 step
    const maxChange = MAX_LEVEL_CHANGE_PER_SESSION;
    const diff = newLevel - currentLevel;
    const clampedDiff = Math.max(-maxChange, Math.min(maxChange, diff));
    let result = currentLevel + clampedDiff;

    // Respect caregiver-set bounds
    result = Math.max(floor, Math.min(ceiling, result));

    // Absolute bounds
    return Math.max(MIN_COMPLEXITY, Math.min(MAX_COMPLEXITY, result));
  }

  /**
   * Main entry point: recalculate complexity for a user after a session.
   */
  async recalculate(
    userId: string,
    metrics: AdaptiveMetrics,
  ): Promise<AdaptivePrediction> {
    const profile = await this.profileRepo.findOne({ where: { userId } });
    if (!profile) {
      this.logger.warn(`No profile found for user ${userId}`);
      return {
        level: 3,
        previousLevel: 3,
        confidence: 0,
        suggestedModifications: [],
      };
    }

    const previousLevel = profile.currentComplexity;
    const rawScore = this.computeRawScore(metrics);
    const smoothed = this.smoothLevel(previousLevel, rawScore);
    const finalLevel = this.clampLevel(
      previousLevel,
      smoothed,
      profile.complexityFloor,
      profile.complexityCeiling,
    );
    const modifications = this.computeModifications(metrics);

    // Persist
    profile.currentComplexity = finalLevel;
    profile.avgErrorRate = metrics.errorRate;
    profile.avgCompletionTime = metrics.avgResponseTime;
    profile.avgTaskCompletion = metrics.taskCompletionRate;
    profile.totalSessions += 1;
    await this.profileRepo.save(profile);

    this.logger.log(
      `User ${userId}: complexity ${previousLevel} → ${finalLevel} (raw: ${rawScore}, smoothed: ${smoothed})`,
    );

    return {
      level: finalLevel,
      previousLevel,
      confidence: 0.7, // Fixed for heuristic engine
      suggestedModifications: modifications,
    };
  }
}
