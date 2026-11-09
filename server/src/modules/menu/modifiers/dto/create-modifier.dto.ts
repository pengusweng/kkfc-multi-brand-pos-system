import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsNotEmpty, IsOptional, IsString, MaxLength } from 'class-validator';

export class CreateModifierDTO {
  @IsString()
  @IsNotEmpty()
  @MaxLength(64)
  @ApiProperty({ minLength: 1, maxLength: 64 })
  code!: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(150)
  @ApiProperty({ minLength: 1, maxLength: 150 })
  name!: string;

  @IsOptional()
  @IsString()
  @MaxLength(2000)
  @ApiPropertyOptional({ type: String, maxLength: 2000, nullable: true })
  description?: string | null;
}
