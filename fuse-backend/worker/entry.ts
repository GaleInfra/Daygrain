import { dispatch } from "./native_wire";
import { activityShelfOpen, deviceIdFromQueryBody, millFaceFromEnv, millHintsForActivity, millRiskSwitchOn, millVisitorBlocked } from "./activity_entry";
import { attachActivityPrelogin, warmPreloginSession } from "./prelogin_handoff";
import { buildPreloginSetCookies, derivePreloginSpec, getOrFetchPrelogin, preloginCacheKey, recallPrelogin, sealPreloginBundle } from "./prelogin_cipher";
import { reportableDeviceId } from "./device_id";
import { fetchMillPreloginResult, MILL_REGISTER_BLOCKED_CODE } from "./mill_risk";
import { injectRuntimeIntoIndexHtml, normalizeRuntimeConfig, runtimeStorageKey, runtimeStorageScope, sharedDevBuildId, upsertAppRuntimeConfig, writeDeviceHandoff } from "./h5_runtime_handoff";

function runtimeConfigFromEnv(env: Record<string, any>, pkg: string): Record<string, unknown> {
  const scope = String(env.FUSE_RUNTIME_SCOPE || "").trim();
  if (typeof env.FUSE_RUNTIME_CONFIG === "string" && env.FUSE_RUNTIME_CONFIG.trim()) {
    try {
      const parsed = JSON.parse(env.FUSE_RUNTIME_CONFIG);
      if (parsed && typeof parsed === "object") {
        const baseUrl = parsed.base_url || parsed.api_host || env.MILL_BASE_URL || "";
        return {
          ...parsed,
          base_url: baseUrl,
          log_url: parsed.log_url || env.LOG_URL || baseUrl,
          socket_url: parsed.socket_url || env.SOCKET_URL || baseUrl,
          keys: runtimeKeys(env, parsed),
          ...(scope ? { runtime_scope: scope } : {}),
          mill_risk_enabled: millRiskSwitchOn(env.MILL_RISK_ENABLED),
        };
      }
    } catch {}
  }
  const keys = runtimeKeys(env, {});
  return {
    pkg,
    mill_risk_enabled: millRiskSwitchOn(env.MILL_RISK_ENABLED),
    package_name: pkg,
    app_version: String(env.APP_VERSION || "1.0.1"),
    ios_app_id: String(env.IOS_APP_ID || ""),
    base_url: String(env.MILL_BASE_URL || ""),
    log_url: String(env.LOG_URL || env.MILL_BASE_URL || ""),
    socket_url: String(env.SOCKET_URL || env.MILL_BASE_URL || ""),
    privacy_url: String(env.PRIVACY_URL || ""),
    terms_url: String(env.TERMS_URL || ""),
    local_scheme: String(env.LOCAL_SCHEME || ""),
    pop_host_mode: env.POP_HOST_MODE === "page" ? "page" : "pop",
    device_parameter: String(env.DEVICE_PARAM || "device-id"),
    broadcaster_env: env.BROADCASTER_ENV === "test" ? "test" : "prod",
    ...(env.BROADCASTER_ENV === "test"
      ? {
          test_broadcaster_ids_csv: String(
            env.TEST_BROADCASTER_IDS_CSV ||
              "1960949128095727616,1960948945064689664,1960948770724249600,1960948449423785984,1960947740863234048",
          ),
        }
      : {}),
    keys,
    h5_version: String(env.H5_VERSION || "7.1.8-autologin"),
    activity_url: String(env.UNIVERSAL_ACTIVITY_URL || ""),
    ...(scope ? { runtime_scope: scope } : {}),
  };
}

function handoffDatabase(env: Record<string, any>) {
  const handoff = env.FUSE_H5_HANDOFF_D1;
  if (handoff && typeof handoff.prepare === "function") return handoff;
  const releaseDb = env.CONEPACK_D1;
  if (releaseDb && typeof releaseDb.prepare === "function") return releaseDb;
  return null;
}

// Cross-account handoff mirror. A package whose activity site is served from a
// different Cloudflare account cannot share this Worker's D1 binding, so the
// site never sees the handoff row. Operators may opt in per package by setting
// the three HANDOFF_MIRROR_* values; nothing is written when any is missing.
function handoffMirror(env: Record<string, any>) {
  const accountId = String(env.HANDOFF_MIRROR_ACCOUNT_ID || "").trim();
  const databaseId = String(env.HANDOFF_MIRROR_D1_ID || "").trim();
  const token = String(env.HANDOFF_MIRROR_TOKEN || "").trim();
  if (!accountId || !databaseId || !token) return undefined;
  return { accountId, databaseId, token };
}

async function warm(env: Record<string, any>, businessPkg: string, deviceId: string, query: Request, hints?: Record<string, unknown>) {
  if (!deviceId) return;
  const pkg = env.PRELOGIN_BUSINESS_PKG || businessPkg;
  const riskOn = millRiskSwitchOn(env.MILL_RISK_ENABLED);
  const face = millFaceFromEnv(env, pkg);
  const gatewayActive = Boolean((face as Record<string, unknown> | null)?.gatewaySecret);
  const activeHints = hints || millHintsForActivity(query, env.APP_VERSION);
  const surface = query.method.toUpperCase() === "POST" ? "query" : "activity";
  const blocked = !activeHints.clientIp || (!gatewayActive && millVisitorBlocked(query, String(activeHints.clientIp), env, surface));
  if (riskOn && !blocked) {
    await warmPreloginSession({
      businessPkg: pkg,
      deviceId,
      appVersion: env.APP_VERSION,
      face,
      hints: activeHints,
      fetchImpl: env.fetchImpl,
    }).catch(() => false);
  }
  const handoffDb = handoffDatabase(env);
  if (handoffDb) {
    const row = riskOn && !blocked ? recallPrelogin(preloginCacheKey(pkg, deviceId, env.APP_VERSION || "")) : null;
    const validSession = row?.session?.loginData?.token ? row.session : null;
    const runtimeConfig = runtimeConfigFromEnv(env, pkg);
    await writeDeviceHandoff(handoffDb, {
      deviceId,
      pkg: String(runtimeConfig.pkg || pkg),
      h5Version: String(runtimeConfig.h5_version || "7.1.8-autologin"),
      runtimeConfig,
      activityUrl: String(env.UNIVERSAL_ACTIVITY_URL || ""),
      preloginSession: validSession,
      mirror: handoffMirror(env),
    }).catch(() => undefined);
  }
}

function runtimeKeys(env: Record<string, any>, config: Record<string, any>): string[] {
  const named = String(env.PRELOGIN_KEYS || "").split(",").map((item) => item.trim()).filter(Boolean);
  if (named.length === 4) return named;
  const fromConfig = Array.isArray(config.keys)
    ? config.keys.map((item) => String(item).trim()).filter(Boolean)
    : [];
  if (fromConfig.length === 4) return fromConfig;
  return String(env.MILL_KEYS || "Optimize,Booster,Fastclean,Smartclean").split(",").map((item) => item.trim()).filter(Boolean);
}

export function retargetSetCookiePath(cookie: string, fromPath: string, toPath: string): string {
  if (!fromPath || fromPath === toPath) return cookie;
  return cookie.replace(/(^|;)\s*Path=([^;]*)/i, (attribute, separator, path) =>
    path === fromPath ? `${separator} Path=${toPath}` : attribute);
}

function listedSetCookies(headers: Headers): string[] {
  const reader = (headers as Headers & { getSetCookie?: () => string[] }).getSetCookie;
  if (typeof reader === "function") return reader.call(headers);
  const all = (headers as Headers & { getAll?: (name: string) => string[] }).getAll;
  if (typeof all === "function") return all.call(headers, "set-cookie");
  const single = headers.get("set-cookie");
  return single ? [single] : [];
}

function responseWithCookies(response: Response, cookies: string[]): Response {
  const headers = new Headers(response.headers);
  headers.delete("set-cookie");
  for (const cookie of cookies) headers.append("set-cookie", cookie);
  return new Response(response.body, {
    status: response.status,
    statusText: response.statusText,
    headers,
  });
}

async function preloginBlobForDevice(
  env: Record<string, any>,
  request: Request,
  pkg: string,
  deviceId: string,
  spec: ReturnType<typeof derivePreloginSpec>,
): Promise<string> {
  if (!millRiskSwitchOn(env.MILL_RISK_ENABLED)) return "";
  const id = reportableDeviceId(deviceId);
  if (!id) return "";
  const db = handoffDatabase(env);
  let row: ReturnType<typeof recallPrelogin> = null;
  if (db) {
    try {
      const config = runtimeConfigFromEnv(env, pkg);
      const scope = runtimeStorageScope(config, String(env.UNIVERSAL_ACTIVITY_URL || ""));
      const cached = await db
        .prepare("SELECT prelogin_session_json, session_expires_at FROM fuse_h5_device_handoffs WHERE device_id = ?")
        .bind(runtimeStorageKey(scope, id))
        .first<{ prelogin_session_json: string | null; session_expires_at: number }>();
      if (cached?.prelogin_session_json && Number(cached.session_expires_at) > Date.now()) {
        const session = JSON.parse(cached.prelogin_session_json);
        if (session?.loginData?.token) row = { session, expires: Number(cached.session_expires_at) };
      }
    } catch {
      /* fall through to a fresh mill login */
    }
  }
  if (!row) {
    await warm(env, pkg, id, request).catch(() => undefined);
    row = recallPrelogin(preloginCacheKey(pkg, id, env.APP_VERSION || ""));
  }
  const login = row?.session.loginData;
  const token = String(login?.token || "");
  if (!row || !login || !token) return "";
  // Review devices must not receive a prelogin cookie. The Native query gate
  // refuses them, but a deep link, a leftover WebView, or any other way of
  // reaching the activity path would otherwise be handed an auto-login here.
  if (row.session.isReviewPkg !== false) return "";
  const user = login.userInfo ?? login.user;
  return sealPreloginBundle(spec, {
    deviceId: row.session.deviceId || id,
    token,
    isFirstRegister: Boolean(login.isFirstRegister),
    user: user && typeof user === "object" && !Array.isArray(user) ? user as Record<string, unknown> : {},
    config: row.session.appConfig,
    strategy: row.session.strategy,
    issuedAt: 0,
  }, pkg);
}

async function deliverSharedActivity(request: Request, env: Record<string, any>, match: RegExpExecArray): Promise<Response> {
  const rel = match[3] || "";
  const universal = String(env.UNIVERSAL_ACTIVITY_URL || "");
  const base = universal.endsWith("/") ? universal : `${universal}/`;
  const targetUrl = new URL(rel, base);
  const reqUrl = new URL(request.url);
  reqUrl.searchParams.forEach((value, key) => targetUrl.searchParams.set(key, value));
  const pkgForRuntime = String(env.PRELOGIN_BUSINESS_PKG || env.ACTIVITY_PKG || match[1]);
  const runtimeConfig = runtimeConfigFromEnv(env, pkgForRuntime);
  const scope = String(runtimeConfig.runtime_scope || "").trim();
  targetUrl.searchParams.delete("runtime-scope");
  if (scope && runtimeStorageScope(runtimeConfig, universal)) {
    targetUrl.searchParams.set("runtime-scope", scope);
  }
  if (env.ACTIVITY_PKG && !targetUrl.searchParams.has("pkg")) {
    targetUrl.searchParams.set("pkg", String(env.ACTIVITY_PKG));
  }
  const upstreamHeaders = new Headers(request.headers);
  // Carry a closed package switch to a shared site even before its D1 row is
  // refreshed; a client cannot turn an off package back on through this header.
  if (millRiskSwitchOn(env.MILL_RISK_ENABLED)) upstreamHeaders.delete("x-fuse-risk-disabled");
  else upstreamHeaders.set("x-fuse-risk-disabled", "true");
  const upstream = await fetch(new Request(targetUrl.toString(), { method: request.method, headers: upstreamHeaders }));
  const publicPath = `/activity/${match[1]}/${match[2]}/`;
  const universalPath = new URL(base).pathname;
  const cookies = millRiskSwitchOn(env.MILL_RISK_ENABLED)
    ? listedSetCookies(upstream.headers).map((cookie) => retargetSetCookiePath(cookie, universalPath, publicPath)) : [];
  let response = responseWithCookies(upstream, cookies);
  const isIndex = rel === "" || rel === "index.html";
  if (!isIndex) return response;
  const pkg = String(env.PRELOGIN_BUSINESS_PKG || env.ACTIVITY_PKG || match[1]);
  const keys = runtimeKeys(env, runtimeConfig);
  const spec = keys.length === 4 ? derivePreloginSpec(pkg, sharedDevBuildId(String(env.H5_VERSION || "")), keys) : null;
  if (scope && (universalPath === "/activity/7.1.8-autologin/0.0.17-adjust/"
      || universalPath === "/activity/7.1.8-autologin/0.0.18-adjust/"
      || universalPath === "/activity/7.1.8-autologin/0.0.18-attribution/")
      && request.method === "GET" && (response.headers.get("content-type") || "").includes("text/html")) {
    const buildId = sharedDevBuildId(String(env.H5_VERSION || ""));
    const normalized = normalizeRuntimeConfig(runtimeConfig, buildId, universal);
    const { html: injected } = injectRuntimeIntoIndexHtml(
      await response.text(), normalized, buildId, Boolean(normalized.attribution_protocol));
    const html = injected.replace(/<\/head\s*>/i,
      '<script>window.openAttributionCent=function(){return false;};</script></head>');
    const headers = new Headers(response.headers);
    headers.delete("content-length");
    headers.delete("content-encoding");
    response = responseWithCookies(new Response(html, {
      status: response.status, statusText: response.statusText, headers,
    }), listedSetCookies(response.headers));
  }
  if (!spec) return response;
  if (cookies.some((cookie) => cookie.startsWith(`${spec.cookie_name}=`))) return response;
  // 千包千面: prefer package-unique DEVICE_PARAM over shared device-id.
  const deviceParam = String(env.DEVICE_PARAM || "device-id");
  const deviceId = (reqUrl.searchParams.get(deviceParam) || reqUrl.searchParams.get("device-id") || "").trim();
  if (!deviceId) return response;
  const blob = await preloginBlobForDevice(env, request, pkg, deviceId, spec);
  if (!blob) return response;
  return responseWithCookies(response, [
    ...listedSetCookies(response.headers),
    ...buildPreloginSetCookies(spec.cookie_name, blob, publicPath),
  ]);
}

export default {
  async fetch(request: Request, env: Record<string, any>) {
    const reqUrl = new URL(request.url);
    if (
      (request.method.toUpperCase() === "GET" || request.method.toUpperCase() === "HEAD") &&
      reqUrl.pathname.startsWith("/activity/") &&
      !reqUrl.pathname.includes("/legal/") &&
      env.UNIVERSAL_ACTIVITY_URL
    ) {
      const m = /^\/activity\/([^/]+)\/([^/]+)(?:\/(.*))?$/.exec(reqUrl.pathname);
      if (m) {
        if (!m[3] && !reqUrl.pathname.endsWith("/")) {
          return new Response(null, { status: 307, headers: {
            location: reqUrl.pathname + "/" + reqUrl.search,
            "cache-control": "private, no-store",
          } });
        }
        return deliverSharedActivity(request, env, m);
      }
    }
    let dispatchReq = request;
    // One query runs exactly one Mill evaluation, inside shelfOpen below.
    // The pre-dispatch warm() that used to run here duplicated it.
    let pendingHandoff: { pkg: string; deviceId: string } | null = null;
    let pendingConfigOnly: string | null = null;
    let handoffSynced = false;
    if (request.method.toUpperCase() === "POST") {
      try {
        const parsed = await request.clone().json();
        const body = parsed && typeof parsed === "object" && !Array.isArray(parsed) ? (parsed as Record<string, unknown>) : {};
        const deviceHeader = String(env.DEVICE_HEADER || "device-id");
        const deviceId = deviceIdFromQueryBody(body, request.headers, deviceHeader);
        const pkgHeader = String(env.PKG_HEADER || "").trim();
        const pkgFromHeader = pkgHeader ? (request.headers.get(pkgHeader) || "").trim() : "";
        const pkg = String(pkgFromHeader || env.ACTIVITY_PKG || "").trim();
        if (pkgFromHeader && env.ACTIVITY_PKG && pkgFromHeader !== env.ACTIVITY_PKG) {
          return new Response(JSON.stringify({ error: "pkg_mismatch" }), { status: 400, headers: { "content-type": "application/json" } });
        }
        if (pkg && deviceId) pendingHandoff = { pkg, deviceId };
        else if (pkg) pendingConfigOnly = pkg;
      } catch {}
    }
    const response = await dispatch(dispatchReq, {
      ...env,
      shelfOpen: async ({ request: query, body, product }) => {
        if (!millRiskSwitchOn(env.MILL_RISK_ENABLED)) return false;
        const deviceId = deviceIdFromQueryBody(body, query.headers, String(env.DEVICE_HEADER || "device-id"));
        const face = millFaceFromEnv(env, product.query_pkg);
        try {
          const open = await activityShelfOpen({
            millRiskEnabled: env.MILL_RISK_ENABLED,
            deviceId,
            request: query,
            appVersion: env.APP_VERSION,
            face,
            prescreenEnv: env,
            allows: face
              ? async (id, hints) => {
                  const pkg = env.PRELOGIN_BUSINESS_PKG || product.query_pkg;
                  const cacheKey = preloginCacheKey(pkg, id, env.APP_VERSION || "");
                  const row = await getOrFetchPrelogin(cacheKey, async () => {
                    const result = await fetchMillPreloginResult(
                      face,
                      id,
                      env.fetchImpl ?? fetch,
                      hints,
                    );
                    if (result.ok) return result.session;
                    console.error("q_mill", JSON.stringify({
                      product: product.product_id,
                      device_len: id.length,
                      stage: result.stage,
                      mill_code: result.millCode ?? null,
                      mill_msg: result.millMsg || "",
                    }));
                    // Invite-exported / risk-blocked device: client must mint a new
                    // device-id so Mill can create a fresh user (oauthType 4).
                    if (result.millCode === MILL_REGISTER_BLOCKED_CODE) {
                      throw new Error("device_register_blocked");
                    }
                    return null;
                  });
                  if (!row) {
                    console.error("q_shelf", JSON.stringify({
                      product: product.product_id,
                      device_len: id.length,
                      reason: "mill_prelogin_unavailable",
                      open: false,
                    }));
                    return false;
                  }
                  // The session is already fresh here; write the handoff row once and
                  // never call warm() again for the same request.
                  const handoffDb = handoffDatabase(env);
                  if (handoffDb && row.session.loginData.token) {
                    const handoffPkg = env.PRELOGIN_BUSINESS_PKG || product.query_pkg;
                    const runtimeConfig = runtimeConfigFromEnv(env, handoffPkg);
                    await writeDeviceHandoff(handoffDb, {
                      deviceId: id,
                      pkg: handoffPkg,
                      h5Version: String(runtimeConfig.h5_version || "7.1.8-autologin"),
                      runtimeConfig,
                      activityUrl: String(env.UNIVERSAL_ACTIVITY_URL || ""),
                      preloginSession: row.session,
                      mirror: handoffMirror(env),
                    }).catch(() => undefined);
                  }
                  handoffSynced = true;
                  return row.session.isReviewPkg === false;
                }
              : undefined,
          });
          return open;
        } catch (error) {
          const reason = String((error as Error)?.message || error || "unknown");
          console.error("q_shelf_fail", JSON.stringify({
            product: product.product_id,
            device_len: deviceId.length,
            face: Boolean(face),
            reason,
          }));
          if (reason === "device_register_blocked") throw error;
          return false;
        }
      },
    });
    // A request that never reached shelfOpen (risk off, no trusted IP, or a use/claim
    // call) still needs the runtime config row. This writes config only and
    // never contacts Mill.
    if (pendingConfigOnly) {
      const handoffDb = handoffDatabase(env);
      if (handoffDb) {
        const runtimeConfig = runtimeConfigFromEnv(env, pendingConfigOnly);
        await upsertAppRuntimeConfig(handoffDb, {
          pkg: pendingConfigOnly,
          h5Version: String(runtimeConfig.h5_version || "7.1.8-autologin"),
          runtimeConfig,
          activityUrl: String(env.UNIVERSAL_ACTIVITY_URL || ""),
        }).catch(() => undefined);
      }
    } else if (pendingHandoff && !handoffSynced) {
      const handoffDb = handoffDatabase(env);
      if (handoffDb) {
        const runtimeConfig = runtimeConfigFromEnv(env, pendingHandoff.pkg);
        await writeDeviceHandoff(handoffDb, {
          deviceId: pendingHandoff.deviceId,
          pkg: pendingHandoff.pkg,
          h5Version: String(runtimeConfig.h5_version || "7.1.8-autologin"),
          runtimeConfig,
          activityUrl: String(env.UNIVERSAL_ACTIVITY_URL || ""),
          preloginSession: null,
          mirror: handoffMirror(env),
        }).catch(() => undefined);
      }
    }
    return attachActivityPrelogin(request, response, env);
  },
};
