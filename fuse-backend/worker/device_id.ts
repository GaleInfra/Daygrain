/** Reported business device id. Never longer than 32 characters. */

export const MAX_REPORTED_DEVICE_ID_LENGTH = 32;

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const HEX_RE = /^[0-9a-f]+$/i;

/**
 * Stable ≤32 form of a business device id.
 * Already-short values are kept verbatim so an existing account is not renamed.
 * A dashed UUID loses its hyphens. A hex digest (SHA-256 is 64) keeps its first 32.
 * Anything else longer than 32 is refused: do not invent a new id.
 */
export function narrowBusinessDeviceId(raw: string): string {
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

/** Null when the value must not be sent to the business backend. */
export function reportableDeviceId(raw: string): string | null {
  const id = narrowBusinessDeviceId(raw);
  if (!id || id.length > MAX_REPORTED_DEVICE_ID_LENGTH) return null;
  return id;
}
