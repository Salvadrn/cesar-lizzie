import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { BullModule } from '@nestjs/bull';
import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { RoutinesModule } from './modules/routines/routines.module';
import { ExecutionsModule } from './modules/executions/executions.module';
import { InteractionLogsModule } from './modules/interaction-logs/interaction-logs.module';
import { SafetyModule } from './modules/safety/safety.module';
import { AlertsModule } from './modules/alerts/alerts.module';
import { CaregiverModule } from './modules/caregiver/caregiver.module';
import { EventsModule } from './gateway/events.module';
import { RobotModule } from './modules/robot/robot.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: (config: ConfigService) => ({
        type: 'postgres' as const,
        host: config.get('DB_HOST', 'localhost'),
        port: config.get<number>('DB_PORT', 5432),
        username: config.get('DB_USER', 'adaptai'),
        password: config.get('DB_PASS', 'adaptai_dev'),
        database: config.get('DB_NAME', 'adaptai'),
        entities: [__dirname + '/**/*.entity{.ts,.js}'],
        synchronize: config.get('NODE_ENV') === 'development',
        logging: config.get('NODE_ENV') === 'development',
      }),
      inject: [ConfigService],
    }),
    BullModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: (config: ConfigService) => ({
        redis: {
          host: config.get('REDIS_HOST', 'localhost'),
          port: config.get<number>('REDIS_PORT', 6379),
        },
      }),
      inject: [ConfigService],
    }),
    AuthModule,
    UsersModule,
    RoutinesModule,
    ExecutionsModule,
    InteractionLogsModule,
    SafetyModule,
    AlertsModule,
    CaregiverModule,
    EventsModule,
    RobotModule,
  ],
})
export class AppModule {}
