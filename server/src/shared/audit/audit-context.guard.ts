import { CanActivate, ExecutionContext, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { randomUUID } from 'node:crypto';
import type { Response } from 'express';
import { AUDIT_KEY, AuditOptions, AuditableRequest } from './audit.decorator';

const REQUEST_ID_PATTERN = /^[A-Za-z0-9._:-]{1,128}$/;

/**
 * Registered globally so it runs before every controller guard. It never
 * blocks; it only attaches the route's audit metadata and a request ID, so
 * later guard rejections (401/403) can still be audited by the exception
 * filter.
 */
@Injectable()
export class AuditContextGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    if (context.getType() !== 'http') return true;

    const http = context.switchToHttp();
    const request = http.getRequest<AuditableRequest>();
    const incoming = request.headers['x-request-id'];
    request.auditRequestId =
      typeof incoming === 'string' && REQUEST_ID_PATTERN.test(incoming)
        ? incoming
        : randomUUID();
    http
      .getResponse<Response>()
      .setHeader('x-request-id', request.auditRequestId);

    const audit = this.reflector.get<AuditOptions | undefined>(
      AUDIT_KEY,
      context.getHandler(),
    );
    if (audit) request.audit = audit;

    return true;
  }
}
