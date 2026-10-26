/**
 * Declarative route forwarder — Spec FR-5.
 * Config only: path / methods / upstream / optional path_rewrite.
 * No custom handler.ts.
 */

import { millFetch } from "./mill_fetch.mjs";

/**
 * @typedef {{ path: string, methods: string[], upstream: string, path_rewrite?: string }} RouteRule
 */

/** A package route is one absolute path. Missing the leading slash would never match a request. */
export function isSafeRoutePath(routePath) {
  return (
    typeof routePath === "string" &&
    routePath.startsWith("/") &&
    !routePath.startsWith("//") &&
    routePath.length > 1 &&
    !routePath.includes("..") &&
    !routePath.includes("\\") &&
    !routePath.includes("?") &&
    !routePath.includes("#") &&
    !routePath.includes(":")
  );
}

const ROUTE_METHODS = new Set(["GET", "HEAD", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"]);

/** Null when a method is missing or not a forwarding method. Callers must not throw on that. */
export function routeMethods(methods) {
  if (!Array.isArray(methods) || methods.length === 0) return null;
  const normalized = [];
  for (const method of methods) {
    if (typeof method !== "string" || !ROUTE_METHODS.has(method.toUpperCase())) return null;
    normalized.push(method.toUpperCase());
  }
  return normalized;
}

/** A path without a trailing slash is exact. A trailing slash is a directory prefix. */
export function routeCoversPath(pathname, routePath) {
  if (!isSafeRoutePath(routePath)) return false;
  const exact = routePath.replace(/\/+$/, "") || "/";
  if (pathname === exact || pathname === routePath) return true;
  return routePath.endsWith("/") && pathname.startsWith(routePath);
}

/**
 * @param {string} pathname
 * @param {string} method
 * @param {RouteRule[]} routes
 */
export function matchRoute(pathname, method, routes) {
  const m = method.toUpperCase();
  for (const rule of routes || []) {
    if (!rule?.path || !Array.isArray(rule.methods)) continue;
    if (!routeCoversPath(pathname, rule.path)) continue;
    if ("handler" in rule && rule.handler != null) {
      throw new Error("route_handler_forbidden");
    }
    const allowed = routeMethods(rule.methods);
    if (!allowed || !allowed.includes(m)) continue;
    return rule;
  }
  return null;
}

/**
 * @param {Request} req
 * @param {RouteRule} rule
 * @param {{ millBaseUrl: string, hostAllowlist: string[], fetchImpl?: typeof fetch }} ctx
 */
export async function forwardRoute(req, rule, ctx) {
  if (rule.upstream !== "mill") {
    throw new Error(`upstream_unsupported:${rule.upstream}`);
  }
  const base = new URL(ctx.millBaseUrl);
  if (base.pathname !== "/" || base.search || base.hash || base.username || base.password) {
    throw new Error("mill_base_url_invalid");
  }
  if (!ctx.hostAllowlist.includes(base.host)) {
    throw new Error(`upstream_host_not_allowlisted:${base.host}`);
  }
  const inbound = new URL(req.url);
  let targetPath = inbound.pathname + inbound.search;
  if (rule.path_rewrite) {
    if (!isRelativeRewrite(rule.path_rewrite)) throw new Error("path_rewrite_must_be_relative");
    const rewritten = rewritePathPrefix(inbound.pathname, rule.path, rule.path_rewrite);
    if (!rewritten) throw new Error("path_rewrite_unmatched");
    targetPath = rewritten + inbound.search;
  }
  if (/^[a-z][a-z0-9+.-]*:/i.test(targetPath) || targetPath.startsWith("//")) {
    throw new Error("path_rewrite_must_be_relative");
  }
  const target = new URL(targetPath.replace(/^\//, ""), `${base.origin}/`);
  if (target.protocol !== "https:" || target.username || target.password || target.host !== base.host || !ctx.hostAllowlist.includes(target.host)) {
    throw new Error(`upstream_host_not_allowlisted:${target.host || target.protocol}`);
  }
  const headers = millRequestHeaders(req.headers);
  const upstream = await millFetch(target.toString(), {
    method: req.method,
    headers,
    body: req.method === "GET" || req.method === "HEAD" ? undefined : req.body,
    fetchImpl: ctx.fetchImpl,
  });
  return millResponse(upstream);
}

/** A decoded mill body must not keep gzip framing, a mismatched length, or mill cookies. */
function millResponse(res) {
  const headers = forwardHeaders(res.headers);
  headers.delete("content-encoding");
  headers.delete("set-cookie");
  const headOnly = res.status === 204 || res.status === 205 || res.status === 304;
  return new Response(headOnly ? null : res.body, {
    status: res.status,
    statusText: res.statusText,
    headers,
  });
}

/** Rewrite only the path prefix. The query string is copied unchanged. */
function rewritePathPrefix(pathname, rulePath, rewrite) {
  const ruleExact = rulePath.replace(/\/+$/, "") || "/";
  const rulePrefix = rulePath.endsWith("/") ? rulePath : `${rulePath}/`;
  const rewriteExact = rewrite.replace(/\/+$/, "") || "/";
  const rewritePrefix = rewrite.endsWith("/") ? rewrite : `${rewrite}/`;
  if (pathname === ruleExact) return rewriteExact;
  if (pathname === rulePath) return rewrite.endsWith("/") ? rewrite : rewriteExact;
  if (pathname.startsWith(rulePrefix)) return rewritePrefix + pathname.slice(rulePrefix.length);
  return null;
}

const HOP_BY_HOP = [
  "connection",
  "keep-alive",
  "proxy-authenticate",
  "proxy-authorization",
  "te",
  "trailer",
  "trailers",
  "transfer-encoding",
  "upgrade",
  "host",
  "content-length",
];

const CLIENT_PROXY_HEADERS = [
  "forwarded",
  "x-forwarded-for",
  "x-forwarded-host",
  "x-forwarded-proto",
  "x-forwarded-port",
  "via",
  "cookie",
];

/** Client-supplied proxy headers must not tell mill which host the user used. */
function millRequestHeaders(source) {
  const headers = forwardHeaders(source);
  for (const name of CLIENT_PROXY_HEADERS) headers.delete(name);
  return headers;
}

/** Drop hop-by-hop headers so a mismatched length or chunked framing is not sent upstream. */
export function forwardHeaders(source) {
  const headers = new Headers(source);
  const named = headers.get("connection");
  for (const name of HOP_BY_HOP) headers.delete(name);
  if (named) {
    for (const part of named.split(",")) {
      const name = part.trim();
      if (name) headers.delete(name);
    }
  }
  return headers;
}

function isRelativeRewrite(value) {
  return (
    typeof value === "string" &&
    value.startsWith("/") &&
    !value.startsWith("//") &&
    !value.includes(":") &&
    !value.includes("\\")
  );
}
