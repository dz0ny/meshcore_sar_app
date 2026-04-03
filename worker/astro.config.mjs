import { defineConfig } from "astro/config";
import cloudflare from "@astrojs/cloudflare";
import react from "@astrojs/react";
import tailwindcss from "@tailwindcss/vite";

export default defineConfig({
  imageService: "compile",
  integrations: [react()],
  vite: {
    cacheDir: ".astro/vite",
    plugins: [tailwindcss()],
    resolve: {
      alias: {
        "@": "/src",
      },
    },
  },
  build: {
    concurrency: 4,
  },
  server: {
    port: 4321,
    host: "0.0.0.0",
    allowedHosts: true,
  },
  devToolbar: {
    enabled: false,
  },
  adapter: cloudflare(),
});
