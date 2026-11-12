import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import { concatMap, Observable } from 'rxjs';
import type { AuditableRequest } from './audit.decorator';
import { AuditRecorder } from './audit-recorder.service';

/**
 * Writes the SUCCESS row for `@Audit()` routes once the handler resolves
 * (after its transaction has committed). Failures are recorded by
 * AllExceptionsFilter, which also sees guard rejections.
 */
@Injectable()
export class AuditInterceptor implements NestInterceptor {
  constructor(private readonly recorder: AuditRecorder) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    if (context.getType() !== 'http') return next.handle();

    const request = context.switchToHttp().getRequest<AuditableRequest>();
    if (!request.audit) return next.handle();

    return next.handle().pipe(
      concatMap(async (result: unknown) => {
        await this.recorder.recordSuccess(request, result);
        return result;
      }),
    );
  }
}
