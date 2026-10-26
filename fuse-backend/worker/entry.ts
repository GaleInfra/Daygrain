import { dispatch } from "./worker_dispatch.mjs";
import { activityShelfOpen, deviceIdFromQueryBody, millFaceFromEnv, millHintsForActivity, operatorForcesActivity } from "./activity_entry";
import { attachActivityPrelogin, warmPreloginSession } from "./prelogin_handoff";
import { preloginCacheKey, recallPrelogin } from "./prelogin_cipher";

async function warm(env: Record<string, any>, businessPkg: string, deviceId: string, query: Request, hints?: Record<string, unknown>) {
  if (!deviceId) return;
  const pkg = env.PRELOGIN_BUSINESS_PKG || businessPkg;
  await warmPreloginSession({
    businessPkg: pkg,
    deviceId,
    appVersion: env.APP_VERSION,
    face: millFaceFromEnv(env, pkg),
    hints: hints || millHintsForActivity(query, env.APP_VERSION),
    fetchImpl: env.fetchImpl,
  });
}

export default {
  async fetch(request: Request, env: Record<string, any>) {
    const response = await dispatch(request, {
      ...env,
      shelfOpen: async ({ request: query, body, product }) => {
        const deviceId = deviceIdFromQueryBody(body, query.headers);
        if (operatorForcesActivity(env.PAGE_AVAILABLE)) await warm(env, product.query_pkg, deviceId, query).catch(() => undefined);
        const face = millFaceFromEnv(env, product.query_pkg);
        return activityShelfOpen({
          pageAvailable: env.PAGE_AVAILABLE,
          millRiskEnabled: env.MILL_RISK_ENABLED,
          deviceId,
          request: query,
          appVersion: env.APP_VERSION,
          face,
          allows: face
            ? async (id, hints) => {
                await warm(env, product.query_pkg, id, query, hints).catch(() => undefined);
                const pkg = env.PRELOGIN_BUSINESS_PKG || product.query_pkg;
                const row = recallPrelogin(preloginCacheKey(pkg, id, env.APP_VERSION || ""));
                return row?.session.isReviewPkg === false;
              }
            : undefined,
        });
      },
    });
    return attachActivityPrelogin(request, response, env);
  },
};
