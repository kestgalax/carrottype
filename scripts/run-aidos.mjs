#!/usr/bin/env node

import { access } from "node:fs/promises";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const currentDirectory = path.dirname(fileURLToPath(import.meta.url));
const projectRoot = path.resolve(currentDirectory, "..");
const command = process.argv[2];
const commandArgs = process.argv.slice(3);

if (!command) {
  console.error(
    "Usage: node scripts/run-aidos.mjs <validate|trace|review|closure|archive|new|init> [args]",
  );
  process.exit(1);
}

/**
 * Resolution order:
 * 1. AIDOS_ROOT — explicit checkout (CI and local AIDOS development)
 * 2. `aidos` on PATH — installed tooling
 *
 * Sibling `../AIDOS` / aidos.config toolingRoot are no longer defaults.
 * Pin and install instructions: ops/tooling.md
 */
const toolingRoot = process.env.AIDOS_ROOT;

async function main() {
  if (toolingRoot) {
    const aidosCli = path.resolve(projectRoot, toolingRoot, "bin", "aidos.js");
    try {
      await access(aidosCli);
    } catch {
      console.error(`AIDOS_ROOT is set but CLI was not found: ${aidosCli}`);
      console.error("Clone kestgalax/AIDOS at the pinned commit and run npm install there.");
      console.error("See ops/tooling.md.");
      process.exit(1);
    }

    const result = spawnSync(process.execPath, [aidosCli, command, ...commandArgs], {
      cwd: projectRoot,
      stdio: "inherit",
    });
    process.exit(result.status ?? 1);
  }

  const result = spawnSync("aidos", [command, ...commandArgs], {
    cwd: projectRoot,
    stdio: "inherit",
  });

  if (result.error && result.error.code === "ENOENT") {
    console.error("Installed `aidos` was not found on PATH, and AIDOS_ROOT is unset.");
    console.error("Set AIDOS_ROOT to a pinned AIDOS checkout (with npm install), or install aidos.");
    console.error("See ops/tooling.md.");
    process.exit(1);
  }

  process.exit(result.status ?? 1);
}

await main();
