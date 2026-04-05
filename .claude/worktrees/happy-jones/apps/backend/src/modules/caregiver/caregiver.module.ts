import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { CaregiverController } from './caregiver.controller';
import { CaregiverService } from './caregiver.service';
import { CaregiverLink } from './entities/caregiver-link.entity';
import { UsersModule } from '../users/users.module';
import { ExecutionsModule } from '../executions/executions.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([CaregiverLink]),
    UsersModule,
  ],
  controllers: [CaregiverController],
  providers: [CaregiverService],
  exports: [CaregiverService],
})
export class CaregiverModule {}
