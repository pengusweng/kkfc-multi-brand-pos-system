import { defineConfig } from "vitest/config";
import react from "@vitejs/plugin-react";
import tsconfigPaths from "vite-tsconfig-paths";

export default defineConfig({
  plugins: [react(), tsconfigPaths()],
  test: {
    setupFiles: ["./tests/setup.ts"],
    projects: [
      {
        extends: true,
        test: {
          name: "unit",
          environment: "node",
          include: ["src/**/*.test.ts"],
          exclude: ["src/**/*.integration.test.ts"],
        },
      },
      {
        extends: true,
        test: {
          name: "integration",
          environment: "jsdom",
          include: ["src/**/*.test.tsx", "src/**/*.integration.test.ts"],
        },
      },
    ],
    reporters: ["default", "junit"],
    outputFile: { junit: "reports/vitest.xml" },
    coverage: {
      provider: "v8",
      include: ["src/features/**/*.{ts,tsx}", "src/app/api/**/*.ts", "src/proxy.ts"],
      reporter: ["text", "html", "lcov"],
    },
  },
});
