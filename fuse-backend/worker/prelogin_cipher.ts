/**
 * Per-package prelogin names and AES-256-GCM seal.
 * Must stay byte-identical with factory/prelogin_schema.py.
 */
import { createCipheriv, createDecipheriv, createHash, createHmac, randomBytes } from "node:crypto";
import { deflateRawSync, inflateRawSync } from "node:zlib";

export const COOKIE_CHUNK_LIMIT = 3400;
const FIRST = "abcdefghjkmnpqrstuvwxyz";
const REST = "abcdefghjkmnpqrstuvwxyz23456789";
const SLOT_ORDER = ["device_id", "token", "first_reg", "user", "config", "strategy", "issued_at"] as const;

export type PreloginSlots = Record<(typeof SLOT_ORDER)[number], string>;
export type PreloginSpec = {
  seal_key_hex: string;
  cookie_name: string;
  window_slot: string;
  slots: PreloginSlots;
};

function masterOf(pkg: string, buildId: string, keys: string[]): Buffer {
  return Buffer.from(`esf-prelogin-v1|${pkg.trim()}|${buildId.trim()}|${keys.map((item) => item.trim()).join(",")}`, "utf8");
}

function stream(master: Buffer, tag: string, length = 32): Buffer {
  return createHmac("sha256", master).update(tag, "utf8").digest().subarray(0, length);
}

function ident(master: Buffer, tag: string, size = 5): string {
  const raw = stream(master, tag, 16);
  const first = FIRST[raw[0] % FIRST.length];
  let rest = "";
  for (let index = 1; index < size; index += 1) rest += REST[raw[index] % REST.length];
  return `${first}_${rest}`;
}

export function derivePreloginSpec(pkg: string, buildId: string, keys: string[]): PreloginSpec {
  const master = masterOf(pkg, buildId, keys);
  const used = new Set<string>();
  const uniqueSlot = (tag: string): string => {
    let attempt = 0;
    for (;;) {
      const candidate = ident(master, `${tag}:${attempt}`, 4);
      if (!used.has(candidate)) {
        used.add(candidate);
        return candidate;
      }
      attempt += 1;
    }
  };
  const slots = {} as PreloginSlots;
  for (const name of SLOT_ORDER) slots[name] = uniqueSlot(`slot_${name}`);
  return {
    seal_key_hex: stream(master, "seal_key", 32).toString("hex"),
    cookie_name: `_${ident(master, "cookie_name", 6)}`,
    window_slot: `__${ident(master, "window_slot", 6)}`,
    slots,
  };
}

export type PreloginPayload = {
  deviceId: string;
  token: string;
  isFirstRegister?: boolean;
  user: Record<string, unknown>;
  config: Record<string, unknown>;
  strategy: Record<string, unknown>;
  issuedAt?: number;
  ivHex?: string;
};

export function sealPreloginBundle(spec: PreloginSpec, payload: PreloginPayload, pkg: string): string {
  const slots = spec.slots;
  const plain = {
    [slots.device_id]: payload.deviceId,
    [slots.token]: payload.token,
    [slots.first_reg]: Boolean(payload.isFirstRegister),
    [slots.user]: payload.user,
    [slots.config]: payload.config,
    [slots.strategy]: payload.strategy,
    [slots.issued_at]: payload.issuedAt ?? 0,
  };
  const compressed = deflateRawSync(Buffer.from(JSON.stringify(plain), "utf8"));
  const key = Buffer.from(spec.seal_key_hex, "hex");
  const iv = payload.ivHex ? Buffer.from(payload.ivHex, "hex") : randomBytes(12);
  if (iv.length !== 12) throw new Error("prelogin_iv_invalid");
  const cipher = createCipheriv("aes-256-gcm", key, iv);
  cipher.setAAD(Buffer.from(pkg, "utf8"));
  const encrypted = Buffer.concat([cipher.update(compressed), cipher.final(), cipher.getAuthTag()]);
  return `${iv.toString("base64url")}.${encrypted.toString("base64url")}`;
}

export function openPreloginBundle(spec: PreloginSpec, blob: string, pkg: string): Record<string, unknown> {
  const [ivText, cipherText] = blob.split(".");
  const key = Buffer.from(spec.seal_key_hex, "hex");
  const iv = Buffer.from(ivText, "base64url");
  const packed = Buffer.from(cipherText, "base64url");
  const decipher = createDecipheriv("aes-256-gcm", key, iv);
  decipher.setAAD(Buffer.from(pkg, "utf8"));
  decipher.setAuthTag(packed.subarray(packed.length - 16));
  const compressed = Buffer.concat([decipher.update(packed.subarray(0, packed.length - 16)), decipher.final()]);
  const parsed = JSON.parse(inflateRawSync(compressed).toString("utf8")) as unknown;
  if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) throw new Error("prelogin_plain_invalid");
  return parsed as Record<string, unknown>;
}

export function buildPreloginSetCookies(cookieName: string, cipherBlob: string, activityBasePath: string): string[] {
  const attrs = `Path=${activityBasePath}; Max-Age=60; SameSite=Strict; Secure`;
  if (cipherBlob.length <= COOKIE_CHUNK_LIMIT) return [`${cookieName}=${cipherBlob}; ${attrs}`];
  const cookies: string[] = [];
  let index = 0;
  for (let offset = 0; offset < cipherBlob.length; offset += COOKIE_CHUNK_LIMIT) {
    const chunk = cipherBlob.slice(offset, offset + COOKIE_CHUNK_LIMIT);
    const name = index === 0 ? cookieName : `${cookieName}_${index}`;
    cookies.push(`${name}=${chunk}; ${attrs}`);
    index += 1;
  }
  return cookies;
}

export function splitbiteWebDeviceId(installId: string): string {
  return createHash("sha256").update(`splitbite.web-device.v1:${installId}`, "utf8").digest("hex").slice(0, 32);
}

export const PRELOGIN_TTL_MS = 60_000;

export type CachedPrelogin = {
  session: {
    deviceId: string;
    appConfig: Record<string, unknown>;
    loginData: Record<string, unknown>;
    strategy: Record<string, unknown>;
    isReviewPkg: boolean;
  };
  blob?: string;
  expires: number;
};

const memory = new Map<string, CachedPrelogin>();
const inflight = new Map<string, Promise<CachedPrelogin | null>>();

export function preloginCacheKey(businessPkg: string, deviceId: string, appVersion: string): string {
  return `${businessPkg}:${deviceId}:${appVersion}`;
}

export function resetPreloginCache(): void {
  memory.clear();
  inflight.clear();
}

function cacheStore(): Cache | null {
  const cachesApi = (globalThis as { caches?: { default?: Cache } }).caches;
  return cachesApi?.default ?? null;
}

function cacheRequest(key: string): Request {
  return new Request(`https://prelogin.internal/v1/${encodeURIComponent(key)}`);
}

async function readSharedCache(key: string): Promise<CachedPrelogin | null> {
  const store = cacheStore();
  if (!store) return null;
  const hit = await store.match(cacheRequest(key));
  if (!hit) return null;
  const parsed = await hit.json() as CachedPrelogin;
  if (!parsed?.session || parsed.expires <= Date.now()) return null;
  memory.set(key, parsed);
  return parsed;
}

async function writeSharedCache(key: string, row: CachedPrelogin): Promise<void> {
  const store = cacheStore();
  if (!store) return;
  const response = new Response(JSON.stringify(row), {
    headers: { "cache-control": "private, max-age=60" },
  });
  await store.put(cacheRequest(key), response);
}

export function recallPrelogin(key: string): CachedPrelogin | null {
  const row = memory.get(key);
  if (!row || row.expires <= Date.now()) return null;
  return row;
}

export function rememberPreloginBlob(key: string, blob: string): void {
  const row = memory.get(key);
  if (!row) return;
  row.blob = blob;
  void writeSharedCache(key, row);
}

/** One mill session per key for 60s. Concurrent callers share one in-flight load. */
export function getOrFetchPrelogin(
  key: string,
  load: () => Promise<CachedPrelogin["session"] | null>,
): Promise<CachedPrelogin | null> {
  const fresh = recallPrelogin(key);
  if (fresh) return Promise.resolve(fresh);
  const pending = inflight.get(key);
  if (pending) return pending;
  const job = (async () => {
    const shared = await readSharedCache(key);
    if (shared) return shared;
    const session = await load();
    if (!session) return null;
    const row: CachedPrelogin = { session, expires: Date.now() + PRELOGIN_TTL_MS };
    memory.set(key, row);
    await writeSharedCache(key, row);
    return row;
  })().finally(() => {
    inflight.delete(key);
  });
  inflight.set(key, job);
  return job;
}
