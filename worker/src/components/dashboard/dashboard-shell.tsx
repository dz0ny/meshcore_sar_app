import { useEffect, useMemo, useState } from "react";

import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";

type WindowKey = "24h" | "7d";

type PacketTypeEntry = {
  key: string;
  label: string;
  total: number;
};

type PathModeEntry = {
  key: string;
  label: string;
  total: number;
};

type ReporterSummary = {
  key6: string;
  lastSeen: string;
  packetTotal: number;
  country: string;
  city: string;
  latitude: number | null;
  longitude: number | null;
};

type ChartPoint = {
  label: string;
  totalPackets: number;
  reports: number;
};

type AppVersionEntry = {
  version: string;
  reporters: number;
  packets: number;
};

type TrafficComposition = {
  human: number;
  overhead: number;
  acks: number;
};

type MultiHopRatio = {
  direct: number;
  multiHop: number;
};

type CompositionPoint = {
  label: string;
  human: number;
  overhead: number;
};

type DashboardResponse = {
  generatedAt: string;
  filter: {
    windowKey: WindowKey;
    label: string;
    sinceIso: string;
    bucket: "hour" | "day";
  };
  reportCount: number;
  uniqueDevices: number;
  decodedPackets: number;
  decodeFailures: number;
  packetTypeTotals: PacketTypeEntry[];
  pathModeTotals: PathModeEntry[];
  recentReporters: ReporterSummary[];
  chartPoints: ChartPoint[];
  appVersions: AppVersionEntry[];
  trafficComposition: TrafficComposition;
  multiHopRatio: MultiHopRatio;
  compositionOverTime: CompositionPoint[];
};

const WINDOW_OPTIONS: Array<{ key: WindowKey; label: string }> = [
  { key: "24h", label: "24h" },
  { key: "7d", label: "7 days" },
];

const PACKET_TYPE_INFO: Record<string, { title: string; summary: string }> = {
  pt_00: { title: "FLOOD REQUEST", summary: "Encrypted request to a known peer" },
  pt_01: { title: "FLOOD RESPONSE", summary: "Encrypted reply to a request" },
  pt_02: { title: "FLOOD TEXT", summary: "Encrypted direct text with timestamp and retry flags" },
  pt_03: { title: "FLOOD ACK", summary: "4-byte acknowledgement for an earlier message" },
  pt_04: { title: "FLOOD ADVERTISEMENT", summary: "Signed node identity broadcast" },
  pt_05: { title: "FLOOD GROUP_TEXT", summary: "Encrypted channel text matched by channel hash" },
  pt_06: { title: "FLOOD GROUP_DATA", summary: "Encrypted channel data with type and length" },
  pt_07: { title: "FLOOD ANON_REQUEST", summary: "Request using an ephemeral sender key" },
  pt_08: { title: "FLOOD RETURNED_PATH", summary: "Return route back to sender, with optional bundled ACK" },
  pt_09: { title: "FLOOD TRACE_PATH", summary: "Direct trace that records SNR at each hop" },
  pt_0a: { title: "FLOOD MULTIPART", summary: "Wrapper for one packet in a multipart sequence" },
  pt_0b: { title: "FLOOD CONTROL", summary: "Discovery or other control data" },
  pt_0c: { title: "RESERVED 0x0C", summary: "Reserved protocol type" },
  pt_0d: { title: "RESERVED 0x0D", summary: "Reserved protocol type" },
  pt_0e: { title: "RESERVED 0x0E", summary: "Reserved protocol type" },
  pt_0f: { title: "RAW CUSTOM", summary: "Application-defined custom packet" },
};

const PATH_MODE_ICONS: Record<string, string> = {
  path_mode_1b: "1B",
  path_mode_2b: "2B",
  path_mode_3b: "3B",
  path_mode_none: "--",
  path_mode_unknown: "??",
};

export function DashboardShell() {
  const [windowKey, setWindowKey] = useState<WindowKey>("24h");
  const [summary, setSummary] = useState<DashboardResponse | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let isCancelled = false;

    async function load() {
      setIsLoading(true);
      setError(null);
      try {
        const response = await fetch(`/api/dashboard?window=${windowKey}`, {
          headers: { accept: "application/json" },
        });
        if (!response.ok) {
          throw new Error(`Dashboard request failed (${response.status})`);
        }
        const nextSummary = (await response.json()) as DashboardResponse;
        if (!isCancelled) setSummary(nextSummary);
      } catch (nextError) {
        if (!isCancelled) {
          setError(nextError instanceof Error ? nextError.message : String(nextError));
        }
      } finally {
        if (!isCancelled) setIsLoading(false);
      }
    }

    void load();
    return () => { isCancelled = true; };
  }, [windowKey]);

  const activePacketTypes = useMemo(
    () => (summary?.packetTypeTotals ?? []).filter((e) => e.total > 0),
    [summary],
  );
  const activePathModes = useMemo(
    () => (summary?.pathModeTotals ?? []).filter((e) => e.total > 0),
    [summary],
  );
  const totalPackets = useMemo(
    () => (summary ? summary.decodedPackets + summary.decodeFailures : 0),
    [summary],
  );
  const decodeRate = totalPackets > 0
    ? ((summary!.decodedPackets / totalPackets) * 100).toFixed(1)
    : "0";
  const maxTrend = Math.max(...(summary?.chartPoints ?? []).map((p) => p.totalPackets), 1);
  const multiHopTotal = (summary?.multiHopRatio.direct ?? 0) + (summary?.multiHopRatio.multiHop ?? 0);
  const multiHopPct = multiHopTotal > 0
    ? ((summary!.multiHopRatio.multiHop / multiHopTotal) * 100).toFixed(1)
    : "0";
  const comp = summary?.trafficComposition;
  const compTotal = comp ? comp.human + comp.overhead + comp.acks : 0;
  const humanPct = compTotal > 0 ? ((comp!.human / compTotal) * 100).toFixed(1) : "0";
  const nodeCount = summary?.uniqueDevices ?? 0;
  const avgPerNode = nodeCount > 0 ? Math.round(totalPackets / nodeCount) : 0;

  return (
    <div className="mx-auto max-w-[1320px] px-5 py-8">
      <Tabs value={windowKey} onValueChange={(v) => setWindowKey(v as WindowKey)}>
        {/* Header */}
        <header className="mb-8 flex flex-wrap items-end justify-between gap-4">
          <div className="space-y-2">
            <div className="flex items-center gap-2.5">
              <img src="/favicon.png" alt="MeshCore SAR" className="h-8 w-8 rounded-lg" />
              <h1 className="text-2xl font-semibold tracking-tight">MeshCore SAR</h1>
            </div>
            <p className="max-w-xl text-sm text-muted-foreground">
              Aggregated observations from opt-in mesh nodes. Counts reflect what reporting nodes observed, not unique network packets.
              Ratios and percentages are statistically valid; absolute numbers scale with reporter count.
            </p>
          </div>
          <div className="flex items-center gap-3">
            <TabsList className="h-9 rounded-full bg-secondary/60 p-1">
              {WINDOW_OPTIONS.map((o) => (
                <TabsTrigger key={o.key} value={o.key} className="rounded-full px-4 text-xs">
                  {o.label}
                </TabsTrigger>
              ))}
            </TabsList>
            {summary && (
              <span className="text-xs text-muted-foreground">
                Updated {formatRelative(summary.generatedAt)}
              </span>
            )}
          </div>
        </header>

        {error && (
          <div className="mb-6 flex items-center gap-3 rounded-2xl border border-destructive/20 bg-destructive/10 px-5 py-3 text-sm text-destructive">
            <span className="flex-1">{error}</span>
            <Button size="sm" variant="outline" onClick={() => setWindowKey((c) => c)}>Retry</Button>
          </div>
        )}

        <TabsContent value={windowKey} className="space-y-6">
          {/* Key metrics */}
          <section className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6">
            <MetricCard
              label="Reporting Nodes"
              value={nodeCount}
              note="Opt-in nodes in this window"
            />
            <MetricCard
              label="Avg / Node"
              value={avgPerNode}
              note={`${totalPackets.toLocaleString()} total obs.`}
            />
            <MetricCard
              label="Decode Rate"
              value={`${decodeRate}%`}
              note={`${summary?.decodeFailures ?? 0} failed`}
            />
            <MetricCard
              label="Multi-Hop"
              value={`${multiHopPct}%`}
              note="Relayed through mesh"
            />
            <MetricCard
              label="Messages"
              value={`${humanPct}%`}
              note="Text + group text"
            />
            <MetricCard
              label="Protocol Types"
              value={activePacketTypes.length}
              note="of 16 types observed"
            />
          </section>

          {/* Traffic breakdown */}
          <section className="space-y-4">
            <Card>
              <CardHeader>
                <CardTitle>Traffic Breakdown</CardTitle>
                <CardDescription>Observed traffic composition across all reporting nodes</CardDescription>
              </CardHeader>
              <CardContent className="space-y-5">
                {comp && compTotal > 0 ? (
                  <>
                    <div className="flex h-6 overflow-hidden rounded-full">
                      <div className="bg-primary" style={{ width: `${(comp.human / compTotal) * 100}%` }} title={`Messages: ${comp.human}`} />
                      <div className="bg-amber-400" style={{ width: `${(comp.acks / compTotal) * 100}%` }} title={`Acks: ${comp.acks}`} />
                      <div className="bg-secondary" style={{ width: `${(comp.overhead / compTotal) * 100}%` }} title={`Overhead: ${comp.overhead}`} />
                    </div>
                    <div className="grid grid-cols-3 gap-3 text-center">
                      <div>
                        <div className="mx-auto mb-1 h-2.5 w-2.5 rounded-full bg-primary" />
                        <div className="text-lg font-semibold tabular-nums">{comp.human.toLocaleString()}</div>
                        <div className="text-xs text-muted-foreground">Messages</div>
                      </div>
                      <div>
                        <div className="mx-auto mb-1 h-2.5 w-2.5 rounded-full bg-amber-400" />
                        <div className="text-lg font-semibold tabular-nums">{comp.acks.toLocaleString()}</div>
                        <div className="text-xs text-muted-foreground">Acks</div>
                      </div>
                      <div>
                        <div className="mx-auto mb-1 h-2.5 w-2.5 rounded-full bg-secondary" />
                        <div className="text-lg font-semibold tabular-nums">{comp.overhead.toLocaleString()}</div>
                        <div className="text-xs text-muted-foreground">Overhead</div>
                      </div>
                    </div>
                  </>
                ) : (
                  <EmptyState label="No traffic data yet." />
                )}
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>Messages vs Protocol Overhead</CardTitle>
                <CardDescription>
                  Human messages (text + group text) compared to protocol overhead (acks, advertisements, routing, control) over time.
                </CardDescription>
              </CardHeader>
              <CardContent>
                {summary?.compositionOverTime.length ? (
                  <CompositionChart points={summary.compositionOverTime} />
                ) : (
                  <EmptyState label="No composition data yet." />
                )}
              </CardContent>
            </Card>
          </section>

          {/* Protocol breakdown */}
          <section className="space-y-4">
            <Card>
              <CardHeader>
                <CardTitle>Protocol Packet Types</CardTitle>
                <CardDescription>
                  MeshCore protocol uses 16 packet type codes (0x00 - 0x0F).
                  Showing types with traffic in this window.
                </CardDescription>
              </CardHeader>
              <CardContent>
                {activePacketTypes.length ? (
                  <div className="grid gap-2 sm:grid-cols-2">
                    {activePacketTypes.map((entry) => {
                      const pct = totalPackets > 0 ? ((entry.total / totalPackets) * 100).toFixed(1) : "0";
                      const info = PACKET_TYPE_INFO[entry.key];
                      return (
                        <div key={entry.key} className="flex gap-3 rounded-xl border border-border/50 bg-secondary/30 p-3">
                          <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-primary/10 text-xs font-mono font-semibold text-primary">
                            {entry.key.replace("pt_", "0x").toUpperCase()}
                          </div>
                          <div className="min-w-0 flex-1">
                            <div className="flex items-baseline justify-between gap-2">
                              <span className="text-sm font-medium">{entry.label}</span>
                              <span className="shrink-0 text-xs text-muted-foreground">{pct}%</span>
                            </div>
                            <div className="mt-0.5 font-mono text-[0.65rem] text-muted-foreground/70">
                              {info?.title ?? entry.key}
                            </div>
                            <p className="mt-0.5 text-xs text-muted-foreground">
                              {info?.summary ?? ""}
                            </p>
                            <div className="mt-1.5 flex items-center gap-2">
                              <div className="h-1.5 flex-1 overflow-hidden rounded-full bg-secondary">
                                <div
                                  className="h-full rounded-full bg-primary/70"
                                  style={{ width: `${pct}%` }}
                                />
                              </div>
                              <span className="text-xs font-semibold tabular-nums">{entry.total.toLocaleString()} obs.</span>
                            </div>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                ) : (
                  <EmptyState label="No packet data yet." />
                )}
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>Path Routing Modes</CardTitle>
                <CardDescription>
                  Path hash byte length determines routing precision.
                  Longer hashes allow more specific multi-hop paths.
                </CardDescription>
              </CardHeader>
              <CardContent>
                {activePathModes.length ? (
                  <div className="grid grid-cols-2 gap-3 sm:grid-cols-5">
                    {activePathModes.map((entry) => {
                      const pct = totalPackets > 0 ? ((entry.total / totalPackets) * 100).toFixed(1) : "0";
                      return (
                        <div key={entry.key} className="rounded-xl border border-border/50 bg-secondary/30 p-4 text-center">
                          <div className="mx-auto mb-2 flex h-10 w-10 items-center justify-center rounded-full bg-primary/10 text-sm font-bold text-primary">
                            {PATH_MODE_ICONS[entry.key] ?? "?"}
                          </div>
                          <div className="text-lg font-semibold tabular-nums">{entry.total.toLocaleString()}</div>
                          <div className="mt-0.5 text-xs text-muted-foreground">{entry.label}</div>
                          <div className="mt-1 text-xs text-muted-foreground">{pct}%</div>
                        </div>
                      );
                    })}
                  </div>
                ) : (
                  <EmptyState label="No path mode samples." />
                )}
              </CardContent>
            </Card>
          </section>

          {/* Map + Traffic trend */}
          <section className="space-y-4">
            <Card>
              <CardHeader>
                <CardTitle>Observations Over Time</CardTitle>
                <CardDescription>
                  Per-node average observations per {summary?.filter.bucket ?? "time"} bucket.
                  Normalizing by reporter count removes the bias of more nodes = higher numbers.
                </CardDescription>
              </CardHeader>
              <CardContent>
                {isLoading && !summary ? (
                  <EmptyState label="Loading..." />
                ) : summary?.chartPoints.length ? (
                  <TrafficChart points={summary.chartPoints} maxValue={maxTrend} />
                ) : (
                  <EmptyState label="No data for this window." />
                )}
              </CardContent>
            </Card>
          </section>

          {/* App versions */}
          <section>
            <Card>
              <CardHeader>
                <CardTitle>App Versions</CardTitle>
                <CardDescription>Distribution of reporting app versions by node count and observations</CardDescription>
              </CardHeader>
              <CardContent>
                {summary?.appVersions.length ? (
                  <div className="space-y-3">
                    {summary.appVersions.map((entry) => {
                      const maxPkts = summary.appVersions[0].packets;
                      return (
                        <div key={entry.version} className="space-y-1.5">
                          <div className="flex items-baseline justify-between gap-3 text-sm">
                            <span className="font-mono font-medium">{entry.version}</span>
                            <span className="text-xs text-muted-foreground">
                              {entry.reporters} {entry.reporters === 1 ? "node" : "nodes"} / {entry.packets.toLocaleString()} obs.
                            </span>
                          </div>
                          <div className="h-2 overflow-hidden rounded-full bg-secondary">
                            <div
                              className="h-full rounded-full bg-primary/70"
                              style={{ width: `${(entry.packets / maxPkts) * 100}%` }}
                            />
                          </div>
                        </div>
                      );
                    })}
                  </div>
                ) : (
                  <EmptyState label="No version data yet." />
                )}
              </CardContent>
            </Card>
          </section>
        </TabsContent>
      </Tabs>
    </div>
  );
}

// --- Composition stacked area chart ---

const MIN_CHART_W = 320;
const COMPOSITION_CHART_H = 236;

function useResponsiveChartWidth(minWidth = MIN_CHART_W) {
  const [element, setElement] = useState<HTMLDivElement | null>(null);
  const [width, setWidth] = useState(minWidth);

  useEffect(() => {
    if (!element) return;

    const sync = () => setWidth(Math.max(element.clientWidth, minWidth));
    sync();

    if (typeof ResizeObserver === "undefined") return;

    const observer = new ResizeObserver(sync);
    observer.observe(element);

    return () => { observer.disconnect(); };
  }, [element, minWidth]);

  return { setElement, width };
}

function CompositionChart({ points }: { points: CompositionPoint[] }) {
  const [hover, setHover] = useState<number | null>(null);
  const { setElement, width } = useResponsiveChartWidth();
  const count = points.length;
  if (count === 0) return null;

  const maxVal = Math.max(...points.map((p) => p.human + p.overhead), 1);
  const pad = { top: 16, right: 16, bottom: 32, left: 48 };
  const innerW = Math.max(width - pad.left - pad.right, 240);
  const innerH = COMPOSITION_CHART_H - pad.top - pad.bottom;

  const xs = points.map((_, i) => i / Math.max(count - 1, 1));

  // stacked: overhead on bottom, human on top
  const overheadYs = points.map((p) => 1 - p.overhead / maxVal);
  const totalYs = points.map((p) => 1 - (p.overhead + p.human) / maxVal);

  const overheadArea = buildAreaPath(xs, overheadYs, innerW, innerH);
  const humanArea = buildStackedAreaPath(xs, totalYs, overheadYs, innerW, innerH);

  const labelStep = Math.max(1, Math.floor(count / 6));
  const gridLines = niceGridLines(maxVal, 3);

  return (
    <div ref={setElement} className="relative select-none">
      <svg
        viewBox={`${-pad.left} ${-pad.top} ${innerW + pad.left + pad.right} ${innerH + pad.top + pad.bottom}`}
        className="h-[236px] w-full"
        onMouseLeave={() => setHover(null)}
      >
        <defs>
          <linearGradient id="humanFill" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="hsl(var(--chart-primary))" stopOpacity={0.5} />
            <stop offset="100%" stopColor="hsl(var(--chart-primary))" stopOpacity={0.1} />
          </linearGradient>
          <linearGradient id="overheadFill" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="hsl(var(--chart-secondary))" stopOpacity={0.5} />
            <stop offset="100%" stopColor="hsl(var(--chart-secondary))" stopOpacity={0.1} />
          </linearGradient>
        </defs>

        {gridLines.map((val) => {
          const y = (1 - val / maxVal) * innerH;
          return (
            <g key={val}>
              <line x1={0} y1={y} x2={innerW} y2={y} stroke="hsl(var(--chart-grid))" strokeWidth={0.3} />
              <text x={-6} y={y} textAnchor="end" dominantBaseline="middle" fill="hsl(var(--chart-label))" fontSize={3.2} fontFamily="var(--font-sans)">
                {formatCompact(val)}
              </text>
            </g>
          );
        })}
        <line x1={0} y1={innerH} x2={innerW} y2={innerH} stroke="hsl(var(--chart-grid))" strokeWidth={0.4} />

        <path d={overheadArea} fill="url(#overheadFill)" />
        <path d={humanArea} fill="url(#humanFill)" />

        {/* X labels */}
        {points.map((p, i) => (i % labelStep === 0 || i === count - 1) ? (
          <text key={i} x={xs[i] * innerW} y={innerH + 10} textAnchor="middle" fill="hsl(var(--chart-label))" fontSize={2.8} fontFamily="var(--font-sans)">
            {p.label.slice(5)}
          </text>
        ) : null)}

        {/* hover zones */}
        {points.map((point, i) => (
          <rect
            key={point.label}
            x={xs[i] * innerW - innerW / count / 2}
            y={0}
            width={innerW / count}
            height={innerH}
            fill="transparent"
            onMouseEnter={() => setHover(i)}
          />
        ))}

        {hover !== null && (
          <line x1={xs[hover] * innerW} y1={0} x2={xs[hover] * innerW} y2={innerH} stroke="hsl(var(--chart-primary))" strokeWidth={0.3} strokeDasharray="1.5 1" />
        )}
      </svg>

      {hover !== null && (
        <div
          className="pointer-events-none absolute -top-2 z-10 -translate-x-1/2 rounded-lg border border-border/50 bg-card px-3 py-1.5 text-xs shadow-lg"
          style={{ left: `${(pad.left + xs[hover] * innerW) / (innerW + pad.left + pad.right) * 100}%` }}
        >
          <div className="font-semibold">{points[hover].label}</div>
          <div className="flex items-center gap-1.5"><span className="inline-block h-2 w-2 rounded-full bg-primary" /> Messages: {points[hover].human.toLocaleString()}</div>
          <div className="flex items-center gap-1.5"><span className="inline-block h-2 w-2 rounded-full bg-secondary" /> Overhead: {points[hover].overhead.toLocaleString()}</div>
        </div>
      )}

      <div className="mt-2 flex items-center justify-center gap-4 text-xs text-muted-foreground">
        <span className="flex items-center gap-1.5"><span className="inline-block h-2.5 w-2.5 rounded-full bg-primary/60" /> Messages</span>
        <span className="flex items-center gap-1.5"><span className="inline-block h-2.5 w-2.5 rounded-full bg-secondary/70" /> Overhead</span>
      </div>
    </div>
  );
}

function buildAreaPath(xs: number[], ys: number[], w: number, h: number): string {
  const line = xs.map((x, i) => `${i === 0 ? "M" : "L"}${x * w},${ys[i] * h}`).join(" ");
  return `${line} L${xs[xs.length - 1] * w},${h} L0,${h} Z`;
}

function buildStackedAreaPath(xs: number[], topYs: number[], bottomYs: number[], w: number, h: number): string {
  const top = xs.map((x, i) => `${i === 0 ? "M" : "L"}${x * w},${topYs[i] * h}`).join(" ");
  const bottom = [...xs].reverse().map((x, i) => `L${x * w},${bottomYs[xs.length - 1 - i] * h}`).join(" ");
  return `${top} ${bottom} Z`;
}

// --- Traffic trend chart ---

const CHART_H = 240;
const CHART_PAD = { top: 20, right: 16, bottom: 32, left: 48 };

function TrafficChart({ points, maxValue: _rawMax }: { points: ChartPoint[]; maxValue: number }) {
  const [hover, setHover] = useState<number | null>(null);
  const { setElement, width } = useResponsiveChartWidth();
  const count = points.length;
  if (count === 0) return null;

  // Normalize: per-node average per bucket
  const normalized = points.map((p) => ({
    ...p,
    perNode: p.reports > 0 ? Math.round(p.totalPackets / p.reports) : 0,
  }));
  const maxValue = Math.max(...normalized.map((p) => p.perNode), 1);

  const innerW = Math.max(width - CHART_PAD.left - CHART_PAD.right, 240);
  const innerH = CHART_H - CHART_PAD.top - CHART_PAD.bottom;

  const peakIdx = normalized.reduce((best, p, i) => (p.perNode > normalized[best].perNode ? i : best), 0);

  const gridLines = niceGridLines(maxValue, 4);

  const xs = normalized.map((_, i) => i / Math.max(count - 1, 1));
  const ys = normalized.map((p) => 1 - p.perNode / maxValue);

  const linePath = xs.map((x, i) => `${i === 0 ? "M" : "L"}${x * innerW},${ys[i] * innerH}`).join(" ");
  const areaPath = `${linePath} L${xs[xs.length - 1] * innerW},${innerH} L0,${innerH} Z`;

  // X-axis labels: show ~6 evenly spaced
  const labelStep = Math.max(1, Math.floor(count / 6));
  const xLabels = points
    .map((p, i) => ({ i, label: p.label.slice(5) }))
    .filter((_, i) => i % labelStep === 0 || i === count - 1);

  return (
    <div ref={setElement} className="relative select-none">
      <svg
        viewBox={`${-CHART_PAD.left} ${-CHART_PAD.top} ${innerW + CHART_PAD.left + CHART_PAD.right} ${CHART_H}`}
        className="h-[240px] w-full"
        onMouseLeave={() => setHover(null)}
      >
        <defs>
          <linearGradient id="areaFill" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="hsl(var(--chart-primary))" stopOpacity={0.35} />
            <stop offset="100%" stopColor="hsl(var(--chart-primary))" stopOpacity={0.03} />
          </linearGradient>
          <linearGradient id="lineStroke" x1="0" y1="0" x2="1" y2="0">
            <stop offset="0%" stopColor="hsl(var(--chart-primary-light))" />
            <stop offset="100%" stopColor="hsl(var(--chart-primary-dark))" />
          </linearGradient>
        </defs>

        {/* Y grid lines */}
        {gridLines.map((val) => {
          const y = (1 - val / maxValue) * innerH;
          return (
            <g key={val}>
              <line x1={0} y1={y} x2={innerW} y2={y} stroke="hsl(var(--chart-grid))" strokeWidth={0.3} />
              <text x={-6} y={y} textAnchor="end" dominantBaseline="middle" fill="hsl(var(--chart-label))" fontSize={3.2} fontFamily="var(--font-sans)">
                {formatCompact(val)}
              </text>
            </g>
          );
        })}

        {/* baseline */}
        <line x1={0} y1={innerH} x2={innerW} y2={innerH} stroke="hsl(var(--chart-grid))" strokeWidth={0.4} />

        {/* area fill */}
        <path d={areaPath} fill="url(#areaFill)" />

        {/* line */}
        <path d={linePath} fill="none" stroke="url(#lineStroke)" strokeWidth={0.7} strokeLinecap="round" strokeLinejoin="round" />

        {/* peak dot */}
        <circle
          cx={xs[peakIdx] * innerW}
          cy={ys[peakIdx] * innerH}
          r={1.5}
          fill="hsl(var(--chart-primary))"
          stroke="white"
          strokeWidth={0.6}
        />

        {/* peak label */}
        <text
          x={xs[peakIdx] * innerW}
          y={ys[peakIdx] * innerH - 4}
          textAnchor="middle"
          fill="hsl(var(--chart-primary-accent))"
          fontSize={3}
          fontWeight={600}
          fontFamily="var(--font-sans)"
        >
          {normalized[peakIdx].perNode.toLocaleString()}
        </text>

        {/* X-axis labels */}
        {xLabels.map(({ i, label }) => (
          <text
            key={i}
            x={xs[i] * innerW}
            y={innerH + 10}
            textAnchor="middle"
            fill="hsl(var(--chart-label))"
            fontSize={2.8}
            fontFamily="var(--font-sans)"
          >
            {label}
          </text>
        ))}

        {/* invisible hover zones */}
        {points.map((point, i) => {
          const sliceW = innerW / count;
          return (
            <rect
              key={point.label}
              x={xs[i] * innerW - sliceW / 2}
              y={0}
              width={sliceW}
              height={innerH}
              fill="transparent"
              onMouseEnter={() => setHover(i)}
            />
          );
        })}

        {/* hover indicator */}
        {hover !== null && (
          <>
            <line
              x1={xs[hover] * innerW}
              y1={0}
              x2={xs[hover] * innerW}
              y2={innerH}
              stroke="hsl(var(--chart-primary))"
              strokeWidth={0.3}
              strokeDasharray="1.5 1"
            />
            <circle
              cx={xs[hover] * innerW}
              cy={ys[hover] * innerH}
              r={1.2}
              fill="white"
              stroke="hsl(var(--chart-primary))"
              strokeWidth={0.6}
            />
          </>
        )}
      </svg>

      {/* hover tooltip */}
      {hover !== null && (
        <div
          className="pointer-events-none absolute -top-2 z-10 -translate-x-1/2 rounded-lg border border-border/50 bg-card px-3 py-1.5 text-xs shadow-lg"
          style={{
            left: `${(CHART_PAD.left + xs[hover] * innerW) / (innerW + CHART_PAD.left + CHART_PAD.right) * 100}%`,
          }}
        >
          <div className="font-semibold tabular-nums">{normalized[hover].perNode.toLocaleString()} avg/node</div>
          <div className="text-muted-foreground">{normalized[hover].totalPackets.toLocaleString()} total from {normalized[hover].reports} {normalized[hover].reports === 1 ? "node" : "nodes"}</div>
          <div className="text-muted-foreground">{normalized[hover].label}</div>
        </div>
      )}
    </div>
  );
}

function niceGridLines(max: number, count: number): number[] {
  if (max <= 0) return [0];
  const rough = max / count;
  const magnitude = 10 ** Math.floor(Math.log10(rough));
  const residual = rough / magnitude;
  const nice = residual <= 1.5 ? 1 : residual <= 3 ? 2 : residual <= 7 ? 5 : 10;
  const step = nice * magnitude;
  const lines: number[] = [];
  for (let v = step; v <= max; v += step) {
    lines.push(Math.round(v));
  }
  return lines;
}

function formatCompact(n: number): string {
  if (n >= 1_000_000) return `${(n / 1_000_000).toFixed(1)}M`;
  if (n >= 1_000) return `${(n / 1_000).toFixed(n >= 10_000 ? 0 : 1)}K`;
  return String(n);
}

function MetricCard({ label, value, note }: { label: string; value: number | string; note: string }) {
  return (
    <Card>
      <CardHeader className="gap-1.5">
        <CardDescription className="text-xs uppercase tracking-wider">{label}</CardDescription>
        <CardTitle className="text-3xl tabular-nums">{typeof value === "number" ? value.toLocaleString() : value}</CardTitle>
        <CardDescription>{note}</CardDescription>
      </CardHeader>
    </Card>
  );
}

function EmptyState({ label }: { label: string }) {
  return (
    <div className="rounded-2xl border border-dashed border-border bg-secondary/20 px-4 py-8 text-center text-sm text-muted-foreground">
      {label}
    </div>
  );
}

function formatRelative(value: string) {
  const diffMs = Date.now() - new Date(value).getTime();
  const diffMin = Math.floor(diffMs / 60000);
  if (diffMin < 1) return "just now";
  if (diffMin < 60) return `${diffMin}m ago`;
  const diffHr = Math.floor(diffMin / 60);
  if (diffHr < 24) return `${diffHr}h ago`;
  return `${Math.floor(diffHr / 24)}d ago`;
}
