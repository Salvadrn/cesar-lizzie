import { IsString, IsIn, IsOptional, IsObject } from 'class-validator';

export class RobotCommandDto {
  @IsString()
  @IsIn(['start', 'stop', 'pause', 'resume', 'update_config', 'emergency_stop', 'reset'])
  commandType: string;

  @IsOptional()
  @IsObject()
  payload?: Record<string, unknown>;
}
