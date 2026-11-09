import { setupServer } from "msw/node";

// Add shared API handlers here; override per test with server.use(...).
export const server = setupServer();
