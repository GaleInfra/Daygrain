/**
 * Template activity page: /activity/<pkg>/live/
 * <pkg> is worker.query.query_pkg. The device query name is not decided here.
 */

const PKG = /^[A-Za-z0-9](?:[A-Za-z0-9._-]*[A-Za-z0-9])?$/;

export function isActivityPkg(pkg) {
  return typeof pkg === "string" && PKG.test(pkg) && !pkg.includes("..");
}

/** Directory path without a trailing slash, or null when pkg is not a single safe segment. */
export function activityLivePrefix(pkg) {
  if (!isActivityPkg(pkg)) return null;
  return `/activity/${pkg}/live`;
}

export function isLegacyActivityEntry(pathname) {
  return pathname === "/activity" || pathname === "/activity/" || pathname === "/activity/index.html";
}

export function isLiveActivityPath(pathname, pkg) {
  const prefix = activityLivePrefix(pkg);
  if (!prefix || typeof pathname !== "string" || pathname.includes("..") || pathname.includes("\\")) {
    return false;
  }
  return pathname === prefix || pathname === `${prefix}/` || pathname.startsWith(`${prefix}/`);
}
