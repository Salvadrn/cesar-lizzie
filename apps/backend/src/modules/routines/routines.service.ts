import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Routine } from './entities/routine.entity';
import { RoutineStep } from './entities/routine-step.entity';
import { CreateRoutineDto } from './dto/create-routine.dto';

@Injectable()
export class RoutinesService {
  constructor(
    @InjectRepository(Routine)
    private routineRepo: Repository<Routine>,
    @InjectRepository(RoutineStep)
    private stepRepo: Repository<RoutineStep>,
  ) {}

  async findAll(userId: string, role: string): Promise<Routine[]> {
    if (role === 'user') {
      return this.routineRepo.find({
        where: { assignedTo: userId, isActive: true },
        relations: ['steps'],
        order: { createdAt: 'DESC' },
      });
    }
    // Caregivers see routines they created
    return this.routineRepo.find({
      where: { createdBy: userId, isActive: true },
      relations: ['steps'],
      order: { createdAt: 'DESC' },
    });
  }

  async findById(id: string): Promise<Routine> {
    const routine = await this.routineRepo.findOne({
      where: { id },
      relations: ['steps'],
      order: { steps: { stepOrder: 'ASC' } },
    });
    if (!routine) throw new NotFoundException('Routine not found');
    return routine;
  }

  async findTemplates(): Promise<Routine[]> {
    return this.routineRepo.find({
      where: { isTemplate: true, isActive: true },
      relations: ['steps'],
      order: { createdAt: 'DESC' },
    });
  }

  async create(dto: CreateRoutineDto, createdBy: string): Promise<Routine> {
    const routine = this.routineRepo.create({
      ...dto,
      createdBy,
    });
    return this.routineRepo.save(routine);
  }

  async update(id: string, data: Partial<Routine>): Promise<Routine> {
    const routine = await this.findById(id);
    Object.assign(routine, data);
    return this.routineRepo.save(routine);
  }

  async softDelete(id: string): Promise<void> {
    await this.routineRepo.update(id, { isActive: false });
  }

  // Step management
  async addStep(routineId: string, stepData: Partial<RoutineStep>): Promise<RoutineStep> {
    const routine = await this.findById(routineId);
    const maxOrder = routine.steps?.length
      ? Math.max(...routine.steps.map((s) => s.stepOrder))
      : 0;

    const step = this.stepRepo.create({
      ...stepData,
      routineId,
      stepOrder: stepData.stepOrder ?? maxOrder + 1,
    });
    return this.stepRepo.save(step);
  }

  async updateStep(stepId: string, data: Partial<RoutineStep>): Promise<RoutineStep> {
    const step = await this.stepRepo.findOne({ where: { id: stepId } });
    if (!step) throw new NotFoundException('Step not found');
    Object.assign(step, data);
    return this.stepRepo.save(step);
  }

  async deleteStep(stepId: string): Promise<void> {
    await this.stepRepo.delete(stepId);
  }

  async reorderSteps(routineId: string, stepIds: string[]): Promise<void> {
    const updates = stepIds.map((id, index) =>
      this.stepRepo.update(id, { stepOrder: index + 1 }),
    );
    await Promise.all(updates);
  }
}
