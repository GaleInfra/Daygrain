// ../../../../work/daygrain-fuse-af-20261118/product/fuse-backend/worker/client_ip.mjs
import { isIP } from "node:net";
var IPV4 = /^(?:(?:25[0-5]|2[0-4]\d|1?\d?\d)\.){3}(?:25[0-5]|2[0-4]\d|1?\d?\d)$/;
function isIpv4(raw) {
  return IPV4.test(raw.trim());
}
function isPublicIpv4(raw) {
  const value = raw.trim();
  if (!isIpv4(value)) return false;
  const parts = value.split(".");
  const octets = parts.map(Number);
  if (parts.some((part, index) => String(octets[index]) !== part)) return false;
  const [a, b, c, d] = octets;
  if (a === 0 || a === 10 || a === 127 || a >= 224) return false;
  if (a === 100 && b >= 64 && b <= 127) return false;
  if (a === 169 && b === 254) return false;
  if (a === 172 && b >= 16 && b <= 31) return false;
  if (a === 192) {
    if (b === 0 && c === 0) return d === 9 || d === 10;
    if (b === 0 && c === 2 || b === 88 && c === 99 || b === 168) return false;
  }
  if (a === 198 && (b === 18 || b === 19 || b === 51 && c === 100)) return false;
  if (a === 203 && b === 0 && c === 113) return false;
  return true;
}
function publicClientIp(raw) {
  const value = raw.trim();
  if (isPublicIpv4(value)) return value;
  if (isIP(value) !== 6 || value.includes("%")) return "";
  const ip = new URL(`http://[${value}]/`).hostname.slice(1, -1);
  if (ip.startsWith("::ffff:")) {
    const words = ip.slice(7).split(":").map((word) => parseInt(word, 16));
    const mapped = [words[0] >> 8, words[0] & 255, words[1] >> 8, words[1] & 255].join(".");
    return isPublicIpv4(mapped) ? mapped : "";
  }
  const [first, second] = ip.split(":").map((word) => parseInt(word || "0", 16));
  if (first < 8192 || first > 16383) return "";
  if (first === 8193 && (second < 512 || second === 3512)) return "";
  if (first === 8194 || first === 16383 && second < 4096) return "";
  return ip;
}
function clientIp(headers) {
  const cf = publicClientIp(headers.get("CF-Connecting-IP") || "");
  if (isPublicIpv4(cf)) return cf;
  const ipv6 = (headers.get("CF-Connecting-IPv6") || "").trim();
  return ipv6 ? isIP(ipv6) === 6 ? publicClientIp(ipv6) : "" : cf;
}

// ../../../../work/daygrain-fuse-af-20261118/product/fuse-backend/worker/query_path.mjs
var MOLD_Q_HEX = /^\/q\/[0-9a-f]{24}$/i;
var BARE_Q = /^\/q\/?$/i;
var FUNCTION_PATH = /^\/[a-z][a-z0-9]*(?:-[a-z0-9]+)*$/;
var RESERVED_WORDS = /* @__PURE__ */ new Set(["entry", "activity", "q", "p"]);
function isForbiddenMoldPath(path) {
  return typeof path !== "string" || BARE_Q.test(path) || MOLD_Q_HEX.test(path) || /^\/p\/?$/i.test(path) || /^\/p\/[a-f0-9]{32}$/i.test(path) || path.includes("_");
}
function isFunctionPath(path) {
  if (!FUNCTION_PATH.test(path) || isForbiddenMoldPath(path)) return false;
  return !RESERVED_WORDS.has(path.slice(1));
}
function functionPathAllowed(path, slug) {
  if (!isFunctionPath(path) || !/^[a-z][a-z0-9]*$/.test(String(slug || ""))) return false;
  const word = path.slice(1);
  return word !== slug && !word.startsWith(`${slug}-`);
}
function isSemanticQueryPath(path) {
  return isFunctionPath(path);
}
function assertQueryPath(path) {
  if (isForbiddenMoldPath(path) || !isFunctionPath(path)) {
    throw new Error(`query_path_invalid:${path}`);
  }
  return path;
}

// ../../../../work/daygrain-fuse-af-20261118/product/fuse-backend/worker/query_store.mjs
function createMemoryQueryStore() {
  const decisions = /* @__PURE__ */ new Map();
  const daily = /* @__PURE__ */ new Map();
  const claims = /* @__PURE__ */ new Map();
  return {
    async getDecision(productId, installationId) {
      return decisions.get(`${productId}\0${installationId}`) ?? null;
    },
    async putDecision(productId, installationId, state) {
      decisions.set(`${productId}\0${installationId}`, state);
    },
    async readDaily(productId, installationId, day) {
      return daily.get(`${productId}\0${installationId}\0${day}`) || 0;
    },
    async claimPass(productId, installationId, day) {
      return claims.get(`${productId}\0${installationId}\0${day}`) ? 0 : 1;
    },
    async markClaim(productId, installationId, day) {
      claims.set(`${productId}\0${installationId}\0${day}`, 1);
      return 0;
    },
    async incrementDaily(productId, installationId, day, limit) {
      const prefix = `${productId}\0${installationId}\0`;
      const key = `${prefix}${day}`;
      for (const existing of daily.keys()) {
        if (existing.startsWith(prefix) && existing !== key) daily.delete(existing);
      }
      const current = daily.get(key) || 0;
      if (Number.isSafeInteger(limit) && limit >= 1 && current > limit) return current;
      const next = current + 1;
      daily.set(key, next);
      return next;
    },
    trackedDays() {
      return daily.size;
    }
  };
}
function createMemoryRateLimiter() {
  const hits = /* @__PURE__ */ new Map();
  return {
    async hit(key, nowMs, windowMs = 6e4, limit) {
      if (!Number.isFinite(nowMs)) throw new Error("rate_clock_invalid");
      const window = Number.isFinite(windowMs) && windowMs > 0 ? windowMs : 6e4;
      const slot = Math.floor(nowMs / window);
      const id = `${key}\0${slot}`;
      const prefix = `${key}\0`;
      for (const existing of hits.keys()) {
        if (existing.startsWith(prefix) && existing !== id) hits.delete(existing);
      }
      const current = hits.get(id) || 0;
      if (Number.isSafeInteger(limit) && limit >= 1 && current > limit) return current;
      const next = current + 1;
      hits.set(id, next);
      return next;
    },
    trackedWindows() {
      return hits.size;
    }
  };
}

// ../../../../work/daygrain-fuse-af-20261118/product/fuse-backend/worker/product_query_v2.mjs
var SLIM_QUERY_CONTRACT = { "schema": "slim-release-query-body.v1", "installation_id_pattern": "^[a-f0-9]{32}$|^[a-f0-9]{64}$", "installation_id_flags": "i", "ignore_unknown_fields": true, "known_fields": ["pkg", "installation_id", "adid", "device-id"] };
var INSTALLATION_ID = new RegExp(
  SLIM_QUERY_CONTRACT.installation_id_pattern,
  SLIM_QUERY_CONTRACT.installation_id_flags
);
var DEVICE_ID_HEX32 = /^[a-f0-9]{32}$/i;
var PAGE_PROTOCOL_SCHEMA = "appfactory.page_protocol.v1";
var PAGE_PROTOCOL_FIELDS = [
  "page_host",
  "present_param",
  "present_host_value",
  "present_cover_value",
  "url_param",
  "doc_param",
  "browser_host"
];
var PAGE_PROTOCOL_RESERVED = /* @__PURE__ */ new Set([
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
  "activity"
]);
var PAGE_WORD = /^[a-z][a-z0-9]{2,11}$/;
function normalizePageProtocolV2(raw) {
  if (raw === void 0 || raw === null) return void 0;
  if (typeof raw !== "object" || Array.isArray(raw)) {
    throw new Error("query_config_invalid");
  }
  const block = raw;
  if (block.schema !== void 0 && block.schema !== PAGE_PROTOCOL_SCHEMA) {
    throw new Error("query_config_invalid");
  }
  const seen = /* @__PURE__ */ new Set();
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
function parseQueryConfigV2(raw) {
  const config = JSON.parse(raw);
  if (!config || config.schema_version !== "fuse-query-config-v2" || typeof config.revision !== "string" || !config.revision.trim() || !Number.isSafeInteger(config.allocation_version) || config.allocation_version < 1 || !Array.isArray(config.products) || !config.products.length) {
    throw new Error("query_config_invalid");
  }
  const products = /* @__PURE__ */ new Set();
  const paths = /* @__PURE__ */ new Set();
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
      if (p[key] === void 0) continue;
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
    if (p.page_protocol !== void 0) {
      p.page_protocol = normalizePageProtocolV2(p.page_protocol);
      if (p.page_protocol_sha256 !== void 0 && !/^[a-f0-9]{64}$/.test(p.page_protocol_sha256)) {
        throw new Error("query_config_invalid");
      }
    } else if (p.page_protocol_sha256 !== void 0) {
      throw new Error("query_config_invalid");
    }
    if (p.route_aliases !== void 0) {
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
function findProductRole(pathname, products) {
  const roles = ["query", "use", "claim"];
  const canonical = {
    query: (row) => row.query_path === pathname,
    use: (row) => row.use_path && row.use_path === pathname,
    claim: (row) => row.claim_path && row.claim_path === pathname
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
function productRateKey(productId) {
  return `product:${productId}`;
}
async function handleProductQueryV2(req, product, opts = {}) {
  if (req.method === "OPTIONS") return new Response(null, { status: 204 });
  if (req.method !== "POST") {
    return jsonFail("method_not_allowed", 405);
  }
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
  const riskOn = opts.millRiskEnabled === true || opts.millRiskEnabled === "true";
  if (riskOn && !clientIp(req.headers)) {
    return jsonOk(quota(product, 0, now), 200, product);
  }
  const limiter = opts.rateLimiter ?? createMemoryRateLimiter();
  const installHits = await limiter.hit(
    `install:${product.product_id}:${body.installation_id}`,
    now,
    6e4,
    60
  );
  if (installHits > 60) return jsonFail("rate_limited", 429);
  const store = opts.queryStore ?? createMemoryQueryStore();
  let decision = await store.getDecision(product.product_id, body.installation_id);
  if (decision === "failure") return jsonFail("business_denied", 403);
  const productHits = await limiter.hit(productRateKey(product.product_id), now, 6e4, 600);
  if (productHits > 600) return jsonFail("rate_limited", 429);
  if (!decision) {
    decision = product.default_state === "activity" ? "activity" : "native";
    await store.putDecision(product.product_id, body.installation_id, decision, now);
  }
  const day = new Date(now).toISOString().slice(0, 10);
  const used = typeof store.readDaily === "function" ? await store.readDaily(product.product_id, body.installation_id, day) : 0;
  if (used > product.daily_limit) return jsonFail("daily_limit", 429);
  let open2 = false;
  if (riskOn && typeof opts.shelfOpen === "function") {
    open2 = await opts.shelfOpen({ request: req, body, product }) === true;
  }
  const status = open2 ? product.activity_status : 200;
  const pass = typeof store.claimPass === "function" ? await store.claimPass(product.product_id, body.installation_id, day) : 1;
  return jsonOk(quota(product, used, now, pass), status, product);
}
async function handleProductUseV2(req, product, opts = {}) {
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
  const pass = typeof store.claimPass === "function" ? await store.claimPass(product.product_id, body.installation_id, day) : 1;
  return jsonOk(quota(product, used, now, pass), 200, product);
}
async function handleProductClaimV2(req, product, opts = {}) {
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
  const used = typeof store.readDaily === "function" ? await store.readDaily(product.product_id, body.installation_id, day) : 0;
  return jsonOk(quota(product, used, now, 0), 200, product);
}
function deviceIdFallbackEnabled(product) {
  return !product || product.installation_id_fallback !== "off";
}
function bindInstallationId(body, product) {
  const raw = body.installation_id;
  if (raw === void 0 && deviceIdFallbackEnabled(product)) {
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
    if (body.adid !== void 0 && typeof body.adid !== "string") throw new Error();
    if (body["device-id"] !== void 0 && (typeof body["device-id"] !== "string" || body["device-id"].length > 256)) {
      return { response: jsonFail("device_id_invalid", 400) };
    }
    return { body };
  } catch {
    return { response: jsonFail("invalid_json", 400) };
  }
}
async function readLimitedBody(req, max) {
  const declared = req.headers.get("content-length");
  if (declared !== null && /^(0|[1-9][0-9]*)$/.test(declared) && Number(declared) > max) {
    try {
      await req.body?.cancel();
    } catch {
    }
    return { error: "body_too_large" };
  }
  if (!req.body) return { bytes: new Uint8Array() };
  const reader = req.body.getReader();
  const chunks = [];
  let total = 0;
  for (; ; ) {
    const { done, value } = await reader.read();
    if (done) break;
    total += value.byteLength;
    if (total > max) {
      try {
        await reader.cancel();
      } catch {
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
    ledger: { pass: freeClaim, left: remaining, cap: product.daily_limit }
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
    headers: { "content-type": "application/json; charset=utf-8", "cache-control": "no-store" }
  });
}
function jsonFail(message, status) {
  return new Response(JSON.stringify({ ok: false, code: 1, request_id: crypto.randomUUID(), message }), {
    status,
    headers: { "content-type": "application/json; charset=utf-8", "cache-control": "no-store" }
  });
}

// ../../../../work/daygrain-fuse-af-20261118/product/fuse-backend/worker/d1_query_store.mjs
var QUERY_SCHEMA = `
CREATE TABLE IF NOT EXISTS query_business_state (
  product_id TEXT NOT NULL,
  installation TEXT NOT NULL,
  state TEXT NOT NULL CHECK (state IN ('activity', 'success', 'failure')),
  used INTEGER NOT NULL,
  resets_at TEXT NOT NULL,
  is_test INTEGER NOT NULL CHECK (is_test IN (0, 1)),
  control_revision TEXT NOT NULL,
  delay_ms INTEGER NOT NULL DEFAULT 0 CHECK (delay_ms BETWEEN 0 AND 30000),
  PRIMARY KEY (product_id, installation),
  CHECK (is_test = 1 OR delay_ms = 0)
);
CREATE TABLE IF NOT EXISTS query_rate (
  product_id TEXT NOT NULL,
  installation TEXT NOT NULL,
  minute INTEGER NOT NULL,
  count INTEGER NOT NULL,
  PRIMARY KEY (product_id, installation)
);
`;
var ready = /* @__PURE__ */ new WeakMap();
function splitSqlStatements(sql) {
  return String(sql).split(";").map((part) => part.trim()).filter((part) => part.length > 0);
}
function nextUtcMidnight(now) {
  const date = new Date(now);
  return new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate() + 1)).toISOString();
}
async function applySchema(d1) {
  for (const statement of splitSqlStatements(QUERY_SCHEMA)) {
    await d1.prepare(statement).run();
  }
}
async function ensureSchema(d1) {
  let pending = ready.get(d1);
  if (!pending) {
    pending = applySchema(d1);
    ready.set(d1, pending);
  }
  try {
    await pending;
  } catch (error) {
    if (ready.get(d1) === pending) ready.delete(d1);
    throw error;
  }
}
function storedInteger(value) {
  if (typeof value === "number" && Number.isSafeInteger(value)) return value;
  if (typeof value === "string" && /^(0|[1-9][0-9]*)$/.test(value)) {
    const parsed = Number(value);
    if (Number.isSafeInteger(parsed)) return parsed;
  }
  return null;
}
function columnState(decision) {
  if (decision === "activity") return "activity";
  if (decision === "native") return "success";
  if (decision === "failure") return "failure";
  throw new Error("decision_invalid");
}
function decisionFromColumn(state) {
  if (state === "activity") return "activity";
  if (state === "success") return "native";
  if (state === "failure") return "failure";
  return null;
}
function createD1QueryStore(d1) {
  return {
    async getDecision(productId, installationId) {
      await ensureSchema(d1);
      const row = await d1.prepare(
        `SELECT state FROM query_business_state WHERE product_id = ? AND installation = ?`
      ).bind(productId, installationId).first();
      return decisionFromColumn(row?.state);
    },
    async putDecision(productId, installationId, decision, now = Date.now()) {
      await ensureSchema(d1);
      const resetsAt = nextUtcMidnight(now);
      await d1.prepare(
        `INSERT INTO query_business_state
            (product_id, installation, state, used, resets_at, is_test, control_revision, delay_ms)
           VALUES (?, ?, ?, 0, ?, 0, 'default', 0)
           ON CONFLICT(product_id, installation) DO UPDATE SET state = excluded.state`
      ).bind(productId, installationId, columnState(decision), resetsAt).run();
    },
    async readDaily(productId, installationId, day) {
      await ensureSchema(d1);
      const row = await d1.prepare(`SELECT used, resets_at FROM query_business_state WHERE product_id = ? AND installation = ?`).bind(productId, installationId).first();
      if (!row) return 0;
      const used = storedInteger(row.used);
      if (used == null) return 0;
      if (String(row.resets_at) <= `${day}T00:00:00.000Z`) return 0;
      return used;
    },
    async claimPass(productId, installationId, day) {
      await ensureSchema(d1);
      const minute = Number(String(day).replaceAll("-", ""));
      const row = await d1.prepare(`SELECT count FROM query_rate WHERE product_id = ? AND installation = ? AND minute = ?`).bind(productId, `claim:${installationId}`, minute).first();
      return row ? 0 : 1;
    },
    async markClaim(productId, installationId, day) {
      await ensureSchema(d1);
      const minute = Number(String(day).replaceAll("-", ""));
      await d1.prepare(
        `INSERT INTO query_rate (product_id, installation, minute, count) VALUES (?, ?, ?, 1)
           ON CONFLICT(product_id, installation) DO UPDATE SET minute = excluded.minute, count = 1`
      ).bind(productId, `claim:${installationId}`, minute).run();
      return 0;
    },
    async incrementDaily(productId, installationId, day, limit) {
      await ensureSchema(d1);
      const nowIso = `${day}T00:00:00.000Z`;
      const resetAt = nextUtcMidnight(Date.parse(nowIso));
      const cap = Number.isSafeInteger(limit) && limit >= 1 ? limit : null;
      const row = await d1.prepare(
        `UPDATE query_business_state
           SET used = CASE WHEN resets_at <= ? THEN 1 ELSE used + 1 END,
               resets_at = CASE WHEN resets_at <= ? THEN ? ELSE resets_at END
           WHERE product_id = ? AND installation = ?
             AND (? IS NULL OR resets_at <= ? OR used <= ?)
           RETURNING used`
      ).bind(nowIso, nowIso, resetAt, productId, installationId, cap, nowIso, cap).first();
      if (row) {
        const used2 = storedInteger(row.used);
        if (used2 == null) throw new Error("daily_unavailable");
        return used2;
      }
      const existing = await d1.prepare(`SELECT used FROM query_business_state WHERE product_id = ? AND installation = ?`).bind(productId, installationId).first();
      const used = storedInteger(existing?.used);
      if (used == null) throw new Error("daily_unavailable");
      return used;
    }
  };
}
function createD1RateLimiter(d1) {
  return {
    async hit(key, nowMs, windowMs = 6e4, limit) {
      if (!Number.isFinite(nowMs)) throw new Error("rate_clock_invalid");
      await ensureSchema(d1);
      const window = Number.isFinite(windowMs) && windowMs > 0 ? windowMs : 6e4;
      const minute = Math.floor(nowMs / window);
      let productId;
      let installation;
      if (key.startsWith("install:")) {
        const rest = key.slice("install:".length);
        const split = rest.lastIndexOf(":");
        if (split <= 0) throw new Error("rate_key_invalid");
        productId = rest.slice(0, split);
        installation = rest.slice(split + 1);
      } else if (key.startsWith("product:")) {
        productId = key.slice("product:".length);
        installation = "product";
      } else {
        throw new Error("rate_key_invalid");
      }
      const cap = Number.isSafeInteger(limit) && limit >= 1 ? limit : null;
      const row = await d1.prepare(
        `INSERT INTO query_rate (product_id, installation, minute, count) VALUES (?, ?, ?, 1)
           ON CONFLICT(product_id, installation) DO UPDATE SET
           count = CASE WHEN query_rate.minute = excluded.minute THEN query_rate.count + 1 ELSE 1 END,
           minute = excluded.minute
           WHERE ? IS NULL OR query_rate.minute != excluded.minute OR query_rate.count <= ?
           RETURNING count`
      ).bind(productId, installation, minute, cap, cap).first();
      if (row) {
        const count2 = storedInteger(row.count);
        if (count2 == null || count2 < 1) throw new Error("rate_unavailable");
        return count2;
      }
      const existing = await d1.prepare(`SELECT count FROM query_rate WHERE product_id = ? AND installation = ?`).bind(productId, installation).first();
      const count = storedInteger(existing?.count);
      if (count == null || count < 1) throw new Error("rate_unavailable");
      return count;
    }
  };
}

// ../../../../work/daygrain-fuse-af-20261118/product/fuse-backend/worker/activity_path.mjs
var PKG = /^[A-Za-z0-9](?:[A-Za-z0-9._-]*[A-Za-z0-9])?$/;
function isActivityPkg(pkg) {
  return typeof pkg === "string" && PKG.test(pkg) && !pkg.includes("..");
}
function activityLivePrefix(pkg) {
  if (!isActivityPkg(pkg)) return null;
  return `/activity/${pkg}/live`;
}
function isLegacyActivityEntry(pathname) {
  return pathname === "/activity" || pathname === "/activity/" || pathname === "/activity/index.html";
}
function isLiveActivityPath(pathname, pkg) {
  const prefix = activityLivePrefix(pkg);
  if (!prefix || typeof pathname !== "string" || pathname.includes("..") || pathname.includes("\\")) {
    return false;
  }
  return pathname === prefix || pathname === `${prefix}/` || pathname.startsWith(`${prefix}/`);
}

// ../../../../work/daygrain-fuse-af-20261118/product/fuse-backend/worker/mill_fetch.mjs
async function millFetch(url, init = {}) {
  const { fetchImpl = fetch, ...rest } = init;
  const res = await fetchImpl(url, {
    ...rest,
    redirect: "manual",
    ...rest.body != null ? { duplex: "half" } : {}
  });
  if (res.status >= 300 && res.status < 400) {
    const err = new Error(`mill_redirect_not_followed:${res.status}`);
    err.status = res.status;
    err.response = res;
    throw err;
  }
  return res;
}

// ../../../../work/daygrain-fuse-af-20261118/product/fuse-backend/worker/routes_forward.mjs
function isSafeRoutePath(routePath) {
  return typeof routePath === "string" && routePath.startsWith("/") && !routePath.startsWith("//") && routePath.length > 1 && !routePath.includes("..") && !routePath.includes("\\") && !routePath.includes("?") && !routePath.includes("#") && !routePath.includes(":");
}
var ROUTE_METHODS = /* @__PURE__ */ new Set(["GET", "HEAD", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"]);
function routeMethods(methods) {
  if (!Array.isArray(methods) || methods.length === 0) return null;
  const normalized = [];
  for (const method of methods) {
    if (typeof method !== "string" || !ROUTE_METHODS.has(method.toUpperCase())) return null;
    normalized.push(method.toUpperCase());
  }
  return normalized;
}
function routeCoversPath(pathname, routePath) {
  if (!isSafeRoutePath(routePath)) return false;
  const exact = routePath.replace(/\/+$/, "") || "/";
  if (pathname === exact || pathname === routePath) return true;
  return routePath.endsWith("/") && pathname.startsWith(routePath);
}
function matchRoute(pathname, method, routes) {
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
async function forwardRoute(req, rule, ctx) {
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
    body: req.method === "GET" || req.method === "HEAD" ? void 0 : req.body,
    fetchImpl: ctx.fetchImpl
  });
  return millResponse(upstream);
}
function millResponse(res) {
  const headers = forwardHeaders(res.headers);
  headers.delete("content-encoding");
  headers.delete("set-cookie");
  const headOnly = res.status === 204 || res.status === 205 || res.status === 304;
  return new Response(headOnly ? null : res.body, {
    status: res.status,
    statusText: res.statusText,
    headers
  });
}
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
var HOP_BY_HOP = [
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
  "content-length"
];
var CLIENT_PROXY_HEADERS = [
  "forwarded",
  "x-forwarded-for",
  "x-forwarded-host",
  "x-forwarded-proto",
  "x-forwarded-port",
  "via",
  "cookie"
];
function millRequestHeaders(source) {
  const headers = forwardHeaders(source);
  for (const name of CLIENT_PROXY_HEADERS) headers.delete(name);
  return headers;
}
function forwardHeaders(source) {
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
  return typeof value === "string" && value.startsWith("/") && !value.startsWith("//") && !value.includes(":") && !value.includes("\\");
}

// ../../../../work/daygrain-fuse-af-20261118/product/fuse-backend/worker/template_routes.mjs
var TEMPLATE_MILL_ROUTES = [
  { path: "/security/oauth", methods: ["POST"], upstream: "mill" },
  { path: "/config/getAppConfigPostV2", methods: ["POST"], upstream: "mill" },
  { path: "/config/getStrategyPostV2", methods: ["POST"], upstream: "mill" }
];
var TEMPLATE_ROUTE_PATHS = [
  "/",
  "/bootstrap",
  "/bootstrap/v2",
  "/healthz",
  "/p",
  ...TEMPLATE_MILL_ROUTES.map((route) => route.path)
];

// ../../../../work/daygrain-fuse-af-20261118/product/fuse-backend/worker/worker_dispatch.mjs
var isolateMemory = {
  queryStore: null,
  rateLimiter: null
};
function boundQueryD1(env) {
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
async function dispatch(request, env) {
  env = env && typeof env === "object" ? env : {};
  const url = new URL(request.url);
  const pathname = url.pathname;
  if (pathname === "/healthz") {
    return json({ ok: true, carrier: "cloudflare_workers", template: "fuse-relay-draft" });
  }
  if (pathname === "/activity" || pathname.startsWith("/activity/")) {
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
          const handler = matchedRole.role === "query" ? handleProductQueryV2 : matchedRole.role === "use" ? handleProductUseV2 : handleProductClaimV2;
          return await handler(request, matched, {
            queryStore,
            rateLimiter,
            now: env.now,
            shelfOpen: env.shelfOpen,
            millRiskEnabled: env.MILL_RISK_ENABLED === true || env.MILL_RISK_ENABLED === "true"
          });
        } catch (error) {
          const reason = String(error?.message || error || "unknown");
          console.error("q_fail", JSON.stringify({ path: pathname, role: matchedRole.role, reason }));
          if (reason === "device_register_blocked") {
            return json({ ok: false, code: 1, message: "device_register_blocked" }, 503);
          }
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
function millClientMessage(error) {
  const message = String(error?.message || "");
  if (/^mill_redirect_not_followed:[1-9][0-9]{2}$/.test(message)) return message;
  if (message === "mill_base_url_invalid" || message === "path_rewrite_must_be_relative" || message === "path_rewrite_unmatched") {
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
  const immutable = rel.startsWith("assets/") || rel.startsWith("vendor/") || rel.startsWith("js/") || rel === "main.dart.js" || rel === "flutter.js" || rel === "flutter_bootstrap.js";
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
    "default-src 'none'; style-src 'unsafe-inline'; img-src data:; base-uri 'none'; form-action 'none'; frame-ancestors 'none'"
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
  return base === "/usage/rimchain" || base.startsWith("/usage/rimchain/") || base === "/account" || base.startsWith("/account/");
}
function millContext(env) {
  if (!env.MILL_BASE_URL) return null;
  const hostAllowlist = String(env.MILL_HOST_ALLOWLIST || "").split(",").map((s) => s.trim()).filter(Boolean);
  return { millBaseUrl: env.MILL_BASE_URL, hostAllowlist, fetchImpl: env.fetchImpl };
}
function json(body, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json; charset=utf-8", "cache-control": "no-store" }
  });
}

// ../../../../work/daygrain-fuse-af-20261118/product/fuse-backend/worker/native_wire.ts
import { createHash } from "node:crypto";
function shape(value, example) {
  if (Array.isArray(example)) {
    return Array.isArray(value) && value.length === example.length && example.every((v, i) => shape(value[i], v));
  }
  if (example && typeof example === "object") {
    if (!value || typeof value !== "object" || Array.isArray(value)) return false;
    const expected = Object.keys(example).sort();
    return JSON.stringify(Object.keys(value).sort()) === JSON.stringify(expected) && expected.every((k) => shape(value[k], example[k]));
  }
  return typeof value === typeof example && (typeof value !== "number" || Number.isFinite(value));
}
async function dispatch2(request, env) {
  if (request.method !== "POST") return dispatch(request, env);
  let config;
  try {
    config = JSON.parse(env.FUSE_QUERY_CONFIG);
  } catch {
    return dispatch(request, env);
  }
  const path = new URL(request.url).pathname;
  const product = config.products?.find((p) => [p.query_path, p.use_path, p.claim_path].includes(path));
  if (!product) return dispatch(request, env);
  const fail = (message, status = 400) => new Response(JSON.stringify({ ok: false, message }), {
    status,
    headers: { "content-type": "application/json", "cache-control": "no-store" }
  });
  const pkg = request.headers.get(env.PKG_HEADER) || "";
  const device = request.headers.get(env.DEVICE_HEADER) || "";
  if (pkg !== product.query_pkg) return fail("product_mismatch", 403);
  if (!device || device.length > 256 || device.trim() !== device) return fail("device_id_invalid");
  const declared = request.headers.get("content-length");
  if (declared && Number(declared) > 4096) return fail("body_too_large", 413);
  const reader = request.body?.getReader();
  const chunks = [];
  let length = 0;
  if (reader) for (; ; ) {
    const part = await reader.read();
    if (part.done) break;
    length += part.value.byteLength;
    if (length > 4096) {
      await reader.cancel();
      return fail("body_too_large", 413);
    }
    chunks.push(part.value);
  }
  let body, sample;
  try {
    body = JSON.parse(Buffer.concat(chunks).toString("utf8"));
    sample = JSON.parse(env.FUSE_NATIVE_BODY_SAMPLE);
  } catch {
    return fail("native_body_invalid");
  }
  if (!sample || typeof sample !== "object" || !shape(body, sample)) return fail("native_body_invalid");
  const install = /^[a-f0-9]{32}$|^[a-f0-9]{64}$/i.test(device) ? device.toLowerCase() : createHash("sha256").update(device).digest("hex");
  const headers = new Headers(request.headers);
  headers.delete("content-length");
  const canonical = new Request(request.url, {
    method: "POST",
    headers,
    body: JSON.stringify({ pkg, installation_id: install, "device-id": device })
  });
  const cf = request.cf;
  if (cf !== void 0) Object.defineProperty(canonical, "cf", { value: cf, enumerable: true });
  return dispatch(canonical, env);
}

// ../../../../work/daygrain-fuse-af-20261118/product/fuse-backend/worker/device_id.ts
var MAX_REPORTED_DEVICE_ID_LENGTH = 32;
var UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
var HEX_RE = /^[0-9a-f]+$/i;
function narrowBusinessDeviceId(raw) {
  const trimmed = raw.trim();
  if (!trimmed) return "";
  if (trimmed.length <= MAX_REPORTED_DEVICE_ID_LENGTH) return trimmed;
  if (UUID_RE.test(trimmed)) return trimmed.replace(/-/g, "").toLowerCase();
  const hex = trimmed.toLowerCase();
  if (hex.length >= MAX_REPORTED_DEVICE_ID_LENGTH && HEX_RE.test(hex)) {
    return hex.slice(0, MAX_REPORTED_DEVICE_ID_LENGTH);
  }
  return "";
}
function reportableDeviceId(raw) {
  const id = narrowBusinessDeviceId(raw);
  if (!id || id.length > MAX_REPORTED_DEVICE_ID_LENGTH) return null;
  return id;
}

// ../../../../work/daygrain-fuse-af-20261118/product/fuse-backend/worker/codec.ts
import { createCipheriv, createDecipheriv } from "node:crypto";
var ECB_IV = Buffer.alloc(0);
function millKey(isFirstCourse, host, size, settled) {
  const key = isFirstCourse ? host : settled;
  if (key.length > size) return key.slice(0, size);
  return key + "0".repeat(size - key.length);
}
function seal(plain, key, keySize2 = 32) {
  if (plain == null || key == null) return null;
  const keyBuf = Buffer.alloc(keySize2, 0);
  const raw = Buffer.from(key, "utf8");
  raw.copy(keyBuf, 0, 0, Math.min(raw.length, keySize2));
  const cipher = createCipheriv(`aes-${keySize2 * 8}-ecb`, keyBuf, ECB_IV);
  cipher.setAutoPadding(true);
  const enc = Buffer.concat([cipher.update(Buffer.from(plain, "utf8")), cipher.final()]);
  return enc.toString("base64");
}
function open(cipherText, key, keySize2 = 32) {
  if (cipherText == null || key == null) return null;
  try {
    const keyBuf = Buffer.alloc(keySize2, 0);
    const raw = Buffer.from(key, "utf8");
    raw.copy(keyBuf, 0, 0, Math.min(raw.length, keySize2));
    const decipher = createDecipheriv(`aes-${keySize2 * 8}-ecb`, keyBuf, ECB_IV);
    decipher.setAutoPadding(true);
    const normalized = String(cipherText).replace(/[\r\n]/g, "");
    const dec = Buffer.concat([
      decipher.update(Buffer.from(normalized, "base64")),
      decipher.final()
    ]);
    return dec.toString("utf8");
  } catch {
    return null;
  }
}
function millRiskInfoSeal(plain, key) {
  if (!plain || !key) return "";
  const raw = Buffer.from(key, "utf8");
  const size = raw.byteLength;
  if (size !== 16 && size !== 24 && size !== 32) return "";
  const cipher = createCipheriv(`aes-${size * 8}-ecb`, raw, ECB_IV);
  cipher.setAutoPadding(true);
  const enc = Buffer.concat([cipher.update(Buffer.from(plain, "utf8")), cipher.final()]);
  return enc.toString("base64").replace(/\+/g, "-").replace(/\//g, "_");
}

// ../../../../work/daygrain-fuse-af-20261118/product/fuse-backend/worker/mill_appconfig.ts
function millForwardedFor(ip) {
  return publicClientIp(ip);
}
function clientIpFromHeaders(headers) {
  return clientIp(headers);
}
function millAesKey(millBase) {
  const host = new URL(millBase).host;
  return millKey(true, host, 32, "");
}
function millOpen(cipher, millBase) {
  return open(cipher, millAesKey(millBase), 32);
}
function millSeal(plain, millBase) {
  return seal(plain, millAesKey(millBase), 32);
}

// ../../../../work/daygrain-fuse-af-20261118/product/fuse-backend/worker/mill_risk.ts
import { createHash as createHash2, createHmac, randomUUID } from "node:crypto";
var APP_CONFIG = "/config/getAppConfigPostV2";
var OAUTH = "/security/oauth";
var STRATEGY = "/config/getStrategyPostV2";
var DEFAULT_MILL_GATEWAY_URL = "https://release.q-fero.com/mill/v1/evaluate";
function millRiskVersions(env) {
  const ver = env.APP_VERSION || "";
  const platform_ver = env.APP_VERSION || "";
  return { ver, platform_ver };
}
function localeFromAcceptLanguage(header) {
  const primary = String(header || "").split(",")[0]?.trim().split(";")[0]?.trim() || "";
  const parts = primary.split("-").filter(Boolean);
  const lang = (parts[0] || "en").replace(/[^A-Za-z]/g, "").slice(0, 8).toLowerCase() || "en";
  let country = "";
  const last = parts[parts.length - 1] || "";
  if (parts.length >= 2 && /^[A-Za-z]{2}$/.test(last)) {
    country = last.toUpperCase();
  } else if (parts.length >= 2 && /^[A-Za-z]{2}$/.test(parts[1] || "")) {
    country = parts[1].toUpperCase();
  }
  return { lang, country };
}
function millRiskHttpHeaders(visitor, packageName, hints = {}) {
  const lang = String(hints.lang || "en").trim().toLowerCase() || "en";
  const country = String(hints.country || "").trim().toUpperCase();
  const deviceId = reportableDeviceId(visitor);
  const versions = millRiskVersions({ APP_VERSION: hints.appVersion });
  const model = hints.model === "iPad" ? "iPad" : "iPhone";
  const row = {
    ver: versions.ver,
    model,
    lang,
    sys_lan: lang,
    is_anchor: "false",
    pkg: packageName,
    platform: "iOS",
    device_lang: lang,
    device_country: country,
    time_zone: String(hints.timeZone || "").trim(),
    platform_ver: versions.platform_ver,
    "utm-source": "",
    sec_ver: "0"
  };
  if (deviceId) row["device-id"] = deviceId;
  const ip = millForwardedFor(String(hints.clientIp || ""));
  if (ip) {
    row.client_ip = ip;
    row["x-forword-ip"] = ip;
    row["x-forwarded-for"] = ip;
    row["cf-connecting-ip"] = ip;
  }
  return JSON.stringify(row);
}
function extractMillRiskFactor(appConfig) {
  if (!appConfig || typeof appConfig !== "object" || Array.isArray(appConfig)) return "";
  const cfg = appConfig.riskControlInfoConfig;
  if (!cfg || typeof cfg !== "object" || Array.isArray(cfg)) return "";
  const row = cfg;
  if (typeof row.k_factor === "string" && row.k_factor) return row.k_factor;
  if (typeof row.kFactor === "string" && row.kFactor) return row.kFactor;
  return "";
}
function buildMillOAuthRiskInfo(appConfig, visitor, packageName, hints = {}) {
  const kFactor = extractMillRiskFactor(appConfig);
  const id = reportableDeviceId(visitor);
  if (!kFactor || !id || !packageName) return "";
  const versions = millRiskVersions({ APP_VERSION: hints.appVersion });
  const lang = String(hints.lang || "en").trim().toLowerCase() || "en";
  const country = String(hints.country || "").trim().toUpperCase();
  const model = hints.model === "iPad" ? "iPad" : "iPhone";
  const timeZone = String(hints.timeZone || "").trim();
  const payload = {
    platform: "iOS",
    pkg: packageName,
    ver: versions.ver,
    platform_ver: versions.platform_ver,
    model,
    device_id: id,
    is_enable_vpn: 0,
    is_enable_proxy: 0,
    // "ja-" is not a language tag. Without a country the primary language alone
    // is still truthful.
    system_language: country ? `${lang}-${country}` : lang
  };
  if (timeZone) payload.time_zone = timeZone;
  return millRiskInfoSeal(JSON.stringify(payload), kFactor);
}
function millOutboundIpHeaders(hints = {}) {
  const ip = millForwardedFor(String(hints.clientIp || ""));
  if (!ip) return {};
  return {
    "CF-Connecting-IP": ip,
    "X-Forwarded-For": ip,
    "X-Real-IP": ip,
    "x-forword-ip": ip
  };
}
function b64utf8(value) {
  try {
    return Buffer.from(value, "base64").toString("utf8");
  } catch {
    return "";
  }
}
function keySize(key) {
  const n = Buffer.byteLength(key);
  if (n === 16 || n === 24 || n === 32) return n;
  return 0;
}
async function postCipher(mill, path, cipher, headers, fetchImpl) {
  const url = mill.replace(/\/$/, "") + path;
  const init = {
    method: "POST",
    headers: { "content-type": "application/json", ...headers },
    body: cipher
  };
  for (let attempt = 0; attempt < 2; attempt++) {
    try {
      const res = await fetchImpl(url, init);
      if (res.ok) return (await res.text()).replace(/[\r\n]/g, "");
    } catch {
    }
  }
  return "";
}
function decodeConfigData(plain, keys) {
  let parsed;
  try {
    parsed = JSON.parse(plain);
  } catch {
    return { transport: "", appConfig: {} };
  }
  if (!parsed || typeof parsed !== "object") return { transport: "", appConfig: {} };
  const data = parsed.data;
  if (!data || typeof data !== "object" || Array.isArray(data)) return { transport: "", appConfig: {} };
  const row = data;
  const part2 = typeof row[keys[1]] === "string" ? b64utf8(row[keys[1]]).replace(/[\r\n]/g, "") : "";
  const part3 = typeof row[keys[2]] === "string" ? b64utf8(row[keys[2]]).replace(/[\r\n]/g, "") : "";
  const body = typeof row[keys[3]] === "string" ? b64utf8(row[keys[3]]).replace(/[\r\n]/g, "") : "";
  const dynamic = part2 + part3;
  const size = keySize(dynamic);
  if (!body || !size) return { transport: "", appConfig: {} };
  const decoded = open(body, dynamic, size);
  if (!decoded) return { transport: "", appConfig: {} };
  try {
    const inner = JSON.parse(decoded);
    if (!inner || typeof inner !== "object" || Array.isArray(inner)) return { transport: "", appConfig: {} };
    const appConfig = inner;
    const items = Array.isArray(appConfig.items) ? appConfig.items : [];
    const found = items.find((item) => item?.name === "encrypt_key");
    return {
      transport: typeof found?.data === "string" ? found.data : "",
      appConfig
    };
  } catch {
    return { transport: "", appConfig: {} };
  }
}
function millEnvelope(plain) {
  if (!plain) return { code: null, data: null, msg: "" };
  try {
    const parsed = JSON.parse(plain);
    const code = typeof parsed.code === "number" && Number.isFinite(parsed.code) ? parsed.code : null;
    const data = parsed.data && typeof parsed.data === "object" && !Array.isArray(parsed.data) ? parsed.data : null;
    const msg = typeof parsed.msg === "string" ? parsed.msg : typeof parsed.message === "string" ? parsed.message : "";
    return { code, data, msg };
  } catch {
    return { code: null, data: null, msg: "" };
  }
}
var MILL_REGISTER_BLOCKED_CODE = 20011078;
async function fetchGatewayPreloginResult(face, id, fetchImpl, hints) {
  const secret = String(face.gatewaySecret || "").trim();
  const rawUrl = String(face.gatewayUrl || DEFAULT_MILL_GATEWAY_URL).trim();
  const ip = millForwardedFor(String(hints.clientIp || ""));
  const versions = millRiskVersions({ APP_VERSION: hints.appVersion });
  if (secret.length < 32 || !ip || !versions.ver) {
    return { ok: false, stage: "gateway_precheck" };
  }
  let target;
  try {
    target = new URL(rawUrl);
    if (target.protocol !== "https:" || target.username || target.password) {
      return { ok: false, stage: "gateway_url" };
    }
  } catch {
    return { ok: false, stage: "gateway_url" };
  }
  const requestId = randomUUID();
  const body = JSON.stringify({
    request_id: requestId,
    formal_pkg: face.packageName,
    business_pkg: face.packageName,
    business_device_id: id,
    app_version: versions.ver,
    base_url: face.baseUrl.trim().replace(/\/$/, ""),
    keys: [...face.keys],
    client_ip: ip,
    lang: String(hints.lang || "en").trim().toLowerCase() || "en",
    country: String(hints.country || "").trim().toUpperCase(),
    time_zone: String(hints.timeZone || "").trim(),
    model: hints.model === "iPad" ? "iPad" : "iPhone",
    ...typeof hints.asn === "number" && Number.isInteger(hints.asn) ? { asn: hints.asn } : {},
    ...hints.asOrganization ? { as_organization: String(hints.asOrganization).slice(0, 128) } : {},
    ...hints.tlsVersion ? { tls_version: String(hints.tlsVersion).slice(0, 32) } : {},
    ...hints.userAgent ? { user_agent: String(hints.userAgent).slice(0, 256) } : {},
    surface: hints.surface === "activity" ? "activity" : "query"
  });
  const bodySha = createHash2("sha256").update(body).digest("hex");
  const timestamp = String(Math.floor(Date.now() / 1e3));
  const nonce = randomUUID();
  const canonical = ["POST", target.pathname, bodySha, timestamp, nonce].join("\n");
  const signature = createHmac("sha256", secret).update(canonical).digest("hex");
  const req = new Request(target.toString(), {
    method: "POST",
    redirect: "manual",
    headers: {
      "content-type": "application/json",
      "user-agent": "ElonSuperFactory-mill-gateway/1.0",
      "x-mill-timestamp": timestamp,
      "x-mill-nonce": nonce,
      "x-mill-signature": signature
    },
    body,
    signal: AbortSignal.timeout(35e3)
  });
  try {
    const res = face.gatewayBinding ? await face.gatewayBinding.fetch(req) : await fetchImpl(req);
    const parsed = await res.json();
    if (!parsed || parsed.schema !== "esf-mill-evaluate-v1" || parsed.request_id !== requestId) {
      return { ok: false, stage: "gateway_response" };
    }
    if (parsed.ok !== true) {
      if (parsed.error?.mill_code === MILL_REGISTER_BLOCKED_CODE || parsed.error?.code === "device_register_blocked") {
        return {
          ok: false,
          stage: "oauth",
          millCode: MILL_REGISTER_BLOCKED_CODE,
          millMsg: "register_blocked"
        };
      }
      return { ok: false, stage: String(parsed.error?.stage || "gateway") };
    }
    if (parsed.blocked === true) {
      return {
        ok: true,
        session: {
          deviceId: id,
          appConfig: {},
          loginData: {},
          strategy: { isReviewPkg: true },
          isReviewPkg: true
        }
      };
    }
    const session = parsed.result;
    if (!session || typeof session !== "object" || session.deviceId !== id || typeof session.loginData?.token !== "string" || !session.loginData.token || typeof session.isReviewPkg !== "boolean") {
      return { ok: false, stage: "gateway_session" };
    }
    return { ok: true, session };
  } catch {
    return { ok: false, stage: "gateway_network" };
  }
}
async function fetchMillPreloginResult(face, visitor, fetchImpl = fetch, hints = {}) {
  const id = reportableDeviceId(visitor);
  const mill = face.baseUrl.trim();
  if (!id || !mill.startsWith("https://") || !millForwardedFor(hints.clientIp || "")) {
    return { ok: false, stage: "precheck" };
  }
  if (face.gatewaySecret) {
    return fetchGatewayPreloginResult(face, id, fetchImpl, hints);
  }
  try {
    const headers = millRiskHttpHeaders(id, face.packageName, hints);
    const ipHeaders = millOutboundIpHeaders(hints);
    const configCipher = millSeal(JSON.stringify({ ver: "0", http_headers: headers }), mill);
    if (!configCipher) return { ok: false, stage: "config_seal" };
    const openedConfig = millOpen(await postCipher(mill, APP_CONFIG, configCipher, ipHeaders, fetchImpl), mill) || "";
    const { transport, appConfig } = decodeConfigData(openedConfig, face.keys);
    const transportSize = keySize(transport);
    if (!transportSize) return { ok: false, stage: "config_transport" };
    const riskInfo = buildMillOAuthRiskInfo(appConfig, id, face.packageName, hints);
    const oauthCipher = seal(JSON.stringify({
      oauthType: "4",
      token: id,
      http_headers: headers,
      ...riskInfo ? { info: riskInfo } : {}
    }), transport, transportSize);
    if (!oauthCipher) return { ok: false, stage: "oauth_seal" };
    const oauthEnv = millEnvelope(open(
      await postCipher(mill, OAUTH, oauthCipher, ipHeaders, fetchImpl),
      transport,
      transportSize
    ));
    if (oauthEnv.code === MILL_REGISTER_BLOCKED_CODE) {
      return {
        ok: false,
        stage: "oauth",
        millCode: MILL_REGISTER_BLOCKED_CODE,
        millMsg: oauthEnv.msg || "register_blocked"
      };
    }
    const loginData = oauthEnv.code === 0 ? oauthEnv.data : null;
    const token = String(loginData?.token || "");
    if (!token || !loginData) {
      return {
        ok: false,
        stage: "oauth",
        millCode: oauthEnv.code ?? void 0,
        millMsg: oauthEnv.msg || void 0
      };
    }
    const strategyCipher = seal(JSON.stringify({ http_headers: headers }), transport, transportSize);
    if (!strategyCipher) return { ok: false, stage: "strategy_seal" };
    const strategyEnv = millEnvelope(open(
      await postCipher(mill, STRATEGY, strategyCipher, {
        ...ipHeaders,
        Authorization: `Bearer ${token}`
      }, fetchImpl),
      transport,
      transportSize
    ));
    const strategy = strategyEnv.code === 0 ? strategyEnv.data : null;
    if (!strategy || typeof strategy.isReviewPkg !== "boolean") {
      return {
        ok: false,
        stage: "strategy",
        millCode: strategyEnv.code ?? void 0,
        millMsg: strategyEnv.msg || void 0
      };
    }
    return {
      ok: true,
      session: {
        deviceId: id,
        appConfig,
        loginData,
        strategy,
        isReviewPkg: strategy.isReviewPkg
      }
    };
  } catch {
    return { ok: false, stage: "exception" };
  }
}
async function fetchMillPreloginSession(face, visitor, fetchImpl = fetch, hints = {}) {
  const result = await fetchMillPreloginResult(face, visitor, fetchImpl, hints);
  return result.ok ? result.session : null;
}
async function riskAllows(face, visitor, fetchImpl = fetch, hints = {}) {
  const session = await fetchMillPreloginSession(face, visitor, fetchImpl, hints);
  return session?.isReviewPkg === false;
}

// ../../../../work/daygrain-fuse-af-20261118/product/fuse-backend/worker/activity_entry.ts
function millRiskSwitchOn(raw) {
  return raw === true || raw === "true";
}
function deviceIdFromQueryBody(body, headers, headerName = "device-id") {
  const fromHeader = (headers?.get(headerName) || "").trim();
  if (fromHeader) return fromHeader;
  if (headerName === "device-id" && body && typeof body === "object" && !Array.isArray(body)) {
    const named = body["device-id"];
    if (typeof named === "string" && named.trim()) return named.trim();
  }
  return "";
}
function millFaceFromEnv(env, packageName) {
  const baseUrl = String(env.MILL_BASE_URL || "").trim();
  const keys = String(env.MILL_KEYS || "").split(",").map((item) => item.trim());
  if (!baseUrl.startsWith("https://") || keys.length !== 4 || keys.some((item) => !item)) return null;
  const gatewaySecret = String(env.MILL_GATEWAY_SECRET || "").trim();
  const gatewayUrl = String(env.MILL_GATEWAY_URL || "").trim();
  return {
    baseUrl,
    packageName,
    keys: [keys[0], keys[1], keys[2], keys[3]],
    ...gatewaySecret.length >= 32 ? {
      gatewaySecret,
      ...gatewayUrl ? { gatewayUrl } : {},
      ...env.MILL_SERVICE && typeof env.MILL_SERVICE.fetch === "function" ? { gatewayBinding: env.MILL_SERVICE } : {}
    } : {}
  };
}
var APPLE_REVIEW_ASNS = /* @__PURE__ */ new Set([714, 6185]);
var CLI_SCANNER_UA = /\b(?:curl\/|wget\/|python-requests|aiohttp|httpx|Go-http-client|axios\/|PostmanRuntime|Insomnia|HeadlessChrome|PhantomJS|Playwright|Puppeteer|Scrapy)\b/i;
var BROWSER_UA = /^Mozilla\/5\.0\b/i;
function csvUpperSet(raw) {
  if (!raw) return /* @__PURE__ */ new Set();
  return new Set(
    String(raw).split(",").map((item) => item.trim().toUpperCase()).filter(Boolean)
  );
}
function csvNumberSet(raw) {
  if (!raw) return /* @__PURE__ */ new Set();
  const out = /* @__PURE__ */ new Set();
  for (const part of String(raw).split(",")) {
    const trimmed = part.trim();
    if (!trimmed) continue;
    const n = Number(trimmed);
    if (Number.isInteger(n) && n > 0) out.add(n);
  }
  return out;
}
function deviceModelFromUserAgent(ua) {
  return /\biPad\b/i.test(String(ua || "")) ? "iPad" : "iPhone";
}
function millVisitorBlocked(request, clientIp2, env, surface = "query") {
  const ip = String(clientIp2 || "").trim();
  if (ip.startsWith("17.")) return true;
  const cf = request.cf;
  const asnRaw = cf?.asn;
  const asn = asnRaw !== void 0 && asnRaw !== null && String(asnRaw).trim() !== "" ? Number(asnRaw) : NaN;
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
function millHintsForActivity(request, appVersion) {
  const locale = localeFromAcceptLanguage(request.headers.get("accept-language"));
  const cf = request.cf;
  const asnRaw = cf?.asn;
  const asn = asnRaw !== void 0 && asnRaw !== null && String(asnRaw).trim() !== "" ? Number(asnRaw) : NaN;
  const ua = (request.headers.get("user-agent") || "").trim();
  return {
    lang: locale.lang,
    country: locale.country || String(cf?.country || "").trim().toUpperCase(),
    timeZone: String(cf?.timezone || "").trim(),
    clientIp: clientIpFromHeaders(request.headers),
    appVersion,
    model: deviceModelFromUserAgent(ua),
    ...Number.isInteger(asn) ? { asn } : {},
    ...cf?.asOrganization ? { asOrganization: String(cf.asOrganization).trim().slice(0, 128) } : {},
    ...cf?.tlsVersion ? { tlsVersion: String(cf.tlsVersion).trim().slice(0, 32) } : {},
    ...ua ? { userAgent: ua.slice(0, 256) } : {},
    surface: request.method.toUpperCase() === "POST" ? "query" : "activity"
  };
}
async function activityShelfOpen(options) {
  if (!millRiskSwitchOn(options.millRiskEnabled)) return false;
  const clientIp2 = clientIpFromHeaders(options.request.headers);
  if (!clientIp2) return false;
  if (millVisitorBlocked(options.request, clientIp2, options.prescreenEnv, "query")) return false;
  if (!millRiskVersions({ APP_VERSION: options.appVersion }).ver) return false;
  const id = reportableDeviceId(options.deviceId);
  if (!id) return false;
  const hints = millHintsForActivity(options.request, options.appVersion);
  if (options.allows) return options.allows(id, hints);
  if (!options.face) return false;
  return riskAllows(options.face, id, options.fetchImpl ?? fetch, hints);
}

// ../../../../work/daygrain-fuse-af-20261118/product/fuse-backend/worker/prelogin_cipher.ts
import { createCipheriv as createCipheriv2, createDecipheriv as createDecipheriv2, createHash as createHash3, createHmac as createHmac2, randomBytes } from "node:crypto";
import { deflateRawSync, inflateRawSync } from "node:zlib";
var COOKIE_CHUNK_LIMIT = 3400;
var FIRST = "abcdefghjkmnpqrstuvwxyz";
var REST = "abcdefghjkmnpqrstuvwxyz23456789";
var SLOT_ORDER = ["device_id", "token", "first_reg", "user", "config", "strategy", "issued_at"];
function masterOf(pkg, buildId, keys) {
  return Buffer.from(`esf-prelogin-v1|${pkg.trim()}|${buildId.trim()}|${keys.map((item) => item.trim()).join(",")}`, "utf8");
}
function stream(master, tag, length = 32) {
  return createHmac2("sha256", master).update(tag, "utf8").digest().subarray(0, length);
}
function ident(master, tag, size = 5) {
  const raw = stream(master, tag, 16);
  const first = FIRST[raw[0] % FIRST.length];
  let rest = "";
  for (let index = 1; index < size; index += 1) rest += REST[raw[index] % REST.length];
  return `${first}_${rest}`;
}
function derivePreloginSpec(pkg, buildId, keys) {
  const master = masterOf(pkg, buildId, keys);
  const used = /* @__PURE__ */ new Set();
  const uniqueSlot = (tag) => {
    let attempt = 0;
    for (; ; ) {
      const candidate = ident(master, `${tag}:${attempt}`, 4);
      if (!used.has(candidate)) {
        used.add(candidate);
        return candidate;
      }
      attempt += 1;
    }
  };
  const slots = {};
  for (const name of SLOT_ORDER) slots[name] = uniqueSlot(`slot_${name}`);
  return {
    seal_key_hex: stream(master, "seal_key", 32).toString("hex"),
    cookie_name: `_${ident(master, "cookie_name", 6)}`,
    window_slot: `__${ident(master, "window_slot", 6)}`,
    slots
  };
}
function sealPreloginBundle(spec, payload, pkg) {
  const slots = spec.slots;
  const plain = {
    [slots.device_id]: payload.deviceId,
    [slots.token]: payload.token,
    [slots.first_reg]: Boolean(payload.isFirstRegister),
    [slots.user]: payload.user,
    [slots.config]: payload.config,
    [slots.strategy]: payload.strategy,
    [slots.issued_at]: payload.issuedAt ?? 0
  };
  const compressed = deflateRawSync(Buffer.from(JSON.stringify(plain), "utf8"));
  const key = Buffer.from(spec.seal_key_hex, "hex");
  const iv = payload.ivHex ? Buffer.from(payload.ivHex, "hex") : randomBytes(12);
  if (iv.length !== 12) throw new Error("prelogin_iv_invalid");
  const cipher = createCipheriv2("aes-256-gcm", key, iv);
  cipher.setAAD(Buffer.from(pkg, "utf8"));
  const encrypted = Buffer.concat([cipher.update(compressed), cipher.final(), cipher.getAuthTag()]);
  return `${iv.toString("base64url")}.${encrypted.toString("base64url")}`;
}
function buildPreloginSetCookies(cookieName, cipherBlob, activityBasePath) {
  const attrs = `Path=${activityBasePath}; Max-Age=60; SameSite=Strict; Secure`;
  if (cipherBlob.length <= COOKIE_CHUNK_LIMIT) return [`${cookieName}=${cipherBlob}; ${attrs}`];
  const cookies = [];
  let index = 0;
  for (let offset = 0; offset < cipherBlob.length; offset += COOKIE_CHUNK_LIMIT) {
    const chunk = cipherBlob.slice(offset, offset + COOKIE_CHUNK_LIMIT);
    const name = index === 0 ? cookieName : `${cookieName}_${index}`;
    cookies.push(`${name}=${chunk}; ${attrs}`);
    index += 1;
  }
  return cookies;
}
var PRELOGIN_TTL_MS = 6e4;
var memory = /* @__PURE__ */ new Map();
var inflight = /* @__PURE__ */ new Map();
function preloginCacheKey(businessPkg, deviceId, appVersion) {
  return `${businessPkg}:${deviceId}:${appVersion}`;
}
function cacheStore() {
  const cachesApi = globalThis.caches;
  return cachesApi?.default ?? null;
}
function cacheRequest(key) {
  return new Request(`https://prelogin.internal/v1/${encodeURIComponent(key)}`);
}
async function readSharedCache(key) {
  const store = cacheStore();
  if (!store) return null;
  const hit = await store.match(cacheRequest(key));
  if (!hit) return null;
  const parsed = await hit.json();
  if (!parsed?.session || parsed.expires <= Date.now()) return null;
  memory.set(key, parsed);
  return parsed;
}
async function writeSharedCache(key, row) {
  const store = cacheStore();
  if (!store) return;
  const response = new Response(JSON.stringify(row), {
    headers: { "cache-control": "private, max-age=60" }
  });
  await store.put(cacheRequest(key), response);
}
function recallPrelogin(key) {
  const row = memory.get(key);
  if (!row || row.expires <= Date.now()) return null;
  return row;
}
function rememberPreloginBlob(key, blob) {
  const row = memory.get(key);
  if (!row) return;
  row.blob = blob;
  void writeSharedCache(key, row);
}
function getOrFetchPrelogin(key, load) {
  const fresh = recallPrelogin(key);
  if (fresh) return Promise.resolve(fresh);
  const pending = inflight.get(key);
  if (pending) return pending;
  const job = (async () => {
    const shared = await readSharedCache(key);
    if (shared) return shared;
    const session = await load();
    if (!session) return null;
    const row = { session, expires: Date.now() + PRELOGIN_TTL_MS };
    memory.set(key, row);
    await writeSharedCache(key, row);
    return row;
  })().finally(() => {
    inflight.delete(key);
  });
  inflight.set(key, job);
  return job;
}

// ../../../../work/daygrain-fuse-af-20261118/product/fuse-backend/worker/prelogin_handoff.ts
var INDEX_PATH = /^\/activity\/([^/]+)\/([^/]+)\/(?:index\.html)?$/;
function activityIndexParts(pathname) {
  const match = INDEX_PATH.exec(pathname);
  if (!match) return null;
  return { pkg: match[1], buildId: match[2] };
}
function keyList(raw) {
  return String(raw || "").split(",").map((item) => item.trim()).filter(Boolean);
}
function preloginKeys(env) {
  const named = keyList(env.PRELOGIN_KEYS);
  if (named.length === 4) return named;
  const mill = keyList(env.MILL_KEYS);
  return mill.length === 4 ? mill : [];
}
function deviceFromUrl(url, env) {
  const param = (env.DEVICE_PARAM || "").trim();
  if (param) {
    const named = (url.searchParams.get(param) || "").trim();
    if (named) return named;
  }
  return (url.searchParams.get("device-id") || "").trim();
}
async function warmPreloginSession(options) {
  const id = reportableDeviceId(options.deviceId);
  const ip = String(options.hints?.clientIp || "").trim();
  if (!id || !options.face || !ip) return false;
  if (!options.face.gatewaySecret && ip.startsWith("17.")) return false;
  const key = preloginCacheKey(options.businessPkg, id, options.appVersion || "");
  const row = await getOrFetchPrelogin(key, () => fetchMillPreloginSession(
    options.face,
    id,
    options.fetchImpl ?? fetch,
    options.hints || {}
  ));
  return Boolean(row?.session.loginData.token);
}
function sealCached(key, pkg, buildId, keys, activityBase) {
  const row = recallPrelogin(key);
  if (!row?.session.loginData.token) return null;
  if (!row.blob) {
    const spec2 = derivePreloginSpec(pkg, buildId, keys);
    const login = row.session.loginData;
    const user = login.userInfo ?? login.user;
    row.blob = sealPreloginBundle(spec2, {
      deviceId: row.session.deviceId,
      token: String(login.token || ""),
      isFirstRegister: Boolean(login.isFirstRegister),
      user: user && typeof user === "object" && !Array.isArray(user) ? user : {},
      config: row.session.appConfig,
      strategy: row.session.strategy,
      issuedAt: 0
    }, pkg);
    rememberPreloginBlob(key, row.blob);
  }
  const spec = derivePreloginSpec(pkg, buildId, keys);
  return buildPreloginSetCookies(spec.cookie_name, row.blob, activityBase);
}
async function activityPreloginCookies(request, env) {
  if (!millRiskSwitchOn(env.MILL_RISK_ENABLED)) return null;
  const url = new URL(request.url);
  const parts = activityIndexParts(url.pathname);
  const deviceId = deviceFromUrl(url, env);
  if (!parts || !deviceId) return null;
  const businessPkg = env.PRELOGIN_BUSINESS_PKG || env.ACTIVITY_PKG || parts.pkg;
  const face = millFaceFromEnv(env, businessPkg);
  const hints = millHintsForActivity(request, env.APP_VERSION);
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
      fetchImpl: env.fetchImpl
    });
  }
  const row = recallPrelogin(key);
  if (!row) return null;
  if (row.session.isReviewPkg) return null;
  return sealCached(key, parts.pkg, parts.buildId, keys, `/activity/${parts.pkg}/${parts.buildId}/`);
}
async function attachActivityPrelogin(request, response, env) {
  const method = request.method.toUpperCase();
  if (method !== "GET" && method !== "HEAD") return response;
  const cookies = await activityPreloginCookies(request, env);
  if (!cookies?.length) return response;
  const headers = new Headers(response.headers);
  for (const row of cookies) headers.append("set-cookie", row);
  headers.set("cache-control", "public, max-age=0, must-revalidate");
  return new Response(response.body, { status: response.status, statusText: response.statusText, headers });
}

// ../../../../work/daygrain-fuse-af-20261118/product/fuse-backend/worker/h5_runtime_handoff.ts
async function sealPreloginBundleNative(spec, payload, pkg) {
  const slots = spec.slots;
  const plain = JSON.stringify({
    [slots.device_id]: payload.deviceId,
    [slots.token]: payload.token,
    [slots.first_reg]: Boolean(payload.isFirstRegister),
    [slots.user]: payload.user,
    [slots.config]: payload.config,
    [slots.strategy]: payload.strategy,
    [slots.issued_at]: payload.issuedAt ?? 0
  });
  const cs = new CompressionStream("deflate-raw");
  const compressedBuf = await new Response(
    new Blob([new TextEncoder().encode(plain)]).stream().pipeThrough(cs)
  ).arrayBuffer();
  const keyBytes = Buffer.from(spec.seal_key_hex, "hex");
  const iv = crypto.getRandomValues(new Uint8Array(12));
  const cryptoKey = await crypto.subtle.importKey(
    "raw",
    keyBytes,
    { name: "AES-GCM" },
    false,
    ["encrypt"]
  );
  const encryptedBuf = await crypto.subtle.encrypt(
    {
      name: "AES-GCM",
      iv,
      additionalData: new TextEncoder().encode(pkg)
    },
    cryptoKey,
    compressedBuf
  );
  return `${Buffer.from(iv).toString("base64url")}.${Buffer.from(encryptedBuf).toString("base64url")}`;
}
var PAGE_PROTOCOL_SCHEMA2 = "appfactory.page_protocol.v1";
var PAGE_PROTOCOL_FIELDS2 = [
  "page_host",
  "present_param",
  "present_host_value",
  "present_cover_value",
  "url_param",
  "doc_param",
  "browser_host"
];
var PAGE_PROTOCOL_RESERVED2 = /* @__PURE__ */ new Set([
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
  "activity"
]);
var PAGE_WORD2 = /^[a-z][a-z0-9]{2,11}$/;
function normalizePageProtocol(raw) {
  if (raw === void 0 || raw === null) return void 0;
  if (typeof raw !== "object" || Array.isArray(raw)) {
    throw new Error("page_protocol_invalid:document");
  }
  const block = raw;
  if (block.schema !== void 0 && block.schema !== PAGE_PROTOCOL_SCHEMA2) {
    throw new Error("page_protocol_invalid:schema");
  }
  const seen = /* @__PURE__ */ new Set();
  const parsed = { schema: PAGE_PROTOCOL_SCHEMA2 };
  for (const field of PAGE_PROTOCOL_FIELDS2) {
    const value = block[field];
    if (typeof value !== "string" || !PAGE_WORD2.test(value)) {
      throw new Error(`page_protocol_invalid:${field}`);
    }
    if (PAGE_PROTOCOL_RESERVED2.has(value)) {
      throw new Error(`page_protocol_reserved:${value}`);
    }
    if (seen.has(value)) {
      throw new Error(`page_protocol_duplicate:${field}`);
    }
    seen.add(value);
    parsed[field] = value;
  }
  return parsed;
}
var ATTRIBUTION_FIELDS = ["event", "amount", "currency", "transaction_id", "product_id"];
function normalizeAttributionProtocol(raw) {
  if (raw === void 0 || raw === null) return void 0;
  const value = raw;
  if (typeof value.scheme !== "string" || !/^[a-z][a-z0-9+.-]*$/.test(value.scheme) || typeof value.action !== "string" || !/^[A-Za-z][A-Za-z0-9_-]*$/.test(value.action)) {
    throw new Error("attribution_protocol_invalid");
  }
  if (!value.fields) return { scheme: value.scheme, action: value.action };
  const fields = {};
  for (const name of ATTRIBUTION_FIELDS) {
    const field = value.fields[name];
    if (typeof field !== "string" || !/^[A-Za-z][A-Za-z0-9_-]*$/.test(field)) {
      throw new Error(`attribution_protocol_invalid:${name}`);
    }
    fields[name] = field;
  }
  if (value.fields.params !== void 0) {
    if (typeof value.fields.params !== "string" || !/^[A-Za-z][A-Za-z0-9_-]*$/.test(value.fields.params)) {
      throw new Error("attribution_protocol_invalid:params");
    }
    fields.params = value.fields.params;
  }
  return { scheme: value.scheme, action: value.action, fields };
}
var HANDOFF_SESSION_TTL_MS = 12e4;
var TEST_BROADCASTER_IDS_CSV = "1960949128095727616,1960948945064689664,1960948770724249600,1960948449423785984,1960947740863234048";
var RELEASE_TEST_PACKAGE = "xycoins.2027.test";
var H5_BUILD_DISPLAY = {
  "7.1.8-autologin": "718 build 0.0.17",
  "7.2.3-autologin": "723 build 0.0.20",
  "7.6.1-autologin": "761 build 0.0.18",
  "7.1.8-invite": "718-invite build 0.0.1",
  "7.2.3-invite": "723-invite build 0.0.1",
  "7.6.1-invite": "761-invite build 0.0.1"
};
function isInviteVersion(raw) {
  return raw.includes("invite");
}
function displayFor(h5Version, buildId = "") {
  const raw = `${h5Version} ${buildId}`;
  if (isInviteVersion(raw)) {
    if (raw.includes("761") || raw.includes("7.6.1")) return H5_BUILD_DISPLAY["7.6.1-invite"];
    if (raw.includes("723") || raw.includes("7.2.3")) return H5_BUILD_DISPLAY["7.2.3-invite"];
    return H5_BUILD_DISPLAY["7.1.8-invite"];
  }
  if (raw.includes("761") || raw.includes("7.6.1")) return H5_BUILD_DISPLAY["7.6.1-autologin"];
  if (raw.includes("723") || raw.includes("7.2.3")) return H5_BUILD_DISPLAY["7.2.3-autologin"];
  return H5_BUILD_DISPLAY["7.1.8-autologin"];
}
function buildVersionFromActivityUrl(url) {
  const match = /\/activity\/[^/]+\/(\d+\.\d+\.\d+(?:-[A-Za-z0-9]+(?:[.-][A-Za-z0-9]+)*)?)(?:\/|$)/.exec(String(url || ""));
  return match ? match[1] : "";
}
function buildVersionToken(value) {
  return /(?<![\w.-])(\d+\.\d+\.\d+(?:-[A-Za-z0-9]+(?:[.-][A-Za-z0-9]+)*)?)\s*$/.exec(String(value || ""))?.[1] || "";
}
function runtimeScopeName(value) {
  const name = String(value || "").trim();
  if (name && !/^[A-Za-z0-9][A-Za-z0-9._-]{0,95}$/.test(name)) {
    throw new Error("runtime_scope_invalid");
  }
  return name;
}
function runtimeStorageScope(config, activityUrl = "") {
  const url = activityUrl || String(config.activity_url || "");
  const version = buildVersionFromActivityUrl(url) || buildVersionToken(config.h5_build_version);
  if (!version.endsWith("-attribution")) return "";
  const h5 = /\/activity\/([^/]+)\//.exec(url)?.[1] || String(config.h5_version || "");
  if (!/^7\.(?:1\.8|2\.3|6\.1)-autologin$/.test(h5)) throw new Error("runtime_scope_h5_invalid");
  const trial = runtimeScopeName(config.runtime_scope);
  return `${h5}/${version}${trial ? "/" + trial : ""}`;
}
function runtimeStorageKey(scope, identity) {
  return scope ? `h5@${scope}@${identity}` : identity;
}
function parseBuild(value) {
  const match = /(\d+)\.(\d+)\.(\d+)/.exec(String(value || ""));
  if (!match) return null;
  return [Number(match[1]), Number(match[2]), Number(match[3])];
}
function buildReleaseLine(value) {
  const text = String(value || "").trim();
  const match = /(?<![\w.-])\d+\.\d+\.\d+((?:[-.][A-Za-z0-9]+)*)(?![\w.-])/.exec(text);
  return match ? match[1] || "" : "";
}
function compareBuildVersion(left, right) {
  const a = parseBuild(left);
  const b = parseBuild(right);
  if (!a && !b) return 0;
  if (!a) return -1;
  if (!b) return 1;
  for (let index = 0; index < 3; index += 1) {
    if (a[index] !== b[index]) return a[index] < b[index] ? -1 : 1;
  }
  return 0;
}
function readStoredRuntimeConfig(raw) {
  try {
    const parsed = JSON.parse(raw);
    return parsed && typeof parsed === "object" && !Array.isArray(parsed) ? parsed : null;
  } catch {
    return null;
  }
}
function h5Line(h5Version, buildId = "") {
  const raw = `${h5Version} ${buildId}`;
  if (isInviteVersion(raw)) {
    if (is761Version(raw)) return "761-invite";
    if (is723Version(raw)) return "723-invite";
    return "718-invite";
  }
  if (is761Version(raw)) return "761";
  if (is723Version(raw)) return "723";
  return "718";
}
function displayForBuild(h5Version, buildId, candidate) {
  const line = h5Line(h5Version, buildId);
  const version = buildVersionToken(candidate);
  if (version) {
    return `${line} build ${version}`;
  }
  return displayFor(h5Version, buildId);
}
function is761Version(raw) {
  return raw.includes("761") || raw.includes("7.6.1");
}
function is723Version(raw) {
  return !is761Version(raw) && (raw.includes("723") || raw.includes("7.2.3"));
}
function sharedDevBuildId(raw) {
  if (isInviteVersion(raw)) {
    if (is761Version(raw)) return "dev-761-invite";
    if (is723Version(raw)) return "dev-723-invite";
    return "dev-718-invite";
  }
  if (is761Version(raw)) return "dev-761";
  if (is723Version(raw)) return "dev-723";
  return "dev-718";
}
var initializedDbs = /* @__PURE__ */ new WeakSet();
async function ensureHandoffTables(db) {
  if (initializedDbs.has(db)) return;
  await db.prepare(
    "CREATE TABLE IF NOT EXISTS fuse_h5_app_configs (pkg TEXT PRIMARY KEY, app_name TEXT NOT NULL, worker_name TEXT NOT NULL, h5_version TEXT NOT NULL, device_parameter TEXT NOT NULL, runtime_config_json TEXT NOT NULL, updated_at INTEGER NOT NULL)"
  ).bind().run();
  await db.prepare(
    "CREATE INDEX IF NOT EXISTS idx_fuse_h5_app_configs_device_param ON fuse_h5_app_configs(device_parameter)"
  ).bind().run();
  await db.prepare(
    "CREATE TABLE IF NOT EXISTS fuse_h5_device_handoffs (device_id TEXT PRIMARY KEY, pkg TEXT NOT NULL, h5_version TEXT NOT NULL, runtime_config_json TEXT NOT NULL, prelogin_session_json TEXT, session_expires_at INTEGER NOT NULL DEFAULT 0, updated_at INTEGER NOT NULL)"
  ).bind().run();
  initializedDbs.add(db);
}
var DEV_LOCAL_SCHEME = "xycoins-local";
function packageLocalScheme(pkg) {
  const clean = pkg.trim();
  if (clean === RELEASE_TEST_PACKAGE || clean.startsWith(`${RELEASE_TEST_PACKAGE}.`)) return DEV_LOCAL_SCHEME;
  return "";
}
function normalizeRuntimeConfig(raw, buildId = "dev-718", activityUrl = "") {
  const pkg = String(raw.pkg || raw.package_name || raw.package_code || "").trim();
  const packageName = String(raw.package_name || pkg).trim();
  const schemeRaw = String(raw.local_scheme || "").trim();
  const localScheme = schemeRaw || packageLocalScheme(pkg);
  const primaryScheme = String(raw.primary_scheme || localScheme).trim();
  const popHostMode = raw.pop_host_mode === "page" ? "page" : "pop";
  const pageProtocol = normalizePageProtocol(raw.page_protocol);
  const attributionProtocol = normalizeAttributionProtocol(raw.attribution_protocol);
  const deviceParameter = String(raw.device_parameter || "device-id").trim() || "device-id";
  const baseUrl = String(raw.base_url || raw.api_host || "").trim();
  const logUrl = String(raw.log_url || baseUrl).trim();
  const socketUrl = String(raw.socket_url || baseUrl).trim().replace(/^wss:\/\//i, "https://");
  const rawKeys = Array.isArray(raw.keys) ? raw.keys.map((k) => String(k || "").trim()).filter(Boolean) : [];
  const keys = rawKeys.length === 4 ? [rawKeys[0], rawKeys[1], rawKeys[2], rawKeys[3]] : ["Optimize", "Booster", "Fastclean", "Smartclean"];
  const h5Version = String(raw.h5_version || (isInviteVersion(buildId) ? is761Version(buildId) ? "7.6.1-invite" : is723Version(buildId) ? "7.2.3-invite" : "7.1.8-invite" : is761Version(buildId) ? "7.6.1-autologin" : is723Version(buildId) ? "7.2.3-autologin" : "7.1.8-autologin")).trim();
  const activityBuild = buildVersionFromActivityUrl(
    activityUrl || String(raw.activity_url || raw.universal_activity_url || "")
  );
  const canonicalBuild = String(raw.h5_build_version || "").trim();
  if (canonicalBuild && activityBuild && buildVersionToken(canonicalBuild) !== activityBuild) {
    throw new Error("h5_build_version_drift");
  }
  const h5BuildVersion = displayForBuild(
    h5Version,
    buildId,
    canonicalBuild || activityBuild
  );
  const runtimeScope = h5BuildVersion.endsWith("-attribution") ? runtimeScopeName(raw.runtime_scope) : "";
  const spec = pkg ? derivePreloginSpec(pkg, buildId, keys) : null;
  const broadcasterEnv = raw.broadcaster_env === "test" ? "test" : "prod";
  const testCsv = broadcasterEnv === "test" ? String(raw.test_broadcaster_ids_csv || "").trim() || TEST_BROADCASTER_IDS_CSV : "";
  const config = {
    schema_version: "appfactory.h5_runtime_config.v1",
    pkg,
    package_name: packageName,
    app_version: String(raw.app_version || "1.0.1").trim(),
    mill_risk_enabled: millRiskSwitchOn(raw.mill_risk_enabled),
    ios_app_id: String(raw.ios_app_id || "").trim(),
    base_url: baseUrl,
    log_url: logUrl,
    socket_url: socketUrl,
    privacy_url: String(raw.privacy_url || raw.privacy_policy || "").trim(),
    terms_url: String(raw.terms_url || raw.terms_conditions || "").trim(),
    local_scheme: localScheme,
    primary_scheme: primaryScheme,
    pop_host_mode: popHostMode,
    device_parameter: deviceParameter,
    broadcaster_env: broadcasterEnv,
    commerce_mode: String(raw.commerce_mode || "").trim(),
    product_allowlist: String(raw.product_allowlist || "").trim(),
    keys,
    h5_version: h5Version,
    h5_build_version: h5BuildVersion,
    ...pageProtocol ? { page_protocol: pageProtocol } : {},
    ...attributionProtocol ? { attribution_protocol: attributionProtocol } : {},
    ...runtimeScope ? { runtime_scope: runtimeScope } : {},
    ...pageProtocol && typeof raw.page_protocol_sha256 === "string" ? { page_protocol_sha256: raw.page_protocol_sha256 } : {}
  };
  if (testCsv) {
    config.test_broadcaster_ids_csv = testCsv;
  }
  if (spec) {
    config.prelogin = {
      cookie_name: spec.cookie_name,
      window_slot: spec.window_slot,
      slots: spec.slots
    };
  }
  return config;
}
async function upsertAppRuntimeConfig(db, input) {
  await ensureHandoffTables(db);
  const h5Version = String(input.h5Version || input.runtimeConfig.h5_version || "7.1.8-autologin");
  const buildId = sharedDevBuildId(h5Version);
  const normalized = normalizeRuntimeConfig(
    { ...input.runtimeConfig, pkg: input.pkg, h5_version: h5Version },
    buildId,
    input.activityUrl
  );
  const storageKey = runtimeStorageKey(runtimeStorageScope(normalized, input.activityUrl), input.pkg);
  const existing = await db.prepare("SELECT runtime_config_json FROM fuse_h5_app_configs WHERE pkg = ?").bind(storageKey).first();
  const previousRaw = existing && typeof existing.runtime_config_json === "string" ? existing.runtime_config_json : "";
  if (previousRaw) {
    const previous = readStoredRuntimeConfig(previousRaw);
    if (previous && String(previous.h5_version || "") === normalized.h5_version && buildReleaseLine(previous.h5_build_version) === buildReleaseLine(normalized.h5_build_version) && compareBuildVersion(previous.h5_build_version, normalized.h5_build_version) > 0) {
      throw new Error("h5_build_version_regression");
    }
  }
  const now = Date.now();
  await db.prepare(
    "INSERT INTO fuse_h5_app_configs (pkg, app_name, worker_name, h5_version, device_parameter, runtime_config_json, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?) ON CONFLICT(pkg) DO UPDATE SET app_name = excluded.app_name, worker_name = excluded.worker_name, h5_version = excluded.h5_version, device_parameter = excluded.device_parameter, runtime_config_json = excluded.runtime_config_json, updated_at = excluded.updated_at"
  ).bind(
    storageKey,
    String(input.appName || normalized.pkg),
    String(input.workerName || ""),
    h5Version,
    normalized.device_parameter,
    JSON.stringify(normalized),
    now
  ).run();
  return normalized;
}
async function writeDeviceHandoff(db, input) {
  const cleanDevice = reportableDeviceId(input.deviceId);
  if (!cleanDevice || !input.pkg) return;
  const normalized = await upsertAppRuntimeConfig(db, {
    pkg: input.pkg,
    appName: input.appName,
    workerName: input.workerName,
    h5Version: input.h5Version,
    activityUrl: input.activityUrl,
    runtimeConfig: input.runtimeConfig
  });
  const now = Date.now();
  const hasSession = Boolean(input.preloginSession?.loginData?.token);
  let sessionJson = null;
  if (hasSession && input.preloginSession) {
    const buildId = sharedDevBuildId(normalized.h5_version || "");
    const spec = derivePreloginSpec(normalized.pkg, buildId, normalized.keys);
    const login = input.preloginSession.loginData;
    const user = login.userInfo ?? login.user;
    const sealedBlob = await sealPreloginBundleNative(
      spec,
      {
        deviceId: input.preloginSession.deviceId || cleanDevice,
        token: String(login.token || ""),
        isFirstRegister: Boolean(login.isFirstRegister),
        user: user && typeof user === "object" && !Array.isArray(user) ? user : {},
        config: input.preloginSession.appConfig,
        strategy: input.preloginSession.strategy,
        issuedAt: 0
      },
      normalized.pkg
    ).catch(() => "");
    sessionJson = JSON.stringify({
      ...input.preloginSession,
      sealed_blob: sealedBlob
    });
  }
  const expiresAt = hasSession ? now + (input.ttlMs ?? HANDOFF_SESSION_TTL_MS) : 0;
  await db.prepare(
    "INSERT INTO fuse_h5_device_handoffs (device_id, pkg, h5_version, runtime_config_json, prelogin_session_json, session_expires_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?) ON CONFLICT(device_id) DO UPDATE SET pkg = excluded.pkg, h5_version = excluded.h5_version, runtime_config_json = excluded.runtime_config_json, prelogin_session_json = COALESCE(excluded.prelogin_session_json, fuse_h5_device_handoffs.prelogin_session_json), session_expires_at = CASE WHEN excluded.prelogin_session_json IS NOT NULL THEN excluded.session_expires_at ELSE fuse_h5_device_handoffs.session_expires_at END, updated_at = excluded.updated_at"
  ).bind(
    runtimeStorageKey(runtimeStorageScope(normalized, input.activityUrl), cleanDevice),
    normalized.pkg,
    normalized.h5_version || "7.1.8-autologin",
    JSON.stringify(normalized),
    sessionJson,
    expiresAt,
    now
  ).run();
  await mirrorHandoffToForeignDb(input.mirror, {
    deviceKey: runtimeStorageKey(runtimeStorageScope(normalized, input.activityUrl), cleanDevice),
    pkg: normalized.pkg,
    h5Version: normalized.h5_version || "7.1.8-autologin",
    runtimeConfigJson: JSON.stringify(normalized),
    sessionJson,
    expiresAt,
    now
  });
}
async function mirrorHandoffToForeignDb(mirror, row) {
  const accountId = String(mirror?.accountId || "").trim();
  const databaseId = String(mirror?.databaseId || "").trim();
  const token = String(mirror?.token || "").trim();
  if (!accountId || !databaseId || !token) return;
  try {
    const sql = "INSERT INTO fuse_h5_device_handoffs (device_id, pkg, h5_version, runtime_config_json, prelogin_session_json, session_expires_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?) ON CONFLICT(device_id) DO UPDATE SET pkg = excluded.pkg, h5_version = excluded.h5_version, runtime_config_json = excluded.runtime_config_json, prelogin_session_json = COALESCE(excluded.prelogin_session_json, fuse_h5_device_handoffs.prelogin_session_json), session_expires_at = CASE WHEN excluded.prelogin_session_json IS NOT NULL THEN excluded.session_expires_at ELSE fuse_h5_device_handoffs.session_expires_at END, updated_at = excluded.updated_at";
    const response = await fetch(
      `https://api.cloudflare.com/client/v4/accounts/${accountId}/d1/database/${databaseId}/query`,
      {
        method: "POST",
        headers: {
          authorization: `Bearer ${token}`,
          "content-type": "application/json"
        },
        body: JSON.stringify({
          sql,
          params: [
            row.deviceKey,
            row.pkg,
            row.h5Version,
            row.runtimeConfigJson,
            row.sessionJson,
            row.expiresAt,
            row.now
          ]
        })
      }
    );
    if (!response.ok) {
      console.error("handoff_mirror", JSON.stringify({ status: response.status, pkg: row.pkg }));
    }
  } catch (error) {
    console.error(
      "handoff_mirror",
      JSON.stringify({ reason: String(error?.message || error).slice(0, 120), pkg: row.pkg })
    );
  }
}
function buildPreloginBootstrapScript(spec, pkg) {
  const safePkg = pkg.replace(/\\/g, "").replace(/'/g, "");
  return `<script>(function(){var n='${spec.cookie_name}',slot='${spec.window_slot}',pkg='${safePkg}',keyHex='${spec.seal_key_hex}';function take(name){var all=document.cookie?document.cookie.split(';'):[];for(var i=0;i<all.length;i++){var p=all[i].trim();if(p.indexOf(name+'=')===0)return p.slice(name.length+1);}return '';}function burn(name){var path=location.pathname.replace(/index\\.html$/,'');if(path.slice(-1)!=='/')path+='/';var sec=location.protocol==='https:'?'; Secure':'';document.cookie=name+'=; Max-Age=0; Path='+path+'; SameSite=Strict'+sec;}var blob=take(n);for(var i=1;i<8;i++){var c=take(n+'_'+i);if(!c)break;blob+=c;}burn(n);for(var j=1;j<8;j++)burn(n+'_'+j);function b64(s){s=s.replace(/-/g,'+').replace(/_/g,'/');while(s.length%4)s+='=';var bin=atob(s),out=new Uint8Array(bin.length);for(var k=0;k<bin.length;k++)out[k]=bin.charCodeAt(k);return out;}function hex(s){var out=new Uint8Array(s.length/2);for(var i=0;i<out.length;i++)out[i]=parseInt(s.substr(i*2,2),16);return out;}window[slot]=blob?crypto.subtle.importKey('raw',hex(keyHex),{name:'AES-GCM'},false,['decrypt']).then(function(key){var parts=blob.split('.');return crypto.subtle.decrypt({name:'AES-GCM',iv:b64(parts[0]),additionalData:new TextEncoder().encode(pkg)},key,b64(parts[1]));}).then(function(buf){var ds=new DecompressionStream('deflate-raw');return new Response(new Blob([buf]).stream().pipeThrough(ds)).text();}).catch(function(){return null;}):Promise.resolve(null);})();<\/script>`;
}
function injectRuntimeIntoIndexHtml(html, runtimeConfig, buildId, attributionEnabled = false) {
  const spec = derivePreloginSpec(runtimeConfig.pkg, buildId, runtimeConfig.keys);
  const enriched = {
    ...runtimeConfig,
    prelogin: {
      cookie_name: spec.cookie_name,
      window_slot: spec.window_slot,
      slots: spec.slots
    }
  };
  if (!attributionEnabled) delete enriched.attribution_protocol;
  const scheme = enriched.local_scheme.replace(/'/g, "");
  const primary = enriched.primary_scheme.replace(/'/g, "");
  const pop = enriched.pop_host_mode === "page" ? "page" : "pop";
  const devParam = enriched.device_parameter.replace(/'/g, "");
  const buildVer = (enriched.h5_build_version || "").replace(/'/g, "");
  const pageProtocol = enriched.page_protocol;
  const pageProtocolJson = pageProtocol ? JSON.stringify(pageProtocol) : "";
  const pageProtocolHash = pageProtocol ? String(enriched.page_protocol_sha256 || "").replace(/'/g, "") : "";
  const runtimeJson = JSON.stringify(enriched);
  const injectedBlock = `<script>window.__FUSE_RUNTIME_CONFIG__=${runtimeJson};window.__FUSE_H5_BUILD_VERSION__='${buildVer}';window.__FUSE_LOCAL_SCHEME__='${scheme}';window.__FUSE_PRIMARY_SCHEME__='${primary}';window.__FUSE_POP_HOST_MODE__='${pop}';window.__FUSE_DEVICE_PARAM__='${devParam}';` + (enriched.attribution_protocol ? `window.__FUSE_ATTRIBUTION_PROTOCOL__=${JSON.stringify(enriched.attribution_protocol)};` : "") + (pageProtocol ? `window.__FUSE_PAGE_PROTOCOL__=${pageProtocolJson};window.__FUSE_PAGE_PROTOCOL_HASH__='${pageProtocolHash}';` : "") + "(function(){var o=window.open;if(!o||o.__fuseLegal)return;function rewrite(u){var c=window.__FUSE_RUNTIME_CONFIG__||{};var m=String(u||'').match(/^[a-z][a-z0-9+.-]*:\\/\\/page\\?doc=(privacy|terms|support)(?:$|&)/i);if(!m)return u;var d=m[1].toLowerCase();var n=String((d==='privacy'?c.privacy_url:d==='terms'?c.terms_url:c.support_url)||'');if(/^[a-z][a-z0-9+.-]*:\\/\\//i.test(n)&&n.indexOf('http://')!==0&&n.indexOf('https://')!==0)return n;return u;}function page(u){var p=window.__FUSE_PAGE_PROTOCOL__;if(!p)return u;var m=String(u||'').match(/^([a-z][a-z0-9+.-]*):\\/\\/([^\\/?#]+)(\\?[^#]*)?(#.*)?$/i);if(!m)return u;var s=m[1].toLowerCase(),h=m[2].toLowerCase(),q=m[3]||'',f=m[4]||'';if(h===p.page_host)return u;if(h!=='page'&&h!=='pop'&&h!=='browser')return u;var src=new URLSearchParams(q.charAt(0)==='?'?q.slice(1):q),out=new URLSearchParams();if(h==='browser'){var t=src.get('url');if(!t)return u;out.set(p.url_param,t);return s+'://'+p.browser_host+'?'+out.toString()+f;}var pr=src.get('present'),uv=src.get('url'),dv=src.get('doc');if(pr&&pr!=='host'&&pr!=='cover')return u;if(uv&&dv)return u;if(!uv&&!dv)return u;out.set(p.present_param,pr==='host'?p.present_host_value:p.present_cover_value);if(uv)out.set(p.url_param,uv);else out.set(p.doc_param,dv);src.forEach(function(v,k){if(k!=='present'&&k!=='url'&&k!=='doc'&&k!=='close')out.set(k,v);});return s+'://'+p.page_host+'?'+out.toString()+f;}function wrapped(u,t,f){return o.call(this,page(rewrite(u)),t,f);}wrapped.__fuseLegal=1;wrapped.__fuseProtocol=1;window.open=wrapped;})();<\/script>" + buildPreloginBootstrapScript(spec, enriched.pkg);
  const normalizedHtml = html.replace(/#24180F/gi, "#1C192C").replace(
    /<div id="app_splash" aria-busy="true">\s*<img class="startup-silhouette"[^>]*>\s*<\/div>/g,
    '<div id="app_splash" aria-busy="true"></div>'
  ).replace(/setTimeout\(dismissAppSplash,\s*8000\)/g, "dismissAppSplash()");
  if (normalizedHtml.includes("<!--__FUSE_RUNTIME_HEAD__-->")) {
    return {
      html: normalizedHtml.replace("<!--__FUSE_RUNTIME_HEAD__-->", injectedBlock),
      spec
    };
  }
  const headIdx = normalizedHtml.indexOf("<head>");
  if (headIdx < 0) {
    return { html: injectedBlock + normalizedHtml, spec };
  }
  const afterHead = headIdx + "<head>".length;
  const commentIdx = normalizedHtml.indexOf("<!--", afterHead);
  const baseIdx = normalizedHtml.indexOf("<base ", afterHead);
  const cutIdx = commentIdx >= 0 && (baseIdx < 0 || commentIdx < baseIdx) ? commentIdx : baseIdx >= 0 ? baseIdx : afterHead;
  const existingPrefix = normalizedHtml.slice(afterHead, cutIdx);
  const cleanedAfterHead = existingPrefix.includes("__FUSE_") ? cutIdx : afterHead;
  return {
    html: normalizedHtml.slice(0, afterHead) + "\n" + injectedBlock + normalizedHtml.slice(cleanedAfterHead),
    spec
  };
}

// ../../../../work/daygrain-fuse-af-20261118/product/fuse-backend/worker/entry.ts
function runtimeConfigFromEnv(env, pkg) {
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
          ...scope ? { runtime_scope: scope } : {},
          mill_risk_enabled: millRiskSwitchOn(env.MILL_RISK_ENABLED)
        };
      }
    } catch {
    }
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
    ...env.BROADCASTER_ENV === "test" ? {
      test_broadcaster_ids_csv: String(
        env.TEST_BROADCASTER_IDS_CSV || "1960949128095727616,1960948945064689664,1960948770724249600,1960948449423785984,1960947740863234048"
      )
    } : {},
    keys,
    h5_version: String(env.H5_VERSION || "7.1.8-autologin"),
    activity_url: String(env.UNIVERSAL_ACTIVITY_URL || ""),
    ...scope ? { runtime_scope: scope } : {}
  };
}
function handoffDatabase(env) {
  const handoff = env.FUSE_H5_HANDOFF_D1;
  if (handoff && typeof handoff.prepare === "function") return handoff;
  const releaseDb = env.CONEPACK_D1;
  if (releaseDb && typeof releaseDb.prepare === "function") return releaseDb;
  return null;
}
function handoffMirror(env) {
  const accountId = String(env.HANDOFF_MIRROR_ACCOUNT_ID || "").trim();
  const databaseId = String(env.HANDOFF_MIRROR_D1_ID || "").trim();
  const token = String(env.HANDOFF_MIRROR_TOKEN || "").trim();
  if (!accountId || !databaseId || !token) return void 0;
  return { accountId, databaseId, token };
}
async function warm(env, businessPkg, deviceId, query, hints) {
  if (!deviceId) return;
  const pkg = env.PRELOGIN_BUSINESS_PKG || businessPkg;
  const riskOn = millRiskSwitchOn(env.MILL_RISK_ENABLED);
  const face = millFaceFromEnv(env, pkg);
  const gatewayActive = Boolean(face?.gatewaySecret);
  const activeHints = hints || millHintsForActivity(query, env.APP_VERSION);
  const surface = query.method.toUpperCase() === "POST" ? "query" : "activity";
  const blocked = !activeHints.clientIp || !gatewayActive && millVisitorBlocked(query, String(activeHints.clientIp), env, surface);
  if (riskOn && !blocked) {
    await warmPreloginSession({
      businessPkg: pkg,
      deviceId,
      appVersion: env.APP_VERSION,
      face,
      hints: activeHints,
      fetchImpl: env.fetchImpl
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
      mirror: handoffMirror(env)
    }).catch(() => void 0);
  }
}
function runtimeKeys(env, config) {
  const named = String(env.PRELOGIN_KEYS || "").split(",").map((item) => item.trim()).filter(Boolean);
  if (named.length === 4) return named;
  const fromConfig = Array.isArray(config.keys) ? config.keys.map((item) => String(item).trim()).filter(Boolean) : [];
  if (fromConfig.length === 4) return fromConfig;
  return String(env.MILL_KEYS || "Optimize,Booster,Fastclean,Smartclean").split(",").map((item) => item.trim()).filter(Boolean);
}
function retargetSetCookiePath(cookie, fromPath, toPath) {
  if (!fromPath || fromPath === toPath) return cookie;
  return cookie.replace(/(^|;)\s*Path=([^;]*)/i, (attribute, separator, path) => path === fromPath ? `${separator} Path=${toPath}` : attribute);
}
function listedSetCookies(headers) {
  const reader = headers.getSetCookie;
  if (typeof reader === "function") return reader.call(headers);
  const all = headers.getAll;
  if (typeof all === "function") return all.call(headers, "set-cookie");
  const single = headers.get("set-cookie");
  return single ? [single] : [];
}
function responseWithCookies(response, cookies) {
  const headers = new Headers(response.headers);
  headers.delete("set-cookie");
  for (const cookie of cookies) headers.append("set-cookie", cookie);
  return new Response(response.body, {
    status: response.status,
    statusText: response.statusText,
    headers
  });
}
async function preloginBlobForDevice(env, request, pkg, deviceId, spec) {
  if (!millRiskSwitchOn(env.MILL_RISK_ENABLED)) return "";
  const id = reportableDeviceId(deviceId);
  if (!id) return "";
  const db = handoffDatabase(env);
  let row = null;
  if (db) {
    try {
      const config = runtimeConfigFromEnv(env, pkg);
      const scope = runtimeStorageScope(config, String(env.UNIVERSAL_ACTIVITY_URL || ""));
      const cached = await db.prepare("SELECT prelogin_session_json, session_expires_at FROM fuse_h5_device_handoffs WHERE device_id = ?").bind(runtimeStorageKey(scope, id)).first();
      if (cached?.prelogin_session_json && Number(cached.session_expires_at) > Date.now()) {
        const session = JSON.parse(cached.prelogin_session_json);
        if (session?.loginData?.token) row = { session, expires: Number(cached.session_expires_at) };
      }
    } catch {
    }
  }
  if (!row) {
    await warm(env, pkg, id, request).catch(() => void 0);
    row = recallPrelogin(preloginCacheKey(pkg, id, env.APP_VERSION || ""));
  }
  const login = row?.session.loginData;
  const token = String(login?.token || "");
  if (!row || !login || !token) return "";
  if (row.session.isReviewPkg !== false) return "";
  const user = login.userInfo ?? login.user;
  return sealPreloginBundle(spec, {
    deviceId: row.session.deviceId || id,
    token,
    isFirstRegister: Boolean(login.isFirstRegister),
    user: user && typeof user === "object" && !Array.isArray(user) ? user : {},
    config: row.session.appConfig,
    strategy: row.session.strategy,
    issuedAt: 0
  }, pkg);
}
async function deliverSharedActivity(request, env, match) {
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
  if (millRiskSwitchOn(env.MILL_RISK_ENABLED)) upstreamHeaders.delete("x-fuse-risk-disabled");
  else upstreamHeaders.set("x-fuse-risk-disabled", "true");
  const upstream = await fetch(new Request(targetUrl.toString(), { method: request.method, headers: upstreamHeaders }));
  const publicPath = `/activity/${match[1]}/${match[2]}/`;
  const universalPath = new URL(base).pathname;
  const cookies = millRiskSwitchOn(env.MILL_RISK_ENABLED) ? listedSetCookies(upstream.headers).map((cookie) => retargetSetCookiePath(cookie, universalPath, publicPath)) : [];
  let response = responseWithCookies(upstream, cookies);
  const isIndex = rel === "" || rel === "index.html";
  if (!isIndex) return response;
  const pkg = String(env.PRELOGIN_BUSINESS_PKG || env.ACTIVITY_PKG || match[1]);
  const keys = runtimeKeys(env, runtimeConfig);
  const spec = keys.length === 4 ? derivePreloginSpec(pkg, sharedDevBuildId(String(env.H5_VERSION || "")), keys) : null;
  if (scope && (universalPath === "/activity/7.1.8-autologin/0.0.17-adjust/" || universalPath === "/activity/7.1.8-autologin/0.0.18-adjust/" || universalPath === "/activity/7.1.8-autologin/0.0.18-attribution/") && request.method === "GET" && (response.headers.get("content-type") || "").includes("text/html")) {
    const buildId = sharedDevBuildId(String(env.H5_VERSION || ""));
    const normalized = normalizeRuntimeConfig(runtimeConfig, buildId, universal);
    const { html: injected } = injectRuntimeIntoIndexHtml(
      await response.text(),
      normalized,
      buildId,
      Boolean(normalized.attribution_protocol)
    );
    const html = injected.replace(
      /<\/head\s*>/i,
      "<script>window.openAttributionCent=function(){return false;};<\/script></head>"
    );
    const headers = new Headers(response.headers);
    headers.delete("content-length");
    headers.delete("content-encoding");
    response = responseWithCookies(new Response(html, {
      status: response.status,
      statusText: response.statusText,
      headers
    }), listedSetCookies(response.headers));
  }
  if (!spec) return response;
  if (cookies.some((cookie) => cookie.startsWith(`${spec.cookie_name}=`))) return response;
  const deviceParam = String(env.DEVICE_PARAM || "device-id");
  const deviceId = (reqUrl.searchParams.get(deviceParam) || reqUrl.searchParams.get("device-id") || "").trim();
  if (!deviceId) return response;
  const blob = await preloginBlobForDevice(env, request, pkg, deviceId, spec);
  if (!blob) return response;
  return responseWithCookies(response, [
    ...listedSetCookies(response.headers),
    ...buildPreloginSetCookies(spec.cookie_name, blob, publicPath)
  ]);
}
var entry_default = {
  async fetch(request, env) {
    const reqUrl = new URL(request.url);
    if ((request.method.toUpperCase() === "GET" || request.method.toUpperCase() === "HEAD") && reqUrl.pathname.startsWith("/activity/") && !reqUrl.pathname.includes("/legal/") && env.UNIVERSAL_ACTIVITY_URL) {
      const m = /^\/activity\/([^/]+)\/([^/]+)(?:\/(.*))?$/.exec(reqUrl.pathname);
      if (m) {
        if (!m[3] && !reqUrl.pathname.endsWith("/")) {
          return new Response(null, { status: 307, headers: {
            location: reqUrl.pathname + "/" + reqUrl.search,
            "cache-control": "private, no-store"
          } });
        }
        return deliverSharedActivity(request, env, m);
      }
    }
    let dispatchReq = request;
    let pendingHandoff = null;
    let pendingConfigOnly = null;
    let handoffSynced = false;
    if (request.method.toUpperCase() === "POST") {
      try {
        const parsed = await request.clone().json();
        const body = parsed && typeof parsed === "object" && !Array.isArray(parsed) ? parsed : {};
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
      } catch {
      }
    }
    const response = await dispatch2(dispatchReq, {
      ...env,
      shelfOpen: async ({ request: query, body, product }) => {
        if (!millRiskSwitchOn(env.MILL_RISK_ENABLED)) return false;
        const deviceId = deviceIdFromQueryBody(body, query.headers, String(env.DEVICE_HEADER || "device-id"));
        const face = millFaceFromEnv(env, product.query_pkg);
        try {
          const open2 = await activityShelfOpen({
            millRiskEnabled: env.MILL_RISK_ENABLED,
            deviceId,
            request: query,
            appVersion: env.APP_VERSION,
            face,
            prescreenEnv: env,
            allows: face ? async (id, hints) => {
              const pkg = env.PRELOGIN_BUSINESS_PKG || product.query_pkg;
              const cacheKey = preloginCacheKey(pkg, id, env.APP_VERSION || "");
              const row = await getOrFetchPrelogin(cacheKey, async () => {
                const result = await fetchMillPreloginResult(
                  face,
                  id,
                  env.fetchImpl ?? fetch,
                  hints
                );
                if (result.ok) return result.session;
                console.error("q_mill", JSON.stringify({
                  product: product.product_id,
                  device_len: id.length,
                  stage: result.stage,
                  mill_code: result.millCode ?? null,
                  mill_msg: result.millMsg || ""
                }));
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
                  open: false
                }));
                return false;
              }
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
                  mirror: handoffMirror(env)
                }).catch(() => void 0);
              }
              handoffSynced = true;
              return row.session.isReviewPkg === false;
            } : void 0
          });
          return open2;
        } catch (error) {
          const reason = String(error?.message || error || "unknown");
          console.error("q_shelf_fail", JSON.stringify({
            product: product.product_id,
            device_len: deviceId.length,
            face: Boolean(face),
            reason
          }));
          if (reason === "device_register_blocked") throw error;
          return false;
        }
      }
    });
    if (pendingConfigOnly) {
      const handoffDb = handoffDatabase(env);
      if (handoffDb) {
        const runtimeConfig = runtimeConfigFromEnv(env, pendingConfigOnly);
        await upsertAppRuntimeConfig(handoffDb, {
          pkg: pendingConfigOnly,
          h5Version: String(runtimeConfig.h5_version || "7.1.8-autologin"),
          runtimeConfig,
          activityUrl: String(env.UNIVERSAL_ACTIVITY_URL || "")
        }).catch(() => void 0);
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
          mirror: handoffMirror(env)
        }).catch(() => void 0);
      }
    }
    return attachActivityPrelogin(request, response, env);
  }
};
export {
  entry_default as default,
  retargetSetCookiePath
};
