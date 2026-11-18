/**
 * One mill login per device, sealed into the activity index Set-Cookie.
 * A request without device-id never calls Mill and never sets a cookie.
 */
import { reportableDeviceId } from "./device_id";
import { millFaceFromEnv, millHintsForActivity, millRiskSwitchOn, millVisitorBlocked, type MillPrescreenEnv } from "./activity_entry";
import { fetchMillPreloginSession, type MillRiskFace, type MillRiskHints } from "./mill_risk";
import {
  buildPreloginSetCookies,
  derivePreloginSpec,
  getOrFetchPrelogin,
  preloginCacheKey,
  recallPrelogin,
  rememberPreloginBlob,
  sealPreloginBundle,
  splitbiteWebDeviceId,
} from "./prelogin_cipher";

export { splitbiteWebDeviceId };

type PreloginEnv = MillPrescreenEnv & {
  MILL_RISK_ENABLED?: string | boolean;
  MILL_BASE_URL?: string;
  MILL_KEYS?: string;
  PRELOGIN_KEYS?: string;
  PRELOGIN_BUSINESS_PKG?: string;
  APP_VERSION?: string;
  ACTIVITY_PKG?: string;
  DEVICE_PARAM?: string;
  fetchImpl?: typeof fetch;
};

const INDEX_PATH = /^\/activity\/([^/]+)\/([^/]+)\/(?:index\.html)?$/;

export function activityIndexParts(pathname: string): { pkg: string; buildId: string } | null {
  const match = INDEX_PATH.exec(pathname);
  if (!match) return null;
  return { pkg: match[1], buildId: match[2] };
}

function keyList(raw: string | undefined): string[] {
  return String(raw || "").split(",").map((item) => item.trim()).filter(Boolean);
}

function preloginKeys(env: PreloginEnv): string[] {
  const named = keyList(env.PRELOGIN_KEYS);
  if (named.length === 4) return named;
  const mill = keyList(env.MILL_KEYS);
  return mill.length === 4 ? mill : [];
}

function deviceFromUrl(url: URL, env: PreloginEnv): string {
  // 千包千面: prefer package-unique DEVICE_PARAM over shared device-id.
  const param = (env.DEVICE_PARAM || "").trim();
  if (param) {
    const named = (url.searchParams.get(param) || "").trim();
    if (named) return named;
  }
  return (url.searchParams.get("device-id") || "").trim();
}

export async function warmPreloginSession(options: {
  businessPkg: string;
  deviceId: string;
  appVersion?: string;
  face: MillRiskFace | null;
  hints?: MillRiskHints;
  fetchImpl?: typeof fetch;
}): Promise<boolean> {
  const id = reportableDeviceId(options.deviceId);
  const ip = String(options.hints?.clientIp || "").trim();
  if (!id || !options.face || !ip) return false;
  if (!options.face.gatewaySecret && ip.startsWith("17.")) return false;
  const key = preloginCacheKey(options.businessPkg, id, options.appVersion || "");
  const row = await getOrFetchPrelogin(key, () => fetchMillPreloginSession(
    options.face as MillRiskFace,
    id,
    options.fetchImpl ?? fetch,
    options.hints || {},
  ));
  return Boolean(row?.session.loginData.token);
}

export async function warmQueryPrelogin(request: Request, env: PreloginEnv, businessPkg: string): Promise<void> {
  if (!millRiskSwitchOn(env.MILL_RISK_ENABLED)) return;
  const face = millFaceFromEnv(env, env.PRELOGIN_BUSINESS_PKG || businessPkg);
  const hints = millHintsForActivity(request, env.APP_VERSION);
  if (!hints.clientIp || (!face?.gatewaySecret && millVisitorBlocked(request, hints.clientIp, env, "query"))) return;
  let body: unknown = null;
  try {
    body = await request.json();
  } catch {
    body = null;
  }
  const fromBody = body && typeof body === "object" && !Array.isArray(body)
    ? String((body as Record<string, unknown>)["device-id"] || "")
    : "";
  const headerId = request.headers.get("device-id") || "";
  const bearer = (request.headers.get("authorization") || "").replace(/^Bearer\s+/i, "").trim();
  const deviceId = (fromBody || headerId || (bearer ? splitbiteWebDeviceId(bearer) : "")).trim();
  if (!deviceId) return;
  await warmPreloginSession({
    businessPkg: env.PRELOGIN_BUSINESS_PKG || businessPkg,
    deviceId,
    appVersion: env.APP_VERSION,
    face,
    hints,
    fetchImpl: env.fetchImpl,
  });
}

function sealCached(key: string, pkg: string, buildId: string, keys: string[], activityBase: string): string[] | null {
  const row = recallPrelogin(key);
  if (!row?.session.loginData.token) return null;
  if (!row.blob) {
    const spec = derivePreloginSpec(pkg, buildId, keys);
    const login = row.session.loginData;
    const user = login.userInfo ?? login.user;
    row.blob = sealPreloginBundle(spec, {
      deviceId: row.session.deviceId,
      token: String(login.token || ""),
      isFirstRegister: Boolean(login.isFirstRegister),
      user: user && typeof user === "object" && !Array.isArray(user) ? user as Record<string, unknown> : {},
      config: row.session.appConfig,
      strategy: row.session.strategy,
      issuedAt: 0,
    }, pkg);
    rememberPreloginBlob(key, row.blob);
  }
  const spec = derivePreloginSpec(pkg, buildId, keys);
  return buildPreloginSetCookies(spec.cookie_name, row.blob, activityBase);
}

/** Cookie lines for an activity index that already carries device-id. Null means do not call Mill. */
export async function activityPreloginCookies(request: Request, env: PreloginEnv): Promise<string[] | null> {
  if (!millRiskSwitchOn(env.MILL_RISK_ENABLED)) return null;
  const url = new URL(request.url);
  const parts = activityIndexParts(url.pathname);
  const deviceId = deviceFromUrl(url, env);
  if (!parts || !deviceId) return null;
  const businessPkg = env.PRELOGIN_BUSINESS_PKG || env.ACTIVITY_PKG || parts.pkg;
  const face = millFaceFromEnv(env, businessPkg);
  const hints = millHintsForActivity(request, env.APP_VERSION);
  // Local prescreen runs in the business Worker first; the service repeats it.
  if (millVisitorBlocked(request, hints.clientIp || "", env, "activity")) return null;
  const keys = preloginKeys(env);
  if (keys.length !== 4) return null;
  const id = reportableDeviceId(deviceId);
  if (!id) return null;
  const key = preloginCacheKey(businessPkg, id, env.APP_VERSION || "");
  if (!recallPrelogin(key) && hints.clientIp) {
    await warmPreloginSession({
      businessPkg,
      deviceId: id,
      appVersion: env.APP_VERSION,
      face,
      hints,
      fetchImpl: env.fetchImpl,
    });
  }
  const row = recallPrelogin(key);
  if (!row) return null;
  if (row.session.isReviewPkg) return null;
  return sealCached(key, parts.pkg, parts.buildId, keys, `/activity/${parts.pkg}/${parts.buildId}/`);
}

export async function attachActivityPrelogin(request: Request, response: Response, env: PreloginEnv): Promise<Response> {
  const method = request.method.toUpperCase();
  if (method !== "GET" && method !== "HEAD") return response;
  const cookies = await activityPreloginCookies(request, env);
  if (!cookies?.length) return response;
  const headers = new Headers(response.headers);
  for (const row of cookies) headers.append("set-cookie", row);
  headers.set("cache-control", "public, max-age=0, must-revalidate");
  return new Response(response.body, { status: response.status, statusText: response.statusText, headers });
}
