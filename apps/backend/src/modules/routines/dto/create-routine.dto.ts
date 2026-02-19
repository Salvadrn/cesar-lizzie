import {
  IsString,
  IsOptional,
  IsBoolean,
  IsNumber,
  IsIn,
  Min,
  Max,
  MinLength,
} from 'class-validator';

export class CreateRoutineDto {
  @IsString()
  @MinLength(1)
  title: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsIn([
    'cooking', 'hygiene', 'laundry', 'medication',
    'transit', 'shopping', 'cleaning', 'social', 'custom',
  ])
  category: string;

  @IsOptional()
  @IsString()
  icon?: string;

  @IsOptional()
  @IsString()
  coverImageUrl?: string;

  @IsOptional()
  @IsString()
  assignedTo?: string;

  @IsOptional()
  @IsBoolean()
  isTemplate?: boolean;

  @IsOptional()
  @IsNumber()
  @Min(1)
  @Max(5)
  complexity?: number;

  @IsOptional()
  @IsNumber()
  estimatedMinutes?: number;

  @IsOptional()
  @IsIn(['daily', 'weekly', 'custom', 'on_demand'])
  scheduleType?: string;

  @IsOptional()
  scheduleConfig?: Record<string, unknown>;
}
