import { ForbiddenException, HttpException, HttpStatus } from '@nestjs/common';
import type { PinVerificationResult } from './pin.repository';

// A wrong PIN on an action is 403, not 401: the web client treats 401 as an
// expired session. Login maps 'invalid' to 401 itself before calling this.
export function assertValidPin(
  result: PinVerificationResult,
): asserts result is { status: 'valid' } {
  if (result.status === 'valid') return;

  if (result.status === 'locked') {
    throw new HttpException(
      {
        code: 'PIN_LOCKED',
        message: 'Too many incorrect PIN attempts. Try again later.',
        locked_until: result.until,
      },
      HttpStatus.TOO_MANY_REQUESTS,
    );
  }

  if (result.status === 'not-configured') {
    throw new ForbiddenException({
      code: 'PIN_NOT_CONFIGURED',
      message: 'Set up your PIN before performing this action.',
    });
  }

  throw new ForbiddenException({
    code: 'INVALID_PIN',
    message: 'Incorrect PIN.',
  });
}
