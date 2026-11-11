import type { NextConfig } from "next";
import { initOpenNextCloudflareForDev } from "@opennextjs/cloudflare";

initOpenNextCloudflareForDev();

const nextConfig: NextConfig = {
  /* config options here */
  // cacheComponents & partialPrefetching hängen aktuell in der
  // Cloudflare-Workers-Runtime (setTimeout-Implementierung, Worker-Logs
  // 2026-11-11); die App nutzt kein "use cache" → gefahrlos deaktiviert.
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
