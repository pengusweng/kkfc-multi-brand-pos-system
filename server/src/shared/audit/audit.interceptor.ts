import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import { concatMap, defer, Observable, switchMap } from 'rxjs';
import { changedFields } from './audit-snapshots';
import type { AuditableRequest } from './audit.decorator';
import { AuditRecorder } from './audit-recorder.service';

/**
 * Writes the SUCCESS row for `@Audit()` routes once the handler resolves
 * (after its transaction has committed). For `snapshot: 'update'` routes it
 * reads the record before the handler runs and again afterwards, storing only
 * the changed fields; for `snapshot: 'create'` it stores the new record.
 * Failures are recorded by AllExceptionsFilter, which also sees guard
 * rejections, and never carry snapshots.
 */
@Injectable()
export class AuditInterceptor implements NestInterceptor {
  constructor(private readonly recorder: AuditRecorder) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    if (context.getType() !== 'http') return next.handle();

    const request = context.switchToHttp().getRequest<AuditableRequest>();
    const audit = request.audit;
    if (!audit) return next.handle();

    // Runs before the handler is invoked: the handler only starts when
    // next.handle() is subscribed inside switchMap.
    const before$ = defer(() =>
      audit.snapshot === 'update'
        ? this.recorder.loadSnapshot(audit.entity, audit.id?.(request))
        : Promise.resolve(null),
    );

    return before$.pipe(
      switchMap((before) =>
        next.handle().pipe(
          concatMap(async (result: unknown) => {
            if (!audit.snapshot) {
              await this.recorder.recordSuccess(request, result);
              return result;
            }
            const after = await this.recorder.loadSnapshot(
              audit.entity,
              audit.id?.(request, result),
            );
            await this.recorder.recordSuccess(
              request,
              result,
              audit.snapshot === 'update'
                ? changedFields(before, after)
                : { before: null, after },
            );
            return result;
          }),
        ),
      ),
    );
  }
}
