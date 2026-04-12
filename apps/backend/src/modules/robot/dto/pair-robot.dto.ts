import { IsUUID } from 'class-validator';

export class PairRobotDto {
  @IsUUID()
  robotId: string;
}
