import { BadRequestException, Injectable, Logger } from '@nestjs/common';
import { validateSync } from 'class-validator';
import { assertValidPagination } from '../../shared/assertions/assert-valid-pagination';
import { AuditRepository } from './audit.repository';
import { FindAuditLogsDTO } from './dto/find-audit-logs.dto';

@Injectable()
export class AuditService {
  private readonly logger = new Logger(AuditService.name);

  constructor(private readonly repository: AuditRepository) {}

  async findAll(query: Partial<FindAuditLogsDTO> = {}) {
    // Internal callers do not pass through Nest's HTTP validation pipe.
    if (!query || typeof query !== 'object' || Array.isArray(query)) {
      throw new BadRequestException('Invalid audit log query.');
    }
    const validated = Object.assign(new FindAuditLogsDTO(), query);
    if (
      validateSync(validated, {
        whitelist: true,
        forbidNonWhitelisted: true,
        forbidUnknownValues: true,
      }).length > 0
    ) {
      throw new BadRequestException('Invalid audit log query.');
    }
    const { page, limit, action, outcome, search, from, to } = validated;
    // YYYY-MM-DD strings compare in calendar order.
    if (from !== undefined && to !== undefined && from > to) {
      throw new BadRequestException('from must be on or before to.');
    }
    const skip = (page - 1) * limit;
    assertValidPagination(skip, this.logger);
    const { logs, total, counts } = await this.repository.findAll(
      {
        ...(action !== undefined ? { action } : {}),
        ...(search !== undefined ? { search } : {}),
        ...(from !== undefined ? { from } : {}),
        ...(to !== undefined ? { to } : {}),
      },
      outcome,
      skip,
      limit,
    );
    return {
      data: logs,
      meta: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
        counts,
      },
    };
  }
}
