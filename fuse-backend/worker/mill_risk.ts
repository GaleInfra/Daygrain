/**
 * Ask the mill whether this visitor may receive the activity page.
 * A review strategy, or any failed call, withholds the page.
 */

import { createHash, createHmac, randomUUID } from "node:crypto";
import { millRiskInfoSeal, open, seal } from "./codec";
import { reportableDeviceId } from "./device_id";
import { millForwardedFor, millOpen, millSeal } from "./mill_appconfig";

const APP_CONFIG = "/config/getAppConfigPostV2";
const OAUTH = "/security/oauth";
const STRATEGY = "/config/getStrategyPostV2";
export const DEFAULT_MILL_GATEWAY_URL = "https://release.q-fero.com/mill/v1/evaluate";

export type MillRiskFace = {
  baseUrl: string;
  packageName: string;
  keys: readonly [string, string, string, string];
  gatewayUrl?: string;
  gatewaySecret?: string;
  gatewayBinding?: { fetch(request: Request): Promise<Response> };
};

/** Locale + client IPv4 for mill http_headers / outbound X-Forwarded-For. */
export type MillRiskHints = {
  lang?: string;
  country?: string;
  timeZone?: string;
  /** Trusted ingress public IPv4 or IPv6; missing IP stays closed. */
  clientIp?: string;
  /** This package's APP_VERSION. Mill ver / platform_ver are not literals. */
  appVersion?: string;
  /** Device family derived from User-Agent ("iPad" | "iPhone"). */
  model?: string;
  asn?: number;
  asOrganization?: string;
  tlsVersion?: string;
  userAgent?: string;
  surface?: "query" | "activity";
};

/** ver and platform_ver both come from the Worker env, never a hardcoded release string. */
export function millRiskVersions(env: { APP_VERSION?: string }): { ver: string; platform_ver: string } {
  const ver = env.APP_VERSION || "";
  const platform_ver = env.APP_VERSION || "";
  return { ver, platform_ver };
}

/**
 * Parse CFNetwork Accept-Language (e.g. "en-US,en;q=0.9") into mill lang/country.
 * No client body change required — URLSession already sends this header.
 */
export function localeFromAcceptLanguage(header: string | null | undefined): {
  lang: string;
  country: string;
} {
  const primary = String(header || "")
    .split(",")[0]
    ?.trim()
    .split(";")[0]
    ?.trim() || "";
  const parts = primary.split("-").filter(Boolean);
  const lang = (parts[0] || "en").replace(/[^A-Za-z]/g, "").slice(0, 8).toLowerCase() || "en";
  let country = "";
  const last = parts[parts.length - 1] || "";
  if (parts.length >= 2 && /^[A-Za-z]{2}$/.test(last)) {
    country = last.toUpperCase();
  } else if (parts.length >= 2 && /^[A-Za-z]{2}$/.test(parts[1] || "")) {
    country = parts[1].toUpperCase();
  }
  return { lang, country };
}

/** Same shape as H5 public-headers so mill does not treat the visitor as abnormal. */
export function millRiskHttpHeaders(
  visitor: string,
  packageName: string,
  hints: MillRiskHints = {},
): string {
  const lang = String(hints.lang || "en").trim().toLowerCase() || "en";
  const country = String(hints.country || "").trim().toUpperCase();
  const deviceId = reportableDeviceId(visitor);
  const versions = millRiskVersions({ APP_VERSION: hints.appVersion });
  const model = hints.model === "iPad" ? "iPad" : "iPhone";
  const row: Record<string, string> = {
    ver: versions.ver,
    model,
    lang,
    sys_lan: lang,
    is_anchor: "false",
    pkg: packageName,
    platform: "iOS",
    device_lang: lang,
    device_country: country,
    time_zone: String(hints.timeZone || "").trim(),
    platform_ver: versions.platform_ver,
    "utm-source": "",
    sec_ver: "0",
  };
  if (deviceId) row["device-id"] = deviceId;
  const ip = millForwardedFor(String(hints.clientIp || ""));
  if (ip) {
    row.client_ip = ip;
    row["x-forword-ip"] = ip;
    row["x-forwarded-for"] = ip;
    row["cf-connecting-ip"] = ip;
  }
  return JSON.stringify(row);
}

export function extractMillRiskFactor(appConfig: Record<string, unknown> | null | undefined): string {
  if (!appConfig || typeof appConfig !== "object" || Array.isArray(appConfig)) return "";
  const cfg = appConfig.riskControlInfoConfig;
  if (!cfg || typeof cfg !== "object" || Array.isArray(cfg)) return "";
  const row = cfg as Record<string, unknown>;
  if (typeof row.k_factor === "string" && row.k_factor) return row.k_factor;
  if (typeof row.kFactor === "string" && row.kFactor) return row.kFactor;
  return "";
}

/** 10-field base risk info matching 7.1.8 H5 RiskUtil.infoEncrypt(null, true) on Web. */
export function buildMillOAuthRiskInfo(
  appConfig: Record<string, unknown> | null | undefined,
  visitor: string,
  packageName: string,
  hints: MillRiskHints = {},
): string {
  const kFactor = extractMillRiskFactor(appConfig);
  const id = reportableDeviceId(visitor);
  if (!kFactor || !id || !packageName) return "";
  const versions = millRiskVersions({ APP_VERSION: hints.appVersion });
  const lang = String(hints.lang || "en").trim().toLowerCase() || "en";
  const country = String(hints.country || "").trim().toUpperCase();
  const model = hints.model === "iPad" ? "iPad" : "iPhone";
  const timeZone = String(hints.timeZone || "").trim();
  const payload: Record<string, string | number> = {
    platform: "iOS",
    pkg: packageName,
    ver: versions.ver,
    platform_ver: versions.platform_ver,
    model,
    device_id: id,
    is_enable_vpn: 0,
    is_enable_proxy: 0,
    // "ja-" is not a language tag. Without a country the primary language alone
    // is still truthful.
    system_language: country ? `${lang}-${country}` : lang,
  };
  // A missing Cloudflare timezone is not evidence; omit the key so the H5 risk
  // upload can report the device's real zone instead of an empty string.
  if (timeZone) payload.time_zone = timeZone;
  return millRiskInfoSeal(JSON.stringify(payload), kFactor);
}

/** Outbound mill fetch headers: single public IP so leftmost XFF hop is the client.
 * `x-forword-ip` is the field name the mill reads. */
export function millOutboundIpHeaders(hints: MillRiskHints = {}): Record<string, string> {
  const ip = millForwardedFor(String(hints.clientIp || ""));
  if (!ip) return {};
  return {
    "CF-Connecting-IP": ip,
    "X-Forwarded-For": ip,
    "X-Real-IP": ip,
    "x-forword-ip": ip,
  };
}

function b64utf8(value: string): string {
  try {
    return Buffer.from(value, "base64").toString("utf8");
  } catch {
    return "";
  }
}

function keySize(key: string): 16 | 24 | 32 | 0 {
  const n = Buffer.byteLength(key);
  if (n === 16 || n === 24 || n === 32) return n;
  return 0;
}

async function postCipher(
  mill: string,
  path: string,
  cipher: string,
  headers: Record<string, string>,
  fetchImpl: typeof fetch,
): Promise<string> {
  const url = mill.replace(/\/$/, "") + path;
  const init: RequestInit = {
    method: "POST",
    headers: { "content-type": "application/json", ...headers },
    body: cipher,
  };
  for (let attempt = 0; attempt < 2; attempt++) {
    try {
      const res = await fetchImpl(url, init);
      if (res.ok) return (await res.text()).replace(/[\r\n]/g, "");
    } catch {
      // retry once on network / fetch failure
    }
  }
  return "";
}

function decodeConfigData(plain: string, keys: MillRiskFace["keys"]): {
  transport: string;
  appConfig: Record<string, unknown>;
} {
  let parsed: unknown;
  try {
    parsed = JSON.parse(plain);
  } catch {
    return { transport: "", appConfig: {} };
  }
  if (!parsed || typeof parsed !== "object") return { transport: "", appConfig: {} };
  const data = (parsed as { data?: unknown }).data;
  if (!data || typeof data !== "object" || Array.isArray(data)) return { transport: "", appConfig: {} };
  const row = data as Record<string, unknown>;
  const part2 = typeof row[keys[1]] === "string" ? b64utf8(row[keys[1]] as string).replace(/[\r\n]/g, "") : "";
  const part3 = typeof row[keys[2]] === "string" ? b64utf8(row[keys[2]] as string).replace(/[\r\n]/g, "") : "";
  const body = typeof row[keys[3]] === "string" ? b64utf8(row[keys[3]] as string).replace(/[\r\n]/g, "") : "";
  const dynamic = part2 + part3;
  const size = keySize(dynamic);
  if (!body || !size) return { transport: "", appConfig: {} };
  const decoded = open(body, dynamic, size);
  if (!decoded) return { transport: "", appConfig: {} };
  try {
    const inner = JSON.parse(decoded) as unknown;
    if (!inner || typeof inner !== "object" || Array.isArray(inner)) return { transport: "", appConfig: {} };
    const appConfig = inner as Record<string, unknown>;
    const items = Array.isArray(appConfig.items) ? appConfig.items as { name?: string; data?: unknown }[] : [];
    const found = items.find((item) => item?.name === "encrypt_key");
    return {
      transport: typeof found?.data === "string" ? found.data : "",
      appConfig,
    };
  } catch {
    return { transport: "", appConfig: {} };
  }
}

function encryptKeyFromConfig(plain: string, keys: MillRiskFace["keys"]): string {
  return decodeConfigData(plain, keys).transport;
}

function codeData(plain: string | null): Record<string, unknown> | null {
  if (!plain) return null;
  try {
    const parsed = JSON.parse(plain) as { code?: unknown; data?: unknown };
    if (parsed.code !== 0 || !parsed.data || typeof parsed.data !== "object") return null;
    return parsed.data as Record<string, unknown>;
  } catch {
    return null;
  }
}

function millEnvelope(plain: string | null): {
  code: number | null;
  data: Record<string, unknown> | null;
  msg: string;
} {
  if (!plain) return { code: null, data: null, msg: "" };
  try {
    const parsed = JSON.parse(plain) as { code?: unknown; data?: unknown; msg?: unknown; message?: unknown };
    const code = typeof parsed.code === "number" && Number.isFinite(parsed.code) ? parsed.code : null;
    const data =
      parsed.data && typeof parsed.data === "object" && !Array.isArray(parsed.data)
        ? (parsed.data as Record<string, unknown>)
        : null;
    const msg = typeof parsed.msg === "string"
      ? parsed.msg
      : typeof parsed.message === "string"
        ? parsed.message
        : "";
    return { code, data, msg };
  } catch {
    return { code: null, data: null, msg: "" };
  }
}

/** Mill blocked device registration (invite-exported / risk-blocked device ids). */
export const MILL_REGISTER_BLOCKED_CODE = 20011078;

export type MillPreloginResult =
  | { ok: true; session: MillPreloginSession }
  | { ok: false; stage: string; millCode?: number; millMsg?: string };

/** Mill-host decrypt only. K2/K3/K4 stay for the terms page. */
export async function fetchMillConfigData(
  baseUrl: string,
  packageName: string,
  visitor: string,
  fetchImpl: typeof fetch = fetch,
  hints: MillRiskHints = {},
): Promise<Record<string, unknown> | null> {
  const id = reportableDeviceId(visitor);
  const mill = baseUrl.trim();
  if (!id || !mill.startsWith("https://") || !millForwardedFor(hints.clientIp || "")) return null;
  try {
    const headers = millRiskHttpHeaders(id, packageName, hints);
    const ipHeaders = millOutboundIpHeaders(hints);
    const configCipher = millSeal(JSON.stringify({ ver: "0", http_headers: headers }), mill);
    if (!configCipher) return null;
    const opened = millOpen(await postCipher(mill, APP_CONFIG, configCipher, ipHeaders, fetchImpl), mill);
    if (!opened) return null;
    const parsed = JSON.parse(opened) as { code?: unknown; data?: unknown };
    if (parsed.code !== 0 || !parsed.data || typeof parsed.data !== "object" || Array.isArray(parsed.data)) {
      return null;
    }
    return parsed.data as Record<string, unknown>;
  } catch {
    return null;
  }
}

/** oauth + strategy. true means isReviewPkg, false means not, null means the call failed. */
export async function strategyReviewFlag(
  baseUrl: string,
  packageName: string,
  visitor: string,
  transportKey: string,
  fetchImpl: typeof fetch = fetch,
  hints: MillRiskHints = {},
  appConfig?: Record<string, unknown> | null,
): Promise<boolean | null> {
  const id = reportableDeviceId(visitor);
  const mill = baseUrl.trim();
  const transport = transportKey.trim();
  const transportSize = keySize(transport);
  if (!id || !mill.startsWith("https://") || !transportSize || !millForwardedFor(hints.clientIp || "")) return false;
  try {
    const headers = millRiskHttpHeaders(id, packageName, hints);
    const ipHeaders = millOutboundIpHeaders(hints);
    const riskInfo = buildMillOAuthRiskInfo(appConfig, id, packageName, hints);
    const oauthCipher = seal(JSON.stringify({
      oauthType: "4",
      token: id,
      http_headers: headers,
      ...(riskInfo ? { info: riskInfo } : {}),
    }), transport, transportSize);
    if (!oauthCipher) return false;
    const oauthPlain = open(
      await postCipher(mill, OAUTH, oauthCipher, ipHeaders, fetchImpl),
      transport,
      transportSize,
    );
    const token = String(codeData(oauthPlain)?.token || "");
    if (!token) return false;
    const strategyCipher = seal(JSON.stringify({ http_headers: headers }), transport, transportSize);
    if (!strategyCipher) return false;
    const strategyPlain = open(
      await postCipher(mill, STRATEGY, strategyCipher, {
        ...ipHeaders,
        Authorization: `Bearer ${token}`,
      }, fetchImpl),
      transport,
      transportSize,
    );
    const strategy = codeData(strategyPlain);
    if (!strategy || typeof strategy.isReviewPkg !== "boolean") return null;
    return strategy.isReviewPkg;
  } catch {
    return null;
  }
}

/** Older callers open only when the strategy says this is not a review package. */
export async function strategyAllows(
  baseUrl: string,
  packageName: string,
  visitor: string,
  transportKey: string,
  fetchImpl: typeof fetch = fetch,
): Promise<boolean> {
  return (await strategyReviewFlag(baseUrl, packageName, visitor, transportKey, fetchImpl)) === false;
}

export type MillPreloginSession = {
  deviceId: string;
  appConfig: Record<string, unknown>;
  loginData: Record<string, unknown>;
  strategy: Record<string, unknown>;
  isReviewPkg: boolean;
};

async function fetchGatewayPreloginResult(
  face: MillRiskFace,
  id: string,
  fetchImpl: typeof fetch,
  hints: MillRiskHints,
): Promise<MillPreloginResult> {
  const secret = String(face.gatewaySecret || "").trim();
  const rawUrl = String(face.gatewayUrl || DEFAULT_MILL_GATEWAY_URL).trim();
  const ip = millForwardedFor(String(hints.clientIp || ""));
  const versions = millRiskVersions({ APP_VERSION: hints.appVersion });
  if (secret.length < 32 || !ip || !versions.ver) {
    return { ok: false, stage: "gateway_precheck" };
  }
  let target: URL;
  try {
    target = new URL(rawUrl);
    if (target.protocol !== "https:" || target.username || target.password) {
      return { ok: false, stage: "gateway_url" };
    }
  } catch {
    return { ok: false, stage: "gateway_url" };
  }
  const requestId = randomUUID();
  const body = JSON.stringify({
    request_id: requestId,
    formal_pkg: face.packageName,
    business_pkg: face.packageName,
    business_device_id: id,
    app_version: versions.ver,
    base_url: face.baseUrl.trim().replace(/\/$/, ""),
    keys: [...face.keys],
    client_ip: ip,
    lang: String(hints.lang || "en").trim().toLowerCase() || "en",
    country: String(hints.country || "").trim().toUpperCase(),
    time_zone: String(hints.timeZone || "").trim(),
    model: hints.model === "iPad" ? "iPad" : "iPhone",
    ...(typeof hints.asn === "number" && Number.isInteger(hints.asn) ? { asn: hints.asn } : {}),
    ...(hints.asOrganization ? { as_organization: String(hints.asOrganization).slice(0, 128) } : {}),
    ...(hints.tlsVersion ? { tls_version: String(hints.tlsVersion).slice(0, 32) } : {}),
    ...(hints.userAgent ? { user_agent: String(hints.userAgent).slice(0, 256) } : {}),
    surface: hints.surface === "activity" ? "activity" : "query",
  });
  const bodySha = createHash("sha256").update(body).digest("hex");
  const timestamp = String(Math.floor(Date.now() / 1000));
  const nonce = randomUUID();
  const canonical = ["POST", target.pathname, bodySha, timestamp, nonce].join("\n");
  const signature = createHmac("sha256", secret).update(canonical).digest("hex");
  const req = new Request(target.toString(), {
    method: "POST",
    redirect: "manual",
    headers: {
      "content-type": "application/json",
      "user-agent": "ElonSuperFactory-mill-gateway/1.0",
      "x-mill-timestamp": timestamp,
      "x-mill-nonce": nonce,
      "x-mill-signature": signature,
    },
    body,
    signal: AbortSignal.timeout(35_000),
  });
  try {
    const res = face.gatewayBinding ? await face.gatewayBinding.fetch(req) : await fetchImpl(req);
    const parsed = (await res.json()) as Record<string, any>;
    if (!parsed || parsed.schema !== "esf-mill-evaluate-v1" || parsed.request_id !== requestId) {
      return { ok: false, stage: "gateway_response" };
    }
    if (parsed.ok !== true) {
      if (parsed.error?.mill_code === MILL_REGISTER_BLOCKED_CODE || parsed.error?.code === "device_register_blocked") {
        return {
          ok: false,
          stage: "oauth",
          millCode: MILL_REGISTER_BLOCKED_CODE,
          millMsg: "register_blocked",
        };
      }
      return { ok: false, stage: String(parsed.error?.stage || "gateway") };
    }
    if (parsed.blocked === true) {
      return {
        ok: true,
        session: {
          deviceId: id,
          appConfig: {},
          loginData: {},
          strategy: { isReviewPkg: true },
          isReviewPkg: true,
        },
      };
    }
    const session = parsed.result as MillPreloginSession | null;
    if (
      !session ||
      typeof session !== "object" ||
      session.deviceId !== id ||
      typeof session.loginData?.token !== "string" ||
      !session.loginData.token ||
      typeof session.isReviewPkg !== "boolean"
    ) {
      return { ok: false, stage: "gateway_session" };
    }
    return { ok: true, session };
  } catch {
    return { ok: false, stage: "gateway_network" };
  }
}

/** One mill config → oauth → strategy read, with stage detail for callers that must branch. */
export async function fetchMillPreloginResult(
  face: MillRiskFace,
  visitor: string,
  fetchImpl: typeof fetch = fetch,
  hints: MillRiskHints = {},
): Promise<MillPreloginResult> {
  const id = reportableDeviceId(visitor);
  const mill = face.baseUrl.trim();
  if (!id || !mill.startsWith("https://") || !millForwardedFor(hints.clientIp || "")) {
    return { ok: false, stage: "precheck" };
  }
  if (face.gatewaySecret) {
    return fetchGatewayPreloginResult(face, id, fetchImpl, hints);
  }
  try {
    const headers = millRiskHttpHeaders(id, face.packageName, hints);
    const ipHeaders = millOutboundIpHeaders(hints);
    const configCipher = millSeal(JSON.stringify({ ver: "0", http_headers: headers }), mill);
    if (!configCipher) return { ok: false, stage: "config_seal" };
    const openedConfig = millOpen(await postCipher(mill, APP_CONFIG, configCipher, ipHeaders, fetchImpl), mill) || "";
    const { transport, appConfig } = decodeConfigData(openedConfig, face.keys);
    const transportSize = keySize(transport);
    if (!transportSize) return { ok: false, stage: "config_transport" };
    const riskInfo = buildMillOAuthRiskInfo(appConfig, id, face.packageName, hints);
    const oauthCipher = seal(JSON.stringify({
      oauthType: "4",
      token: id,
      http_headers: headers,
      ...(riskInfo ? { info: riskInfo } : {}),
    }), transport, transportSize);
    if (!oauthCipher) return { ok: false, stage: "oauth_seal" };
    const oauthEnv = millEnvelope(open(
      await postCipher(mill, OAUTH, oauthCipher, ipHeaders, fetchImpl),
      transport,
      transportSize,
    ));
    if (oauthEnv.code === MILL_REGISTER_BLOCKED_CODE) {
      return {
        ok: false,
        stage: "oauth",
        millCode: MILL_REGISTER_BLOCKED_CODE,
        millMsg: oauthEnv.msg || "register_blocked",
      };
    }
    const loginData = oauthEnv.code === 0 ? oauthEnv.data : null;
    const token = String(loginData?.token || "");
    if (!token || !loginData) {
      return {
        ok: false,
        stage: "oauth",
        millCode: oauthEnv.code ?? undefined,
        millMsg: oauthEnv.msg || undefined,
      };
    }
    const strategyCipher = seal(JSON.stringify({ http_headers: headers }), transport, transportSize);
    if (!strategyCipher) return { ok: false, stage: "strategy_seal" };
    const strategyEnv = millEnvelope(open(
      await postCipher(mill, STRATEGY, strategyCipher, {
        ...ipHeaders,
        Authorization: `Bearer ${token}`,
      }, fetchImpl),
      transport,
      transportSize,
    ));
    const strategy = strategyEnv.code === 0 ? strategyEnv.data : null;
    if (!strategy || typeof strategy.isReviewPkg !== "boolean") {
      return {
        ok: false,
        stage: "strategy",
        millCode: strategyEnv.code ?? undefined,
        millMsg: strategyEnv.msg || undefined,
      };
    }
    return {
      ok: true,
      session: {
        deviceId: id,
        appConfig,
        loginData,
        strategy,
        isReviewPkg: strategy.isReviewPkg,
      },
    };
  } catch {
    return { ok: false, stage: "exception" };
  }
}

/** One mill config → oauth → strategy read. Null when any step fails. */
export async function fetchMillPreloginSession(
  face: MillRiskFace,
  visitor: string,
  fetchImpl: typeof fetch = fetch,
  hints: MillRiskHints = {},
): Promise<MillPreloginSession | null> {
  const result = await fetchMillPreloginResult(face, visitor, fetchImpl, hints);
  return result.ok ? result.session : null;
}

/** True only when strategy says this visitor is not in review. */
export async function riskAllows(
  face: MillRiskFace,
  visitor: string,
  fetchImpl: typeof fetch = fetch,
  hints: MillRiskHints = {},
): Promise<boolean> {
  const session = await fetchMillPreloginSession(face, visitor, fetchImpl, hints);
  return session?.isReviewPkg === false;
}
