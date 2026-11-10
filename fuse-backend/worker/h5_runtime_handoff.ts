/**
 * Unified H5 runtime config & prelogin injector for the 2 universal H5 bundles
 * (`7.1.8-autologin` and `7.2.3-autologin`).
 *
 * `dev` and `release` share the exact same 2 H5 static bundles:
 * - When `pkg === "xycoins.2027.test"` (or no formal package is requested), the Worker
 *   injects the fixed `dev` test environment config + test Mill prelogin cookie.
 * - When `pkg === "<formal_pkg>"` (or matched by formal `device_parameter` / `device_id`
 *   in shared D1 `fuse_h5_app_configs` / `fuse_h5_device_handoffs`), the Worker injects
 *   that package's formal `release` environment config + formal Mill prelogin cookie.
 */

import { millHintsForActivity } from "./activity_entry";
import { reportableDeviceId } from "./device_id";
import { fetchMillPreloginSession, type MillPreloginSession, type MillRiskFace } from "./mill_risk";
import {
  buildPreloginSetCookies,
  derivePreloginSpec,
  preloginCacheKey,
  recallPrelogin,
  type PreloginSlots,
  type PreloginSpec,
} from "./prelogin_cipher";
import { warmPreloginSession } from "./prelogin_handoff";

export async function sealPreloginBundleNative(
  spec: PreloginSpec,
  payload: {
    deviceId: string;
    token: string;
    isFirstRegister?: boolean;
    user: Record<string, unknown>;
    config: Record<string, unknown>;
    strategy: Record<string, unknown>;
    issuedAt?: number;
  },
  pkg: string,
): Promise<string> {
  const slots = spec.slots;
  const plain = JSON.stringify({
    [slots.device_id]: payload.deviceId,
    [slots.token]: payload.token,
    [slots.first_reg]: Boolean(payload.isFirstRegister),
    [slots.user]: payload.user,
    [slots.config]: payload.config,
    [slots.strategy]: payload.strategy,
    [slots.issued_at]: payload.issuedAt ?? 0,
  });
  const cs = new CompressionStream("deflate-raw");
  const compressedBuf = await new Response(
    new Blob([new TextEncoder().encode(plain)]).stream().pipeThrough(cs),
  ).arrayBuffer();
  const keyBytes = Buffer.from(spec.seal_key_hex, "hex");
  const iv = crypto.getRandomValues(new Uint8Array(12));
  const cryptoKey = await crypto.subtle.importKey(
    "raw",
    keyBytes,
    { name: "AES-GCM" },
    false,
    ["encrypt"],
  );
  const encryptedBuf = await crypto.subtle.encrypt(
    {
      name: "AES-GCM",
      iv,
      additionalData: new TextEncoder().encode(pkg),
    },
    cryptoKey,
    compressedBuf,
  );
  return `${Buffer.from(iv).toString("base64url")}.${Buffer.from(encryptedBuf).toString("base64url")}`;
}

export interface HandoffD1 {
  prepare(query: string): {
    bind(...values: unknown[]): {
      first<T = Record<string, unknown>>(): Promise<T | null>;
      run(): Promise<unknown>;
    };
  };
}

const PAGE_PROTOCOL_SCHEMA = "appfactory.page_protocol.v1";
const PAGE_PROTOCOL_FIELDS = [
  "page_host",
  "present_param",
  "present_host_value",
  "present_cover_value",
  "url_param",
  "doc_param",
  "browser_host",
] as const;
const PAGE_PROTOCOL_RESERVED = new Set([
  "page",
  "pop",
  "browser",
  "settings",
  "present",
  "url",
  "doc",
  "privacy",
  "terms",
  "support",
  "device",
  "device-id",
  "device_id",
  "pkg",
  "q",
  "p",
  "entry",
  "activity",
]);
const PAGE_WORD = /^[a-z][a-z0-9]{2,11}$/;

export type PageProtocolConfig = {
  schema: typeof PAGE_PROTOCOL_SCHEMA;
} & Record<(typeof PAGE_PROTOCOL_FIELDS)[number], string>;

/** Validate the seven package-specific protocol words. Missing block means legacy. */
export function normalizePageProtocol(raw: unknown): PageProtocolConfig | undefined {
  if (raw === undefined || raw === null) return undefined;
  if (typeof raw !== "object" || Array.isArray(raw)) {
    throw new Error("page_protocol_invalid:document");
  }
  const block = raw as Record<string, unknown>;
  if (block.schema !== undefined && block.schema !== PAGE_PROTOCOL_SCHEMA) {
    throw new Error("page_protocol_invalid:schema");
  }
  const seen = new Set<string>();
  const parsed = { schema: PAGE_PROTOCOL_SCHEMA } as PageProtocolConfig;
  for (const field of PAGE_PROTOCOL_FIELDS) {
    const value = block[field];
    if (typeof value !== "string" || !PAGE_WORD.test(value)) {
      throw new Error(`page_protocol_invalid:${field}`);
    }
    if (PAGE_PROTOCOL_RESERVED.has(value)) {
      throw new Error(`page_protocol_reserved:${value}`);
    }
    if (seen.has(value)) {
      throw new Error(`page_protocol_duplicate:${field}`);
    }
    seen.add(value);
    parsed[field] = value;
  }
  return parsed;
}

export type H5RuntimeConfig = {
  schema_version: "appfactory.h5_runtime_config.v1";
  pkg: string;
  package_name: string;
  app_version: string;
  ios_app_id?: string;
  base_url: string;
  log_url: string;
  socket_url: string;
  privacy_url?: string;
  terms_url?: string;
  local_scheme: string;
  primary_scheme: string;
  pop_host_mode: "pop" | "page";
  device_parameter: string;
  broadcaster_env: "prod" | "test";
  /** Present only when broadcaster_env=test; H5 robot/搭讪 uses these Mill test anchors. */
  test_broadcaster_ids_csv?: string;
  commerce_mode?: string;
  product_allowlist?: string;
  keys: [string, string, string, string];
  h5_version?: string;
  h5_build_version?: string;
  /** Package-specific page-protocol words. Absent on dev and pre-11.2.1 packages. */
  page_protocol?: PageProtocolConfig;
  page_protocol_sha256?: string;
  /** Which site serves the page: "release" (esf-release / invite release) or "dev" / "preview". H5 hides 退出登录 on release. */
  stage?: "dev" | "preview" | "release";
  prelogin?: {
    window_slot: string;
    slots: PreloginSlots;
  };
};

export const HANDOFF_SESSION_TTL_MS = 120_000;
/** Frozen TEST_BROADCASTER_IDS — test Mill only; never bake into release main.dart.js. */
export const TEST_BROADCASTER_IDS_CSV =
  "1960949128095727616,1960948945064689664,1960948770724249600,1960948449423785984,1960947740863234048";
const DEV_TEST_BROADCASTER_IDS_CSV = TEST_BROADCASTER_IDS_CSV;
const DEFAULT_DEV_DEVICE_ID = "88888888888848888888888888888888";
export const RELEASE_TEST_PACKAGE = "xycoins.2027.test";

/** Ledger display strings. `h5-deploy` rewrites these from `h5_build_versions.json`. */
export const H5_BUILD_DISPLAY: Record<string, string> = {
  "7.1.8-autologin": "718 build 0.0.17",
  "7.2.3-autologin": "723 build 0.0.20",
  "7.6.1-autologin": "761 build 0.0.18",
  "7.1.8-invite": "718-invite build 0.0.1",
  "7.2.3-invite": "723-invite build 0.0.1",
  "7.6.1-invite": "761-invite build 0.0.1",
};

function isInviteVersion(raw: string): boolean {
  return raw.includes("invite");
}

function displayFor(h5Version: string, buildId = ""): string {
  const raw = `${h5Version} ${buildId}`;
  // Match invite before 723/761 — `dev-723-invite` contains both markers.
  if (isInviteVersion(raw)) {
    if (raw.includes("761") || raw.includes("7.6.1")) return H5_BUILD_DISPLAY["7.6.1-invite"];
    if (raw.includes("723") || raw.includes("7.2.3")) return H5_BUILD_DISPLAY["7.2.3-invite"];
    return H5_BUILD_DISPLAY["7.1.8-invite"];
  }
  if (raw.includes("761") || raw.includes("7.6.1")) return H5_BUILD_DISPLAY["7.6.1-autologin"];
  if (raw.includes("723") || raw.includes("7.2.3")) return H5_BUILD_DISPLAY["7.2.3-autologin"];
  return H5_BUILD_DISPLAY["7.1.8-autologin"];
}

/** `0.0.20` from `.../activity/7.2.3-autologin/0.0.20/`. */
export function buildVersionFromActivityUrl(url: string): string {
  const match = /\/activity\/[^/]+\/(\d+\.\d+\.\d+)(?:\/|$)/.exec(String(url || ""));
  return match ? match[1] : "";
}

function parseBuild(value: unknown): [number, number, number] | null {
  const match = /(\d+)\.(\d+)\.(\d+)/.exec(String(value || ""));
  if (!match) return null;
  return [Number(match[1]), Number(match[2]), Number(match[3])];
}

export function compareBuildVersion(left: unknown, right: unknown): number {
  const a = parseBuild(left);
  const b = parseBuild(right);
  if (!a && !b) return 0;
  if (!a) return -1;
  if (!b) return 1;
  for (let index = 0; index < 3; index += 1) {
    if (a[index] !== b[index]) return a[index] < b[index] ? -1 : 1;
  }
  return 0;
}

function h5Line(h5Version: string, buildId = ""): string {
  const raw = `${h5Version} ${buildId}`;
  if (isInviteVersion(raw)) {
    if (is761Version(raw)) return "761-invite";
    if (is723Version(raw)) return "723-invite";
    return "718-invite";
  }
  if (is761Version(raw)) return "761";
  if (is723Version(raw)) return "723";
  return "718";
}

/** Canonical build label; choose one explicit source and never merge by highest. */
function displayForBuild(
  h5Version: string,
  buildId: string,
  candidate: unknown,
): string {
  const line = h5Line(h5Version, buildId);
  const parsed = parseBuild(candidate);
  if (parsed) {
    return `${line} build ${parsed.join(".")}`;
  }
  return displayFor(h5Version, buildId);
}

function is761Version(raw: string): boolean {
  return raw.includes("761") || raw.includes("7.6.1");
}

function is723Version(raw: string): boolean {
  return !is761Version(raw) && (raw.includes("723") || raw.includes("7.2.3"));
}

export type SharedDevBuildId =
  | "dev-718"
  | "dev-723"
  | "dev-761"
  | "dev-718-invite"
  | "dev-723-invite"
  | "dev-761-invite";

export function sharedDevBuildId(raw: string): SharedDevBuildId {
  if (isInviteVersion(raw)) {
    if (is761Version(raw)) return "dev-761-invite";
    if (is723Version(raw)) return "dev-723-invite";
    return "dev-718-invite";
  }
  if (is761Version(raw)) return "dev-761";
  if (is723Version(raw)) return "dev-723";
  return "dev-718";
}

const initializedDbs = new WeakSet<object>();

export async function ensureHandoffTables(db: HandoffD1): Promise<void> {
  if (initializedDbs.has(db as unknown as object)) return;
  await db
    .prepare(
      "CREATE TABLE IF NOT EXISTS fuse_h5_app_configs (pkg TEXT PRIMARY KEY, app_name TEXT NOT NULL, worker_name TEXT NOT NULL, h5_version TEXT NOT NULL, device_parameter TEXT NOT NULL, runtime_config_json TEXT NOT NULL, updated_at INTEGER NOT NULL)",
    )
    .bind()
    .run();
  await db
    .prepare(
      "CREATE INDEX IF NOT EXISTS idx_fuse_h5_app_configs_device_param ON fuse_h5_app_configs(device_parameter)",
    )
    .bind()
    .run();
  await db
    .prepare(
      "CREATE TABLE IF NOT EXISTS fuse_h5_device_handoffs (device_id TEXT PRIMARY KEY, pkg TEXT NOT NULL, h5_version TEXT NOT NULL, runtime_config_json TEXT NOT NULL, prelogin_session_json TEXT, session_expires_at INTEGER NOT NULL DEFAULT 0, updated_at INTEGER NOT NULL)",
    )
    .bind()
    .run();
  initializedDbs.add(db as unknown as object);
}

// The fixed dev protocol. Only the dev runtime (test package) uses it.
export const DEV_LOCAL_SCHEME = "xycoins-local";

// No configured scheme: the test package keeps the fixed dev protocol.
// A formal package does not invent `<segment>-local`; the bake supplies the domain scheme.
export function packageLocalScheme(pkg: string): string {
  const clean = pkg.trim();
  if (clean === RELEASE_TEST_PACKAGE || clean.startsWith(`${RELEASE_TEST_PACKAGE}.`)) return DEV_LOCAL_SCHEME;
  return "";
}

export function normalizeRuntimeConfig(
  raw: Record<string, unknown>,
  buildId = "dev-718",
  activityUrl = "",
): H5RuntimeConfig {
  const pkg = String(raw.pkg || raw.package_name || raw.package_code || "").trim();
  const packageName = String(raw.package_name || pkg).trim();
  const schemeRaw = String(raw.local_scheme || "").trim();
  const localScheme = schemeRaw || packageLocalScheme(pkg);
  const primaryScheme = String(raw.primary_scheme || localScheme).trim();
  const popHostMode = raw.pop_host_mode === "page" ? "page" : "pop";
  const pageProtocol = normalizePageProtocol(raw.page_protocol);
  const deviceParameter = String(raw.device_parameter || "device-id").trim() || "device-id";
  const baseUrl = String(raw.base_url || raw.api_host || "").trim();
  const logUrl = String(raw.log_url || baseUrl).trim();
  const socketUrl = String(raw.socket_url || baseUrl)
    .trim()
    .replace(/^wss:\/\//i, "https://");
  const rawKeys = Array.isArray(raw.keys) ? raw.keys.map((k) => String(k || "").trim()).filter(Boolean) : [];
  const keys: [string, string, string, string] =
    rawKeys.length === 4
      ? [rawKeys[0], rawKeys[1], rawKeys[2], rawKeys[3]]
      : ["Optimize", "Booster", "Fastclean", "Smartclean"];
  const h5Version = String(raw.h5_version || (
    isInviteVersion(buildId)
      ? is761Version(buildId)
        ? "7.6.1-invite"
        : is723Version(buildId)
          ? "7.2.3-invite"
          : "7.1.8-invite"
      : is761Version(buildId)
        ? "7.6.1-autologin"
        : is723Version(buildId)
          ? "7.2.3-autologin"
          : "7.1.8-autologin"
  )).trim();
  const activityBuild = buildVersionFromActivityUrl(
    activityUrl || String(raw.activity_url || raw.universal_activity_url || ""),
  );
  const canonicalBuild = String(raw.h5_build_version || "").trim();
  if (
    canonicalBuild &&
    activityBuild &&
    compareBuildVersion(canonicalBuild, activityBuild) !== 0
  ) {
    throw new Error("h5_build_version_drift");
  }
  const h5BuildVersion = displayForBuild(
    h5Version,
    buildId,
    canonicalBuild || activityBuild,
  );
  const spec = pkg ? derivePreloginSpec(pkg, buildId, keys) : null;
  const broadcasterEnv = raw.broadcaster_env === "test" ? "test" : "prod";
  const testCsv =
    broadcasterEnv === "test"
      ? String(raw.test_broadcaster_ids_csv || "").trim() || TEST_BROADCASTER_IDS_CSV
      : "";
  const config: H5RuntimeConfig = {
    schema_version: "appfactory.h5_runtime_config.v1",
    pkg,
    package_name: packageName,
    app_version: String(raw.app_version || "1.0.1").trim(),
    ios_app_id: String(raw.ios_app_id || "").trim(),
    base_url: baseUrl,
    log_url: logUrl,
    socket_url: socketUrl,
    privacy_url: String(raw.privacy_url || raw.privacy_policy || "").trim(),
    terms_url: String(raw.terms_url || raw.terms_conditions || "").trim(),
    local_scheme: localScheme,
    primary_scheme: primaryScheme,
    pop_host_mode: popHostMode,
    device_parameter: deviceParameter,
    broadcaster_env: broadcasterEnv,
    commerce_mode: String(raw.commerce_mode || "").trim(),
    product_allowlist: String(raw.product_allowlist || "").trim(),
    keys,
    h5_version: h5Version,
    h5_build_version: h5BuildVersion,
    ...(pageProtocol ? { page_protocol: pageProtocol } : {}),
    ...(pageProtocol && typeof raw.page_protocol_sha256 === "string"
      ? { page_protocol_sha256: raw.page_protocol_sha256 }
      : {}),
  };
  if (testCsv) {
    config.test_broadcaster_ids_csv = testCsv;
  }
  if (spec) {
    config.prelogin = {
      window_slot: spec.window_slot,
      slots: spec.slots,
    };
  }
  return config;
}

export function isTestReleaseRuntime(config: { pkg?: string; broadcaster_env?: string; base_url?: string } | null): boolean {
  if (!config) return false;
  const pkg = String(config.pkg || "").trim();
  if (pkg === RELEASE_TEST_PACKAGE || pkg.startsWith(`${RELEASE_TEST_PACKAGE}.`)) return true;
  if (config.broadcaster_env === "test") return true;
  return String(config.base_url || "").includes("test-app.dirth.quest");
}

/** Formal page for an unbound release visitor. No test Mill, no test broadcasters, no package mill. */
export function buildReleaseOpenConfig(buildId: SharedDevBuildId): H5RuntimeConfig {
  const config = normalizeRuntimeConfig(
    {
      pkg: "release.open",
      package_name: "release.open",
      app_version: "1.0.0",
      base_url: "",
      log_url: "",
      socket_url: "",
      local_scheme: "app-local",
      primary_scheme: "app-local",
      pop_host_mode: "pop",
      device_parameter: "device-id",
      broadcaster_env: "prod",
      keys: ["open-page", "open-page", "open-page", "open-page"],
      h5_version: isInviteVersion(buildId)
        ? buildId === "dev-761-invite"
          ? "7.6.1-invite"
          : buildId === "dev-723-invite"
            ? "7.2.3-invite"
            : "7.1.8-invite"
        : buildId === "dev-761"
          ? "7.6.1-autologin"
          : buildId === "dev-723"
            ? "7.2.3-autologin"
            : "7.1.8-autologin",
    },
    buildId,
  );
  delete config.test_broadcaster_ids_csv;
  return config;
}

export function buildDevRuntimeConfig(buildId: SharedDevBuildId): H5RuntimeConfig {
  return normalizeRuntimeConfig(
    {
      pkg: "xycoins.2027.test",
      package_name: "xycoins.2027.test",
      app_version: "1.0.1",
      ios_app_id: "6700000000",
      base_url: "https://test-app.dirth.quest",
      log_url: "https://test-log.dirth.quest",
      socket_url: "https://test-im.dirth.quest",
      privacy_url: "https://claydev.pages.dev/privacy/",
      terms_url: "https://claydev.pages.dev/terms/",
      local_scheme: DEV_LOCAL_SCHEME,
      primary_scheme: DEV_LOCAL_SCHEME,
      pop_host_mode: "pop",
      device_parameter: "device-id",
      broadcaster_env: "test",
      test_broadcaster_ids_csv: DEV_TEST_BROADCASTER_IDS_CSV,
      keys: ["Optimize", "Booster", "Fastclean", "Smartclean"],
      h5_version: isInviteVersion(buildId)
        ? buildId === "dev-761-invite"
          ? "7.6.1-invite"
          : buildId === "dev-723-invite"
            ? "7.2.3-invite"
            : "7.1.8-invite"
        : buildId === "dev-761"
          ? "7.6.1-autologin"
          : buildId === "dev-723"
            ? "7.2.3-autologin"
            : "7.1.8-autologin",
    },
    buildId,
  );
}

export async function upsertAppRuntimeConfig(
  db: HandoffD1,
  input: {
    pkg: string;
    appName?: string;
    workerName?: string;
    h5Version?: string;
    activityUrl?: string;
    runtimeConfig: Record<string, unknown> | H5RuntimeConfig;
  },
): Promise<H5RuntimeConfig> {
  await ensureHandoffTables(db);
  const h5Version = String(input.h5Version || (input.runtimeConfig as H5RuntimeConfig).h5_version || "7.1.8-autologin");
  const buildId = sharedDevBuildId(h5Version);
  const normalized = normalizeRuntimeConfig(
    { ...input.runtimeConfig, pkg: input.pkg, h5_version: h5Version },
    buildId,
    input.activityUrl,
  );
  const existing = await db
    .prepare("SELECT runtime_config_json FROM fuse_h5_app_configs WHERE pkg = ?")
    .bind(input.pkg)
    .first();
  const previousRaw = existing && typeof existing.runtime_config_json === "string"
    ? existing.runtime_config_json
    : "";
  if (previousRaw) {
    try {
      const previous = JSON.parse(previousRaw) as H5RuntimeConfig;
      const sameFamily = String(previous.h5_version || "") === normalized.h5_version;
      if (
        sameFamily &&
        compareBuildVersion(previous.h5_build_version, normalized.h5_build_version) > 0
      ) {
        throw new Error("h5_build_version_regression");
      }
    } catch (error) {
      if (error instanceof SyntaxError) {
        // A corrupt row must not block a fresh write.
      } else {
        throw error;
      }
    }
  }
  const now = Date.now();
  await db
    .prepare(
      "INSERT INTO fuse_h5_app_configs (pkg, app_name, worker_name, h5_version, device_parameter, runtime_config_json, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?) ON CONFLICT(pkg) DO UPDATE SET app_name = excluded.app_name, worker_name = excluded.worker_name, h5_version = excluded.h5_version, device_parameter = excluded.device_parameter, runtime_config_json = excluded.runtime_config_json, updated_at = excluded.updated_at",
    )
    .bind(
      normalized.pkg,
      String(input.appName || normalized.pkg),
      String(input.workerName || ""),
      h5Version,
      normalized.device_parameter,
      JSON.stringify(normalized),
      now,
    )
    .run();
  return normalized;
}

export async function writeDeviceHandoff(
  db: HandoffD1,
  input: {
    deviceId: string;
    pkg: string;
    appName?: string;
    workerName?: string;
    h5Version?: string;
    runtimeConfig: Record<string, unknown> | H5RuntimeConfig;
    preloginSession?: MillPreloginSession | null;
    ttlMs?: number;
  },
): Promise<void> {
  const cleanDevice = reportableDeviceId(input.deviceId);
  if (!cleanDevice || !input.pkg) return;
  const normalized = await upsertAppRuntimeConfig(db, {
    pkg: input.pkg,
    appName: input.appName,
    workerName: input.workerName,
    h5Version: input.h5Version,
    runtimeConfig: input.runtimeConfig,
  });
  const now = Date.now();
  const hasSession = Boolean(input.preloginSession?.loginData?.token);
  let sessionJson: string | null = null;
  if (hasSession && input.preloginSession) {
    const buildId = sharedDevBuildId(normalized.h5_version || "");
    const spec = derivePreloginSpec(normalized.pkg, buildId, normalized.keys);
    const login = input.preloginSession.loginData;
    const user = login.userInfo ?? login.user;
    const sealedBlob = await sealPreloginBundleNative(
      spec,
      {
        deviceId: input.preloginSession.deviceId || cleanDevice,
        token: String(login.token || ""),
        isFirstRegister: Boolean(login.isFirstRegister),
        user: user && typeof user === "object" && !Array.isArray(user) ? (user as Record<string, unknown>) : {},
        config: input.preloginSession.appConfig,
        strategy: input.preloginSession.strategy,
        issuedAt: 0,
      },
      normalized.pkg,
    ).catch(() => "");
    sessionJson = JSON.stringify({
      ...input.preloginSession,
      sealed_blob: sealedBlob,
    });
  }
  const expiresAt = hasSession ? now + (input.ttlMs ?? HANDOFF_SESSION_TTL_MS) : 0;
  await db
    .prepare(
      "INSERT INTO fuse_h5_device_handoffs (device_id, pkg, h5_version, runtime_config_json, prelogin_session_json, session_expires_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?) ON CONFLICT(device_id) DO UPDATE SET pkg = excluded.pkg, h5_version = excluded.h5_version, runtime_config_json = excluded.runtime_config_json, prelogin_session_json = COALESCE(excluded.prelogin_session_json, fuse_h5_device_handoffs.prelogin_session_json), session_expires_at = CASE WHEN excluded.prelogin_session_json IS NOT NULL THEN excluded.session_expires_at ELSE fuse_h5_device_handoffs.session_expires_at END, updated_at = excluded.updated_at",
    )
    .bind(
      cleanDevice,
      normalized.pkg,
      normalized.h5_version || "7.1.8-autologin",
      JSON.stringify(normalized),
      sessionJson,
      expiresAt,
      now,
    )
    .run();
}

function readCookie(request: Request, name: string): string {
  const raw = request.headers.get("cookie") || "";
  for (const part of raw.split(";")) {
    const trimmed = part.trim();
    if (trimmed.startsWith(`${name}=`)) {
      return trimmed.slice(name.length + 1).trim();
    }
  }
  return "";
}

export function releaseIndexErrorCode(input: {
  pkg: string;
  deviceId: string;
  customDeviceParam: string;
  runtime: { base_url?: string; pkg?: string } | null;
}): string {
  const pkg = input.pkg.trim();
  const hasDevice = Boolean(input.deviceId.trim() || input.customDeviceParam.trim());
  if (pkg === RELEASE_TEST_PACKAGE || pkg.startsWith(`${RELEASE_TEST_PACKAGE}.`)) {
    return "release_package_unrecognized";
  }
  if (!pkg && !hasDevice) return "release_identity_missing";
  if (!input.runtime) return "release_package_unrecognized";
  const runtimePkg = String(input.runtime.pkg || "").trim();
  if (runtimePkg === RELEASE_TEST_PACKAGE || runtimePkg.startsWith(`${RELEASE_TEST_PACKAGE}.`)) {
    return "release_package_unrecognized";
  }
  // A formal row with no origin is not an error for the index any more: the
  // page opens on the formal open config (see serveSharedH5Bundle).
  return "";
}

export async function fingerprintReturnedAsset(body: string): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(body));
  return Array.from(new Uint8Array(digest), (byte) => byte.toString(16).padStart(2, "0")).join("").slice(0, 32);
}

export function extractReleaseRequestIdentity(request: Request): {
  deviceId: string;
  pkg: string;
  customDeviceParam: string;
} {
  const url = new URL(request.url);
  const pkg = (url.searchParams.get("pkg") || url.searchParams.get("packageName") || "").trim();
  let deviceId = "";
  let customDeviceParam = "";

  for (const [key, value] of url.searchParams.entries()) {
    const cleanVal = reportableDeviceId(value.trim());
    if (!cleanVal) continue;
    if (key === "device-id" || key === "device") {
      if (!deviceId) deviceId = cleanVal;
    } else if (key.endsWith("_device")) {
      deviceId = cleanVal;
      customDeviceParam = key;
      break;
    }
  }
  if (!deviceId) {
    const fromHeader = reportableDeviceId(request.headers.get("device-id") || "");
    const fromCookie = reportableDeviceId(readCookie(request, "esf_last_device"));
    deviceId = fromHeader || fromCookie || "";
  }
  return { deviceId, pkg, customDeviceParam };
}

export function buildPreloginBootstrapScript(spec: PreloginSpec, pkg: string): string {
  const safePkg = pkg.replace(/\\/g, "").replace(/'/g, "");
  return (
    "<script>(function(){" +
    `var n='${spec.cookie_name}',slot='${spec.window_slot}',pkg='${safePkg}',keyHex='${spec.seal_key_hex}';` +
    "function take(name){var all=document.cookie?document.cookie.split(';'):[];" +
    "for(var i=0;i<all.length;i++){var p=all[i].trim();if(p.indexOf(name+'=')===0)return p.slice(name.length+1);}return '';}" +
    "function burn(name){var path=location.pathname.replace(/index\\.html$/,'');" +
    "if(path.slice(-1)!=='/')path+='/';" +
    "var sec=location.protocol==='https:'?'; Secure':'';" +
    "document.cookie=name+'=; Max-Age=0; Path='+path+'; SameSite=Strict'+sec;}" +
    "var blob=take(n);for(var i=1;i<8;i++){var c=take(n+'_'+i);if(!c)break;blob+=c;}" +
    "burn(n);for(var j=1;j<8;j++)burn(n+'_'+j);" +
    "function b64(s){s=s.replace(/-/g,'+').replace(/_/g,'/');while(s.length%4)s+='=';" +
    "var bin=atob(s),out=new Uint8Array(bin.length);for(var k=0;k<bin.length;k++)out[k]=bin.charCodeAt(k);return out;}" +
    "function hex(s){var out=new Uint8Array(s.length/2);for(var i=0;i<out.length;i++)out[i]=parseInt(s.substr(i*2,2),16);return out;}" +
    "window[slot]=blob?crypto.subtle.importKey('raw',hex(keyHex),{name:'AES-GCM'},false,['decrypt']).then(function(key){" +
    "var parts=blob.split('.');" +
    "return crypto.subtle.decrypt({name:'AES-GCM',iv:b64(parts[0]),additionalData:new TextEncoder().encode(pkg)},key,b64(parts[1]));" +
    "}).then(function(buf){var ds=new DecompressionStream('deflate-raw');" +
    "return new Response(new Blob([buf]).stream().pipeThrough(ds)).text();" +
    "}).catch(function(){return null;}):Promise.resolve(null);" +
    "})();</script>"
  );
}

export function injectRuntimeIntoIndexHtml(
  html: string,
  runtimeConfig: H5RuntimeConfig,
  buildId: string,
): { html: string; spec: PreloginSpec } {
  const spec = derivePreloginSpec(runtimeConfig.pkg, buildId, runtimeConfig.keys);
  const enriched: H5RuntimeConfig = {
    ...runtimeConfig,
    prelogin: {
      window_slot: spec.window_slot,
      slots: spec.slots,
    },
  };
  const scheme = enriched.local_scheme.replace(/'/g, "");
  const primary = enriched.primary_scheme.replace(/'/g, "");
  const pop = enriched.pop_host_mode === "page" ? "page" : "pop";
  const devParam = enriched.device_parameter.replace(/'/g, "");
  const buildVer = (enriched.h5_build_version || "").replace(/'/g, "");
  const pageProtocol = enriched.page_protocol;
  const pageProtocolJson = pageProtocol ? JSON.stringify(pageProtocol) : "";
  const pageProtocolHash = pageProtocol
    ? String(enriched.page_protocol_sha256 || "").replace(/'/g, "")
    : "";
  const runtimeJson = JSON.stringify(enriched);
  const injectedBlock =
    "<script>" +
    `window.__FUSE_RUNTIME_CONFIG__=${runtimeJson};` +
    `window.__FUSE_H5_BUILD_VERSION__='${buildVer}';` +
    `window.__FUSE_LOCAL_SCHEME__='${scheme}';` +
    `window.__FUSE_PRIMARY_SCHEME__='${primary}';` +
    `window.__FUSE_POP_HOST_MODE__='${pop}';` +
    `window.__FUSE_DEVICE_PARAM__='${devParam}';` +
    (pageProtocol
      ? `window.__FUSE_PAGE_PROTOCOL__=${pageProtocolJson};` +
        `window.__FUSE_PAGE_PROTOCOL_HASH__='${pageProtocolHash}';`
      : "") +
    "(function(){var o=window.open;if(!o||o.__fuseLegal)return;" +
    "function rewrite(u){var c=window.__FUSE_RUNTIME_CONFIG__||{};var m=String(u||'').match(/^[a-z][a-z0-9+.-]*:\\/\\/page\\?doc=(privacy|terms|support)(?:$|&)/i);if(!m)return u;var d=m[1].toLowerCase();var n=String((d==='privacy'?c.privacy_url:d==='terms'?c.terms_url:c.support_url)||'');if(/^[a-z][a-z0-9+.-]*:\\/\\//i.test(n)&&n.indexOf('http://')!==0&&n.indexOf('https://')!==0)return n;return u;}" +
    "function page(u){var p=window.__FUSE_PAGE_PROTOCOL__;if(!p)return u;var m=String(u||'').match(/^([a-z][a-z0-9+.-]*):\\/\\/([^\\/?#]+)(\\?[^#]*)?(#.*)?$/i);if(!m)return u;" +
    "var s=m[1].toLowerCase(),h=m[2].toLowerCase(),q=m[3]||'',f=m[4]||'';if(h===p.page_host)return u;if(h!=='page'&&h!=='pop'&&h!=='browser')return u;" +
    "var src=new URLSearchParams(q.charAt(0)==='?'?q.slice(1):q),out=new URLSearchParams();" +
    "if(h==='browser'){var t=src.get('url');if(!t)return u;out.set(p.url_param,t);return s+'://'+p.browser_host+'?'+out.toString()+f;}" +
    "var pr=src.get('present'),uv=src.get('url'),dv=src.get('doc');" +
    "if(pr&&pr!=='host'&&pr!=='cover')return u;if(uv&&dv)return u;if(!uv&&!dv)return u;" +
    "out.set(p.present_param,pr==='host'?p.present_host_value:p.present_cover_value);" +
    "if(uv)out.set(p.url_param,uv);else out.set(p.doc_param,dv);" +
    "src.forEach(function(v,k){if(k!=='present'&&k!=='url'&&k!=='doc'&&k!=='close')out.set(k,v);});" +
    "return s+'://'+p.page_host+'?'+out.toString()+f;}" +
    "function wrapped(u,t,f){return o.call(this,page(rewrite(u)),t,f);}wrapped.__fuseLegal=1;wrapped.__fuseProtocol=1;window.open=wrapped;})();" +
    "</script>" +
    buildPreloginBootstrapScript(spec, enriched.pkg);

  const normalizedHtml = html
    .replace(/#24180F/gi, "#1C192C")
    .replace(
      /<div id="app_splash" aria-busy="true">\s*<img class="startup-silhouette"[^>]*>\s*<\/div>/g,
      '<div id="app_splash" aria-busy="true"></div>',
    )
    .replace(/setTimeout\(dismissAppSplash,\s*8000\)/g, "dismissAppSplash()");

  if (normalizedHtml.includes("<!--__FUSE_RUNTIME_HEAD__-->")) {
    return {
      html: normalizedHtml.replace("<!--__FUSE_RUNTIME_HEAD__-->", injectedBlock),
      spec,
    };
  }
  const headIdx = normalizedHtml.indexOf("<head>");
  if (headIdx < 0) {
    return { html: injectedBlock + normalizedHtml, spec };
  }
  const afterHead = headIdx + "<head>".length;
  const commentIdx = normalizedHtml.indexOf("<!--", afterHead);
  const baseIdx = normalizedHtml.indexOf("<base ", afterHead);
  const cutIdx =
    commentIdx >= 0 && (baseIdx < 0 || commentIdx < baseIdx)
      ? commentIdx
      : baseIdx >= 0
        ? baseIdx
        : afterHead;
  const existingPrefix = normalizedHtml.slice(afterHead, cutIdx);
  const cleanedAfterHead = existingPrefix.includes("__FUSE_") ? cutIdx : afterHead;
  return {
    html: normalizedHtml.slice(0, afterHead) + "\n" + injectedBlock + normalizedHtml.slice(cleanedAfterHead),
    spec,
  };
}

export async function serveSharedH5Bundle(
  request: Request,
  assets: { fetch(req: Request): Promise<Response> } | undefined,
  db: HandoffD1 | undefined,
  options: {
    buildId?: SharedDevBuildId;
    is723?: boolean;
    publicPrefix: string;
    /** Immutable release copies are served from their own version directory. */
    assetPrefix?: string;
    /** esf-release passes "release" and does not fall back to the test Mill. */
    siteMode?: "dev" | "release";
    fetchImpl?: typeof fetch;
  },
): Promise<Response> {
  if (!assets) {
    return new Response("activity_assets_unbound", { status: 503 });
  }
  const url = new URL(request.url);
  const buildId = options.buildId ?? (options.is723 ? "dev-723" : "dev-718");
  const physicalPrefix = options.assetPrefix
    ? options.assetPrefix.endsWith("/")
      ? options.assetPrefix
      : `${options.assetPrefix}/`
    : `/activity/xycoins.2027.test/${buildId}/`;
  const publicPrefix = options.publicPrefix.endsWith("/")
    ? options.publicPrefix
    : `${options.publicPrefix}/`;

  if (url.pathname === publicPrefix.slice(0, -1)) {
    return Response.redirect(`${url.origin}${publicPrefix}${url.search}`, 308);
  }

  const relPath = url.pathname.startsWith(publicPrefix)
    ? url.pathname.slice(publicPrefix.length)
    : "";
  const isIndex = relPath === "" || relPath === "index.html";

  // Map any alias prefix (e.g. /activity/release-718/...) to the single physical H5 asset directory
  const assetUrl = new URL(request.url);
  assetUrl.pathname = `${physicalPrefix}${relPath}`;
  assetUrl.search = "";
  const assetReq = new Request(assetUrl.toString(), {
    method: request.method,
    headers: request.headers,
  });

  const upstream = await assets.fetch(assetReq);
  if (!isIndex || !upstream.ok) {
    const headers = new Headers(upstream.headers);
    if (upstream.ok && !headers.has("cache-control")) {
      headers.set("cache-control", "public, max-age=31536000, immutable");
    }
    return new Response(upstream.body, {
      status: upstream.status,
      statusText: upstream.statusText,
      headers,
    });
  }

  const { deviceId, pkg, customDeviceParam } = extractReleaseRequestIdentity(request);
  const effectiveDeviceId = deviceId || DEFAULT_DEV_DEVICE_ID;
  const requestIsTestPkg =
    pkg === RELEASE_TEST_PACKAGE || pkg.startsWith(`${RELEASE_TEST_PACKAGE}.`);
  // Dev trees keep the test Mill. Release never does, even for xycoins.2027.test.
  const forceDev =
    options.siteMode !== "release" &&
    (requestIsTestPkg || publicPrefix.includes("/activity/xycoins.2027.test/"));

  let runtimeConfig: H5RuntimeConfig | null = null;
  let preloginSession: MillPreloginSession | null = null;

  if (!forceDev && db) {
    try {
      await ensureHandoffTables(db);
      // 1. Explicit formal package name in ?pkg=<formal_pkg>
      if (pkg && !requestIsTestPkg) {
        const appRow = await db
          .prepare("SELECT runtime_config_json FROM fuse_h5_app_configs WHERE pkg = ?")
          .bind(pkg)
          .first<{ runtime_config_json: string }>();
        if (appRow?.runtime_config_json) {
          const parsed = normalizeRuntimeConfig(
            JSON.parse(appRow.runtime_config_json) as Record<string, unknown>,
            buildId,
          );
          if (options.siteMode !== "release" || !isTestReleaseRuntime(parsed)) {
            runtimeConfig = parsed;
          }
        }
      }
      // 2. Match by package-specific device parameter (e.g. ?emberyar_device=... or ?pitchlan_device=...)
      if (!runtimeConfig && customDeviceParam) {
        const paramRow = await db
          .prepare("SELECT runtime_config_json FROM fuse_h5_app_configs WHERE device_parameter = ?")
          .bind(customDeviceParam)
          .first<{ runtime_config_json: string }>();
        if (paramRow?.runtime_config_json) {
          const parsed = normalizeRuntimeConfig(
            JSON.parse(paramRow.runtime_config_json) as Record<string, unknown>,
            buildId,
          );
          if (options.siteMode !== "release" || !isTestReleaseRuntime(parsed)) {
            runtimeConfig = parsed;
          }
        }
      }
      // 3. Check device handoff row (for prelogin session or device-bound formal package)
      if (deviceId) {
        const handoffRow = await db
          .prepare(
            "SELECT pkg, h5_version, runtime_config_json, prelogin_session_json, session_expires_at FROM fuse_h5_device_handoffs WHERE device_id = ?",
          )
          .bind(deviceId)
          .first<{
            pkg: string;
            h5_version: string;
            runtime_config_json: string;
            prelogin_session_json: string | null;
            session_expires_at: number;
          }>();
        if (handoffRow?.runtime_config_json) {
          const fromDevice = normalizeRuntimeConfig(
            JSON.parse(handoffRow.runtime_config_json) as Record<string, unknown>,
            buildId,
          );
          if (!runtimeConfig && !isTestReleaseRuntime(fromDevice)) {
            runtimeConfig = fromDevice;
          }
          if (
            runtimeConfig &&
            fromDevice.pkg === runtimeConfig.pkg &&
            handoffRow.prelogin_session_json &&
            Number(handoffRow.session_expires_at) > Date.now()
          ) {
            preloginSession = JSON.parse(handoffRow.prelogin_session_json) as MillPreloginSession;
          }
        }
      }
      // 4. If formal runtimeConfig matched but prelogin session expired/missing, sign against formal Mill
      if (runtimeConfig && !preloginSession?.loginData?.token && runtimeConfig.base_url) {
        const face: MillRiskFace = {
          baseUrl: runtimeConfig.base_url,
          packageName: runtimeConfig.pkg,
          keys: runtimeConfig.keys,
        };
        const refreshed = await fetchMillPreloginSession(
          face,
          effectiveDeviceId,
          options.fetchImpl ?? fetch,
          millHintsForActivity(request, runtimeConfig.app_version),
        ).catch(() => null);
        if (refreshed?.loginData?.token) {
          preloginSession = refreshed;
          await writeDeviceHandoff(db, {
            deviceId: effectiveDeviceId,
            pkg: runtimeConfig.pkg,
            h5Version: runtimeConfig.h5_version,
            runtimeConfig,
            preloginSession: refreshed,
          }).catch(() => undefined);
        }
      }
    } catch (error) {
      // A bad protocol block must not silently downgrade to the dev config.
      if (String((error as Error)?.message || "").startsWith("page_protocol_")) throw error;
      /* fallback to dev config if D1 query fails */
    }
  }

  // esf-dev still injects the test Mill. esf-release does not.
  // Any device opens the page: an unbound device, a missing device-id or
  // bundle id, the test package name, or a formal row with no origin all get
  // 200 on the formal open config. Device registration in D1 is not a gate.
  // Prelogin and handoff writes run only for a real formal config with an
  // origin, so opening the page does not grant a Mill session.
  if (options.siteMode === "release") {
    if (isTestReleaseRuntime(runtimeConfig)) {
      runtimeConfig = null;
      preloginSession = null;
    }
    if (runtimeConfig && !String(runtimeConfig.base_url || "").trim()) {
      runtimeConfig = null;
      preloginSession = null;
    }
    if (!runtimeConfig) {
      runtimeConfig = buildReleaseOpenConfig(buildId);
      preloginSession = null;
    }
  }
  if (!runtimeConfig) {
    runtimeConfig = buildDevRuntimeConfig(buildId);
    const cacheKey = preloginCacheKey(runtimeConfig.pkg, effectiveDeviceId, runtimeConfig.app_version);
    if (!recallPrelogin(cacheKey)) {
      const face: MillRiskFace = {
        baseUrl: runtimeConfig.base_url,
        packageName: runtimeConfig.pkg,
        keys: runtimeConfig.keys,
      };
      await warmPreloginSession({
        businessPkg: runtimeConfig.pkg,
        deviceId: effectiveDeviceId,
        appVersion: runtimeConfig.app_version,
        face,
        hints: millHintsForActivity(request, runtimeConfig.app_version),
        fetchImpl: options.fetchImpl,
      }).catch(() => false);
    }
    preloginSession = recallPrelogin(cacheKey)?.session ?? null;
  }

  const rawHtml = await upstream.text();
  // 告诉 H5 当前是正式站还是测试站；正式站隐藏退出登录按钮。
  runtimeConfig = { ...runtimeConfig, stage: options.siteMode === "release" ? "release" : "dev" };
  const { html: injectedHtml, spec } = injectRuntimeIntoIndexHtml(
    rawHtml,
    runtimeConfig,
    buildId,
  );
  const headers = new Headers({
    "content-type": "text/html; charset=utf-8",
    "cache-control": "private, no-store",
    "x-fuse-h5-build": await fingerprintReturnedAsset(rawHtml),
  });
  if (effectiveDeviceId) {
    headers.append(
      "set-cookie",
      `esf_last_device=${effectiveDeviceId}; Path=${publicPrefix}; Max-Age=86400; SameSite=Strict; Secure`,
    );
  }
  if (preloginSession?.loginData?.token) {
    const login = preloginSession.loginData;
    const user = login.userInfo ?? login.user;
    const blob = await sealPreloginBundleNative(
      spec,
      {
        deviceId: preloginSession.deviceId || effectiveDeviceId,
        token: String(login.token || ""),
        isFirstRegister: Boolean(login.isFirstRegister),
        user: user && typeof user === "object" && !Array.isArray(user) ? (user as Record<string, unknown>) : {},
        config: preloginSession.appConfig,
        strategy: preloginSession.strategy,
        issuedAt: 0,
      },
      runtimeConfig.pkg,
    ).catch(() => "");
    if (blob) {
      for (const cookieLine of buildPreloginSetCookies(spec.cookie_name, blob, publicPrefix)) {
        headers.append("set-cookie", cookieLine);
      }
    }
  }

  return new Response(injectedHtml, {
    status: 200,
    headers,
  });
}

// Backward-compatible alias
export const serveUniversalReleaseActivity = (
  request: Request,
  assets: { fetch(req: Request): Promise<Response> } | undefined,
  db: HandoffD1 | undefined,
  options: { buildId: "release-718" | "release-723" | "release-761"; fetchImpl?: typeof fetch },
): Promise<Response> =>
  serveSharedH5Bundle(request, assets, db, {
    buildId: sharedDevBuildId(options.buildId),
    publicPrefix: `/activity/${options.buildId}/`,
    fetchImpl: options.fetchImpl,
  });
