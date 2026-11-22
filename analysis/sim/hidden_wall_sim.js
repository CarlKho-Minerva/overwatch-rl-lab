// The hidden-wall experiment by the grid's rules alone: no game, no physics, no slips.
// Used to choose the short-strip design before it was run in the game, and by the lesson page so a reader can rerun it.
//   node analysis/sim/hidden_wall_sim.js            prints both designs at 200 training episodes, 300 simulated runs each
// kind 0 = runner blind, 1 = remembers bumps, 2 = sees the wall. Same rewards and settings as the Workshop script:
// -1 a step, +50 goal, -100 fall, -50 at the 40-step limit, alpha 0.5, epsilon 0.1, discount 1, ties broken at random.
var HW = (function () {
  var NC = 12, NR = 4, NCELLS = 48, MAXS = 40;
  function rng(seed) { var s = seed >>> 0; return function () { s = (s + 0x6D2B79F5) >>> 0; var t = s; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296; }; }
  // one move by the rules: returns {cell, fell, bump}
  function move(cell, a, wallRow, WALL_COL) {
    var col = cell % NC, row = Math.floor(cell / NC);
    var tc = col + [1, -1, 0, 0][a], tr = row + [0, 0, 1, -1][a];
    if (tr < 0) return { cell: cell, fell: true, bump: false };
    if (tc < 0 || tc >= NC || tr >= NR) return { cell: cell, fell: false, bump: false };
    if (tr === wallRow && tc === WALL_COL) return { cell: cell, fell: false, bump: true, row: tr };
    return { cell: tr * NC + tc, fell: false, bump: false };
  }
  function view(kind, cell, mem, wallRow) { return kind === 0 ? cell : (kind === 1 ? cell + NCELLS * mem : cell + NCELLS * wallRow); }
  function argmax(Q, s, rand) {
    var best = -1e18, pick = [], i;
    for (i = 0; i < 4; i++) { var v = Q[s * 4 + i]; if (v > best + 1e-12) { best = v; pick = [i]; } else if (Math.abs(v - best) <= 1e-12) pick.push(i); }
    return pick[Math.floor(rand() * pick.length)];
  }
  // one run: train, then test with learning and exploring off. kind 0 blind, 1 remembers bumps, 2 sees the wall.
  function run(kind, seed, opt) {
    opt = opt || {};
    var rand = rng(seed), Q = new Float64Array(NCELLS * 5 * 4).fill(opt.qinit || 0), alpha = 0.5, eps = 0.1;
    var GOAL = opt.goal === undefined ? 11 : opt.goal, WALL_COL = opt.wallCol === undefined ? 6 : opt.wallCol;
    var train = opt.train || 200, tests = opt.tests || 20, out = { goal: 0, steps: 0, bumps: 0, trainFalls: 0 };
    for (var ep = 0; ep < train + tests; ep++) {
      var learning = ep < train, wallRow = Math.floor(rand() * (opt.rows || 2)), cell = 0, mem = 0, steps = 0, done = false, reached = false;
      while (!done) {
        var s = view(kind, cell, mem, wallRow);
        var a = (learning && rand() < eps) ? Math.floor(rand() * 4) : argmax(Q, s, rand);
        var m = move(cell, a, wallRow, WALL_COL), r = -1;
        if (m.bump) { mem = 1 + m.row; if (!learning) out.bumps++; }
        steps++;
        if (m.fell) { r += -100; done = true; if (learning) out.trainFalls++; }
        else if (m.cell === GOAL) { r += 50; done = true; reached = true; }
        else if (steps >= MAXS) { r += -50; done = true; }
        if (learning) {
          var s2 = view(kind, m.cell, mem, wallRow), target = r;
          if (!done) { var mx = -1e18; for (var i = 0; i < 4; i++) mx = Math.max(mx, Q[s2 * 4 + i]); target += mx; }
          Q[s * 4 + a] += alpha * (target - Q[s * 4 + a]);
        }
        cell = m.cell;
      }
      if (!learning) { out.goal += reached ? 1 : 0; out.steps += reached ? steps : MAXS; }
    }
    out.goal /= tests; out.steps /= tests; out.bumps /= tests; out.trainFalls = 100 * out.trainFalls / train;
    return out;
  }
  function many(kind, n, seed0, opt) {
    var g = 0, st = 0, all = 0, none = 0, b = 0, f = 0;
    for (var i = 0; i < n; i++) { var o = run(kind, seed0 + i * 7919 + kind * 104729, opt); g += o.goal; st += o.steps; b += o.bumps; f += o.trainFalls; if (o.goal === 1) all++; if (o.goal === 0) none++; }
    return { goal: g / n, steps: st / n, all: all, none: none, bumps: b / n, falls: f / n, n: n };
  }
  return { move: move, run: run, many: many, NC: NC, NR: NR, MAXS: MAXS };
})();
if (typeof module !== "undefined") {
  module.exports = HW;
  if (require.main === module) {
    var designs = [["long strip, wall in one of two rows (goal column 11, wall column 6)", { rows: 2, goal: 11, wallCol: 6 }],
                   ["short strip, wall in any of four rows (goal column 5, wall column 3)", { rows: 4, goal: 5, wallCol: 3 }]];
    designs.forEach(function (d) {
      [200, 400, 1000].forEach(function (train) {
        console.log(d[0] + ", " + train + " training episodes, 300 simulated runs each");
        ["blind", "remembers bumps", "sees the wall"].forEach(function (name, k) {
          var o = HW.many(k, 300, 11, Object.assign({ train: train }, d[1]));
          console.log("  " + (name + "                ").slice(0, 16) + " test crossings reaching the goal " + (100 * o.goal).toFixed(1) + "%   steps per test crossing " + o.steps.toFixed(1) +
                      "   runs with all 20: " + o.all + "   with none: " + o.none);
        });
      });
    });
  }
}
