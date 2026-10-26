/**
 * Template-owned routes. Package configs must not shadow these.
 * Mill paths are forwarded with millFetch; they are not package branches.
 */

export const TEMPLATE_MILL_ROUTES = [
  { path: "/security/oauth", methods: ["POST"], upstream: "mill" },
  { path: "/config/getAppConfigPostV2", methods: ["POST"], upstream: "mill" },
  { path: "/config/getStrategyPostV2", methods: ["POST"], upstream: "mill" },
];

export const TEMPLATE_ROUTE_PATHS = [
  "/",
  "/bootstrap",
  "/bootstrap/v2",
  "/healthz",
  "/p",
  ...TEMPLATE_MILL_ROUTES.map((route) => route.path),
];
