"""Turn a folder of Night School logs into the numbers and figures the write-up uses.

    python -m rllab.night_summary <log folder> <out folder>

Writes <out>/summary.json (every number, generated, never typed by hand) and <out>/*.png (dark, for the lab page).
Only complete runs from matches of the standard build (version 2xx) are counted, unless stated.
"""
from __future__ import annotations

import json
import math
import random
import sys
from pathlib import Path

from . import night as ns
from .night_report import collect, run_rows, first_goal, mean

BG, PANEL, INK, MUTED, GRID = "#141310", "#1d1b17", "#f4eee3", "#c3bbad", "#2c2924"
COLORS = {0: "#6fb3ff", 1: "#ff8a5c", 2: "#b08cff", 3: "#ffd166", 4: "#7bd389", 5: "#f25f9c", 6: "#9aa5b1", 7: "#4dd0c8",
          8: "#e0b0ff", 9: "#8f877a", 10: "#ffffff", 11: "#ff5a5f"}
MARKERS = {0: "o", 1: "s", 2: "D", 3: "^", 4: "v", 5: "P", 6: "X", 7: "h", 8: "<", 9: ".", 10: "*", 11: ">"}


def boot_ci(xs, fn=mean, n=4000, seed=7):
    """95% bootstrap interval for a statistic of a list of per-run values."""
    xs = list(xs)
    if len(xs) < 2:
        return (float("nan"), float("nan"))
    rng = random.Random(seed)
    vals = sorted(fn([xs[rng.randrange(len(xs))] for _ in xs]) for _ in range(n))
    return (vals[int(0.025 * n)], vals[int(0.975 * n) - 1])


def perm_p(a, b, n=20000, seed=11):
    """Two-sided permutation test on the difference of means of two lists of per-run values."""
    a, b = list(a), list(b)
    if len(a) < 2 or len(b) < 2:
        return float("nan")
    obs = abs(mean(a) - mean(b))
    pool = a + b
    rng = random.Random(seed)
    hits = 0
    for _ in range(n):
        rng.shuffle(pool)
        if abs(mean(pool[:len(a)]) - mean(pool[len(a):])) >= obs - 1e-12:
            hits += 1
    return (hits + 1) / (n + 1)


def per_run(r, n_last=40):
    tr, ev = r["train"], r["eval"]
    d = {
        "falls": sum(e["outcome"] == 2 for e in tr), "timeouts": sum(e["outcome"] == 3 for e in tr), "goals": sum(e["outcome"] == 1 for e in tr),
        "n": len(tr), "falls_per_100": 100 * sum(e["outcome"] == 2 for e in tr) / max(1, len(tr)),
        "last_return": mean(e["ret"] for e in tr[-n_last:]), "last_edge": mean(e["edge"] for e in tr[-n_last:]),
        "last_falls": sum(e["outcome"] == 2 for e in tr[-n_last:]),
        "first_goal": first_goal(tr), "train_steps": sum(e["steps"] for e in tr),
        "eval_goals": sum(e["outcome"] == 1 for e in ev), "eval_n": len(ev),
        "eval_clean": bool(ev) and all(e["outcome"] == 1 for e in ev),
        "eval_steps": mean(e["steps"] for e in ev if e["outcome"] == 1) if any(e["outcome"] == 1 for e in ev) else None,
        "sec_per_step": (r["seconds"] / r["steps"]) if r.get("steps") else None,
        "slips": r.get("slips") or 0, "steps": r.get("steps") or 0,
    }
    return d


def summarise(matches, n_last=40):
    std = [m for m in matches if 200 <= m.header.get("version", 0) < 1000]
    rows = [r for r in run_rows(std)]
    full = [r for r in rows if r["complete"] == 1]
    S: dict = {"n_matches": len(std), "n_runs": len(rows), "n_runs_complete": len(full),
               "n_episodes": sum(len(m.episodes) for m in std), "n_steps": sum(e["steps"] for m in std for e in m.episodes)}
    dur = sum(max((e["t"] for e in m.episodes), default=0) for m in std)
    S["game_hours"] = dur / 3600
    S["steps_per_sec"] = S["n_steps"] / max(dur, 1)
    S["episodes_per_min"] = 60 * S["n_episodes"] / max(dur, 1)
    S["slips"] = sum(r.get("slips") or 0 for r in rows)
    S["slips_per_1000_steps"] = 1000 * S["slips"] / max(1, sum(r.get("steps") or 0 for r in rows))
    S["load_peak"] = max((l["load_peak"] for m in std for l in m.load), default=None)
    S["load_avg"] = mean(l["load"] for m in std for l in m.load) if any(m.load for m in std) else None
    S["move_speeds"] = sorted({m.header["move_speed"] for m in std})
    S["run_speed"] = mean(m.header["run_speed"] for m in std) if std else None
    checked = bad = 0
    for m in std:
        c, b = ns.replay_steps(m)
        checked += c
        bad += len(b)
    S["replay_checked"], S["replay_bad"] = checked, bad
    S["sanity_problems"] = sum(len(ns.sanity(m)) for m in std)
    conds = {}
    for cond in sorted({r["cond"] for r in full}):
        rs = [per_run(r, n_last) for r in full if r["cond"] == cond]
        d = {"name": ns.CONDITION_NAMES[cond], "runs": len(rs)}
        for key in ("falls_per_100", "last_return", "last_edge", "falls", "timeouts", "train_steps", "sec_per_step"):
            vals = [x[key] for x in rs if x[key] is not None]
            d[key] = mean(vals)
            lo, hi = boot_ci(vals)
            d[key + "_lo"], d[key + "_hi"] = lo, hi
        fg = [x["first_goal"] for x in rs]
        d["first_goal_median"] = sorted([x for x in fg if x])[len([x for x in fg if x]) // 2] if any(fg) else None
        d["never_reached_goal"] = sum(1 for x in fg if not x)
        ev = [x for x in rs if x["eval_n"]]
        d["eval_runs"] = len(ev)
        d["eval_clean_runs"] = sum(1 for x in ev if x["eval_clean"])
        d["eval_goal_rate"] = mean(x["eval_goals"] / x["eval_n"] for x in ev) if ev else None
        es = [x["eval_steps"] for x in ev if x["eval_steps"]]
        d["eval_steps"] = mean(es) if es else None
        d["per_run_falls"] = [x["falls"] for x in rs]
        d["per_run_last_return"] = [x["last_return"] for x in rs]
        d["per_run_last_edge"] = [x["last_edge"] for x in rs]
        conds[cond] = d
    S["conditions"] = conds

    def contrast(a, b, key):
        xa = [per_run(r, n_last)[key] for r in full if r["cond"] == a]
        xb = [per_run(r, n_last)[key] for r in full if r["cond"] == b]
        if len(xa) < 2 or len(xb) < 2:
            return None
        diffs_seed = random.Random(3)
        boots = sorted(mean([xa[diffs_seed.randrange(len(xa))] for _ in xa]) - mean([xb[diffs_seed.randrange(len(xb))] for _ in xb]) for _ in range(4000))
        return {"a": ns.CONDITION_NAMES[a], "b": ns.CONDITION_NAMES[b], "key": key, "mean_a": mean(xa), "mean_b": mean(xb),
                "diff": mean(xa) - mean(xb), "lo": boots[100], "hi": boots[3899], "p": perm_p(xa, xb), "n_a": len(xa), "n_b": len(xb)}

    S["contrasts"] = {
        "sarsa_vs_q_falls": contrast(0, 1, "falls_per_100"), "sarsa_vs_q_edge": contrast(0, 1, "last_edge"),
        "sarsa_vs_q_return": contrast(0, 1, "last_return"),
        "dyna_vs_q_falls": contrast(5, 1, "falls_per_100"), "dyna_vs_q_return": contrast(5, 1, "last_return"),
        "fading_vs_q_falls": contrast(3, 1, "falls_per_100"), "optimism_vs_q_falls": contrast(4, 1, "falls_per_100"),
        "bonus_vs_q_falls": contrast(8, 1, "falls_per_100"), "mc_vs_sarsa_return": contrast(6, 0, "last_return"),
        "pg_vs_q_return": contrast(11, 1, "last_return"), "lambda_vs_sarsa_falls": contrast(7, 0, "falls_per_100"),
    }

    # Prediction (the random-walk bot): error of the TD(0) and Monte Carlo value tables against the exact answer.
    exact = ns.random_policy_values()
    pred: dict = {}
    for m in std:
        for p in m.ptables:
            if p["kind"] == 2:
                continue
            key = (Path(m.path).name, p["bot"], p["run"], p["ep"], p["kind"])
            pred.setdefault(key, {})[p["row"]] = p["values"]
        visits = {}
        for p in m.ptables:
            if p["kind"] == 2:
                visits.setdefault((Path(m.path).name, p["bot"], p["run"], p["ep"]), {})[p["row"]] = p["values"]
        for key, rowsv in list(pred.items()):
            if key[0] != Path(m.path).name or len(rowsv) < ns.NROWS or "rmse" in rowsv:
                continue
            v = visits.get(key[:4], {})
            sq, n = 0.0, 0
            for row in range(ns.NROWS):
                for c in range(ns.NCOLS):
                    cell = row * ns.NCOLS + c
                    if cell == ns.GOAL or (v and v.get(row, [1] * 12)[c] < 1):
                        continue
                    sq += (rowsv[row][c] - exact[cell]) ** 2
                    n += 1
            rowsv["rmse"] = math.sqrt(sq / max(1, n))
            rowsv["cells"] = n
    by_ep: dict = {}
    for (fname, bot, run, ep, kind), rowsv in pred.items():
        if "rmse" in rowsv:
            by_ep.setdefault((ep, kind), []).append(rowsv["rmse"])
    S["prediction"] = {f"{'td' if k == 0 else 'mc'}_{ep}": {"rmse": mean(v), "runs": len(v)} for (ep, k), v in sorted(by_ep.items())}
    S["exact_random_start_value"] = exact[ns.START]
    rnd = [e for m in std for e in m.episodes if m.runs.get((e["bot"], e["run"]), {}).get("algo") == ns.RANDOM]
    if rnd:
        S["random_walk"] = {"episodes": len(rnd), "mean_return": mean(e["ret"] for e in rnd), "mean_steps": mean(e["steps"] for e in rnd),
                            "goal_rate": mean(1 if e["outcome"] == 1 else 0 for e in rnd),
                            "se_return": (sum((e["ret"] - mean(x["ret"] for x in rnd)) ** 2 for e in rnd) / max(1, len(rnd) - 1)) ** 0.5 / math.sqrt(len(rnd))}
    # Planner: sweeps until the values stopped changing.
    sweeps = {}
    for m in std:
        for s in m.sweeps:
            sweeps.setdefault((Path(m.path).name, s["bot"], s["run"]), []).append(s["delta"])
    if sweeps:
        S["planner_sweeps"] = mean(len(v) for v in sweeps.values())
        S["planner_sweep_deltas"] = max(sweeps.values(), key=len)
    Q, deltas = ns.value_iteration()
    S["planner_reference_sweeps"] = len(deltas)
    S["best_return"] = max(Q[0:4])
    return S, rows


def curves(rows, cond, n_eps, key="ret", window=10):
    """Mean learning curve of a condition over complete runs: smoothed per-episode values."""
    runs = [[e[key] if key != "fell" else (100.0 if e["outcome"] == 2 else 0.0) for e in r["train"][:n_eps]] for r in rows if r["cond"] == cond and r["complete"] == 1]
    runs = [r for r in runs if len(r) >= n_eps]
    if not runs:
        return None
    avg = [mean(r[i] for r in runs) for i in range(n_eps)]
    sm = [mean(avg[max(0, i - window + 1): i + 1]) for i in range(n_eps)]
    return sm, len(runs)


def figures(S, rows, out: Path):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    plt.rcParams.update({"figure.facecolor": PANEL, "axes.facecolor": PANEL, "savefig.facecolor": PANEL, "axes.edgecolor": "#484239",
                         "axes.labelcolor": MUTED, "xtick.color": "#8f877a", "ytick.color": "#8f877a", "text.color": INK,
                         "grid.color": GRID, "font.size": 11, "axes.spines.top": False, "axes.spines.right": False})
    made = []

    def curve_fig(name, conds, title, key, ylabel, n_eps=150, ylim=None):
        fig, ax = plt.subplots(figsize=(8.6, 4.4), dpi=160)
        any_line = False
        for c in conds:
            got = curves(rows, c, n_eps if c != 10 else 40, key)
            if not got:
                continue
            sm, n = got
            ax.plot(range(1, len(sm) + 1), sm, color=COLORS[c], lw=2, label=f"{ns.CONDITION_NAMES[c]} ({n} runs)")
            ax.annotate(ns.CONDITION_NAMES[c], (len(sm), sm[-1]), xytext=(6, 0), textcoords="offset points", color=COLORS[c], fontsize=9, va="center")
            any_line = True
        if not any_line:
            plt.close(fig)
            return
        ax.set_xlabel("training episode")
        ax.set_ylabel(ylabel)
        ax.set_title(title, loc="left", fontsize=12, color=INK)
        ax.grid(True, axis="y", lw=0.6)
        ax.set_xlim(1, n_eps * 1.22)
        if ylim:
            ax.set_ylim(*ylim)
        fig.tight_layout()
        fig.savefig(out / name)
        plt.close(fig)
        made.append(name)

    curve_fig("fig_control_return.png", [0, 1, 2], "Return per episode while still exploring (mean of runs, smoothed over 10)", "ret", "return")
    curve_fig("fig_control_falls.png", [0, 1, 2], "Share of episodes ending in a fall (percent, smoothed over 10)", "fell", "falls per 100 episodes", ylim=(0, 100))
    curve_fig("fig_explore_falls.png", [1, 3, 4, 8], "Four ways to explore: share of episodes ending in a fall", "fell", "falls per 100 episodes", ylim=(0, 100))
    curve_fig("fig_dyna_return.png", [1, 5], "Thinking between steps: Dyna-Q against plain Q-learning", "ret", "return")
    curve_fig("fig_all_return.png", [0, 1, 2, 3, 4, 5, 6, 7, 8, 11], "Every learner: return per training episode", "ret", "return")
    curve_fig("fig_mc_td_return.png", [0, 6, 7], "Learn every step, or wait for the end of the episode", "ret", "return")
    curve_fig("fig_pg_return.png", [1, 11], "Learning values against learning the policy directly", "ret", "return")

    # Dot plot: falls per 100 training episodes, every run a dot, mean and interval per condition.
    conds = [c for c in (10, 5, 4, 8, 0, 2, 7, 3, 1, 6, 11) if c in S["conditions"]]
    if conds:
        fig, ax = plt.subplots(figsize=(8.6, 0.5 * len(conds) + 1.6), dpi=160)
        for i, c in enumerate(conds):
            d = S["conditions"][c]
            per = [100 * f / max(1, t) for f, t in zip(d["per_run_falls"], [150 if c != 10 else 40] * len(d["per_run_falls"]))]
            ax.scatter(per, [i + (random.Random(i * 31 + k).random() - 0.5) * 0.3 for k in range(len(per))], s=14, color=COLORS[c], alpha=0.55, marker=MARKERS[c], lw=0)
            ax.plot([d["falls_per_100_lo"], d["falls_per_100_hi"]], [i, i], color=INK, lw=1.6)
            ax.scatter([d["falls_per_100"]], [i], s=46, color=INK, zorder=3)
            ax.text(101, i, f"{d['falls_per_100']:.0f}", va="center", fontsize=9, color=MUTED)
        ax.set_yticks(range(len(conds)))
        ax.set_yticklabels([f"{S['conditions'][c]['name']} ({S['conditions'][c]['runs']})" for c in conds])
        ax.set_xlim(0, 108)
        ax.invert_yaxis()
        ax.set_xlabel("training episodes that ended in a fall, per 100 (each small mark is one run; white dot and bar: mean and 95% interval)")
        ax.grid(True, axis="x", lw=0.6)
        fig.tight_layout()
        fig.savefig(out / "fig_falls_by_method.png")
        plt.close(fig)
        made.append("fig_falls_by_method.png")

    # Prediction error.
    pr = S.get("prediction", {})
    eps = sorted({int(k.split("_")[1]) for k in pr})
    if eps:
        fig, ax = plt.subplots(figsize=(7.2, 4), dpi=160)
        for kind, col, lab in (("td", COLORS[0], "TD(0): learn after every step"), ("mc", COLORS[1], "Monte Carlo: learn at the end of the episode")):
            xs = [e for e in eps if f"{kind}_{e}" in pr]
            ax.plot(xs, [pr[f"{kind}_{e}"]["rmse"] for e in xs], marker="o", color=col, lw=2, label=lab)
        ax.set_xscale("log")
        ax.set_xlabel("episodes of random walking (log scale)")
        ax.set_ylabel("typical error of the value estimates")
        ax.legend(frameon=False)
        ax.grid(True, axis="y", lw=0.6)
        fig.tight_layout()
        fig.savefig(out / "fig_prediction_error.png")
        plt.close(fig)
        made.append("fig_prediction_error.png")
    return made


def main(argv):
    logs, out = Path(argv[0]), Path(argv[1])
    out.mkdir(parents=True, exist_ok=True)
    matches = collect([logs])
    S, rows = summarise(matches)
    S["figures"] = figures(S, rows, out)
    (out / "summary.json").write_text(json.dumps(S, indent=1, default=str))
    print(f"{S['n_matches']} matches, {S['n_runs_complete']} complete runs of {S['n_runs']}, {S['n_episodes']} episodes, {S['n_steps']} real steps, "
          f"{S['game_hours']:.2f} h, {S['steps_per_sec']:.1f} steps/s; replay {S['replay_checked'] - S['replay_bad']}/{S['replay_checked']}; figures {len(S['figures'])}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
