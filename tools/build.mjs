// Compiles the OverPy sources into Workshop text that Overwatch can import.
// Usage: node tools/build.mjs        (exit code 1 on any error or warning)
import { createRequire } from "node:module";
import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { dirname, resolve, basename } from "node:path";
import { fileURLToPath } from "node:url";

const require = createRequire(import.meta.url);
const overpy = require("overpy");
const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");

const targets = [
    ["workshop/main.opy", "workshop/compiled/overwatch-rl-lab.txt"],
    ["workshop/variants/demo.opy", "workshop/compiled/variant-demo.txt"],
    ["workshop/variants/verify_sarsa.opy", "workshop/compiled/variant-verify-sarsa.txt"],
    ["workshop/variants/verify_qlearning.opy", "workshop/compiled/variant-verify-qlearning.txt"],
    ["workshop/variants/widow.opy", "workshop/compiled/variant-widow.txt"],
    ["workshop/variants/blink_openloop.opy", "workshop/compiled/variant-blink-openloop.txt"],
    ["workshop/variants/nondefault_cliff.opy", "workshop/compiled/variant-nondefault-cliff.txt"],
    ["workshop/variants/nondefault_widow.opy", "workshop/compiled/variant-nondefault-widow.txt"],
    ["workshop/variants/fail_wrong_map.opy", "workshop/compiled/variant-fail-wrong-map.txt"],
    ["workshop/variants/fail_rooted_tracer.opy", "workshop/compiled/variant-fail-rooted-tracer.txt"],
    ["workshop/variants/fail_no_floor_at_origin.opy", "workshop/compiled/variant-fail-no-floor-at-origin.txt"],
    ["workshop/night/night.opy", "workshop/compiled/night-school.txt"],
    ["workshop/night/night_test.opy", "workshop/compiled/night-school-test.txt"],
    ["workshop/night/night_golden.opy", "workshop/compiled/night-school-golden.txt"],
    ["workshop/night/night_duel.opy", "workshop/compiled/night-school-duel.txt"],
    ["workshop/night/night_fill.opy", "workshop/compiled/night-school-fill.txt"],
    ["workshop/night/night_pomdp.opy", "workshop/compiled/night-school-pomdp.txt"],
    ["workshop/night/night_pomdp_probe.opy", "workshop/compiled/night-school-pomdp-probe.txt"],
    ["workshop/night/night_pomdp4.opy", "workshop/compiled/night-school-pomdp4.txt"],
    ["workshop/night/night_pomdp4_probe.opy", "workshop/compiled/night-school-pomdp4-probe.txt"],
    ["workshop/night/night_duel_test.opy", "workshop/compiled/night-school-duel-test.txt"],
];
// The course games: one mode per lecture (gNN.opy, played by a person) and its automatic check (gNN_auto.opy, a bot
// stands in for the player). A game is listed once its files exist.
import { existsSync } from "node:fs";
for (let n = 0; n <= 11; n++) {
    const id = String(n).padStart(2, "0");
    for (const [suffix, out] of [["", ""], ["_auto", "-auto"]]) {
        const src = `workshop/games/g${id}${suffix}.opy`;
        if (existsSync(resolve(root, src))) targets.push([src, `workshop/compiled/game-${id}${out}.txt`]);
    }
}

// With an argument, build only that source file (used by tools/warm_start.py).
const only = process.argv[2];
const list = only
    ? (targets.filter(([src]) => src === only.replace(/\\/g, "/")).length
        ? targets.filter(([src]) => src === only.replace(/\\/g, "/"))
        : [[only.replace(/\\/g, "/"), "workshop/compiled/variant-" + basename(only, ".opy").replace(/_/g, "-") + ".txt"]])
    : targets;

await overpy.readyPromise;
let failed = false;
for (const [src, out] of list) {
    const srcPath = resolve(root, src);
    try {
        const res = await overpy.compile(readFileSync(srcPath, "utf8"), "en-US", dirname(srcPath) + "/", basename(srcPath));
        const warnings = res.encounteredWarnings ?? [];
        mkdirSync(dirname(resolve(root, out)), { recursive: true });
        writeFileSync(resolve(root, out), res.result, "utf8");
        const elements = res.nbElements ?? "?";
        console.log(`${src} -> ${out}  (${res.result.length} chars, ${elements} elements, ${warnings.length} warnings)`);
        for (const w of warnings) {
            failed = true;
            console.log("  WARNING: " + (w && w.message ? w.message : String(w)).split(/\r?\n/).slice(0, 2).join(" "));
        }
    } catch (e) {
        failed = true;
        console.log(`${src}: COMPILE ERROR\n  ${e && e.message ? e.message : e}`);
    }
}
process.exit(failed ? 1 : 0);
