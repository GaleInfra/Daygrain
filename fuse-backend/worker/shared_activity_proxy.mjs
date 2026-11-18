/**
 * Shared-release H5 proxy for /activity/<pkg>/live/ when ASSETS are unavailable locally.
 */

import https from "node:https";
import http from "node:http";

function nodeGet(url, method, headers) {
  return new Promise((resolve, reject) => {
    const lib = url.startsWith("https:") ? https : http;
    const req = lib.request(url, { method, headers: Object.fromEntries(headers) }, (res) => {
      const chunks = [];
      res.on("data", (chunk) => chunks.push(chunk));
      res.on("end", () => {
        const body = Buffer.concat(chunks);
        const out = new Headers();
        for (const [key, value] of Object.entries(res.headers)) {
          if (value) out.append(key, Array.isArray(value) ? value.join(", ") : value);
        }
        resolve(new Response(body, { status: res.statusCode || 502, headers: out }));
      });
    });
    req.on("error", reject);
    req.end();
  });
}

function listedSetCookies(headers) {
  if (headers && typeof headers.getSetCookie === "function") return headers.getSetCookie();
  const raw = headers.get("set-cookie");
  return raw ? [raw] : [];
}

function retargetCookiePath(cookie, fromPath, toPath) {
  const match = /;\s*Path=([^;]+)/i.exec(cookie);
  if (!match) return cookie;
  const path = match[1].trim();
  if (path === fromPath || path.startsWith(fromPath)) {
    return cookie.replace(match[0], `; Path=${path.replace(fromPath, toPath)}`);
  }
  return cookie;
}

function withCookies(response, cookies) {
  const headers = new Headers(response.headers);
  headers.delete("set-cookie");
  for (const cookie of cookies) headers.append("set-cookie", cookie);
  return new Response(response.body, { status: response.status, statusText: response.statusText, headers });
}

function runtimePkg(html, formalPkg) {
  return html.replace(/window\.__FUSE_RUNTIME_CONFIG__\s*=\s*(\{[\s\S]*?\});/, (block) =>
    block.replace(/"pkg"\s*:\s*"[^"]*"/, `"pkg":"${formalPkg}"`));
}

/**
 * @param {Request} request
 * @param {{ UNIVERSAL_ACTIVITY_URL?: string, ACTIVITY_PKG?: string }} env
 * @param {string} pkg
 * @param {string} publicPath e.g. /activity/com.stillnote.journal/live/
 */
export async function fetchSharedLiveActivity(request, env, pkg, publicPath) {
  const universal = String(env.UNIVERSAL_ACTIVITY_URL || "").trim();
  if (!universal) return null;
  const reqUrl = new URL(request.url);
  const rel = reqUrl.pathname.slice(publicPath.replace(/\/$/, "").length).replace(/^\//, "") || "";
  const base = universal.endsWith("/") ? universal : `${universal}/`;
  const target = new URL(rel || "index.html", base);
  reqUrl.searchParams.forEach((value, key) => target.searchParams.set(key, value));
  const upstreamHeaders = new Headers();
  upstreamHeaders.set("accept", request.headers.get("accept") || "text/html");
  upstreamHeaders.set("user-agent", request.headers.get("user-agent") || "ElonSuperFactory-startup-check");
  const upstream = await nodeGet(target.toString(), request.method, upstreamHeaders);
  const universalPath = new URL(base).pathname;
  const cookies = listedSetCookies(upstream.headers).map((cookie) =>
    retargetCookiePath(cookie, universalPath, publicPath));
  let response = withCookies(upstream, cookies);
  const contentType = upstream.headers.get("content-type") || "";
  if ((rel === "" || rel === "index.html") && contentType.includes("text/html")) {
    let html = await response.text();
    html = runtimePkg(html, pkg);
    const headers = new Headers(response.headers);
    headers.delete("content-length");
    headers.delete("content-encoding");
    response = new Response(html, { status: response.status, statusText: response.statusText, headers });
  }
  return response;
}