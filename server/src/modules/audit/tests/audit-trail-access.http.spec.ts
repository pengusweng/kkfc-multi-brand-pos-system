import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { UserRole } from '@prisma/client';
import {
  auditPipelineProviders,
  createAuditSpy,
} from '../../../shared/testing/audit.testing';
import { AuthService } from '../../auth/auth.service';
import { AuditController } from '../audit.controller';
import { AuditService } from '../audit.service';

const actorId = '11111111-1111-4111-8111-111111111111';

describe('Audit trail access logging', () => {
  let app: INestApplication;
  let url: string;
  let role: UserRole;
  const audit = createAuditSpy();
  const service = { findAll: jest.fn() };
  const auth = {
    validateSession: jest.fn(() =>
      Promise.resolve({
        session_id: 'session',
        user_id: actorId,
        user: { user_id: actorId, role },
      }),
    ),
  };

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      controllers: [AuditController],
      providers: [
        { provide: AuditService, useValue: service },
        { provide: AuthService, useValue: auth },
        ...auditPipelineProviders(audit),
      ],
    }).compile();
    app = module.createNestApplication();
    app.useLogger(false);
    app.setGlobalPrefix('api');
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
      }),
    );
    await app.listen(0);
    url = `${await app.getUrl()}/api/audit-logs`;
  });

  afterAll(async () => app.close());

  beforeEach(() => {
    role = UserRole.SUPERADMIN;
    audit.create.mockClear().mockResolvedValue({});
    service.findAll.mockReset().mockResolvedValue({ data: [], meta: {} });
  });

  const view = (query = '') =>
    fetch(`${url}${query}`, { headers: { Authorization: 'Bearer token' } });

  it('IT-AUDIT-013: Given a superadmin, When they view the audit trail with valid and invalid filters, Then no audit rows are written', async () => {
    const valid = await view('?action=ORDER_CONFIRMED&outcome=DENIED');
    const invalid = await view('?limit=1000');

    expect([valid.status, invalid.status]).toEqual([200, 400]);
    expect(service.findAll).toHaveBeenCalledTimes(1);
    expect(audit.rows()).toEqual([]);
  });

  it('IT-AUDIT-014: Given a manager, When they try to view the audit trail, Then it is denied without reading or writing audit rows', async () => {
    role = UserRole.MANAGER;

    const response = await view();

    expect(response.status).toBe(403);
    expect(service.findAll).not.toHaveBeenCalled();
    expect(audit.rows()).toEqual([]);
  });
});
