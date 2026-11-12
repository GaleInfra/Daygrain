#!/usr/bin/env node
// Deploy only the Daygrain attribution trial worker.
// Refuses the product wrangler.json and any worker name other than esf-daygrain-adjust-trial.
import { spawnSync } from "node:child_process";
import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const configName = "wrangler.attribution-trial.json";
const configPath = join(root, configName);
const config = JSON.parse(readFileSync(configPath, "utf8"));
if (config.name !== "esf-daygrain-adjust-trial") {
  console.error("trial_worker_name_mismatch");
  process.exit(2);
}
if (process.argv.includes("wrangler.json") || process.argv.includes("--config")) {
  console.error("trial_deploy_config_locked");
  process.exit(2);
}
const token = process.env.CLOUDFLARE_API_TOKEN || "";
const account = process.env.CLOUDFLARE_ACCOUNT_ID || "";
if (!token || !/^[a-f0-9]{32}$/.test(account)) {
  console.error("cloudflare_env_missing");
  process.exit(2);
}
const handoff = (config.d1_databases || []).find((row) => row.binding === "FUSE_H5_HANDOFF_D1");
if (!handoff || !/^[a-f0-9-]{36}$/.test(handoff.database_id || "")) {
  console.error("site_handoff_pending");
  process.exit(3);
}
const query = (config.d1_databases || []).find((row) => row.binding === "FUSE_D1");
if (!query || query.database_name !== "esf-daygrain-adjust-trial") {
  console.error("trial_query_database_mismatch");
  process.exit(2);
}

const env = { ...process.env, CLOUDFLARE_API_TOKEN: token, CLOUDFLARE_ACCOUNT_ID: account };
for (const key of ["ALL_PROXY", "all_proxy", "HTTP_PROXY", "http_proxy", "HTTPS_PROXY", "https_proxy"]) delete env[key];
const local = join(root, "node_modules/.bin/wrangler");
const bin = existsSync(local) ? local : "npx";
function wrangler(args) {
  const full = existsSync(local) ? args : ["--yes", "wrangler", ...args];
  const result = spawnSync(bin, full, { cwd: root, env, encoding: "utf8" });
  const text = `${result.stdout || ""}\n${result.stderr || ""}`;
  if (result.status !== 0) {
    process.stderr.write(text);
    process.exit(result.status ?? 1);
  }
  return text;
}

if (!/^[a-f0-9-]{36}$/.test(query.database_id || "")) {
  const created = wrangler(["d1", "create", query.database_name]);
  const match = created.match(/database_id\s*=\s*"([a-f0-9-]{36})"/i) || created.match(/([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})/);
  if (!match) {
    console.error("trial_d1_id_missing");
    process.exit(1);
  }
  query.database_id = match[1];
  writeFileSync(configPath, JSON.stringify(config, null, 2) + "\n");
}

const deployed = wrangler(["deploy", "--config", configName]);
process.stdout.write(deployed);
