const fs = require('node:fs');

const [action, ...args] = process.argv.slice(2);
const read = (file) => JSON.parse(fs.readFileSync(file, 'utf8'));
const output = (value) => process.stdout.write(JSON.stringify(value));

try {
  if (action === 'get') {
    const [file, path] = args;
    const value = path
      .split('.')
      .reduce((result, key) => result?.[key], read(file));
    if (value === undefined || value === null || value === '')
      throw new Error(`Missing ${path}`);
    process.stdout.write(String(value));
  } else if (action === 'login') {
    output({ username: args[0], password: process.env.E2E_LOGIN_PASSWORD });
  } else if (action === 'assign') {
    output({ [args[0]]: args[1] });
  } else if (action === 'order') {
    const [order_id, menu_item_id, order_channel, quantity] = args;
    output({
      order_id,
      order_channel,
      lines: [{ menu_item_id, quantity: Number(quantity) }],
      ...(order_channel === 'GRABFOOD'
        ? {
            merchant_store_reference: `e2e-${order_id}`,
            external_order_reference: order_id,
          }
        : {}),
    });
  } else if (action === 'rejections') {
    const [order_item_id, count, invalid] = args;
    const numbers = invalid
      ? [Number(count) + 1]
      : Array.from({ length: Number(count) }, (_, index) => index + 1);
    output({
      rejections: numbers.map((portion_number) => ({
        order_item_id,
        portion_number,
        rejection_reason: 'INCOMPLETE',
        description: invalid ? 'Invalid portion' : 'Needs rework',
      })),
    });
  } else if (action === 'check') {
    const [file, kind, ...values] = args;
    const body = read(file);
    const checks = {
      draft: () =>
        body.status === 'DRAFT' && body.kitchen_tickets_order === null,
      confirmed: () =>
        body.status === 'CONFIRMED' &&
        body.kitchen_tickets_order?.status === 'QUEUED',
      preparer: () => body.preparer_id === values[0],
      status: () => body.status === values[0],
      prepared: () =>
        body.ticket?.status === 'PREPARING' &&
        body.order?.status === 'PREPARING',
      checking: () =>
        body.ticket?.status === 'CHECKING' &&
        body.attempt?.status === 'IN_PROGRESS' &&
        body.attempt?.attempt_number === Number(values[0]),
      rejected: () =>
        body.ticket?.status === 'REWORKING' &&
        body.attempt?.status === 'FAILED' &&
        body.rejections?.length === Number(values[0]),
      rejections: () =>
        Array.isArray(body) &&
        body.length === Number(values[0]) &&
        body.every(
          (row) =>
            row.order_item_id === values[1] && row.qc_attempt_id === values[2],
        ),
      ready: () =>
        body.ticket?.status === 'READY' && body.attempt?.status === 'PASSED',
      code: () => body.code === values[0],
      completed: () =>
        body.order?.status === 'COMPLETED' &&
        body.order?.kitchen_tickets_order?.status === 'HANDED_OVER' &&
        body.handedOverTicket?.status === 'HANDED_OVER',
      handoff: () =>
        body.handoffs?.some(
          (row) =>
            row.kitchen_ticket_id === values[0] && row.img_urls?.length === 1,
        ),
    };
    if (!checks[kind] || !checks[kind]())
      throw new Error(`Response assertion failed: ${kind}`);
  } else throw new Error(`Unknown JSON action: ${action}`);
} catch (error) {
  console.error(error.message);
  process.exitCode = 1;
}
