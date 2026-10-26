/**
 * Product query v2 — no Bearer token; semantic query_path; product-scoped rate key.
 * Simplified for template acceptance tests (D1/mill gate left to factory full merge).
 */

import { assertQueryPath, functionPathAllowed, isSemanticQueryPath } from "./query_path.mjs";
import { createMemoryQueryStore, createMemoryRateLimiter } from "./query_store.mjs";

/**
 * @typedef {{
 *   product_id: string,
 *   query_pkg: string,
 *   query_path: string,
 *   activity_status: number,
 *   allocation_version: number,
 *   default_state: "native"|"activity",
 *   activity_url_digest: string,
 *   daily_limit: number,
 * }} QueryProduct
 */

/**
 * @param {string} raw
 * @returns {{ schema_version: string, revision: string, allocation_version: number, products: QueryProduct[] }}
 */
export function parseQueryConfigV2(raw) {
  const config = JSON.parse(raw);
  if (
    !config ||
    config.schema_version !== "fuse-query-config-v2" ||
    typeof config.revision !== "string" ||
    !config.revision.trim() ||
    !Number.isSafeInteger(config.allocation_version) ||
    config.allocation_version < 1 ||
    !Array.isArray(config.products) ||
    !config.products.length
  ) {
    throw new Error("query_config_invalid");
  }
  const products = new Set();
  const paths = new Set();
  const statuses = new Set();
  for (const p of config.products) {
    if (!p || typeof p.product_id !== "string" || !p.product_id) throw new Error("query_config_invalid");
    if (typeof p.query_pkg !== "string" || !p.query_pkg) throw new Error("query_config_invalid");
    assertQueryPath(p.query_path);
    if (!functionPathAllowed(p.query_path, p.package_slug)) throw new Error("query_config_invalid");
    if (!Number.isInteger(p.activity_status) || p.activity_status < 460 || p.activity_status > 498) {
      throw new Error("query_config_invalid");
    }
    if (!["native", "activity"].includes(p.default_state)) throw new Error("query_config_invalid");
    for (const key of ["use_path", "claim_path"]) {
      if (p[key] === undefined) continue;
      if (!functionPathAllowed(p[key], p.package_slug) || p[key] === p.query_path) {
        throw new Error("query_config_invalid");
      }
      if (paths.has(p[key])) throw new Error("query_config_invalid");
      paths.add(p[key]);
    }
    if (!Number.isSafeInteger(p.daily_limit) || p.daily_limit < 1) throw new Error("query_config_invalid");
    if (products.has(p.product_id) || paths.has(p.query_path) || statuses.has(p.activity_status)) {
      throw new Error("query_config_invalid");
    }
    products.add(p.product_id);
    paths.add(p.query_path);
    statuses.add(p.activity_status);
  }
  return config;
}

/** Rate-limit key after token removal — Spec FR-3. */
export function productRateKey(productId) {
  return `product:${productId}`;
}

const IPV4 = /^(?:(?:25[0-5]|2[0-4]\d|1?\d?\d)\.){3}(?:25[0-5]|2[0-4]\d|1?\d?\d)$/;

/**
 * Same reader as vendor/fuse-relay/src/client_ip.ts.
 * CF-Connecting-IP when it is IPv4; otherwise the first IPv4 in X-Forwarded-For.
 * IPv6-only, missing, empty, and malformed headers are no IPv4.
 * @param {Headers} headers
 */
export function clientIpv4FromHeaders(headers) {
  const cf = String(headers.get("CF-Connecting-IP") || "").trim();
  if (IPV4.test(cf)) return cf;
  const forwarded = headers.get("X-Forwarded-For") || "";
  for (const part of forwarded.split(",")) {
    const candidate = part.trim();
    if (IPV4.test(candidate)) return candidate;
  }
  return "";
}

/**
 * Handle POST query without Authorization.
 * @param {Request} req
 * @param {QueryProduct} product
 * @param {{
 *   openActivity?: boolean,
 *   pageAvailable?: boolean,
 *   millRiskEnabled?: boolean,
 *   queryStore?: ReturnType<typeof createMemoryQueryStore>,
 *   rateLimiter?: ReturnType<typeof createMemoryRateLimiter>,
 *   now?: number,
 *   shelfOpen?: (ctx: { request: Request, body: object, product: QueryProduct }) => Promise<boolean>,
 * }} [opts]
 */
export async function handleProductQueryV2(req, product, opts = {}) {
  if (req.method === "OPTIONS") return new Response(null, { status: 204 });
  if (req.method !== "POST") {
    return jsonFail("method_not_allowed", 405);
  }
  // Explicitly ignore Bearer — template must not require it.
  void req.headers.get("authorization");

  const limited = await readLimitedBody(req, 4096);
  if (limited.error) return jsonFail(limited.error, 413);
  let body;
  try {
    const text = new TextDecoder("utf-8", { fatal: true }).decode(limited.bytes);
    body = JSON.parse(text);
    if (!body || typeof body !== "object" || Array.isArray(body)) throw new Error();
    if (Object.keys(body).some((k) => !["pkg", "installation_id", "adid", "device-id"].includes(k))) {
      throw new Error();
    }
  } catch {
    return jsonFail("invalid_json", 400);
  }
  if (body.pkg !== product.query_pkg) return jsonFail("product_mismatch", 403);
  if (typeof body.installation_id !== "string" || !/^[a-f0-9]{64}$/i.test(body.installation_id)) {
    return jsonFail("installation_id_required", 400);
  }
  body.installation_id = body.installation_id.toLowerCase();
  if (body.adid !== undefined && typeof body.adid !== "string") return jsonFail("invalid_json", 400);
  if (body["device-id"] !== undefined) {
    if (typeof body["device-id"] !== "string" || body["device-id"].length > 256) {
      return jsonFail("device_id_invalid", 400);
    }
  }

  if (!Number.isSafeInteger(product.daily_limit) || product.daily_limit < 1) {
    return jsonFail("daily_limit_invalid", 503);
  }

  const now = opts.now ?? Date.now();
  if (!Number.isFinite(now)) return jsonFail("query_clock_invalid", 503);
  // No IPv4 is decided after structural checks and before D1 / Mill.
  // MILL_RISK_ENABLED (boolean true, already coerced from the env string)
  // opens the activity page and does not read the D1 decision, so a stored
  // `failure` does not 403. Switch off, false, or unset stays on the native
  // page below: D1 `failure` is still 403, and an activity decision does not
  // open or call Mill. PAGE_AVAILABLE=true is unchanged and still forces open
  // after the D1 read. IPv4 keeps the existing D1 and Mill path.
  const noIpv4 = !clientIpv4FromHeaders(req.headers);
  if (opts.pageAvailable !== true && noIpv4 && opts.millRiskEnabled === true) {
    return jsonOk(quota(product, 0, now), product.activity_status);
  }
  const noIpv4HoldNative = opts.pageAvailable !== true && noIpv4;
  const limiter = opts.rateLimiter ?? createMemoryRateLimiter();
  const installHits = await limiter.hit(
    `install:${product.product_id}:${body.installation_id}`,
    now,
    60_000,
    60,
  );
  if (installHits > 60) return jsonFail("rate_limited", 429);

  const store = opts.queryStore ?? createMemoryQueryStore();
  let decision = await store.getDecision(product.product_id, body.installation_id);
  if (decision === "failure") return jsonFail("business_denied", 403);
  const productHits = await limiter.hit(productRateKey(product.product_id), now, 60_000, 600);
  if (productHits > 600) return jsonFail("rate_limited", 429);
  if (!decision) {
    decision = product.default_state === "activity" ? "activity" : "native";
    await store.putDecision(product.product_id, body.installation_id, decision, now);
  }

  const day = new Date(now).toISOString().slice(0, 10);
  const used = await store.incrementDaily(product.product_id, body.installation_id, day, product.daily_limit);
  if (used > product.daily_limit) return jsonFail("daily_limit", 429);
  let open = decision === "activity";
  if (opts.pageAvailable === true) {
    open = true;
  } else if (noIpv4HoldNative) {
    open = false;
  } else if (opts.millRiskEnabled === true && typeof opts.shelfOpen === "function") {
    open = await opts.shelfOpen({ request: req, body, product }) === true;
  } else if (open && typeof opts.shelfOpen === "function") {
    open = await opts.shelfOpen({ request: req, body, product }) === true;
  }
  const status = open ? product.activity_status : 200;
  return jsonOk(quota(product, used, now), status);
}

/** Consume one unit on the package use path. No Bearer. */
export async function handleProductUseV2(req, product, opts = {}) {
  if (req.method === "OPTIONS") return new Response(null, { status: 204 });
  if (req.method !== "POST") return jsonFail("method_not_allowed", 405);
  const parsed = await readQueryBody(req);
  if (parsed.response) return parsed.response;
  const body = parsed.body;
  if (body.pkg !== product.query_pkg) return jsonFail("product_mismatch", 403);
  const now = opts.now ?? Date.now();
  if (!Number.isFinite(now)) return jsonFail("query_clock_invalid", 503);
  const store = opts.queryStore ?? createMemoryQueryStore();
  const day = new Date(now).toISOString().slice(0, 10);
  const used = await store.incrementDaily(product.product_id, body.installation_id, day, product.daily_limit);
  if (used > product.daily_limit) return jsonFail("daily_limit", 429);
  return jsonOk(quota(product, used, now), 200);
}

/** Named claim route. Returns the public quota envelope and does not spend a unit. */
export async function handleProductClaimV2(req, product, opts = {}) {
  if (req.method === "OPTIONS") return new Response(null, { status: 204 });
  if (req.method !== "POST") return jsonFail("method_not_allowed", 405);
  const parsed = await readQueryBody(req);
  if (parsed.response) return parsed.response;
  const body = parsed.body;
  if (body.pkg !== product.query_pkg) return jsonFail("product_mismatch", 403);
  const now = opts.now ?? Date.now();
  if (!Number.isFinite(now)) return jsonFail("query_clock_invalid", 503);
  return jsonOk(quota(product, 0, now), 200);
}

async function readQueryBody(req) {
  const limited = await readLimitedBody(req, 4096);
  if (limited.error) return { response: jsonFail(limited.error, 413) };
  try {
    const text = new TextDecoder("utf-8", { fatal: true }).decode(limited.bytes);
    const body = JSON.parse(text);
    if (!body || typeof body !== "object" || Array.isArray(body)) throw new Error();
    if (Object.keys(body).some((k) => !["pkg", "installation_id", "adid", "device-id"].includes(k))) {
      throw new Error();
    }
    if (typeof body.installation_id !== "string" || !/^[a-f0-9]{64}$/i.test(body.installation_id)) {
      return { response: jsonFail("installation_id_required", 400) };
    }
    body.installation_id = body.installation_id.toLowerCase();
    if (body.adid !== undefined && typeof body.adid !== "string") throw new Error();
    if (body["device-id"] !== undefined && (typeof body["device-id"] !== "string" || body["device-id"].length > 256)) {
      return { response: jsonFail("device_id_invalid", 400) };
    }
    return { body };
  } catch {
    return { response: jsonFail("invalid_json", 400) };
  }
}

/**
 * Resolve product by exact pathname (not /q/ prefix).
 * @param {string} pathname
 * @param {QueryProduct[]} products
 */
export function findProductByPath(pathname, products) {
  return products.find((p) => p.query_path === pathname) ?? null;
}

/** Stop reading once the query body passes the byte cap. */
export async function readLimitedBody(req, max) {
  const declared = req.headers.get("content-length");
  if (declared !== null && /^(0|[1-9][0-9]*)$/.test(declared) && Number(declared) > max) {
    try {
      await req.body?.cancel();
    } catch {
      /* the caller still gets the size error */
    }
    return { error: "body_too_large" };
  }
  if (!req.body) return { bytes: new Uint8Array() };
  const reader = req.body.getReader();
  const chunks = [];
  let total = 0;
  for (;;) {
    const { done, value } = await reader.read();
    if (done) break;
    total += value.byteLength;
    if (total > max) {
      try {
        await reader.cancel();
      } catch {
        /* already over the cap */
      }
      return { error: "body_too_large" };
    }
    chunks.push(value);
  }
  const bytes = new Uint8Array(total);
  let offset = 0;
  for (const chunk of chunks) {
    bytes.set(chunk, offset);
    offset += chunk.byteLength;
  }
  return { bytes };
}

function quota(product, used, now) {
  const date = new Date(now);
  const resetsAt = new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate() + 1)).toISOString();
  return {
    limit: product.daily_limit,
    remaining: Math.max(0, product.daily_limit - used),
    resetsAt,
  };
}

function jsonOk(data, status) {
  const payload = { ok: true, code: 0, request_id: crypto.randomUUID(), data };
  return new Response(JSON.stringify(payload), {
    status,
    headers: { "content-type": "application/json; charset=utf-8", "cache-control": "no-store" },
  });
}

function jsonFail(message, status) {
  return new Response(JSON.stringify({ ok: false, code: 1, request_id: crypto.randomUUID(), message }), {
    status,
    headers: { "content-type": "application/json; charset=utf-8", "cache-control": "no-store" },
  });
}

export { isSemanticQueryPath };
