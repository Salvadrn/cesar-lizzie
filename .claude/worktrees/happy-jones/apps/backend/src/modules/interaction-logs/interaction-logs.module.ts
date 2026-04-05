import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { BullModule } from '@nestjs/bull';
import { InteractionLogsController } from './interaction-logs.controller';
import { InteractionLogsService } from './interaction-logs.service';
import { InteractionLog } from './entities/interaction-log.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([InteractionLog]),
    BullModule.registerQueue({ name: 'interaction-logs' }),
  ],
  controllers: [InteractionLogsController],
  providers: [InteractionLogsService],
  exports: [InteractionLogsService],
})
export class InteractionLogsModule {}
