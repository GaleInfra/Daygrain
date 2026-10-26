/**
 * Workers entry shipped beside wrangler.json. No filesystem, no package name.
 */
import { dispatch } from "./worker_dispatch.mjs";

export default {
  async fetch(request, env) {
    try {
      return await dispatch(request, env);
    } catch {
      return new Response(JSON.stringify({ ok: false, code: 1, message: "worker_unavailable" }), {
        status: 500,
        headers: { "content-type": "application/json; charset=utf-8", "cache-control": "no-store" },
      });
    }
  },
};
