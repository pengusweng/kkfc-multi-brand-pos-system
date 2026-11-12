import {
  ArgumentsHost,
  Catch,
  HttpException,
  Inject,
  Logger,
  Optional,
} from '@nestjs/common';
import { BaseExceptionFilter } from '@nestjs/core';
import type { AuditableRequest } from '../audit/audit.decorator';
import { AuditRecorder } from '../audit/audit-recorder.service';

@Catch()
export class AllExceptionsFilter extends BaseExceptionFilter<unknown> {
  private readonly logger = new Logger(AllExceptionsFilter.name);

  // Optional: test modules that register this filter without audit wiring
  // still resolve it, and simply skip audit recording.
  @Optional()
  @Inject(AuditRecorder)
  private readonly auditRecorder?: AuditRecorder;

  catch(exception: unknown, host: ArgumentsHost): void {
    if (exception instanceof HttpException) {
      const status = exception.getStatus();
      const message = `${exception.name} (HTTP ${status})`;

      if (status < 500) {
        this.logger.warn(message);
      } else {
        this.logger.error(message);
      }
    }

    const request =
      host.getType() === 'http'
        ? host.switchToHttp().getRequest<AuditableRequest>()
        : undefined;

    // Record denied/failed `@Audit()` requests (including guard rejections)
    // before responding. recordFailure never rejects.
    if (this.auditRecorder && request?.audit) {
      void this.auditRecorder
        .recordFailure(request, exception)
        .finally(() => super.catch(exception, host));
      return;
    }

    super.catch(exception, host);
  }
}
