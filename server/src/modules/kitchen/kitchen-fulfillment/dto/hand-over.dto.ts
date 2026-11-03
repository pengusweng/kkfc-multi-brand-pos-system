import { PartialType } from '@nestjs/swagger';
import { CreateHandoffDTO } from '../../handoff/dto/create-handoff.dto';

export class HandOverDTO extends PartialType(CreateHandoffDTO, {
  skipNullProperties: false,
}) {}
