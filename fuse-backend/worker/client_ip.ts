/** Client IPv4 for mill. One implementation, shared by the relay template and the mill-contract reference. */

const IPV4 = /^(?:(?:25[0-5]|2[0-4]\d|1?\d?\d)\.){3}(?:25[0-5]|2[0-4]\d|1?\d?\d)$/;

export function isIpv4(raw: string): boolean {
  return IPV4.test(raw.trim());
}

/** CF-Connecting-IP when it is IPv4; otherwise the first IPv4 in X-Forwarded-For. */
export function clientIpv4(headers: Headers): string {
  const cf = (headers.get("CF-Connecting-IP") || "").trim();
  if (isIpv4(cf)) return cf;
  const forwarded = headers.get("X-Forwarded-For") || "";
  for (const part of forwarded.split(",")) {
    const candidate = part.trim();
    if (isIpv4(candidate)) return candidate;
  }
  return "";
}
