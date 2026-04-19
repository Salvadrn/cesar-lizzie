import { IsEmail, IsString, MinLength, IsIn, Matches } from 'class-validator';

export class RegisterDto {
  @IsEmail()
  email: string;

  @IsString()
  @MinLength(8, { message: 'La contraseña debe tener al menos 8 caracteres' })
  @Matches(/[A-Z]/, { message: 'La contraseña debe incluir al menos una letra mayúscula' })
  @Matches(/[a-z]/, { message: 'La contraseña debe incluir al menos una letra minúscula' })
  @Matches(/[0-9]/, { message: 'La contraseña debe incluir al menos un número' })
  password: string;

  @IsString()
  @MinLength(2)
  displayName: string;

  @IsIn(['user', 'caregiver'])
  role: 'user' | 'caregiver';
}
