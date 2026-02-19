import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Alert } from './entities/alert.entity';

@Injectable()
export class AlertsService {
  constructor(
    @InjectRepository(Alert)
    private alertRepo: Repository<Alert>,
  ) {}

  async create(data: {
    userId: string;
    caregiverId?: string;
    alertType: string;
    severity: 'info' | 'warning' | 'critical';
    title: string;
    message?: string;
    metadata?: Record<string, unknown>;
  }): Promise<Alert> {
    const alert = this.alertRepo.create(data);
    return this.alertRepo.save(alert);
  }

  async findForCaregiver(caregiverId: string) {
    return this.alertRepo.find({
      where: [
        { caregiverId },
        { caregiverId: undefined as any }, // null = broadcast to all
      ],
      order: { createdAt: 'DESC' },
      take: 50,
    });
  }

  async findByUser(userId: string) {
    return this.alertRepo.find({
      where: { userId },
      order: { createdAt: 'DESC' },
      take: 50,
    });
  }

  async getUnreadCount(caregiverId: string): Promise<number> {
    return this.alertRepo.count({
      where: { caregiverId, isRead: false },
    });
  }

  async markRead(id: string) {
    return this.alertRepo.update(id, { isRead: true });
  }

  async acknowledge(id: string) {
    return this.alertRepo.update(id, {
      isRead: true,
      acknowledgedAt: new Date(),
    });
  }
}
