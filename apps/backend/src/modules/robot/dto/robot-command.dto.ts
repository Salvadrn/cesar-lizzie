import { IsString, IsOptional, IsObject } from 'class-validator';

export class RobotCommandDto {
  @IsString()
  commandType:
    | 'start'
    | 'stop'
    | 'pause'
    | 'resume'
    | 'update_config'
    | 'emergency_stop'
    | 'reset';

  @IsOptional()
  @IsObject()
  payload?: Record<string, unknown>;
}
