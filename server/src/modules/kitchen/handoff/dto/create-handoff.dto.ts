import { ApiProperty } from '@nestjs/swagger';
import {
  ArrayMinSize,
  ArrayMaxSize,
  IsArray,
  IsString,
  Matches,
  MaxLength,
} from 'class-validator';

export class CreateHandoffDTO {
  @ApiProperty({
    type: 'array',
    minItems: 1,
    items: { type: 'string', minLength: 1, maxLength: 2048 },
    description:
      'Storage keys returned by the asset upload API for handoff images.',
    example: [
      'uploads/00000000-0000-4000-8000-000000000001/00000000-0000-4000-8000-000000000002.png',
    ],
  })
  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(5, { message: 'A handover can have at most 5 images.' })
  @IsString({ each: true })
  @Matches(/\S/, { each: true })
  @MaxLength(2048, { each: true })
  img_keys!: string[];
}
