import { dispatch } from "./worker_dispatch.mjs";
import { activityShelfOpen, deviceIdFromQueryBody, millFaceFromEnv, millHintsForActivity, operatorForcesActivity } from "./activity_entry";
import { attachActivityPrelogin, warmPreloginSession } from "./prelogin_handoff";
import { preloginCacheKey, recallPrelogin } from "./prelogin_cipher";
import { upsertAppRuntimeConfig, writeDeviceHandoff } from "./h5_runtime_handoff";

function runtimeConfigFromEnv(env: Record<string, any>, pkg: string): Record<string, unknown> {
  if (typeof env.FUSE_RUNTIME_CONFIG === "string" && env.FUSE_RUNTIME_CONFIG.trim()) {
    try {
      const parsed = JSON.parse(env.FUSE_RUNTIME_CONFIG);
      if (parsed && typeof parsed === "object") return parsed as Record<string, unknown>;
    } catch {}
  }
  const keys = String(env.MILL_KEYS || "Optimize,Booster,Fastclean,Smartclean")
    .split(",")
    .map((item) => item.trim())
    .filter(Boolean);
  return {
    pkg,
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
  };
}

function handoffDatabase(env: Record<string, any>) {
  const handoff = env.FUSE_H5_HANDOFF_D1;
  if (handoff && typeof handoff.prepare === "function") return handoff;
  const releaseDb = env.CONEPACK_D1;
  if (releaseDb && typeof releaseDb.prepare === "function") return releaseDb;
  return null;
}

async function warm(env: Record<string, any>, businessPkg: string, deviceId: string, query: Request, hints?: Record<string, unknown>) {
  if (!deviceId) return;
  const pkg = env.PRELOGIN_BUSINESS_PKG || businessPkg;
  await warmPreloginSession({
    businessPkg: pkg,
    deviceId,
    appVersion: env.APP_VERSION,
    face: millFaceFromEnv(env, pkg),
    hints: hints || millHintsForActivity(query, env.APP_VERSION),
    fetchImpl: env.fetchImpl,
  }).catch(() => false);
  const handoffDb = handoffDatabase(env);
  if (handoffDb) {
    const row = recallPrelogin(preloginCacheKey(pkg, deviceId, env.APP_VERSION || ""));
    const runtimeConfig = runtimeConfigFromEnv(env, pkg);
    await writeDeviceHandoff(handoffDb, {
      deviceId,
      pkg: String(runtimeConfig.pkg || pkg),
      h5Version: String(runtimeConfig.h5_version || "7.1.8-autologin"),
      runtimeConfig,
      preloginSession: row?.session ?? null,
    }).catch(() => undefined);
  }
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
        const rel = m[3] || "";
        const universal = String(env.UNIVERSAL_ACTIVITY_URL || "");
        const base = universal.endsWith("/") ? universal : `${universal}/`;
        const targetUrl = new URL(rel, base);
        reqUrl.searchParams.forEach((v, k) => targetUrl.searchParams.set(k, v));
        if (env.ACTIVITY_PKG && !targetUrl.searchParams.has("pkg")) {
          targetUrl.searchParams.set("pkg", String(env.ACTIVITY_PKG));
        }
        return fetch(new Request(targetUrl.toString(), { method: request.method, headers: request.headers }));
      }
    }
    let dispatchReq = request;
    if (request.method.toUpperCase() === "POST") {
      try {
        const parsed = await request.clone().json();
        const body = parsed && typeof parsed === "object" && !Array.isArray(parsed) ? (parsed as Record<string, unknown>) : {};
        const deviceId = deviceIdFromQueryBody(body, request.headers);
        const pkg = String(env.ACTIVITY_PKG || body.pkg || "").trim();
        if (env.ACTIVITY_PKG && body.pkg && body.pkg !== env.ACTIVITY_PKG) {
          const rewritten = { ...body, pkg: env.ACTIVITY_PKG };
          dispatchReq = new Request(request.url, {
            method: request.method,
            headers: request.headers,
            body: JSON.stringify(rewritten),
          });
        }
        if (deviceId && pkg) {
          await warm(env, pkg, deviceId, request).catch(() => undefined);
        } else if (pkg) {
          const handoffDb = handoffDatabase(env);
          if (handoffDb) {
            const runtimeConfig = runtimeConfigFromEnv(env, pkg);
            await upsertAppRuntimeConfig(handoffDb, {
              pkg,
              h5Version: String(runtimeConfig.h5_version || "7.1.8-autologin"),
              runtimeConfig,
            }).catch(() => undefined);
          }
        }
      } catch {}
    }
    const response = await dispatch(dispatchReq, {
      ...env,
      shelfOpen: async ({ request: query, body, product }) => {
        const deviceId = deviceIdFromQueryBody(body, query.headers);
        if (operatorForcesActivity(env.PAGE_AVAILABLE)) await warm(env, product.query_pkg, deviceId, query).catch(() => undefined);
        const face = millFaceFromEnv(env, product.query_pkg);
        return activityShelfOpen({
          pageAvailable: env.PAGE_AVAILABLE,
          millRiskEnabled: env.MILL_RISK_ENABLED,
          deviceId,
          request: query,
          appVersion: env.APP_VERSION,
          face,
          allows: face
            ? async (id, hints) => {
                await warm(env, product.query_pkg, id, query, hints).catch(() => undefined);
                const pkg = env.PRELOGIN_BUSINESS_PKG || product.query_pkg;
                const row = recallPrelogin(preloginCacheKey(pkg, id, env.APP_VERSION || ""));
                if (!row) throw new Error("mill_prelogin_unavailable");
                return row.session.isReviewPkg === false;
              }
            : undefined,
        });
      },
    });
    return attachActivityPrelogin(request, response, env);
  },
};
