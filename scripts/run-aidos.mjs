#!/usr/bin/env node

import { readFile } from "node:fs/promises";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const currentDirectory = path.dirname(fileURLToPath(import.meta.url));
const projectRoot = path.resolve(currentDirectory, "..");
const command = process.argv[2];

if (!command) {
  console.error("Usage: node scripts/run-aidos.mjs <validate|trace|review>");
  process.exit(1);
}

const configPath = path.join(projectRoot, "aidos.config.json");
const config = JSON.parse(await readFile(configPath, "utf8"));
const toolingRoot = process.env.AIDOS_ROOT ?? config.toolingRoot ?? "../AIDOS";
const aidosCli = path.resolve(projectRoot, toolingRoot, "bin", "aidos.js");

const result = spawnSync(process.execPath, [aidosCli, command], {
  cwd: projectRoot,
  stdio: "inherit",
});

process.exit(result.status ?? 1);
