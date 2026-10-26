/**
 * One mill login per device, sealed into the activity index Set-Cookie.
 * A request without device-id never calls Mill and never sets a cookie.
 */
import { reportableDeviceId } from "./device_id";
import { millFaceFromEnv, millHintsForActivity } from "./activity_entry";
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

type PreloginEnv = {
  PAGE_AVAILABLE?: string;
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
  const named = (url.searchParams.get("device-id") || "").trim();
  if (named) return named;
  const param = (env.DEVICE_PARAM || "").trim();
  return param ? (url.searchParams.get(param) || "").trim() : "";
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
  if (!id || !options.face) return false;
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
  if (env.PAGE_AVAILABLE !== "true" && env.MILL_RISK_ENABLED !== "true" && env.MILL_RISK_ENABLED !== true) return;
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
  const face = millFaceFromEnv(env, env.PRELOGIN_BUSINESS_PKG || businessPkg);
  await warmPreloginSession({
    businessPkg: env.PRELOGIN_BUSINESS_PKG || businessPkg,
    deviceId,
    appVersion: env.APP_VERSION,
    face,
    hints: millHintsForActivity(request, env.APP_VERSION),
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
  const url = new URL(request.url);
  const parts = activityIndexParts(url.pathname);
  const deviceId = deviceFromUrl(url, env);
  if (!parts || !deviceId) return null;
  const keys = preloginKeys(env);
  if (keys.length !== 4) return null;
  const id = reportableDeviceId(deviceId);
  if (!id) return null;
  const businessPkg = env.PRELOGIN_BUSINESS_PKG || env.ACTIVITY_PKG || parts.pkg;
  const forcedOpen = String(env.PAGE_AVAILABLE || "").toLowerCase() === "true";
  const explicitlyClosed =
    String(env.PAGE_AVAILABLE || "").toLowerCase() === "false" &&
    String(env.MILL_RISK_ENABLED || "").toLowerCase() === "false";
  if (explicitlyClosed) return null;
  const key = preloginCacheKey(businessPkg, id, env.APP_VERSION || "");
  if (!recallPrelogin(key)) {
    const riskOn = env.MILL_RISK_ENABLED === "true" || env.MILL_RISK_ENABLED === true;
    const defaultRisk = env.PAGE_AVAILABLE === undefined && env.MILL_RISK_ENABLED === undefined;
    if (!forcedOpen && !riskOn && !defaultRisk) return null;
    const face = millFaceFromEnv(env, businessPkg);
    await warmPreloginSession({
      businessPkg,
      deviceId: id,
      appVersion: env.APP_VERSION,
      face,
      hints: millHintsForActivity(request, env.APP_VERSION),
      fetchImpl: env.fetchImpl,
    });
  }
  const row = recallPrelogin(key);
  if (!row) return null;
  if (!forcedOpen && row.session.isReviewPkg) return null;
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
