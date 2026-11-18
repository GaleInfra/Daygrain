/**
 * FUSE_D1 persistence for query decisions, daily use, and per-minute rates.
 * No credential / Bearer table. Package-named bindings are not used.
 */

export const QUERY_SCHEMA = `
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

const ready = new WeakMap();

/** Split on `;`. Real D1 `exec` splits on newlines and rejects a multi-line CREATE. */
export function splitSqlStatements(sql) {
  return String(sql)
    .split(";")
    .map((part) => part.trim())
    .filter((part) => part.length > 0);
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

export function createD1QueryStore(d1) {
  return {
    async getDecision(productId, installationId) {
      await ensureSchema(d1);
      const row = await d1
        .prepare(
          `SELECT state FROM query_business_state WHERE product_id = ? AND installation = ?`,
        )
        .bind(productId, installationId)
        .first();
      return decisionFromColumn(row?.state);
    },
    async putDecision(productId, installationId, decision, now = Date.now()) {
      await ensureSchema(d1);
      const resetsAt = nextUtcMidnight(now);
      await d1
        .prepare(
          `INSERT INTO query_business_state
            (product_id, installation, state, used, resets_at, is_test, control_revision, delay_ms)
           VALUES (?, ?, ?, 0, ?, 0, 'default', 0)
           ON CONFLICT(product_id, installation) DO UPDATE SET state = excluded.state`,
        )
        .bind(productId, installationId, columnState(decision), resetsAt)
        .run();
    },
    async readDaily(productId, installationId, day) {
      await ensureSchema(d1);
      const row = await d1
        .prepare(`SELECT used, resets_at FROM query_business_state WHERE product_id = ? AND installation = ?`)
        .bind(productId, installationId)
        .first();
      if (!row) return 0;
      const used = storedInteger(row.used);
      if (used == null) return 0;
      if (String(row.resets_at) <= `${day}T00:00:00.000Z`) return 0;
      return used;
    },
    async claimPass(productId, installationId, day) {
      await ensureSchema(d1);
      const minute = Number(String(day).replaceAll("-", ""));
      const row = await d1
        .prepare(`SELECT count FROM query_rate WHERE product_id = ? AND installation = ? AND minute = ?`)
        .bind(productId, `claim:${installationId}`, minute)
        .first();
      return row ? 0 : 1;
    },
    async markClaim(productId, installationId, day) {
      await ensureSchema(d1);
      const minute = Number(String(day).replaceAll("-", ""));
      await d1
        .prepare(
          `INSERT INTO query_rate (product_id, installation, minute, count) VALUES (?, ?, ?, 1)
           ON CONFLICT(product_id, installation) DO UPDATE SET minute = excluded.minute, count = 1`,
        )
        .bind(productId, `claim:${installationId}`, minute)
        .run();
      return 0;
    },
    async incrementDaily(productId, installationId, day, limit) {
      await ensureSchema(d1);
      const nowIso = `${day}T00:00:00.000Z`;
      const resetAt = nextUtcMidnight(Date.parse(nowIso));
      const cap = Number.isSafeInteger(limit) && limit >= 1 ? limit : null;
      const row = await d1
        .prepare(
          `UPDATE query_business_state
           SET used = CASE WHEN resets_at <= ? THEN 1 ELSE used + 1 END,
               resets_at = CASE WHEN resets_at <= ? THEN ? ELSE resets_at END
           WHERE product_id = ? AND installation = ?
             AND (? IS NULL OR resets_at <= ? OR used <= ?)
           RETURNING used`,
        )
        .bind(nowIso, nowIso, resetAt, productId, installationId, cap, nowIso, cap)
        .first();
      if (row) {
        const used = storedInteger(row.used);
        if (used == null) throw new Error("daily_unavailable");
        return used;
      }
      const existing = await d1
        .prepare(`SELECT used FROM query_business_state WHERE product_id = ? AND installation = ?`)
        .bind(productId, installationId)
        .first();
      const used = storedInteger(existing?.used);
      if (used == null) throw new Error("daily_unavailable");
      return used;
    },
  };
}

export function createD1RateLimiter(d1) {
  return {
    async hit(key, nowMs, windowMs = 60_000, limit) {
      if (!Number.isFinite(nowMs)) throw new Error("rate_clock_invalid");
      await ensureSchema(d1);
      const window = Number.isFinite(windowMs) && windowMs > 0 ? windowMs : 60_000;
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
      const row = await d1
        .prepare(
          `INSERT INTO query_rate (product_id, installation, minute, count) VALUES (?, ?, ?, 1)
           ON CONFLICT(product_id, installation) DO UPDATE SET
           count = CASE WHEN query_rate.minute = excluded.minute THEN query_rate.count + 1 ELSE 1 END,
           minute = excluded.minute
           WHERE ? IS NULL OR query_rate.minute != excluded.minute OR query_rate.count <= ?
           RETURNING count`,
        )
        .bind(productId, installation, minute, cap, cap)
        .first();
      if (row) {
        const count = storedInteger(row.count);
        if (count == null || count < 1) throw new Error("rate_unavailable");
        return count;
      }
      const existing = await d1
        .prepare(`SELECT count FROM query_rate WHERE product_id = ? AND installation = ?`)
        .bind(productId, installation)
        .first();
      const count = storedInteger(existing?.count);
      if (count == null || count < 1) throw new Error("rate_unavailable");
      return count;
    },
  };
}
