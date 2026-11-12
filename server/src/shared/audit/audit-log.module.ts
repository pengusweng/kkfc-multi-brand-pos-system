import { Global, Module } from '@nestjs/common';
import { AuditRecorder } from './audit-recorder.service';

/** Global so AllExceptionsFilter and the interceptor can inject the recorder. */
@Global()
@Module({
  providers: [AuditRecorder],
  exports: [AuditRecorder],
})
export class AuditLogModule {}
