import { IsString } from 'class-validator';

export class PairRobotDto {
  @IsString()
  serialNumber: string;

  @IsString()
  pairingCode: string;
}
