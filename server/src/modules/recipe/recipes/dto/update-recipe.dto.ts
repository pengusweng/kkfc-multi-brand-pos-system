import { IsOptional, IsString, MaxLength } from 'class-validator';

export class UpdateRecipeDTO {
  @IsOptional()
  @IsString()
  @MaxLength(10000)
  instructions?: string | null;

  @IsOptional()
  @IsString()
  @MaxLength(2000)
  notes?: string | null;
}
