/**
 * In-memory query decision + daily counter and per-minute rate limiter.
 * Factory D1 can replace these; the method shape stays the same.
 */

export function createMemoryQueryStore() {
  const decisions = new Map();
  const daily = new Map();
  const claims = new Map();
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
    },
  };
}

export function createMemoryRateLimiter() {
  const hits = new Map();
  return {
    async hit(key, nowMs, windowMs = 60_000, limit) {
      if (!Number.isFinite(nowMs)) throw new Error("rate_clock_invalid");
      const window = Number.isFinite(windowMs) && windowMs > 0 ? windowMs : 60_000;
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
    },
  };
}
