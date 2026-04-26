import {
  IsBoolean,
  IsIn,
  IsNumber,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
} from 'class-validator';

export class RobotTelemetryDto {
  @IsOptional()
  @IsString()
  @IsIn([
    'idle',
    'following',
    'paused',
    'error',
    'emergency_stop',
    'charging',
  ])
  state?: string;

  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(100)
  batteryPercent?: number;

  @IsOptional()
  @IsBoolean()
  bleTargetFound?: boolean;

  @IsOptional()
  @IsString()
  @MaxLength(200)
  emergencyReason?: string;

  @IsOptional()
  @IsNumber()
  @Min(-90)
  @Max(90)
  latitude?: number;

  @IsOptional()
  @IsNumber()
  @Min(-180)
  @Max(180)
  longitude?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(100)
  signalStrength?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  speed?: number;
}

export class RobotStatusChangeDto {
  @IsString()
  @IsIn(['idle', 'following', 'paused', 'error', 'emergency_stop'])
  state!: string;
}
