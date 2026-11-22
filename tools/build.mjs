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
];

await overpy.readyPromise;
let failed = false;
for (const [src, out] of targets) {
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
