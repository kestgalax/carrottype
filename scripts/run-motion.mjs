#!/usr/bin/env node

import { access } from "node:fs/promises";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const currentDirectory = path.dirname(fileURLToPath(import.meta.url));
const projectRoot = path.resolve(currentDirectory, "..");
const commandArgs = process.argv.slice(2);

/**
 * Resolution order (same idea as AIDOS / `run-aidos.mjs`):
 * 1. MOTION_OS_ROOT — explicit checkout of private kestgalax/motion-os
 * 2. `motion` on PATH — if a global/bin install exists later
 *
 * No npm dependency on motion-os in this public product repo.
 * Setup: ops/motion-tooling.md
 */
const toolingRoot = process.env.MOTION_OS_ROOT;

async function main() {
  if (toolingRoot) {
    const motionCli = path.resolve(projectRoot, toolingRoot, "cli", "src", "index.ts");
    try {
      await access(motionCli);
    } catch {
      console.error(`MOTION_OS_ROOT is set but CLI was not found: ${motionCli}`);
      console.error("Clone kestgalax/motion-os (private) and run npm install there.");
      console.error("See ops/motion-tooling.md.");
      process.exit(1);
    }

    const result = spawnSync(process.execPath, [motionCli, ...commandArgs], {
      cwd: projectRoot,
      stdio: "inherit",
      env: process.env,
    });
    process.exit(result.status ?? 1);
  }

  const result = spawnSync("motion", commandArgs, {
    cwd: projectRoot,
    stdio: "inherit",
    env: process.env,
  });

  if (result.error && result.error.code === "ENOENT") {
    console.error("Installed `motion` was not found on PATH, and MOTION_OS_ROOT is unset.");
    console.error("Set MOTION_OS_ROOT to a motion-os checkout (with npm install), or put `motion` on PATH.");
    console.error("See ops/motion-tooling.md.");
    process.exit(1);
  }

  process.exit(result.status ?? 1);
}

await main();
