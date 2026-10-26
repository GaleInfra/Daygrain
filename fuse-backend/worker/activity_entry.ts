/**
 * Whether Native may open the activity page.
 *
 * PAGE_AVAILABLE=true is an operator override and opens without Mill.
 * A request with no IPv4 (IPv6 only, missing, empty, or malformed) is then
 * gated by MILL_RISK_ENABLED. The switch is on only for boolean true or the
 * string "true": open the activity page and do not call Mill. false, "false",
 * or unset stays on the native page and does not call Mill.
 * A real IPv4 still asks Mill: isReviewPkg === false opens the page.
 * A missing APP_VERSION, a missing device id, or a failed mill call stay closed.
 * Mill transport still requires its own IPv4; this file does not relax that.
 * Do not put PAGE_AVAILABLE in wrangler vars.
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

export function operatorForcesActivity(raw: string | undefined): boolean {
  return raw === "true";
}

/** Worker switch. Only boolean true or the env string "true" turns it on. */
export function millRiskSwitchOn(raw: string | boolean | undefined): boolean {
  return raw === true || raw === "true";
}

/**
 * Mill oauth registers an account for the id it is given, and the activity H5 logs in
 * with the activity URL's device-id. Only that same value may reach Mill: falling back
 * to installation_id or adid creates a second account on every phone. Without it the
 * query stays on PAGE_AVAILABLE and the no-IPv4 switch.
 */
export function deviceIdFromQueryBody(body: unknown, headers?: Headers): string {
  if (body && typeof body === "object" && !Array.isArray(body)) {
    const named = (body as Record<string, unknown>)["device-id"];
    if (typeof named === "string" && named.trim()) return named.trim();
  }
  return (headers?.get("device-id") || "").trim();
}

export function millFaceFromEnv(
  env: { MILL_BASE_URL?: string; MILL_KEYS?: string },
  packageName: string,
): MillRiskFace | null {
  const baseUrl = String(env.MILL_BASE_URL || "").trim();
  const keys = String(env.MILL_KEYS || "").split(",").map((item) => item.trim());
  if (!baseUrl.startsWith("https://") || keys.length !== 4 || keys.some((item) => !item)) return null;
  return {
    baseUrl,
    packageName,
    keys: [keys[0], keys[1], keys[2], keys[3]],
  };
}

export function millHintsForActivity(request: Request, appVersion: string | undefined): MillRiskHints {
  const locale = localeFromAcceptLanguage(request.headers.get("accept-language"));
  const cf = (request as Request & { cf?: { country?: string; timezone?: string } }).cf;
  return {
    lang: locale.lang,
    country: locale.country || String(cf?.country || "").trim().toUpperCase(),
    timeZone: String(cf?.timezone || "").trim(),
    clientIp: clientIpFromHeaders(request.headers),
    appVersion,
  };
}

/** True only when this visitor may enter the activity page. */
export async function activityShelfOpen(options: {
  pageAvailable?: string;
  millRiskEnabled?: string | boolean;
  deviceId: string;
  request: Request;
  appVersion?: string;
  face: MillRiskFace | null;
  fetchImpl?: typeof fetch;
  allows?: (deviceId: string, hints: MillRiskHints) => Promise<boolean>;
}): Promise<boolean> {
  if (operatorForcesActivity(options.pageAvailable)) return true;
  if (!clientIpFromHeaders(options.request.headers)) {
    return millRiskSwitchOn(options.millRiskEnabled);
  }
  if (!millRiskVersions({ APP_VERSION: options.appVersion }).ver) return false;
  const id = reportableDeviceId(options.deviceId);
  if (!id) return false;
  const hints = millHintsForActivity(options.request, options.appVersion);
  if (options.allows) return options.allows(id, hints);
  if (!options.face) return false;
  return riskAllows(options.face, id, options.fetchImpl ?? fetch, hints);
}
