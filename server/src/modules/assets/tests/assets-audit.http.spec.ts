import {
  INestApplication,
  NotFoundException,
  ServiceUnavailableException,
  ValidationPipe,
} from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { UserRole } from '@prisma/client';
import {
  auditPipelineProviders,
  createAuditSpy,
} from '../../../shared/testing/audit.testing';
import { AuthService } from '../../auth/auth.service';
import { AssetsController } from '../assets.controller';
import { AssetsService } from '../assets.service';

const actorId = '11111111-1111-4111-8111-111111111111';
const key = 'uploads/11111111/handoff-photo.png';

describe('Assets audit logging', () => {
  let app: INestApplication;
  let url: string;
  const audit = createAuditSpy();
  const assets = { upload: jest.fn(), download: jest.fn() };
  const auth = {
    validateSession: jest.fn(() =>
      Promise.resolve({
        session_id: 'session',
        user_id: actorId,
        user: { user_id: actorId, role: UserRole.KITCHEN_STAFF },
      }),
    ),
  };

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      controllers: [AssetsController],
      providers: [
        { provide: AssetsService, useValue: assets },
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
    url = `${await app.getUrl()}/api/assets`;
  });

  afterAll(async () => app.close());

  beforeEach(() => {
    audit.create.mockClear().mockResolvedValue({});
    assets.upload.mockReset().mockResolvedValue({ key });
    assets.download
      .mockReset()
      .mockResolvedValue({ url: 'https://signed.example/file' });
  });

  const authHeader = { Authorization: 'Bearer token' };

  function upload() {
    const form = new FormData();
    form.append(
      'file',
      new Blob([new Uint8Array([137, 80, 78, 71])], { type: 'image/png' }),
      'photo.png',
    );
    return fetch(url, { method: 'POST', headers: authHeader, body: form });
  }

  const download = (
    query: string,
    headers: Record<string, string> = authHeader,
  ) => fetch(`${url}/download-url?${query}`, { headers });

  it('IT-ASSET-017: Given a signed-in user, When they upload an image and request its download URL, Then audit both without the object key or signed URL', async () => {
    const uploaded = await upload();
    const issued = await download(`key=${encodeURIComponent(key)}`);

    expect([uploaded.status, issued.status]).toEqual([201, 200]);
    expect(audit.rows()).toEqual([
      expect.objectContaining({
        actor_id: actorId,
        action: 'ASSET_UPLOADED',
        entity_type: 'assets',
        entity_id: null,
        outcome: 'SUCCESS',
      }),
      expect.objectContaining({
        actor_id: actorId,
        action: 'ASSET_DOWNLOAD_URL_ISSUED',
        entity_type: 'assets',
        entity_id: null,
        outcome: 'SUCCESS',
      }),
    ]);
    const stored = JSON.stringify(audit.rows());
    expect(stored).not.toContain('handoff-photo');
    expect(stored).not.toContain('signed.example');
  });

  it('IT-ASSET-018: Given a storage outage, an unknown key and an empty key, When download URLs are requested, Then audit only the outage', async () => {
    assets.download
      .mockRejectedValueOnce(
        new ServiceUnavailableException('Asset storage is unavailable'),
      )
      .mockRejectedValueOnce(new NotFoundException('Asset not found'));

    const outage = await download(`key=${encodeURIComponent(key)}`);
    const unknown = await download('key=uploads/missing.png');
    const empty = await download('key=');

    expect([outage.status, unknown.status, empty.status]).toEqual([
      503, 404, 400,
    ]);
    expect(audit.rows()).toEqual([
      expect.objectContaining({
        action: 'ASSET_DOWNLOAD_URL_ISSUED',
        outcome: 'FAILED',
        reason: 'HTTP_503',
      }),
    ]);
  });

  it('IT-ASSET-019: Given no session, When a download URL is requested, Then audit a DENIED row with no actor', async () => {
    const response = await download(`key=${encodeURIComponent(key)}`, {});

    expect(response.status).toBe(401);
    expect(assets.download).not.toHaveBeenCalled();
    expect(audit.rows()).toEqual([
      expect.objectContaining({
        actor_id: null,
        action: 'ASSET_DOWNLOAD_URL_ISSUED',
        outcome: 'DENIED',
        reason: 'SESSION_TOKEN_REQUIRED',
      }),
    ]);
  });
});
