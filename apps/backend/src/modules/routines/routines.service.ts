import { Injectable, ForbiddenException, NotFoundException } from '@nestjs/common';
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

  async findByIdAuthorized(
    id: string,
    user: { id: string; role: string },
  ): Promise<Routine> {
    const routine = await this.findById(id);
    if (
      user.role !== 'admin' &&
      routine.createdBy !== user.id &&
      routine.assignedTo !== user.id
    ) {
      throw new ForbiddenException('Not allowed to access this routine');
    }
    return routine;
  }

  private assertCanMutate(routine: Routine, user: { id: string; role: string }) {
    if (user.role !== 'admin' && routine.createdBy !== user.id) {
      throw new ForbiddenException('Not allowed to modify this routine');
    }
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

  async update(
    id: string,
    data: Partial<Routine>,
    user: { id: string; role: string },
  ): Promise<Routine> {
    const routine = await this.findById(id);
    this.assertCanMutate(routine, user);
    // Never allow caller to overwrite ownership / identity fields.
    const { id: _i, createdBy: _c, ...safe } = data;
    Object.assign(routine, safe);
    return this.routineRepo.save(routine);
  }

  async softDelete(id: string, user: { id: string; role: string }): Promise<void> {
    const routine = await this.findById(id);
    this.assertCanMutate(routine, user);
    await this.routineRepo.update(id, { isActive: false });
  }

  async addStep(
    routineId: string,
    stepData: Partial<RoutineStep>,
    user: { id: string; role: string },
  ): Promise<RoutineStep> {
    const routine = await this.findById(routineId);
    this.assertCanMutate(routine, user);
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

  async updateStep(
    stepId: string,
    data: Partial<RoutineStep>,
    user: { id: string; role: string },
  ): Promise<RoutineStep> {
    const step = await this.stepRepo.findOne({ where: { id: stepId } });
    if (!step) throw new NotFoundException('Step not found');
    const routine = await this.findById(step.routineId);
    this.assertCanMutate(routine, user);
    const { id: _i, routineId: _r, ...safe } = data;
    Object.assign(step, safe);
    return this.stepRepo.save(step);
  }

  async deleteStep(
    stepId: string,
    user: { id: string; role: string },
  ): Promise<void> {
    const step = await this.stepRepo.findOne({ where: { id: stepId } });
    if (!step) throw new NotFoundException('Step not found');
    const routine = await this.findById(step.routineId);
    this.assertCanMutate(routine, user);
    await this.stepRepo.delete(stepId);
  }

  async reorderSteps(
    routineId: string,
    stepIds: string[],
    user: { id: string; role: string },
  ): Promise<void> {
    const routine = await this.findById(routineId);
    this.assertCanMutate(routine, user);
    const updates = stepIds.map((id, index) =>
      this.stepRepo.update(
        { id, routineId },
        { stepOrder: index + 1 },
      ),
    );
    await Promise.all(updates);
  }
}
