// Write analysis/sim/sim_table.json: every simulated number the course pages quote, so none is typed by hand.
//   node analysis/sim/make_table.js
const HW = require("./hidden_wall_sim.js");
const fs = require("fs");
const path = require("path");
const LAYOUT = { short: { rows: 4, goal: 5, wallCol: 3 }, long: { rows: 2, goal: 11, wallCol: 6 } };
const RUNS = 300, SEED = 11;
function row(kind, layout, train, testEps) {
  const o = HW.many(kind, RUNS, SEED, Object.assign({ train: train, testEps: testEps || 0 }, LAYOUT[layout]));
  return { goal_pct: +(100 * o.goal).toFixed(1), steps: +o.steps.toFixed(1), runs_all: o.all, runs_none: o.none, test_falls_pct: +(100 * o.testFalls).toFixed(1) };
}
const T = { runs_per_cell: RUNS, seed: SEED, kinds: ["blind", "remembers bumps", "sees the wall"], table: {}, random_moves_in_tests: {} };
for (const layout of ["short", "long"]) for (const train of [200, 400, 1000]) T.table[layout + "_" + train] = [0, 1, 2].map(k => row(k, layout, train));
// Silver's other way out of aliasing (lecture 7): a policy with some randomness. Here: the blind runner on the short
// strip keeps a share of uniformly random moves during her test crossings.
for (const eps of [0, 0.1, 0.25, 0.5]) T.random_moves_in_tests["blind_short_" + eps] = row(0, "short", 200, eps);
fs.writeFileSync(path.join(__dirname, "sim_table.json"), JSON.stringify(T, null, 1));
console.log("wrote sim_table.json:", Object.keys(T.table).length, "cells,", Object.keys(T.random_moves_in_tests).length, "random-move rows");
