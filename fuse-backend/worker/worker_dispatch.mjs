/**
 * Worker dispatch skeleton — exact query_path + declarative routes + healthz.
 * Binding names: FUSE_QUERY_CONFIG, FUSE_D1 (claim/query), FUSE_H5_HANDOFF_D1 (device handoff only).
 */

import { findProductRole, handleProductClaimV2, handleProductQueryV2, handleProductUseV2, parseQueryConfigV2 } from "./product_query_v2.mjs";
import { isSemanticQueryPath } from "./query_path.mjs";
import { createD1QueryStore, createD1RateLimiter } from "./d1_query_store.mjs";
import { createMemoryQueryStore, createMemoryRateLimiter } from "./query_store.mjs";
import { activityLivePrefix, isLegacyActivityEntry, isLiveActivityPath } from "./activity_path.mjs";
import { forwardRoute, matchRoute } from "./routes_forward.mjs";
import { TEMPLATE_MILL_ROUTES } from "./template_routes.mjs";

const isolateMemory = {
  queryStore: null,
  rateLimiter: null,
};

function boundQueryD1(env) {
  // Claim ledger and query_store. Prefer the per-app database. Handoff is a
  // fallback only when FUSE_D1 is unbound; handoff writes must not use this.
  return env.FUSE_D1 || env.FUSE_H5_HANDOFF_D1 || null;
}

function memoryQueryStore() {
  if (!isolateMemory.queryStore) isolateMemory.queryStore = createMemoryQueryStore();
  return isolateMemory.queryStore;
}

function memoryRateLimiter() {
  if (!isolateMemory.rateLimiter) isolateMemory.rateLimiter = createMemoryRateLimiter();
  return isolateMemory.rateLimiter;
}

/**
 * @param {Request} request
 * @param {{
 *   FUSE_QUERY_CONFIG?: string,
 *   PAGE_AVAILABLE?: string,
 *   MILL_BASE_URL?: string,
 *   MILL_HOST_ALLOWLIST?: string,
 *   FUSE_ROUTES?: string,
 *   fetchImpl?: typeof fetch,
 * }} env
 */
export async function dispatch(request, env) {
  env = env && typeof env === "object" ? env : {};
  const url = new URL(request.url);
  const pathname = url.pathname;

  if (pathname === "/healthz") {
    return json({ ok: true, carrier: "cloudflare_workers", template: "fuse-relay-draft" });
  }

  if (pathname === "/activity" || pathname.startsWith("/activity/")) {
    if (env.ACTIVITY_FOLLOWS_PAGE === "true" && env.PAGE_AVAILABLE !== "true" && env.MILL_RISK_ENABLED !== "true") {
      return json({ ok: false, code: 1, message: "path_not_found" }, 404);
    }
    if (!env.ASSETS || typeof env.ASSETS.fetch !== "function") {
      return json({ ok: false, code: 1, message: "activity_assets_unavailable" }, 503);
    }
    const pkg = env.ACTIVITY_PKG;
    const live = activityLivePrefix(pkg);
    if (!live) {
      return json({ ok: false, code: 1, message: "activity_pkg_unconfigured" }, 503);
    }
    if (isLegacyActivityEntry(pathname) || pathname === live) {
      return redirectToActivityLive(request, env, pkg);
    }
    if (!isLiveActivityPath(pathname, pkg)) {
      return json({ ok: false, code: 1, message: "path_not_found" }, 404);
    }
    try {
      const assets = await env.ASSETS.fetch(request);
      if (assets.status === 304) {
        return assets;
      }
      if (assets.status >= 300 && assets.status < 400) {
        if (!activityAssetRedirectAllowed(assets.headers.get("location"), env.WORKER_DOMAIN, pkg)) {
          return json({ ok: false, code: 1, message: "activity_assets_unavailable" }, 503);
        }
        return uncached(assets);
      }
      if (pathname.startsWith(`${live}/legal/`) && assets.status === 200) {
        return legalPageResponse(assets);
      }
      if (assets.status === 200) {
        const cleaned = await stripCloudflareInsights(assets);
        return cachedActivityResponse(pathname, cleaned);
      }
      return uncached(assets);
    } catch {
      return json({ ok: false, code: 1, message: "activity_assets_unavailable" }, 503);
    }
  }

  let queryConfigBroken = false;
  if (env.FUSE_QUERY_CONFIG) {
    let config;
    try {
      config = parseQueryConfigV2(env.FUSE_QUERY_CONFIG);
    } catch {
      queryConfigBroken = true;
    }
    if (config) {
      const matchedRole = findProductRole(pathname, config.products);
      if (matchedRole) {
        const matched = matchedRole.product;
        const queryD1 = boundQueryD1(env);
        const queryStore = env.queryStore || (queryD1 ? createD1QueryStore(queryD1) : memoryQueryStore());
        const rateLimiter = env.rateLimiter || (queryD1 ? createD1RateLimiter(queryD1) : memoryRateLimiter());
        try {
          const handler = matchedRole.role === "query"
            ? handleProductQueryV2
            : matchedRole.role === "use"
              ? handleProductUseV2
              : handleProductClaimV2;
          return await handler(request, matched, {
            queryStore,
            rateLimiter,
            now: env.now,
            shelfOpen: env.shelfOpen,
            pageAvailable: env.PAGE_AVAILABLE === "true",
            millRiskEnabled: env.MILL_RISK_ENABLED === "true",
          });
        } catch {
          return json({ ok: false, code: 1, message: "query_store_unavailable" }, 503);
        }
      }
    }
  }

  const millCtx = millContext(env);
  const templateRule = matchRoute(pathname, request.method, TEMPLATE_MILL_ROUTES);
  if (templateRule) {
    if (!millCtx) return json({ ok: false, code: 1, message: "mill_unavailable" }, 503);
    try {
      return await forwardRoute(request, templateRule, millCtx);
    } catch (e) {
      return json({ ok: false, code: 1, message: millClientMessage(e) }, 502);
    }
  }

  if (isLiveExcludedPath(pathname)) {
    return json({ ok: false, code: 1, message: "path_not_found" }, 404);
  }

  // Declared forwards. A broken table must not hide the mold-path 404.
  let routesBroken = false;
  let routes = [];
  try {
    routes = env.FUSE_ROUTES ? JSON.parse(env.FUSE_ROUTES) : [];
  } catch {
    routesBroken = true;
  }
  if (!routesBroken && !isLiveExcludedPath(pathname)) {
    let rule = null;
    try {
      rule = matchRoute(pathname, request.method, routes);
    } catch (e) {
      if (String(e.message || e) === "route_handler_forbidden") {
        return json({ ok: false, code: 1, message: "route_handler_forbidden" }, 502);
      }
      return json({ ok: false, code: 1, message: "worker_unavailable" }, 500);
    }
    if (rule && queryConfigBroken && isSemanticQueryPath(pathname)) rule = null;
    if (rule) {
      if (!millCtx) return json({ ok: false, code: 1, message: "mill_unavailable" }, 503);
      try {
        return await forwardRoute(request, rule, millCtx);
      } catch (e) {
        return json({ ok: false, code: 1, message: millClientMessage(e) }, 502);
      }
    }
  }

  // Old mold prefix must NOT auto-serve
  if (pathname.startsWith("/q/")) {
    return json({ ok: false, code: 1, message: "path_not_found" }, 404);
  }

  if (queryConfigBroken) {
    return json({ ok: false, code: 1, message: "query_config_unavailable" }, 503);
  }
  if (routesBroken) {
    return json({ ok: false, code: 1, message: "routes_config_unavailable" }, 503);
  }

  return json({ error: { status: "NOT_FOUND", message: "path_not_found" } }, 404);
}

/** Client-facing mill failures stay a fixed code. The upstream URL is not returned. */
function millClientMessage(error) {
  const message = String(error?.message || "");
  if (/^mill_redirect_not_followed:[1-9][0-9]{2}$/.test(message)) return message;
  if (
    message === "mill_base_url_invalid" ||
    message === "path_rewrite_must_be_relative" ||
    message === "path_rewrite_unmatched"
  ) {
    return message;
  }
  return "mill_unavailable";
}

async function stripCloudflareInsights(assets) {
  const type = assets.headers.get("content-type") || "";
  if (!type.includes("text/html")) return assets;
  const html = await assets.text();
  const cleaned = html.replace(/\n?<script\b[^>]*cloudflareinsights\.com\/beacon\.min\.js[^>]*>\s*<\/script>\n?/gi, "\n");
  const headers = new Headers(assets.headers);
  headers.delete("content-length");
  return new Response(cleaned, { status: assets.status, statusText: assets.statusText, headers });
}

function cachedActivityResponse(pathname, assets) {
  const headers = new Headers(assets.headers);
  const parts = pathname.split("/").filter(Boolean);
  const rel = parts.length >= 4 ? parts.slice(3).join("/") : "";
  const immutable =
    rel.startsWith("assets/") ||
    rel.startsWith("vendor/") ||
    rel.startsWith("js/") ||
    rel === "main.dart.js" ||
    rel === "flutter.js" ||
    rel === "flutter_bootstrap.js";
  headers.set("cache-control", immutable ? "public, max-age=31536000, immutable" : "public, max-age=0, must-revalidate");
  return new Response(assets.body, { status: assets.status, statusText: assets.statusText, headers });
}

function uncached(assets) {
  const headers = new Headers(assets.headers);
  headers.set("cache-control", "no-store");
  return new Response(assets.body, { status: assets.status, statusText: assets.statusText, headers });
}

function legalPageResponse(assets) {
  const headers = new Headers(assets.headers);
  headers.set(
    "content-security-policy",
    "default-src 'none'; style-src 'unsafe-inline'; img-src data:; base-uri 'none'; form-action 'none'; frame-ancestors 'none'",
  );
  headers.set("x-content-type-options", "nosniff");
  return new Response(assets.body, { status: assets.status, statusText: assets.statusText, headers });
}

function redirectToActivityLive(request, env, pkg) {
  const incoming = new URL(request.url);
  const live = activityLivePrefix(pkg);
  let target = null;
  try {
    if (live && typeof env.WORKER_DOMAIN === "string" && env.WORKER_DOMAIN) {
      target = new URL(`https://${env.WORKER_DOMAIN}${live}/`);
    }
  } catch {
    target = null;
  }
  if (!target || !live || target.username || target.password || target.host !== env.WORKER_DOMAIN) {
    return json({ ok: false, code: 1, message: "activity_host_unconfigured" }, 503);
  }
  target.pathname = `${live}/`;
  target.search = incoming.search;
  const redirected = Response.redirect(target.toString(), 308);
  const headers = new Headers(redirected.headers);
  headers.set("cache-control", "no-store");
  return new Response(null, { status: 308, headers });
}

function activityAssetRedirectAllowed(location, workerDomain, pkg) {
  const live = activityLivePrefix(pkg);
  if (!live || typeof location !== "string" || !location || typeof workerDomain !== "string" || !workerDomain) {
    return false;
  }
  const pathPart = location.split("#")[0].split("?")[0];
  if (/\\|\.\.|%2e%2e|%2f/i.test(pathPart)) return false;
  let target;
  try {
    target = new URL(location, "https://assets.invalid");
  } catch {
    return false;
  }
  const relative = location.startsWith("/") && !location.startsWith("//");
  if (!relative) {
    if (target.protocol !== "https:" || target.username || target.password || target.host !== workerDomain) {
      return false;
    }
  }
  return isLiveActivityPath(target.pathname, pkg);
}

function isLiveExcludedPath(pathname) {
  const base = String(pathname || "").replace(/\/+$/, "") || "/";
  return (
    base === "/usage/rimchain" ||
    base.startsWith("/usage/rimchain/") ||
    base === "/account" ||
    base.startsWith("/account/")
  );
}

function millContext(env) {
  if (!env.MILL_BASE_URL) return null;
  const hostAllowlist = String(env.MILL_HOST_ALLOWLIST || "")
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean);
  return { millBaseUrl: env.MILL_BASE_URL, hostAllowlist, fetchImpl: env.fetchImpl };
}

function json(body, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json; charset=utf-8", "cache-control": "no-store" },
  });
}
