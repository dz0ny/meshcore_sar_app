# MeshCore SAR RX Stats Worker

This worker follows the same split as `/Users/dz0ny/site-vendorvigilance`:

- Astro builds the dashboard UI into `dist`
- a small Cloudflare Worker handles `/api/*` before assets are served

## Layout

- `src/pages/index.astro` - dashboard shell
- `worker/index.ts` - Cloudflare Worker entrypoint
- `worker/stats.ts` - D1 queries, payload validation, and aggregation helpers
- `public/.assetsignore` - keeps Astro's private `_worker.js` bundle out of public asset uploads
- `schema.sql` - D1 schema

## Setup

1. Install dependencies with `bun install`.
2. Create a D1 database with `bunx wrangler d1 create meshcore_sar_rx_stats`.
3. Apply the schema with `bunx wrangler d1 execute meshcore_sar_rx_stats --remote --file=./schema.sql`.
4. Add the real D1 binding id to `wrangler.toml` when deploying.
5. Build the dashboard with `bun run build`.
6. Run checks with `bun run check`, `bun run test`, and `bun run typecheck`.

## Routes

- `GET /` - static Astro dashboard
- `GET /api/dashboard?window=24h|7d|30d` - aggregated dashboard JSON
- `POST /api/ingest` - anonymous RX stats ingest
