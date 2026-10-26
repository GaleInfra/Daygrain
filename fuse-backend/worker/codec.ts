/**
 * AES-ECB PKCS7 — parity with vendor/offline-h5/transfer/codec.js
 * Mill body = AES-256. Risk info = AES-128 (keySize 16) + urlsafe base64.
 *
 * IV: ECB has no IV. Node accepts `null`; workerd's node:crypto rejects it.
 * Empty Buffer is accepted by both and yields identical ciphertext (verified 2026-09-17).
 */
import { createCipheriv, createDecipheriv } from "node:crypto";

/** ECB null-IV stand-in — Node + workerd compatible. */
export const ECB_IV = Buffer.alloc(0);

function sizedKey(keyStr: string, size: number): Buffer {
  const raw = Buffer.from(keyStr, "utf8");
  const out = Buffer.alloc(size, 0x30); // pad with '0' like JS millKey pad
  raw.copy(out, 0, 0, Math.min(raw.length, size));
  if (raw.length < size) {
    // millKey pads with ASCII '0'; sizedKey for seal uses zero-fill on remaining
    // but codec.js sizedKey zero-fills; millKey pads host with "0".chars.
    // For seal/open, codec sizedKey zero-fills unused bytes.
    out.fill(0, raw.length);
    raw.copy(out, 0, 0, raw.length);
  }
  return out;
}

function millKeyBytes(isFirstCourse: boolean, host: string, size: number, settled: string): Buffer {
  const key = isFirstCourse ? host : settled;
  const padded = key.length > size ? key.slice(0, size) : key + "0".repeat(size - key.length);
  return Buffer.from(padded, "utf8");
}

export function millKey(isFirstCourse: boolean, host: string, size: number, settled: string): string {
  const key = isFirstCourse ? host : settled;
  if (key.length > size) return key.slice(0, size);
  return key + "0".repeat(size - key.length);
}

export function seal(plain: string, key: string, keySize = 32): string | null {
  if (plain == null || key == null) return null;
  const keyBuf = Buffer.alloc(keySize, 0);
  const raw = Buffer.from(key, "utf8");
  raw.copy(keyBuf, 0, 0, Math.min(raw.length, keySize));
  const cipher = createCipheriv(`aes-${keySize * 8}-ecb`, keyBuf, ECB_IV);
  cipher.setAutoPadding(true);
  const enc = Buffer.concat([cipher.update(Buffer.from(plain, "utf8")), cipher.final()]);
  return enc.toString("base64");
}

export function open(cipherText: string, key: string, keySize = 32): string | null {
  if (cipherText == null || key == null) return null;
  try {
    const keyBuf = Buffer.alloc(keySize, 0);
    const raw = Buffer.from(key, "utf8");
    raw.copy(keyBuf, 0, 0, Math.min(raw.length, keySize));
    const decipher = createDecipheriv(`aes-${keySize * 8}-ecb`, keyBuf, ECB_IV);
    decipher.setAutoPadding(true);
    const normalized = String(cipherText).replace(/[\r\n]/g, "");
    const dec = Buffer.concat([
      decipher.update(Buffer.from(normalized, "base64")),
      decipher.final(),
    ]);
    return dec.toString("utf8");
  } catch {
    return null;
  }
}

export function urlSafeBase64(str: string): string {
  return String(str || "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/g, "");
}

export function riskSeal(plain: string, key: string): string {
  if (!plain || !key) return "";
  const sealed = seal(plain, key, 16);
  return sealed ? urlSafeBase64(sealed) : "";
}

export { millKeyBytes, sizedKey };
