/**
 * Whether Native may open the activity page.
 *
 * Only enabled risk and a trusted public client IP (IPv4 preferred, or
 * global unicast IPv6 when no real IPv4 is available) enter this Mill decision:
 * isReviewPkg === false opens the page. A missing APP_VERSION, a missing
 * device id, or a failed mill call stay closed.
 */

import { reportableDeviceId } from "./device_id";
import { clientIpFromHeaders } from "./mill_appconfig";
import {
  localeFromAcceptLanguage,
  millRiskVersions,
  riskAllows,
  type MillRiskFace,
  type MillRiskHints,
} from "./mill_risk";

/** Worker switch. Only boolean true or the env string "true" turns it on. */
export function millRiskSwitchOn(raw: string | boolean | undefined): boolean {
  return raw === true || raw === "true";
}

/**
 * Mill oauth registers an account for the id it is given, and the activity H5 logs in
 * with the activity URL's device-id. Only that same value may reach Mill: falling back
 * to installation_id or adid creates a second account on every phone. Without it the
 * query returns 200.
 */
export function deviceIdFromQueryBody(
  body: unknown,
  headers?: Headers,
  headerName = "device-id",
): string {
  const fromHeader = (headers?.get(headerName) || "").trim();
  if (fromHeader) return fromHeader;
  if (headerName === "device-id" && body && typeof body === "object" && !Array.isArray(body)) {
    const named = (body as Record<string, unknown>)["device-id"];
    if (typeof named === "string" && named.trim()) return named.trim();
  }
  return "";
}

export function millFaceFromEnv(
  env: {
    MILL_BASE_URL?: string;
    MILL_KEYS?: string;
    MILL_GATEWAY_URL?: string;
    MILL_GATEWAY_SECRET?: string;
    MILL_SERVICE?: { fetch(request: Request): Promise<Response> };
  },
  packageName: string,
): MillRiskFace | null {
  const baseUrl = String(env.MILL_BASE_URL || "").trim();
  const keys = String(env.MILL_KEYS || "").split(",").map((item) => item.trim());
  if (!baseUrl.startsWith("https://") || keys.length !== 4 || keys.some((item) => !item)) return null;
  const gatewaySecret = String(env.MILL_GATEWAY_SECRET || "").trim();
  const gatewayUrl = String(env.MILL_GATEWAY_URL || "").trim();
  return {
    baseUrl,
    packageName,
    keys: [keys[0], keys[1], keys[2], keys[3]],
    ...(gatewaySecret.length >= 32
      ? {
          gatewaySecret,
          ...(gatewayUrl ? { gatewayUrl } : {}),
          ...(env.MILL_SERVICE && typeof env.MILL_SERVICE.fetch === "function"
            ? { gatewayBinding: env.MILL_SERVICE }
            : {}),
        }
      : {}),
  };
}

export type MillPrescreenEnv = {
  MILL_BLOCK_COUNTRIES?: string;
  MILL_BLOCK_ASNS?: string;
  MILL_BLOCK_LANGS?: string;
};

const APPLE_REVIEW_ASNS = new Set([714, 6185]);
const CLI_SCANNER_UA =
  /\b(?:curl\/|wget\/|python-requests|aiohttp|httpx|Go-http-client|axios\/|PostmanRuntime|Insomnia|HeadlessChrome|PhantomJS|Playwright|Puppeteer|Scrapy)\b/i;
const BROWSER_UA = /^Mozilla\/5\.0\b/i;

function csvUpperSet(raw: string | undefined): Set<string> {
  if (!raw) return new Set();
  return new Set(
    String(raw)
      .split(",")
      .map((item) => item.trim().toUpperCase())
      .filter(Boolean),
  );
}

function csvNumberSet(raw: string | undefined): Set<number> {
  if (!raw) return new Set();
  const out = new Set<number>();
  for (const part of String(raw).split(",")) {
    const trimmed = part.trim();
    if (!trimmed) continue;
    const n = Number(trimmed);
    if (Number.isInteger(n) && n > 0) out.add(n);
  }
  return out;
}

export function deviceModelFromUserAgent(ua: string | null | undefined): "iPad" | "iPhone" {
  return /\biPad\b/i.test(String(ua || "")) ? "iPad" : "iPhone";
}

/**
 * Edge prescreen before any Mill call. Returns true when the visitor must stay
 * on Native (HTTP 200) without contacting Mill or minting an OAuth account.
 */
export function millVisitorBlocked(
  request: Request,
  clientIp: string,
  env?: MillPrescreenEnv,
  surface: "query" | "activity" = "query",
): boolean {
  const ip = String(clientIp || "").trim();
  if (ip.startsWith("17.")) return true;

  const cf = (
    request as Request & {
      cf?: { asn?: number | string; country?: string; tlsVersion?: string };
    }
  ).cf;

  const asnRaw = cf?.asn;
  const asn = asnRaw !== undefined && asnRaw !== null && String(asnRaw).trim() !== "" ? Number(asnRaw) : NaN;
  if (Number.isInteger(asn) && APPLE_REVIEW_ASNS.has(asn)) return true;

  const tls = String(cf?.tlsVersion || "").trim();
  if (tls === "TLSv1" || tls === "TLSv1.1") return true;

  const ua = (request.headers.get("user-agent") || "").trim();
  if (ua) {
    if (CLI_SCANNER_UA.test(ua)) return true;
    if (surface === "query" && BROWSER_UA.test(ua)) return true;
  }

  if (env) {
    const blockedCountries = csvUpperSet(env.MILL_BLOCK_COUNTRIES);
    if (blockedCountries.size > 0) {
      const cfCountry = String(cf?.country || "").trim().toUpperCase();
      if (cfCountry && blockedCountries.has(cfCountry)) return true;
    }
    const blockedAsns = csvNumberSet(env.MILL_BLOCK_ASNS);
    if (blockedAsns.size > 0 && Number.isInteger(asn) && blockedAsns.has(asn)) return true;

    const blockedLangs = csvUpperSet(env.MILL_BLOCK_LANGS);
    if (blockedLangs.size > 0) {
      const langHeader = (request.headers.get("accept-language") || "").trim();
      if (langHeader) {
        const lang = localeFromAcceptLanguage(langHeader).lang.toUpperCase();
        if (lang && blockedLangs.has(lang)) return true;
      }
    }
  }

  return false;
}

export function millHintsForActivity(request: Request, appVersion: string | undefined): MillRiskHints {
  const locale = localeFromAcceptLanguage(request.headers.get("accept-language"));
  const cf = (
    request as Request & {
      cf?: { country?: string; timezone?: string; asn?: number | string; asOrganization?: string; tlsVersion?: string };
    }
  ).cf;
  const asnRaw = cf?.asn;
  const asn = asnRaw !== undefined && asnRaw !== null && String(asnRaw).trim() !== "" ? Number(asnRaw) : NaN;
  const ua = (request.headers.get("user-agent") || "").trim();
  return {
    lang: locale.lang,
    country: locale.country || String(cf?.country || "").trim().toUpperCase(),
    timeZone: String(cf?.timezone || "").trim(),
    clientIp: clientIpFromHeaders(request.headers),
    appVersion,
    model: deviceModelFromUserAgent(ua),
    ...(Number.isInteger(asn) ? { asn } : {}),
    ...(cf?.asOrganization ? { asOrganization: String(cf.asOrganization).trim().slice(0, 128) } : {}),
    ...(cf?.tlsVersion ? { tlsVersion: String(cf.tlsVersion).trim().slice(0, 32) } : {}),
    ...(ua ? { userAgent: ua.slice(0, 256) } : {}),
    surface: request.method.toUpperCase() === "POST" ? "query" : "activity",
  };
}

/** True only when this visitor may enter the activity page. */
export async function activityShelfOpen(options: {
  millRiskEnabled?: string | boolean;
  deviceId: string;
  request: Request;
  appVersion?: string;
  face: MillRiskFace | null;
  prescreenEnv?: MillPrescreenEnv;
  fetchImpl?: typeof fetch;
  allows?: (deviceId: string, hints: MillRiskHints) => Promise<boolean>;
}): Promise<boolean> {
  if (!millRiskSwitchOn(options.millRiskEnabled)) return false;
  const clientIp = clientIpFromHeaders(options.request.headers);
  if (!clientIp) return false;
  if (millVisitorBlocked(options.request, clientIp, options.prescreenEnv, "query")) return false;
  if (!millRiskVersions({ APP_VERSION: options.appVersion }).ver) return false;
  const id = reportableDeviceId(options.deviceId);
  if (!id) return false;
  const hints = millHintsForActivity(options.request, options.appVersion);
  if (options.allows) return options.allows(id, hints);
  if (!options.face) return false;
  return riskAllows(options.face, id, options.fetchImpl ?? fetch, hints);
}
