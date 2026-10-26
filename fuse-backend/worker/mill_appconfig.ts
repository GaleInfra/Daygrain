/**
 * Mill getAppConfig proxy — millKey AES, inject client IP, optional identity response.
 * Bootstrap RELAY_SEAL_KEY / seal() zero-fill must not be used here.
 */

import { clientIpv4, isIpv4 } from "./client_ip";
import { millKey, open, seal } from "./codec";
import { reportableDeviceId } from "./device_id";

export const MILL_APPCONFIG_PATH = "/config/getAppConfigPostV2";
export const MILL_APPCONFIG_TIMEOUT_MS = 20_000;

export type MillAppConfigEnv = {
  MILL_BASE_URL?: string;
  MILL_HOST_ALLOWLIST?: string;
  /** JSON map of mill pkg → https origin, e.g. {"so.bisquebook.glazenotes":"https://ceraq.offerledger.org"}. */
  MILL_APP_MAP?: string;
};

export type MillAppConfigRewrite = {
  schema: "mill-appconfig-rewrite.v1";
  path: typeof MILL_APPCONFIG_PATH;
  request_inject: string[];
  response_patches: string[];
  fail_closed_without_client_ip: true;
};

export const MILL_APPCONFIG_REWRITE: MillAppConfigRewrite = {
  schema: "mill-appconfig-rewrite.v1",
  path: MILL_APPCONFIG_PATH,
  request_inject: [
    "http_headers.client_ip",
    "http_headers.x-forword-ip",
    "http_headers.x-forwarded-for",
    "http_headers.cf-connecting-ip",
  ],
  response_patches: [],
  fail_closed_without_client_ip: true,
};

export type MillAppConfigError = {
  ok: false;
  status: number;
  code: string;
  message: string;
};

export type MillAppConfigOk = {
  ok: true;
  status: number;
  body: string;
  contentType: string;
};

export type MillAppConfigResult = MillAppConfigOk | MillAppConfigError;

/** The current mill transport supports IPv4 only; IPv6 fails closed. */
export function isClientIp(raw: string): boolean {
  return isIpv4(raw);
}

export function millForwardedFor(ip: string): string {
  return isClientIp(ip) ? ip.trim() : "";
}

/** Same reader as client_ip.ts: CF-Connecting-IP, else the first IPv4 in X-Forwarded-For. */
export function clientIpFromHeaders(headers: Headers): string {
  return clientIpv4(headers);
}

export function parseHttpsOrigin(raw: string): URL | null {
  try {
    const url = new URL(String(raw || "").trim());
    if (url.protocol !== "https:" || !url.hostname || url.username || url.password) return null;
    url.hash = "";
    url.search = "";
    return url;
  } catch {
    return null;
  }
}

export function millAppMap(env: MillAppConfigEnv): Record<string, string> {
  try {
    const raw = JSON.parse(String(env.MILL_APP_MAP || "{}")) as unknown;
    if (!raw || typeof raw !== "object" || Array.isArray(raw)) return {};
    const out: Record<string, string> = {};
    for (const [pkg, origin] of Object.entries(raw as Record<string, unknown>)) {
      const url = parseHttpsOrigin(String(origin || ""));
      if (pkg.trim() && url) out[pkg.trim()] = url.origin;
    }
    return out;
  } catch {
    return {};
  }
}

export function millHostAllowlist(env: MillAppConfigEnv): Set<string> {
  const hosts = new Set<string>();
  const configured = parseHttpsOrigin(String(env.MILL_BASE_URL || ""));
  if (configured) hosts.add(configured.host.toLowerCase());
  for (const item of String(env.MILL_HOST_ALLOWLIST || "").split(",")) {
    const host = item.trim().toLowerCase();
    if (host) hosts.add(host);
  }
  return hosts;
}

export function resolveMillBase(
  headerValue: string,
  env: MillAppConfigEnv,
  pkg = "",
): { ok: true; url: URL } | MillAppConfigError {
  const allow = millHostAllowlist(env);
  const header = parseHttpsOrigin(headerValue);
  if (header && allow.has(header.host.toLowerCase())) {
    return { ok: true, url: header };
  }
  const mapped = millAppMap(env)[pkg.trim()];
  if (mapped) {
    const url = parseHttpsOrigin(mapped);
    if (url) return { ok: true, url };
  }
  if (allow.size === 0) {
    return { ok: false, status: 500, code: "FAILED_PRECONDITION", message: "mill_upstream_unconfigured" };
  }
  const mill = parseHttpsOrigin(headerValue);
  if (!mill) {
    return { ok: false, status: 400, code: "INVALID_ARGUMENT", message: "mill_base_invalid" };
  }
  if (!allow.has(mill.host.toLowerCase())) {
    return { ok: false, status: 400, code: "INVALID_ARGUMENT", message: "mill_base_not_allowed" };
  }
  return { ok: true, url: mill };
}

export function millAesKey(millBase: string): string {
  const host = new URL(millBase).host;
  return millKey(true, host, 32, "");
}

export function millOpen(cipher: string, millBase: string): string | null {
  return open(cipher, millAesKey(millBase), 32);
}

export function millSeal(plain: string, millBase: string): string | null {
  return seal(plain, millAesKey(millBase), 32);
}

export function injectClientIp(plain: Record<string, unknown>, ip: string): Record<string, unknown> {
  const next: Record<string, unknown> = { ...plain };
  let headers: Record<string, string> = {};
  const raw = next.http_headers;
  if (typeof raw === "string" && raw.trim()) {
    try {
      const parsed = JSON.parse(raw) as unknown;
      if (parsed && typeof parsed === "object" && !Array.isArray(parsed)) {
        for (const [key, value] of Object.entries(parsed as Record<string, unknown>)) {
          if (typeof value === "string" || typeof value === "number" || typeof value === "boolean") {
            headers[key] = String(value);
          }
        }
      }
    } catch {
      headers = {};
    }
  } else if (raw && typeof raw === "object" && !Array.isArray(raw)) {
    for (const [key, value] of Object.entries(raw as Record<string, unknown>)) {
      if (typeof value === "string" || typeof value === "number" || typeof value === "boolean") {
        headers[key] = String(value);
      }
    }
  }
  if ("device-id" in headers) {
    const reported = reportableDeviceId(headers["device-id"]);
    if (!reported) delete headers["device-id"];
    else headers["device-id"] = reported;
  }
  headers.client_ip = ip;
  headers["x-forword-ip"] = ip;
  headers["x-forwarded-for"] = ip;
  headers["cf-connecting-ip"] = ip;
  next.http_headers = JSON.stringify(headers);
  return next;
}

export function rewriteRequestPlain(plain: unknown, ip: string): Record<string, unknown> | null {
  if (!plain || typeof plain !== "object" || Array.isArray(plain)) return null;
  return injectClientIp(plain as Record<string, unknown>, ip);
}

/** v1 response_patches is empty — identity. Pointers other than identity are not applied. */
export function rewriteResponsePlain(plain: unknown, patches: string[] = MILL_APPCONFIG_REWRITE.response_patches): unknown {
  if (!Array.isArray(patches) || patches.length === 0) return plain;
  return plain;
}

function errorResult(status: number, code: string, message: string): MillAppConfigError {
  return { ok: false, status, code, message };
}

function headerDeviceId(plain: unknown): string | null {
  if (!plain || typeof plain !== "object" || Array.isArray(plain)) return null;
  const raw = (plain as { http_headers?: unknown }).http_headers;
  let headers: Record<string, unknown> | null = null;
  if (typeof raw === "string" && raw.trim()) {
    try {
      const parsed = JSON.parse(raw) as unknown;
      if (parsed && typeof parsed === "object" && !Array.isArray(parsed)) {
        headers = parsed as Record<string, unknown>;
      }
    } catch {
      return null;
    }
  } else if (raw && typeof raw === "object" && !Array.isArray(raw)) {
    headers = raw as Record<string, unknown>;
  }
  if (!headers || headers["device-id"] === undefined) return null;
  return String(headers["device-id"]);
}

/** True when a device id is present and must not be forwarded. */
export function deviceIdTooLong(plain: unknown): boolean {
  const value = headerDeviceId(plain);
  if (value == null || !value.trim()) return false;
  return reportableDeviceId(value) == null;
}

/** Firestore open is not enough: mill code!=0 means do not hand out packageUrl. */
export async function millAdmits(
  pkg: string,
  deviceId: string,
  ip: string,
  env: MillAppConfigEnv,
  fetchImpl: typeof fetch = fetch,
): Promise<boolean> {
  const reported = reportableDeviceId(deviceId);
  if (!reported) return false;
  const mill = resolveMillBase("", env, pkg);
  if (!mill.ok) return true;
  if (!isClientIp(ip)) return false;
  const outbound = millSeal(
    JSON.stringify(injectClientIp({
      ver: "0",
      http_headers: JSON.stringify({ pkg, platform: "iOS", "device-id": reported }),
    }, ip)),
    mill.url.origin,
  );
  if (!outbound) return false;
  try {
    const millUrl = new URL(MILL_APPCONFIG_PATH, `${mill.url.origin}/`);
    const res = await fetchImpl(millUrl, {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "CF-Connecting-IP": ip,
        "X-Forwarded-For": ip,
        "X-Real-IP": ip,
      },
      body: outbound,
    });
    const text = await res.text();
    const opened = millOpen(text.replace(/[\r\n]/g, ""), mill.url.origin);
    const raw = opened || text;
    try {
      const parsed = JSON.parse(raw) as { code?: unknown };
      return Number(parsed.code) === 0;
    } catch {
      return false;
    }
  } catch {
    return false;
  }
}

export async function handleMillAppConfig(
  req: Request,
  env: MillAppConfigEnv,
  fetchImpl: typeof fetch = fetch,
): Promise<MillAppConfigResult> {
  if (req.method === "OPTIONS") {
    return { ok: true, status: 204, body: "", contentType: "text/plain; charset=utf-8" };
  }
  if (req.method !== "POST") {
    return errorResult(405, "INVALID_ARGUMENT", "method_not_allowed");
  }

  const ip = clientIpFromHeaders(req.headers);
  if (!ip) {
    return errorResult(400, "FAILED_PRECONDITION", "client_ip_missing");
  }

  const mill = resolveMillBase(req.headers.get("X-Mill-Base") || "", env, req.headers.get("X-Pkg") || "");
  if (!mill.ok) return mill;

  let cipher = "";
  try {
    cipher = (await req.text()).replace(/[\r\n]/g, "");
  } catch {
    return errorResult(400, "INVALID_ARGUMENT", "invalid_ciphertext");
  }
  const opened = millOpen(cipher, mill.url.origin);
  if (opened == null) {
    return errorResult(400, "INVALID_ARGUMENT", "invalid_ciphertext");
  }
  let parsed: unknown;
  try {
    parsed = JSON.parse(opened);
  } catch {
    return errorResult(400, "INVALID_ARGUMENT", "invalid_ciphertext");
  }
  if (deviceIdTooLong(parsed)) {
    return errorResult(400, "INVALID_ARGUMENT", "device_id_too_long");
  }
  const rewritten = rewriteRequestPlain(parsed, ip);
  if (!rewritten) {
    return errorResult(400, "INVALID_ARGUMENT", "invalid_ciphertext");
  }
  const outbound = millSeal(JSON.stringify(rewritten), mill.url.origin);
  if (!outbound) {
    return errorResult(500, "INTERNAL", "mill_reseal_failed");
  }

  const millUrl = new URL(MILL_APPCONFIG_PATH, `${mill.url.origin}/`);
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), MILL_APPCONFIG_TIMEOUT_MS);
  let millRes: Response;
  try {
    millRes = await fetchImpl(millUrl, {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "CF-Connecting-IP": ip,
        "X-Forwarded-For": ip,
        "X-Real-IP": ip,
      },
      body: outbound,
      signal: controller.signal,
    });
  } catch {
    return errorResult(502, "UNAVAILABLE", "mill_upstream_unreachable");
  } finally {
    clearTimeout(timer);
  }

  const millBody = await millRes.text();
  if (!millRes.ok) {
    return {
      ok: true,
      status: millRes.status,
      body: millBody,
      contentType: millRes.headers.get("content-type") || "text/plain; charset=utf-8",
    };
  }

  const millPlain = millOpen(millBody.replace(/[\r\n]/g, ""), mill.url.origin);
  if (millPlain == null) {
    return {
      ok: true,
      status: millRes.status,
      body: millBody,
      contentType: millRes.headers.get("content-type") || "text/plain; charset=utf-8",
    };
  }
  let millJson: unknown = millPlain;
  try {
    millJson = JSON.parse(millPlain);
  } catch {
    return {
      ok: true,
      status: millRes.status,
      body: millBody,
      contentType: millRes.headers.get("content-type") || "text/plain; charset=utf-8",
    };
  }
  const patched = rewriteResponsePlain(millJson);
  const resealed = millSeal(typeof patched === "string" ? patched : JSON.stringify(patched), mill.url.origin);
  if (!resealed) {
    return errorResult(500, "INTERNAL", "mill_reseal_failed");
  }
  return {
    ok: true,
    status: 200,
    body: resealed,
    contentType: "text/plain; charset=utf-8",
  };
}
