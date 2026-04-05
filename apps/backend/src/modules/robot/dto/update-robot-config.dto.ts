import { IsNumber, IsBoolean, IsString, IsOptional, Min, Max } from 'class-validator';

export class UpdateRobotConfigDto {
  @IsOptional()
  @IsNumber()
  @Min(0.5)
  @Max(5)
  followDistanceM?: number;

  @IsOptional()
  @IsNumber()
  @Min(0.1)
  @Max(1.0)
  maxSpeed?: number;

  @IsOptional()
  @IsNumber()
  @Min(10)
  @Max(100)
  emergencyStopCm?: number;

  @IsOptional()
  @IsNumber()
  @Min(1)
  @Max(10)
  telemetryRateHz?: number;

  @IsOptional()
  @IsString()
  bleTargetUuid?: string;

  @IsOptional()
  @IsBoolean()
  lidarEnabled?: boolean;
}
