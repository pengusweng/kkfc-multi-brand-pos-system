import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  rewrites() {
    const apiUrl = process.env.API_URL;
    if (!apiUrl) throw new Error("Set API_URL in web/.env.");

    return [{
      source: "/api/:path*",
      destination: new URL("/api/:path*", apiUrl).toString(),
    }];
  },
  experimental: {
    agentFeedback: true,
  },
  cacheComponents: true,
  partialPrefetching: true,
  turbopack: {
    rules: {
      "*.css": {
        loaders: ["@tailwindcss/turbopack"],
        as: "*.css",
      },
    },
  },
};

export default nextConfig;
