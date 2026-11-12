import { Injectable, OnModuleDestroy } from '@nestjs/common';
import { Subject } from 'rxjs';

/**
 * Signals that kitchen tickets changed. Lives outside KitchenTicketService so
 * modules that KitchenTicketModule depends on (e.g. orders) can signal too.
 *
 * Only call `notify()` after the write has committed; listeners refetch
 * immediately and would otherwise read the pre-commit state.
 */
@Injectable()
export class KitchenTicketChanges implements OnModuleDestroy {
  private readonly subject = new Subject<void>();
  readonly changes$ = this.subject.asObservable();

  notify() {
    this.subject.next();
  }

  onModuleDestroy() {
    this.subject.complete();
  }
}
