import { readFile } from "node:fs/promises";
import { join, normalize } from "node:path";

function json(message, status = 404) {
  return new Response(JSON.stringify({ ok: false, code: 1, message }), {
    status,
    headers: { "content-type": "application/json" },
  });
}

/**
 * Serve bundled public/activity/<pkg>/live assets for local http_dev (no ASSETS binding).
 */
export async function serveLocalPublicActivity(request, env, pkg, publicPath) {
  const root = String(env.LOCAL_ASSET_ROOT || "").trim();
  if (!root) return null;
  const reqUrl = new URL(request.url);
  const base = join(root, "activity", pkg, "live");
  const rel = reqUrl.pathname.slice(publicPath.replace(/\/$/, "").length).replace(/^\//, "") || "index.html";
  const file = normalize(join(base, rel));
  if (!file.startsWith(normalize(base + "/")) && file !== normalize(join(base, rel === "" ? "index.html" : rel))) {
    return json("path_not_found", 404);
  }
  if (!file.startsWith(normalize(base))) return json("path_not_found", 404);
  try {
    const body = await readFile(file);
    const type = rel.endsWith(".html") ? "text/html; charset=UTF-8"
      : rel.endsWith(".js") ? "application/javascript"
      : rel.endsWith(".json") ? "application/json"
      : "application/octet-stream";
    const headers = new Headers({ "content-type": type, "cache-control": "private, no-store" });
    if (rel === "" || rel === "index.html") {
      headers.set("x-fuse-h5-build", String(env.FUSE_H5_BUILD_HEADER || ""));
    }
    return new Response(body, { status: 200, headers });
  } catch {
    return json("activity_assets_unavailable", 503);
  }
}