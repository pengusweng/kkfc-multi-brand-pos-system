import { Controller } from '@nestjs/common';
import { HandoffService } from './handoff.service';

@Controller('handoff')
export class HandoffController {
  constructor(private readonly handoffService: HandoffService) {}
}
