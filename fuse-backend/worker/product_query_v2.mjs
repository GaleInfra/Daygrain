import { clientIp, clientIpv4 } from "./client_ip.mjs";
/**
 * Product query v2 — no Bearer token; semantic query_path; product-scoped rate key.
 * Simplified for template acceptance tests (D1/mill gate left to factory full merge).
 */

import { assertQueryPath, functionPathAllowed, isSemanticQueryPath } from "./query_path.mjs";
import { createMemoryQueryStore, createMemoryRateLimiter } from "./query_store.mjs";

// Slim release query body. 32-hex and 64-hex installation ids are both hex.
// Unknown keys (for example "app") are ignored. Sablier's pkg + 64-hex
// installation_id + optional adid + optional device-id body stays valid.
// installation_id is required. A missing key falls back to device-id unless
// the product sets installation_id_fallback to "off". The default, a missing
// key, and the literal "device_id" all enable that fallback. When it is on
// and the installation_id key is absent, a 32-hex device-id (case-insensitive,
// stored lowercased) becomes the installation id. 64-hex, dashed, empty,
// non-string, and over-long device-id values are not a fallback identity and
// stay installation_id_required. A present installation_id is never replaced,
// even when it is illegal. Sablier's 64-hex body stays valid.
export const SLIM_QUERY_CONTRACT = {"schema":"slim-release-query-body.v1","installation_id_pattern":"^[a-f0-9]{32}$|^[a-f0-9]{64}$","installation_id_flags":"i","ignore_unknown_fields":true,"known_fields":["pkg","installation_id","adid","device-id"]};

const INSTALLATION_ID = new RegExp(
  SLIM_QUERY_CONTRACT.installation_id_pattern,
  SLIM_QUERY_CONTRACT.installation_id_flags,
);
const DEVICE_ID_HEX32 = /^[a-f0-9]{32}$/i;
const PAGE_PROTOCOL_SCHEMA = "appfactory.page_protocol.v1";
const PAGE_PROTOCOL_FIELDS = [
  "page_host",
  "present_param",
  "present_host_value",
  "present_cover_value",
  "url_param",
  "doc_param",
  "browser_host",
];
const PAGE_PROTOCOL_RESERVED = new Set([
  "page",
  "pop",
  "browser",
  "settings",
  "present",
  "url",
  "doc",
  "privacy",
  "terms",
  "support",
  "device",
  "device-id",
  "device_id",
  "pkg",
  "q",
  "p",
  "entry",
  "activity",
]);
const PAGE_WORD = /^[a-z][a-z0-9]{2,11}$/;

/**
 * Validate the package-specific page protocol carried by FUSE_QUERY_CONFIG.
 * Missing means a pre-v11.2.1 package and keeps the legacy Native behavior.
 * Invalid is fail-closed at Worker config parse time, not silently downgraded.
 * @param {unknown} raw
 * @returns {Record<string, string> | undefined}
 */
export function normalizePageProtocolV2(raw) {
  if (raw === undefined || raw === null) return undefined;
  if (typeof raw !== "object" || Array.isArray(raw)) {
    throw new Error("query_config_invalid");
  }
  const block = raw;
  if (block.schema !== undefined && block.schema !== PAGE_PROTOCOL_SCHEMA) {
    throw new Error("query_config_invalid");
  }
  const seen = new Set();
  const parsed = { schema: PAGE_PROTOCOL_SCHEMA };
  for (const field of PAGE_PROTOCOL_FIELDS) {
    const value = block[field];
    if (typeof value !== "string" || !PAGE_WORD.test(value) || PAGE_PROTOCOL_RESERVED.has(value) || seen.has(value)) {
      throw new Error("query_config_invalid");
    }
    seen.add(value);
    parsed[field] = value;
  }
  return parsed;
}

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
    if (products.has(p.product_id) || paths.has(p.query_path)) {
      throw new Error("query_config_invalid");
    }
    products.add(p.product_id);
    paths.add(p.query_path);
    if (p.page_protocol !== undefined) {
      p.page_protocol = normalizePageProtocolV2(p.page_protocol);
      if (p.page_protocol_sha256 !== undefined && !/^[a-f0-9]{64}$/.test(p.page_protocol_sha256)) {
        throw new Error("query_config_invalid");
      }
    } else if (p.page_protocol_sha256 !== undefined) {
      throw new Error("query_config_invalid");
    }
    if (p.route_aliases !== undefined) {
      const aliases = p.route_aliases;
      if (!aliases || typeof aliases !== "object" || Array.isArray(aliases)) {
        throw new Error("query_config_invalid");
      }
      for (const role of Object.keys(aliases)) {
        if (!["query", "use", "claim"].includes(role)) throw new Error("query_config_invalid");
        const list = aliases[role];
        if (!Array.isArray(list)) throw new Error("query_config_invalid");
        for (const alias of list) {
          if (!functionPathAllowed(alias, p.package_slug) || paths.has(alias)) {
            throw new Error("query_config_invalid");
          }
          paths.add(alias);
        }
      }
    }
  }
  return config;
}

function aliasList(row, role) {
  const table = row && row.route_aliases;
  if (!table || typeof table !== "object" || Array.isArray(table)) return [];
  const paths = table[role];
  return Array.isArray(paths) ? paths : [];
}

/**
 * Canonical path wins. An alias uses the same handler as that role.
 * @param {string} pathname
 * @param {QueryProduct[]} products
 * @returns {{ product: QueryProduct, role: "query"|"use"|"claim" } | null}
 */
export function findProductRole(pathname, products) {
  const roles = ["query", "use", "claim"];
  const canonical = {
    query: (row) => row.query_path === pathname,
    use: (row) => row.use_path && row.use_path === pathname,
    claim: (row) => row.claim_path && row.claim_path === pathname,
  };
  for (const role of roles) {
    const product = products.find((row) => canonical[role](row));
    if (product) return { product, role };
  }
  for (const role of roles) {
    const product = products.find((row) => aliasList(row, role).includes(pathname));
    if (product) return { product, role };
  }
  return null;
}

/** Rate-limit key after token removal — Spec FR-3. */
export function productRateKey(productId) {
  return `product:${productId}`;
}

/** Legacy IPv4-only export retained for callers that explicitly request IPv4. */
export function clientIpv4FromHeaders(headers) {
  return clientIpv4(headers);
}

/**
 * Handle POST query without Authorization.
 * @param {Request} req
 * @param {QueryProduct} product
 * @param {{
 *   millRiskEnabled?: boolean | string,
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

  const parsed = await readQueryBody(req, product);
  if (parsed.response) return parsed.response;
  const body = parsed.body;
  if (body.pkg !== product.query_pkg) return jsonFail("product_mismatch", 403);

  if (!Number.isSafeInteger(product.daily_limit) || product.daily_limit < 1) {
    return jsonFail("daily_limit_invalid", 503);
  }

  const now = opts.now ?? Date.now();
  if (!Number.isFinite(now)) return jsonFail("query_clock_invalid", 503);
  // Only the enabled risk path reads the client IP. No public IP returns 200
  // ahead of the store and Mill; disabled risk uses normal business.
  const riskOn = opts.millRiskEnabled === true || opts.millRiskEnabled === "true";
  if (riskOn && !clientIp(req.headers)) {
    return jsonOk(quota(product, 0, now), 200, product);
  }
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
  const used = typeof store.readDaily === "function"
    ? await store.readDaily(product.product_id, body.installation_id, day)
    : 0;
  if (used > product.daily_limit) return jsonFail("daily_limit", 429);
  let open = false;
  if (riskOn && typeof opts.shelfOpen === "function") {
    open = await opts.shelfOpen({ request: req, body, product }) === true;
  }
  const status = open ? product.activity_status : 200;
  const pass = typeof store.claimPass === "function"
    ? await store.claimPass(product.product_id, body.installation_id, day)
    : 1;
  return jsonOk(quota(product, used, now, pass), status, product);
}

/** Consume one unit on the package use path. No Bearer. */
export async function handleProductUseV2(req, product, opts = {}) {
  if (req.method === "OPTIONS") return new Response(null, { status: 204 });
  if (req.method !== "POST") return jsonFail("method_not_allowed", 405);
  const parsed = await readQueryBody(req, product);
  if (parsed.response) return parsed.response;
  const body = parsed.body;
  if (body.pkg !== product.query_pkg) return jsonFail("product_mismatch", 403);
  const now = opts.now ?? Date.now();
  if (!Number.isFinite(now)) return jsonFail("query_clock_invalid", 503);
  const store = opts.queryStore ?? createMemoryQueryStore();
  const day = new Date(now).toISOString().slice(0, 10);
  const used = await store.incrementDaily(product.product_id, body.installation_id, day, product.daily_limit);
  if (used > product.daily_limit) return jsonFail("daily_limit", 429);
  const pass = typeof store.claimPass === "function"
    ? await store.claimPass(product.product_id, body.installation_id, day)
    : 1;
  return jsonOk(quota(product, used, now, pass), 200, product);
}

/** Named claim route. Returns the public quota envelope and does not spend a unit. */
export async function handleProductClaimV2(req, product, opts = {}) {
  if (req.method === "OPTIONS") return new Response(null, { status: 204 });
  if (req.method !== "POST") return jsonFail("method_not_allowed", 405);
  const parsed = await readQueryBody(req, product);
  if (parsed.response) return parsed.response;
  const body = parsed.body;
  if (body.pkg !== product.query_pkg) return jsonFail("product_mismatch", 403);
  const now = opts.now ?? Date.now();
  if (!Number.isFinite(now)) return jsonFail("query_clock_invalid", 503);
  const store = opts.queryStore ?? createMemoryQueryStore();
  const day = new Date(now).toISOString().slice(0, 10);
  if (typeof store.markClaim === "function") await store.markClaim(product.product_id, body.installation_id, day);
  const used = typeof store.readDaily === "function"
    ? await store.readDaily(product.product_id, body.installation_id, day)
    : 0;
  return jsonOk(quota(product, used, now, 0), 200, product);
}

function deviceIdFallbackEnabled(product) {
  return !product || product.installation_id_fallback !== "off";
}

function bindInstallationId(body, product) {
  const raw = body.installation_id;
  if (raw === undefined && deviceIdFallbackEnabled(product)) {
    const device = body["device-id"];
    if (typeof device === "string" && DEVICE_ID_HEX32.test(device)) {
      body.installation_id = device.toLowerCase();
      return null;
    }
    return { response: jsonFail("installation_id_required", 400) };
  }
  if (typeof raw !== "string" || !INSTALLATION_ID.test(raw)) {
    return { response: jsonFail("installation_id_required", 400) };
  }
  body.installation_id = raw.toLowerCase();
  return null;
}

function knownQueryFields(body) {
  if (!SLIM_QUERY_CONTRACT.ignore_unknown_fields) {
    const known = new Set(SLIM_QUERY_CONTRACT.known_fields);
    if (Object.keys(body).some((key) => !known.has(key))) throw new Error("unknown_field");
  }
  const picked = {};
  for (const key of SLIM_QUERY_CONTRACT.known_fields) {
    if (Object.prototype.hasOwnProperty.call(body, key)) picked[key] = body[key];
  }
  return picked;
}

async function readQueryBody(req, product) {
  const limited = await readLimitedBody(req, 4096);
  if (limited.error) return { response: jsonFail(limited.error, 413) };
  try {
    const text = new TextDecoder("utf-8", { fatal: true }).decode(limited.bytes);
    const parsed = JSON.parse(text);
    if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) throw new Error();
    const body = knownQueryFields(parsed);
    const identity = bindInstallationId(body, product);
    if (identity) return identity;
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
  const matched = findProductRole(pathname, products);
  return matched && matched.role === "query" ? matched.product : null;
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

function quota(product, used, now, pass = 1) {
  const date = new Date(now);
  const resetsAt = new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate() + 1)).toISOString().replace(".000Z", "Z");
  const remaining = Math.max(0, product.daily_limit - used);
  const freeClaim = pass === 0 ? 0 : 1;
  return {
    limit: product.daily_limit,
    remaining,
    resetsAt,
    ledger: { pass: freeClaim, left: remaining, cap: product.daily_limit },
  };
}

function jsonOk(data, status, product) {
  const payload = { ok: true, code: 0, request_id: crypto.randomUUID(), data };
  if (product && product.page_protocol) {
    payload.page_protocol = product.page_protocol;
    if (product.page_protocol_sha256) {
      payload.page_protocol_sha256 = product.page_protocol_sha256;
    }
  }
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
