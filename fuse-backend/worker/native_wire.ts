/** Adapt the frozen Native wire surface to the SDK's internal quota model. */
import { dispatch as sdkDispatch } from './worker_dispatch.mjs';
import { createHash } from 'node:crypto';

function shape(value: unknown, example: unknown): boolean {
  if (Array.isArray(example)) {
    return Array.isArray(value) && value.length === example.length && example.every((v, i) => shape(value[i], v));
  }
  if (example && typeof example === 'object') {
    if (!value || typeof value !== 'object' || Array.isArray(value)) return false;
    const expected = Object.keys(example).sort();
    return JSON.stringify(Object.keys(value).sort()) === JSON.stringify(expected)
      && expected.every(k => shape((value as Record<string, unknown>)[k], (example as Record<string, unknown>)[k]));
  }
  return typeof value === typeof example && (typeof value !== 'number' || Number.isFinite(value));
}

export async function dispatch(request: Request, env: Record<string, any>): Promise<Response> {
  if (request.method !== 'POST') return sdkDispatch(request, env);
  let config: any;
  try { config = JSON.parse(env.FUSE_QUERY_CONFIG); } catch { return sdkDispatch(request, env); }
  const path = new URL(request.url).pathname;
  const product = config.products?.find((p: any) => [p.query_path, p.use_path, p.claim_path].includes(path));
  if (!product) return sdkDispatch(request, env);
  const fail = (message: string, status = 400) => new Response(JSON.stringify({ ok: false, message }), {
    status, headers: { 'content-type': 'application/json', 'cache-control': 'no-store' },
  });
  const pkg = request.headers.get(env.PKG_HEADER) || '';
  const device = request.headers.get(env.DEVICE_HEADER) || '';
  if (pkg !== product.query_pkg) return fail('product_mismatch', 403);
  if (!device || device.length > 256 || device.trim() !== device) return fail('device_id_invalid');
  const declared = request.headers.get('content-length');
  if (declared && Number(declared) > 4096) return fail('body_too_large', 413);
  const reader = request.body?.getReader();
  const chunks: Uint8Array[] = []; let length = 0;
  if (reader) for (;;) {
    const part = await reader.read(); if (part.done) break;
    length += part.value.byteLength;
    if (length > 4096) { await reader.cancel(); return fail('body_too_large', 413); }
    chunks.push(part.value);
  }
  let body: unknown, sample: unknown;
  try {
    body = JSON.parse(Buffer.concat(chunks).toString('utf8'));
    sample = JSON.parse(env.FUSE_NATIVE_BODY_SAMPLE);
  } catch { return fail('native_body_invalid'); }
  if (!sample || typeof sample !== 'object' || !shape(body, sample)) return fail('native_body_invalid');
  // Only the internal quota key is normalised. Mill/H5 always receive the actual business ID.
  const install = /^[a-f0-9]{32}$|^[a-f0-9]{64}$/i.test(device)
    ? device.toLowerCase() : createHash('sha256').update(device).digest('hex');
  const headers = new Headers(request.headers); headers.delete('content-length');
  const canonical = new Request(request.url, { method: 'POST', headers,
    body: JSON.stringify({ pkg, installation_id: install, 'device-id': device }),
  });
  const cf = (request as Request & { cf?: unknown }).cf;
  if (cf !== undefined) Object.defineProperty(canonical, 'cf', { value: cf, enumerable: true });
  return sdkDispatch(canonical, env);
}
