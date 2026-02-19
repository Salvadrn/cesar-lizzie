import { IsOptional, IsString, IsNumber, IsBoolean, IsIn, Min, Max } from 'class-validator';

export class UpdateProfileDto {
  @IsOptional()
  @IsIn(['default', 'low_stimulation', 'high_contrast'])
  sensoryMode?: 'default' | 'low_stimulation' | 'high_contrast';

  @IsOptional()
  @IsBoolean()
  hapticEnabled?: boolean;

  @IsOptional()
  @IsNumber()
  @Min(1)
  @Max(5)
  hapticIntensity?: number;

  @IsOptional()
  @IsBoolean()
  audioEnabled?: boolean;

  @IsOptional()
  @IsNumber()
  @Min(0.5)
  @Max(2.0)
  audioSpeed?: number;

  @IsOptional()
  @IsNumber()
  @Min(0.8)
  @Max(2.0)
  fontScale?: number;

  @IsOptional()
  @IsBoolean()
  animationEnabled?: boolean;

  @IsOptional()
  @IsString()
  lostModeName?: string;

  @IsOptional()
  @IsString()
  lostModeAddress?: string;

  @IsOptional()
  @IsString()
  lostModePhone?: string;

  @IsOptional()
  @IsIn(['touch', 'voice', 'switch'])
  preferredInput?: 'touch' | 'voice' | 'switch';

  @IsOptional()
  @IsString()
  language?: string;
}
