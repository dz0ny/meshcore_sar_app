export const PACKET_TYPE_KEYS = [
  "pt_00",
  "pt_01",
  "pt_02",
  "pt_03",
  "pt_04",
  "pt_05",
  "pt_06",
  "pt_07",
  "pt_08",
  "pt_09",
  "pt_0a",
  "pt_0b",
  "pt_0c",
  "pt_0d",
  "pt_0e",
  "pt_0f",
] as const;

export const PATH_MODE_KEYS = [
  "path_mode_1b",
  "path_mode_2b",
  "path_mode_3b",
  "path_mode_none",
  "path_mode_unknown",
] as const;

export const COUNT_KEYS = [
  ...PACKET_TYPE_KEYS,
  "decode_fail",
  ...PATH_MODE_KEYS,
] as const;

const REPORT_COLUMNS = [
  "report_id",
  "device_key6",
  "window_start",
  "window_end",
  "received_at",
  "app_version",
  "cf_country",
  "cf_region",
  "cf_city",
  "cf_latitude",
  "cf_longitude",
  "cf_colo",
  ...COUNT_KEYS,
] as const;

const PACKET_TYPE_LABELS: Record<(typeof PACKET_TYPE_KEYS)[number], string> = {
  pt_00: "Request",
  pt_01: "Response",
  pt_02: "Text message",
  pt_03: "Ack",
  pt_04: "Advertisement",
  pt_05: "Group text",
  pt_06: "Group datagram",
  pt_07: "Anonymous request",
  pt_08: "Returned path",
  pt_09: "Trace path",
  pt_0a: "Multipart packet",
  pt_0b: "Control packet",
  pt_0c: "Reserved 0x0C",
  pt_0d: "Reserved 0x0D",
  pt_0e: "Reserved 0x0E",
  pt_0f: "Custom packet",
};

const PATH_MODE_LABELS: Record<(typeof PATH_MODE_KEYS)[number], string> = {
  path_mode_1b: "1-byte path hash",
  path_mode_2b: "2-byte path hash",
  path_mode_3b: "3-byte path hash",
  path_mode_none: "No path bytes",
  path_mode_unknown: "Unknown path mode",
};

const WINDOW_OPTIONS = {
  "24h": {
    label: "Last 24 hours",
    durationMs: 24 * 60 * 60 * 1000,
    bucket: "hour",
  },
  "7d": {
    label: "Last 7 days",
    durationMs: 7 * 24 * 60 * 60 * 1000,
    bucket: "day",
  },
  "30d": {
    label: "Last 30 days",
    durationMs: 30 * 24 * 60 * 60 * 1000,
    bucket: "day",
  },
} as const;

export const jsonHeaders = {
  "content-type": "application/json; charset=utf-8",
} as const;

type CountKey = (typeof COUNT_KEYS)[number];
type PacketTypeKey = (typeof PACKET_TYPE_KEYS)[number];
type PathModeKey = (typeof PATH_MODE_KEYS)[number];
type WindowKey = keyof typeof WINDOW_OPTIONS;

export type Counts = Record<CountKey, number>;

export interface Env {
  DB: D1Database;
}

export interface IngestPayload {
  reportId: string;
  deviceKey6: string;
  windowStart: string;
  windowEnd: string;
  appVersion: string;
  counts: Counts;
}

export interface CfGeo {
  country: string | null;
  region: string | null;
  city: string | null;
  latitude: number | null;
  longitude: number | null;
  colo: string | null;
}

export interface ReportRow extends Counts {
  report_id: string;
  device_key6: string;
  window_start: string;
  window_end: string;
  received_at: string;
  app_version: string | null;
  cf_country: string | null;
  cf_region: string | null;
  cf_city: string | null;
  cf_latitude: number | null;
  cf_longitude: number | null;
  cf_colo: string | null;
}

export interface WindowFilter {
  windowKey: WindowKey;
  label: string;
  sinceIso: string;
  bucket: "hour" | "day";
}

export interface ChartPoint {
  label: string;
  totalPackets: number;
  reports: number;
}

export interface LocationPoint {
  key6: string;
  city: string;
  country: string;
  latitude: number;
  longitude: number;
}

export interface ReporterSummary {
  key6: string;
  lastSeen: string;
  packetTotal: number;
  country: string;
  city: string;
  latitude: number | null;
  longitude: number | null;
}

export interface AppVersionEntry {
  version: string;
  reporters: number;
  packets: number;
}

export interface ColoEntry {
  colo: string;
  reporters: number;
  packets: number;
}

export interface TrafficComposition {
  human: number;
  overhead: number;
  acks: number;
}

export interface MultiHopRatio {
  direct: number;
  multiHop: number;
}

export interface CompositionPoint {
  label: string;
  human: number;
  overhead: number;
}

export interface DashboardSummary {
  filter: WindowFilter;
  reportCount: number;
  uniqueDevices: number;
  decodedPackets: number;
  decodeFailures: number;
  packetTypeTotals: Array<{ key: PacketTypeKey; label: string; total: number }>;
  pathModeTotals: Array<{ key: PathModeKey; label: string; total: number }>;
  recentReporters: ReporterSummary[];
  chartPoints: ChartPoint[];
  locationPoints: LocationPoint[];
  appVersions: AppVersionEntry[];
  coloDistribution: ColoEntry[];
  trafficComposition: TrafficComposition;
  multiHopRatio: MultiHopRatio;
  compositionOverTime: CompositionPoint[];
}

export const REPORT_INSERT_SQL = `
INSERT OR IGNORE INTO reports (
  ${REPORT_COLUMNS.join(", ")}
) VALUES (
  ${REPORT_COLUMNS.map(() => "?").join(", ")}
)`.trim();

export function createEmptyCounts(): Counts {
  return Object.fromEntries(
    COUNT_KEYS.map((key) => [key, 0]),
  ) as Counts;
}

export function validateIngestPayload(payload: unknown): IngestPayload {
  if (typeof payload !== "object" || payload === null) {
    throw new Error("Body must be a JSON object.");
  }
  const record = payload as Record<string, unknown>;
  const reportId = asTrimmedString(record.reportId, "reportId");
  const deviceKey6 = asTrimmedString(record.deviceKey6, "deviceKey6");
  if (!/^[0-9a-f]{12}$/.test(deviceKey6)) {
    throw new Error("deviceKey6 must be 12 lowercase hex characters.");
  }
  const windowStart = asIsoString(record.windowStart, "windowStart");
  const windowEnd = asIsoString(record.windowEnd, "windowEnd");
  if (Date.parse(windowEnd) < Date.parse(windowStart)) {
    throw new Error("windowEnd must not be earlier than windowStart.");
  }
  const appVersion = asTrimmedString(record.appVersion, "appVersion");
  const counts = validateCounts(record.counts);
  return {
    reportId,
    deviceKey6,
    windowStart,
    windowEnd,
    appVersion,
    counts,
  };
}

export function extractCfGeo(request: Request): CfGeo {
  const cf = (request as Request & { cf?: Record<string, unknown> }).cf;
  return {
    country: asNullableString(cf?.country),
    region: asNullableString(cf?.region),
    city: asNullableString(cf?.city),
    latitude: asNullableNumber(cf?.latitude),
    longitude: asNullableNumber(cf?.longitude),
    colo: asNullableString(cf?.colo),
  };
}

export function buildWindowFilter(
  requestedWindow: string | null,
  now: Date = new Date(),
): WindowFilter {
  const windowKey =
    requestedWindow === "24h" ||
    requestedWindow === "7d" ||
    requestedWindow === "30d"
      ? requestedWindow
      : "24h";
  const option = WINDOW_OPTIONS[windowKey];
  return {
    windowKey,
    label: option.label,
    sinceIso: new Date(now.getTime() - option.durationMs).toISOString(),
    bucket: option.bucket,
  };
}

export async function loadDashboardSummary(
  env: Env,
  requestedWindow: string | null,
  now: Date = new Date(),
): Promise<DashboardSummary> {
  const filter = buildWindowFilter(requestedWindow, now);
  const query = await env.DB.prepare(
    "SELECT * FROM reports WHERE window_end >= ? ORDER BY window_end DESC",
  )
    .bind(filter.sinceIso)
    .all<ReportRow>();
  const rows = (query.results ?? []) as ReportRow[];
  return summarizeRows(rows, filter);
}

export function summarizeRows(
  rows: ReportRow[],
  filter: WindowFilter,
): DashboardSummary {
  const packetTypeTotals = PACKET_TYPE_KEYS.map((key) => ({
    key,
    label: PACKET_TYPE_LABELS[key],
    total: sumRows(rows, key),
  })).sort((left, right) => right.total - left.total);
  const pathModeTotals = PATH_MODE_KEYS.map((key) => ({
    key,
    label: PATH_MODE_LABELS[key],
    total: sumRows(rows, key),
  })).sort((left, right) => right.total - left.total);
  const decodedPackets = PACKET_TYPE_KEYS.reduce(
    (total, key) => total + sumRows(rows, key),
    0,
  );
  const decodeFailures = sumRows(rows, "decode_fail");
  const reporterMap = new Map<string, ReporterSummary>();
  const chartBuckets = new Map<string, ChartPoint>();

  // per-version and per-colo accumulators
  const versionMap = new Map<string, { reporters: Set<string>; packets: number }>();
  const coloMap = new Map<string, { reporters: Set<string>; packets: number }>();
  const compositionBuckets = new Map<string, { human: number; overhead: number }>();

  for (const row of rows) {
    const packetTotal =
      decodeFailuresForRow(row) +
      PACKET_TYPE_KEYS.reduce((total, key) => total + row[key], 0);
    const existingReporter = reporterMap.get(row.device_key6);
    if (!existingReporter) {
      reporterMap.set(row.device_key6, {
        key6: row.device_key6,
        lastSeen: row.window_end,
        packetTotal,
        country: row.cf_country ?? "Unknown",
        city: row.cf_city ?? row.cf_region ?? "Unknown",
        latitude: row.cf_latitude,
        longitude: row.cf_longitude,
      });
    } else {
      existingReporter.packetTotal += packetTotal;
      if (row.window_end > existingReporter.lastSeen) {
        existingReporter.lastSeen = row.window_end;
        existingReporter.country = row.cf_country ?? existingReporter.country;
        existingReporter.city =
          row.cf_city ?? row.cf_region ?? existingReporter.city;
        existingReporter.latitude = row.cf_latitude;
        existingReporter.longitude = row.cf_longitude;
      }
    }

    const bucketKey = formatBucket(row.window_end, filter.bucket);
    const existingBucket = chartBuckets.get(bucketKey);
    if (existingBucket) {
      existingBucket.totalPackets += packetTotal;
      existingBucket.reports += 1;
    } else {
      chartBuckets.set(bucketKey, {
        label: bucketKey,
        totalPackets: packetTotal,
        reports: 1,
      });
    }

    // app version
    const ver = row.app_version ?? "unknown";
    const verEntry = versionMap.get(ver);
    if (verEntry) {
      verEntry.reporters.add(row.device_key6);
      verEntry.packets += packetTotal;
    } else {
      versionMap.set(ver, { reporters: new Set([row.device_key6]), packets: packetTotal });
    }

    // CF colo
    const colo = row.cf_colo ?? "unknown";
    const coloEntry = coloMap.get(colo);
    if (coloEntry) {
      coloEntry.reporters.add(row.device_key6);
      coloEntry.packets += packetTotal;
    } else {
      coloMap.set(colo, { reporters: new Set([row.device_key6]), packets: packetTotal });
    }

    // composition over time (human = text + group_text, overhead = rest)
    const humanPackets = row.pt_02 + row.pt_05;
    const overheadPackets = packetTotal - humanPackets;
    const compBucket = compositionBuckets.get(bucketKey);
    if (compBucket) {
      compBucket.human += humanPackets;
      compBucket.overhead += overheadPackets;
    } else {
      compositionBuckets.set(bucketKey, { human: humanPackets, overhead: overheadPackets });
    }
  }

  const recentReporters = [...reporterMap.values()]
    .sort((left, right) => right.lastSeen.localeCompare(left.lastSeen))
    .slice(0, 12);
  const locationPoints = recentReporters
    .filter(
      (
        reporter,
      ): reporter is ReporterSummary & { latitude: number; longitude: number } =>
        reporter.latitude !== null && reporter.longitude !== null,
    )
    .map((reporter) => ({
      key6: reporter.key6,
      city: reporter.city,
      country: reporter.country,
      latitude: reporter.latitude,
      longitude: reporter.longitude,
    }));

  // human = text messages (pt_02 + pt_05), acks = pt_03, overhead = everything else
  const humanTotal = sumRows(rows, "pt_02") + sumRows(rows, "pt_05");
  const acksTotal = sumRows(rows, "pt_03");
  const overheadTotal = decodedPackets - humanTotal - acksTotal;

  // multi-hop: direct = path_mode_none, multiHop = 1b+2b+3b
  const directTotal = sumRows(rows, "path_mode_none");
  const multiHopTotal = sumRows(rows, "path_mode_1b") + sumRows(rows, "path_mode_2b") + sumRows(rows, "path_mode_3b");

  return {
    filter,
    reportCount: rows.length,
    uniqueDevices: reporterMap.size,
    decodedPackets,
    decodeFailures,
    packetTypeTotals,
    pathModeTotals,
    recentReporters,
    chartPoints: [...chartBuckets.values()].sort((left, right) =>
      left.label.localeCompare(right.label),
    ),
    locationPoints,
    appVersions: [...versionMap.entries()]
      .map(([version, entry]) => ({ version, reporters: entry.reporters.size, packets: entry.packets }))
      .sort((left, right) => right.packets - left.packets),
    coloDistribution: [...coloMap.entries()]
      .map(([colo, entry]) => ({ colo, reporters: entry.reporters.size, packets: entry.packets }))
      .sort((left, right) => right.packets - left.packets),
    trafficComposition: { human: humanTotal, overhead: overheadTotal, acks: acksTotal },
    multiHopRatio: { direct: directTotal, multiHop: multiHopTotal },
    compositionOverTime: [...compositionBuckets.entries()]
      .map(([label, entry]) => ({ label, ...entry }))
      .sort((left, right) => left.label.localeCompare(right.label)),
  };
}

function validateCounts(value: unknown): Counts {
  if (typeof value !== "object" || value === null) {
    throw new Error("counts must be an object.");
  }
  const record = value as Record<string, unknown>;
  const counts = createEmptyCounts();
  for (const key of COUNT_KEYS) {
    const rawValue = record[key];
    if (typeof rawValue !== "number" || !Number.isFinite(rawValue)) {
      throw new Error(`counts.${key} must be a number.`);
    }
    if (rawValue < 0) {
      throw new Error(`counts.${key} must be zero or greater.`);
    }
    counts[key] = Math.trunc(rawValue);
  }
  return counts;
}

function sumRows(rows: ReportRow[], key: CountKey): number {
  return rows.reduce((total, row) => total + (row[key] ?? 0), 0);
}

function decodeFailuresForRow(row: ReportRow): number {
  return row.decode_fail ?? 0;
}

function formatBucket(value: string, bucket: "hour" | "day"): string {
  const date = new Date(value);
  const month = `${date.getUTCMonth() + 1}`.padStart(2, "0");
  const day = `${date.getUTCDate()}`.padStart(2, "0");
  if (bucket === "day") {
    return `${date.getUTCFullYear()}-${month}-${day}`;
  }
  const hour = `${date.getUTCHours()}`.padStart(2, "0");
  return `${date.getUTCFullYear()}-${month}-${day} ${hour}:00`;
}

function asTrimmedString(value: unknown, fieldName: string): string {
  if (typeof value !== "string" || value.trim().length === 0) {
    throw new Error(`${fieldName} must be a non-empty string.`);
  }
  return value.trim();
}

function asIsoString(value: unknown, fieldName: string): string {
  const stringValue = asTrimmedString(value, fieldName);
  if (Number.isNaN(Date.parse(stringValue))) {
    throw new Error(`${fieldName} must be a valid ISO-8601 timestamp.`);
  }
  return new Date(stringValue).toISOString();
}

function asNullableString(value: unknown): string | null {
  return typeof value === "string" && value.trim().length > 0
    ? value.trim()
    : null;
}

function asNullableNumber(value: unknown): number | null {
  if (typeof value === "number" && Number.isFinite(value)) {
    return value;
  }
  if (typeof value === "string" && value.trim().length > 0) {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : null;
  }
  return null;
}
