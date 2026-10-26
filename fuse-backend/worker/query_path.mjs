/** Semantic query_path helpers — Spec FR-3 (no /q/hex mold). */

/** A product function word. Not /slug_capability, not entry, not /p/<hash> or /q/<hex>. */
export const MOLD_Q_HEX = /^\/q\/[0-9a-f]{24}$/i;
export const BARE_Q = /^\/q\/?$/i;
export const FUNCTION_PATH = /^\/[a-z][a-z0-9]*(?:-[a-z0-9]+)*$/;
const RESERVED_WORDS = new Set(["entry", "activity", "q", "p"]);

export function isForbiddenMoldPath(path) {
  return (
    typeof path !== "string" ||
    BARE_Q.test(path) ||
    MOLD_Q_HEX.test(path) ||
    /^\/p\/?$/i.test(path) ||
    /^\/p\/[a-f0-9]{32}$/i.test(path) ||
    path.includes("_")
  );
}

export function isFunctionPath(path) {
  if (!FUNCTION_PATH.test(path) || isForbiddenMoldPath(path)) return false;
  return !RESERVED_WORDS.has(path.slice(1));
}

export function packageSlug(name) {
  return String(name || "")
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "");
}

/** The word is this product's own function, not its slug and not a shared mold. */
export function functionPathAllowed(path, slug) {
  if (!isFunctionPath(path) || !/^[a-z][a-z0-9]*$/.test(String(slug || ""))) return false;
  const word = path.slice(1);
  return word !== slug && !word.startsWith(`${slug}-`);
}

export function isSemanticQueryPath(path) {
  return isFunctionPath(path);
}

export function assertQueryPath(path) {
  if (isForbiddenMoldPath(path) || !isFunctionPath(path)) {
    throw new Error(`query_path_invalid:${path}`);
  }
  return path;
}
