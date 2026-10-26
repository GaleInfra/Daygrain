#!/usr/bin/env node
// Developer entry: wrangler with the Cloudflare credentials in ../fuse.config.json.
// Usage: node scripts/cf-run.mjs <dev|deploy|whoami|tail|d1-migrate|bake-h5|deploy-all|wrangler> [args...]
import { spawnSync } from "node:child_process";
import { existsSync, readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const config = JSON.parse(readFileSync(join(root, "fuse.config.json"), "utf8"));
const cf = config.cloudflare || {};
if (!/^[a-f0-9]{32}$/.test(cf.account_id || "") || !cf.api_token) {
  console.error("fuse.config.json cloudflare.account_id / cloudflare.api_token missing");
  process.exit(2);
}
const env = { ...process.env, CLOUDFLARE_API_TOKEN: cf.api_token, CLOUDFLARE_ACCOUNT_ID: cf.account_id };
for (const key of ["ALL_PROXY", "all_proxy", "HTTP_PROXY", "http_proxy", "HTTPS_PROXY", "https_proxy"]) delete env[key];

function run(command, args) {
  const result = spawnSync(command, args, { cwd: root, env, stdio: "inherit" });
  if (result.status !== 0) process.exit(result.status ?? 1);
}
function wrangler(args) {
  const local = join(root, "node_modules/.bin/wrangler");
  if (existsSync(local)) run(local, args);
  else run("npx", ["--yes", "wrangler", ...args]);
}
function d1Name() {
  const wranglerJson = JSON.parse(readFileSync(join(root, "wrangler.json"), "utf8"));
  const db = (wranglerJson.d1_databases || [])[0] || {};
  return db.database_name || db.binding;
}
function bakeH5() {
  const builder = join(root, "h5", "build_activity.py");
  const buildConfig = join(root, "h5", "activity.build.json");
  if (!existsSync(builder) || !existsSync(buildConfig)) {
    console.log("bake-h5: h5/build_activity.py or h5/activity.build.json absent; deploying assets as already baked");
    return;
  }
  const pkg = (config.worker && config.worker.query && config.worker.query.query_pkg) || "";
  const out = pkg ? join(root, "public", "activity", pkg, "live") : join(root, "public");
  run("python3", [builder, "--config", buildConfig, "--out", out]);
}

const [action = "whoami", ...rest] = process.argv.slice(2);
switch (action) {
  case "dev": wrangler(["dev", ...rest]); break;
  case "deploy": wrangler(["deploy", ...rest]); break;
  case "whoami": wrangler(["whoami", ...rest]); break;
  case "tail": wrangler(["tail", ...rest]); break;
  case "d1-migrate": wrangler(["d1", "migrations", "apply", d1Name(), "--remote", ...rest]); break;
  case "bake-h5": bakeH5(); break;
  case "deploy-all": bakeH5(); wrangler(["deploy", ...rest]); break;
  case "wrangler": wrangler(rest); break;
  default:
    console.error(`unknown action: ${action}`);
    process.exit(2);
}
