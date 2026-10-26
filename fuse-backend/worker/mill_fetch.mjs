/**
 * Unified mill egress — Spec FR-4 / P0.
 * Always redirect: "manual"; treat 3xx as failure (do not follow).
 */

/**
 * @param {string} url
 * @param {RequestInit & { fetchImpl?: typeof fetch }} [init]
 */
export async function millFetch(url, init = {}) {
  const { fetchImpl = fetch, ...rest } = init;
  const res = await fetchImpl(url, {
    ...rest,
    redirect: "manual",
    ...(rest.body != null ? { duplex: "half" } : {}),
  });
  if (res.status >= 300 && res.status < 400) {
    const err = new Error(`mill_redirect_not_followed:${res.status}`);
    err.status = res.status;
    err.response = res;
    throw err;
  }
  return res;
}
