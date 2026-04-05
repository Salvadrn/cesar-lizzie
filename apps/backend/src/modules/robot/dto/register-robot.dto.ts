import { IsString, IsUUID, IsOptional, MaxLength } from 'class-validator';

export class RegisterRobotDto {
  @IsUUID()
  userId: string;

  @IsString()
  @MaxLength(100)
  serialNumber: string;

  @IsString()
  @MaxLength(100)
  name: string;

  @IsOptional()
  @IsString()
  @MaxLength(50)
  firmwareVersion?: string;
}
