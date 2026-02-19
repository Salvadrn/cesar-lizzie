import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ExecutionsController } from './executions.controller';
import { ExecutionsService } from './executions.service';
import { RoutineExecution } from './entities/routine-execution.entity';
import { StepExecution } from './entities/step-execution.entity';
import { UsersModule } from '../users/users.module';
import { RoutinesModule } from '../routines/routines.module';
import { AlertsModule } from '../alerts/alerts.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([RoutineExecution, StepExecution]),
    UsersModule,
    RoutinesModule,
    AlertsModule,
  ],
  controllers: [ExecutionsController],
  providers: [ExecutionsService],
  exports: [ExecutionsService],
})
export class ExecutionsModule {}
