import { useEffect, useMemo, useState } from "react";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";

type WindowKey = "24h" | "7d" | "30d";

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

type LocationPoint = {
  key6: string;
  city: string;
  country: string;
  latitude: number;
  longitude: number;
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
  locationPoints: LocationPoint[];
};

const WINDOW_OPTIONS: Array<{ key: WindowKey; label: string }> = [
  { key: "24h", label: "Last 24 hours" },
  { key: "7d", label: "Last 7 days" },
  { key: "30d", label: "Last 30 days" },
];

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
          headers: {
            accept: "application/json",
          },
        });
        if (!response.ok) {
          throw new Error(`Dashboard request failed (${response.status})`);
        }
        const nextSummary = (await response.json()) as DashboardResponse;
        if (!isCancelled) {
          setSummary(nextSummary);
        }
      } catch (nextError) {
        if (!isCancelled) {
          setError(
            nextError instanceof Error ? nextError.message : String(nextError),
          );
        }
      } finally {
        if (!isCancelled) {
          setIsLoading(false);
        }
      }
    }

    void load();

    return () => {
      isCancelled = true;
    };
  }, [windowKey]);

  const topPacketTypes = useMemo(
    () => (summary?.packetTypeTotals ?? []).filter((entry) => entry.total > 0).slice(0, 8),
    [summary],
  );
  const topPacketMix = useMemo(
    () => (summary?.packetTypeTotals ?? []).filter((entry) => entry.total > 0).slice(0, 6),
    [summary],
  );
  const activePathModes = useMemo(
    () => (summary?.pathModeTotals ?? []).filter((entry) => entry.total > 0),
    [summary],
  );
  const maxPacketMix = Math.max(...topPacketMix.map((entry) => entry.total), 1);
  const maxTrend = Math.max(...(summary?.chartPoints ?? []).map((point) => point.totalPackets), 1);

  return (
    <div className="mx-auto max-w-[1320px] px-5 py-8">
      <Tabs value={windowKey} onValueChange={(value) => setWindowKey(value as WindowKey)}>
        <section className="grid gap-5 lg:grid-cols-[1.8fr_1fr]">
          <Card className="overflow-hidden">
            <CardHeader className="space-y-4">
              <div className="flex flex-wrap items-center gap-3">
                <Badge variant="secondary" className="rounded-full px-3 py-1 text-[0.65rem] uppercase tracking-[0.18em]">
                  MeshCore SAR
                </Badge>
                <Badge variant="outline" className="bg-white/70">
                  Anonymous RX ingest
                </Badge>
              </div>
              <div className="space-y-3">
                <CardTitle className="max-w-[10ch] text-4xl leading-none md:text-6xl">
                  Anonymous RX traffic stats
                </CardTitle>
                <CardDescription className="max-w-3xl text-sm leading-6 md:text-base">
                  shadcn-based Cloudflare dashboard for RX live-traffic packet types and
                  path-hash modes. Location comes from Cloudflare ingress metadata, while
                  device identity is reduced to key6.
                </CardDescription>
              </div>
              <TabsList className="h-auto flex-wrap justify-start gap-1 rounded-[999px] bg-white/70 p-1">
                {WINDOW_OPTIONS.map((option) => (
                  <TabsTrigger key={option.key} value={option.key}>
                    {option.label}
                  </TabsTrigger>
                ))}
              </TabsList>
            </CardHeader>
          </Card>

          <Card className="justify-between">
            <CardHeader>
              <Badge variant="outline" className="w-fit bg-white/70">
                Current range
              </Badge>
              <CardTitle className="text-4xl">
                {summary?.filter.label ?? (isLoading ? "Loading…" : "Unavailable")}
              </CardTitle>
              <CardDescription className="leading-6">
                {summary
                  ? `Showing reports with window end after ${formatTimestamp(summary.filter.sinceIso)}. Generated ${formatTimestamp(summary.generatedAt)}.`
                  : isLoading
                    ? "Fetching dashboard data from D1."
                    : "The dashboard API did not return data."}
              </CardDescription>
            </CardHeader>
            {error ? (
              <CardContent>
                <div className="rounded-2xl border border-destructive/20 bg-destructive/10 px-4 py-3 text-sm text-destructive">
                  {error}
                </div>
                <div className="mt-4">
                  <Button onClick={() => setWindowKey((current) => current)}>Retry</Button>
                </div>
              </CardContent>
            ) : null}
          </Card>
        </section>

        <TabsContent value={windowKey} className="space-y-5">
          <section className="grid gap-5 md:grid-cols-2 xl:grid-cols-4">
            <MetricCard label="Reports" value={summary?.reportCount ?? 0} note="Accepted upload windows in this range." />
            <MetricCard label="Reporters" value={summary?.uniqueDevices ?? 0} note="Unique key6 reporters." />
            <MetricCard label="Decoded RX" value={summary?.decodedPackets ?? 0} note="Packets grouped by known payload type." />
            <MetricCard label="Decode Fail" value={summary?.decodeFailures ?? 0} note="Malformed or undecodable RX packets." />
          </section>

          <section className="grid gap-5 xl:grid-cols-[1.25fr_0.95fr]">
            <Card>
              <CardHeader>
                <CardTitle>Traffic trend</CardTitle>
                <CardDescription>Packets per reporting bucket.</CardDescription>
              </CardHeader>
              <CardContent>
                {isLoading && !summary ? (
                  <EmptyState label="Loading traffic trend…" />
                ) : summary?.chartPoints.length ? (
                  <div className="grid min-h-[220px] grid-cols-[repeat(auto-fit,minmax(32px,1fr))] items-end gap-2">
                    {summary.chartPoints.map((point) => {
                      const height = Math.max((point.totalPackets / maxTrend) * 180, 8);
                      return (
                        <div key={point.label} className="grid min-h-[220px] content-end gap-3">
                          <div className="text-center text-xs font-semibold">
                            {point.totalPackets}
                          </div>
                          <div
                            className="rounded-[14px_14px_8px_8px] bg-gradient-to-b from-sky-600 to-teal-600"
                            style={{ height }}
                          />
                          <div className="text-center text-[0.7rem] text-muted-foreground">
                            {point.label.slice(5)}
                          </div>
                        </div>
                      );
                    })}
                  </div>
                ) : (
                  <EmptyState label="No data yet for this window." />
                )}
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>Path mode distribution</CardTitle>
                <CardDescription>1-byte, 2-byte, 3-byte, none, and unknown path hashes.</CardDescription>
              </CardHeader>
              <CardContent>
                {activePathModes.length ? (
                  <div className="flex flex-wrap gap-3">
                    {activePathModes.map((entry) => (
                      <Badge
                        key={entry.key}
                        variant="outline"
                        className="rounded-2xl bg-white/70 px-4 py-3 text-left"
                      >
                        <span className="block text-lg font-semibold">{entry.total}</span>
                        <span className="text-xs text-muted-foreground">{entry.label}</span>
                      </Badge>
                    ))}
                  </div>
                ) : (
                  <EmptyState label="No path mode samples yet." />
                )}
              </CardContent>
            </Card>
          </section>

          <section className="grid gap-5 xl:grid-cols-[1.25fr_0.95fr]">
            <Card>
              <CardHeader>
                <CardTitle>Top packet types</CardTitle>
                <CardDescription>Top fixed columns aggregated from D1.</CardDescription>
              </CardHeader>
              <CardContent>
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Label</TableHead>
                      <TableHead>Column</TableHead>
                      <TableHead className="text-right">Total</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {topPacketTypes.length ? (
                      topPacketTypes.map((entry) => (
                        <TableRow key={entry.key}>
                          <TableCell>{entry.label}</TableCell>
                          <TableCell>
                            <code>{entry.key}</code>
                          </TableCell>
                          <TableCell className="text-right font-semibold">
                            {entry.total}
                          </TableCell>
                        </TableRow>
                      ))
                    ) : (
                      <TableRow>
                        <TableCell colSpan={3} className="text-center text-muted-foreground">
                          No packet data yet.
                        </TableCell>
                      </TableRow>
                    )}
                  </TableBody>
                </Table>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>Recent reporters</CardTitle>
                <CardDescription>Latest key6 reporters with Cloudflare ingress geo.</CardDescription>
              </CardHeader>
              <CardContent>
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>key6</TableHead>
                      <TableHead>City</TableHead>
                      <TableHead>Country</TableHead>
                      <TableHead className="text-right">Packets</TableHead>
                      <TableHead className="text-right">Last seen</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {summary?.recentReporters.length ? (
                      summary.recentReporters.map((reporter) => (
                        <TableRow key={`${reporter.key6}-${reporter.lastSeen}`}>
                          <TableCell>
                            <code>{reporter.key6}</code>
                          </TableCell>
                          <TableCell>{reporter.city}</TableCell>
                          <TableCell>{reporter.country}</TableCell>
                          <TableCell className="text-right font-semibold">
                            {reporter.packetTotal}
                          </TableCell>
                          <TableCell className="text-right text-muted-foreground">
                            {formatTimestamp(reporter.lastSeen)}
                          </TableCell>
                        </TableRow>
                      ))
                    ) : (
                      <TableRow>
                        <TableCell colSpan={5} className="text-center text-muted-foreground">
                          No reporter activity yet.
                        </TableCell>
                      </TableRow>
                    )}
                  </TableBody>
                </Table>
              </CardContent>
            </Card>
          </section>

          <section className="grid gap-5 xl:grid-cols-[1.25fr_0.95fr]">
            <Card>
              <CardHeader>
                <CardTitle>Cloudflare geo map</CardTitle>
                <CardDescription>
                  Dots reflect Cloudflare ingress latitude and longitude, not device GPS coordinates.
                </CardDescription>
              </CardHeader>
              <CardContent>
                <div className="relative min-h-[320px] overflow-hidden rounded-[1.25rem] border border-white/10 bg-[radial-gradient(circle_at_25%_35%,rgba(255,255,255,0.14),transparent_16%),radial-gradient(circle_at_72%_48%,rgba(255,255,255,0.12),transparent_18%),linear-gradient(180deg,#10263d_0%,#173858_100%)]">
                  <div className="absolute inset-[18%_auto_auto_8%] h-[22%] w-[26%] rounded-full bg-white/10 blur-[1px]" />
                  <div className="absolute inset-[20%_auto_auto_38%] h-[18%] w-[20%] rounded-full bg-white/10 blur-[1px]" />
                  <div className="absolute inset-[30%_10%_auto_auto] h-[26%] w-[26%] rounded-full bg-white/10 blur-[1px]" />
                  <div className="absolute inset-[auto_auto_12%_34%] h-[20%] w-[18%] rounded-full bg-white/10 blur-[1px]" />
                  {(summary?.locationPoints ?? []).map((point) => (
                    <div
                      key={`${point.key6}-${point.latitude}-${point.longitude}`}
                      className="absolute h-3 w-3 -translate-x-1/2 -translate-y-1/2 rounded-full border-2 border-white bg-orange-400 shadow-[0_0_0_8px_rgba(255,143,60,0.16)]"
                      style={{
                        left: `${((point.longitude + 180) / 360) * 100}%`,
                        top: `${((90 - point.latitude) / 180) * 100}%`,
                      }}
                      title={`${point.key6} · ${point.city}, ${point.country}`}
                    />
                  ))}
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>Packet type mix</CardTitle>
                <CardDescription>Top packet types as share of the busiest series.</CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                {topPacketMix.length ? (
                  topPacketMix.map((entry) => (
                    <div key={entry.key} className="space-y-2">
                      <div className="flex items-center justify-between gap-3 text-sm">
                        <span>{entry.label}</span>
                        <span className="font-semibold">{entry.total}</span>
                      </div>
                      <div className="h-3 overflow-hidden rounded-full bg-secondary">
                        <div
                          className="h-full rounded-full bg-gradient-to-r from-sky-600 to-teal-600"
                          style={{ width: `${(entry.total / maxPacketMix) * 100}%` }}
                        />
                      </div>
                    </div>
                  ))
                ) : (
                  <EmptyState label="No packet mix data yet." />
                )}
              </CardContent>
            </Card>
          </section>
        </TabsContent>
      </Tabs>
    </div>
  );
}

function MetricCard({
  label,
  value,
  note,
}: {
  label: string;
  value: number;
  note: string;
}) {
  return (
    <Card>
      <CardHeader className="gap-3">
        <Badge variant="outline" className="w-fit bg-white/70">
          {label}
        </Badge>
        <CardTitle className="text-4xl">{value}</CardTitle>
        <CardDescription>{note}</CardDescription>
      </CardHeader>
    </Card>
  );
}

function EmptyState({ label }: { label: string }) {
  return (
    <div className="rounded-2xl border border-dashed border-border bg-white/55 px-4 py-6 text-sm text-muted-foreground">
      {label}
    </div>
  );
}

function formatTimestamp(value: string) {
  const date = new Date(value);
  const month = `${date.getUTCMonth() + 1}`.padStart(2, "0");
  const day = `${date.getUTCDate()}`.padStart(2, "0");
  const hour = `${date.getUTCHours()}`.padStart(2, "0");
  const minute = `${date.getUTCMinutes()}`.padStart(2, "0");
  return `${date.getUTCFullYear()}-${month}-${day} ${hour}:${minute} UTC`;
}
