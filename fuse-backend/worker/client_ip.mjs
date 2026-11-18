/** Trusted client IP, shared by the relay template and Mill service. */
import { isIP } from "node:net";

const IPV4 = /^(?:(?:25[0-5]|2[0-4]\d|1?\d?\d)\.){3}(?:25[0-5]|2[0-4]\d|1?\d?\d)$/;

export function isIpv4(raw) {
  return IPV4.test(raw.trim());
}

/** Public unicast IPv4; preserve the existing release trust boundary. */
export function isPublicIpv4(raw) {
  const value = raw.trim();
  if (!isIpv4(value)) return false;
  const parts = value.split(".");
  const octets = parts.map(Number);
  if (parts.some((part, index) => String(octets[index]) !== part)) return false;
  const [a, b, c, d] = octets;
  if (a === 0 || a === 10 || a === 127 || a >= 224) return false;
  if (a === 100 && b >= 64 && b <= 127) return false;
  if (a === 169 && b === 254) return false;
  if (a === 172 && b >= 16 && b <= 31) return false;
  if (a === 192) {
    if (b === 0 && c === 0) return d === 9 || d === 10;
    if ((b === 0 && c === 2) || (b === 88 && c === 99) || b === 168) return false;
  }
  if (a === 198 && (b === 18 || b === 19 || (b === 51 && c === 100))) return false;
  if (a === 203 && b === 0 && c === 113) return false;
  return true;
}

/** Normalize mapped IPv4 through the existing policy; accept global unicast IPv6. */
export function publicClientIp(raw) {
  const value = raw.trim();
  if (isPublicIpv4(value)) return value;
  if (isIP(value) !== 6 || value.includes("%")) return "";
  const ip = new URL(`http://[${value}]/`).hostname.slice(1, -1);
  if (ip.startsWith("::ffff:")) {
    const words = ip.slice(7).split(":").map(word => parseInt(word, 16));
    const mapped = [words[0] >> 8, words[0] & 255, words[1] >> 8, words[1] & 255].join(".");
    return isPublicIpv4(mapped) ? mapped : "";
  }
  const [first, second] = ip.split(":").map(word => parseInt(word || "0", 16));
  if (first < 0x2000 || first > 0x3fff) return "";
  // Exclude protocol/transition, benchmarking and documentation allocations.
  if (first === 0x2001 && (second < 0x200 || second === 0xdb8)) return "";
  if (first === 0x2002 || (first === 0x3fff && second < 0x1000)) return "";
  return ip;
}

/** IPv4 first, then the real IPv6 preserved by Cloudflare; never caller XFF. */
export function clientIp(headers) {
  const cf = publicClientIp(headers.get("CF-Connecting-IP") || "");
  if (isPublicIpv4(cf)) return cf;
  const ipv6 = (headers.get("CF-Connecting-IPv6") || "").trim();
  return ipv6 ? (isIP(ipv6) === 6 ? publicClientIp(ipv6) : "") : cf;
}

/** Trusted Cloudflare edge only. IPv6, missing/invalid IP and Pseudo IPv4 fail closed. */
export function clientIpv4(headers) {
  if ((headers.get("CF-Connecting-IPv6") || "").trim()) return "";
  const cf = (headers.get("CF-Connecting-IP") || "").trim();
  return isPublicIpv4(cf) ? cf : "";
}
