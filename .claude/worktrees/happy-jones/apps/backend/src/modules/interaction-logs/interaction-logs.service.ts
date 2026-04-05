import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { InjectQueue } from '@nestjs/bull';
import { Queue } from 'bull';
import { InteractionLog } from './entities/interaction-log.entity';

@Injectable()
export class InteractionLogsService {
  constructor(
    @InjectRepository(InteractionLog)
    private logRepo: Repository<InteractionLog>,
    @InjectQueue('interaction-logs')
    private logQueue: Queue,
  ) {}

  async submitBatch(
    userId: string,
    sessionId: string,
    events: Array<{
      eventType: string;
      screen?: string;
      targetElement?: string;
      tapAccuracy?: number;
      responseTime?: number;
      wasError?: boolean;
      errorType?: string;
      complexityLevel: number;
      metadata?: Record<string, unknown>;
      timestamp: string;
    }>,
  ) {
    // Queue for async processing
    await this.logQueue.add('batch-insert', {
      userId,
      sessionId,
      events,
    });

    return { queued: events.length };
  }

  async processBatch(data: {
    userId: string;
    sessionId: string;
    events: any[];
  }) {
    const logs = data.events.map((event) =>
      this.logRepo.create({
        userId: data.userId,
        sessionId: data.sessionId,
        eventType: event.eventType,
        screen: event.screen,
        targetElement: event.targetElement,
        tapAccuracy: event.tapAccuracy,
        responseTime: event.responseTime,
        wasError: event.wasError ?? false,
        errorType: event.errorType,
        complexityLevel: event.complexityLevel,
        metadata: event.metadata,
      }),
    );
    await this.logRepo.save(logs);
  }

  async getSummary(userId: string) {
    const result = await this.logRepo
      .createQueryBuilder('log')
      .select([
        'AVG(log.tap_accuracy) as avgTapAccuracy',
        'AVG(log.response_time) as avgResponseTime',
        'SUM(CASE WHEN log.was_error = true THEN 1 ELSE 0 END)::float / COUNT(*) as errorRate',
        'COUNT(*) as totalEvents',
      ])
      .where('log.user_id = :userId', { userId })
      .andWhere('log.created_at > NOW() - INTERVAL \'7 days\'')
      .getRawOne();

    return result;
  }
}
