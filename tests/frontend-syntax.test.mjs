import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { readFileSync } from "node:fs";
test("all public ES modules parse as modules, including Japanese copy", () => {
  for (const file of [
    "web/app.js",
    "web/tiles.js",
    "web/stats.js",
    "web/analyzer.js",
    "web/hand-input.js",
  ]) {
    const checked = spawnSync(
      process.execPath,
      ["--check", "--input-type=module"],
      { input: readFileSync(file, "utf8"), encoding: "utf8" },
    );
    assert.equal(checked.status, 0, `${file}: ${checked.stderr}`);
  }
});
