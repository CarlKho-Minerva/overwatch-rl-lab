"""Compare algorithms across repeated runs.

One run is one sample. The Workshop cannot seed its random numbers, so the only honest comparison is
between runs: this module picks out the runs that were made under the standard settings, summarises
the late part of each, and tests the difference between algorithms at the level of runs.

Usage:  python -m rllab.compare data/logs/*.txt [--last 40] [--min-train 100]
"""

from __future__ import annotations

import argparse
import itertools
import statistics
import sys

from .logs import ALGOS, LabLog, parse_log

# The settings every run in the comparison must share (RUN line and EP line fields).
STANDARD_RUN = {
    "experiment": 0, "q_init": 0, "r_step": -1, "r_goal": 50, "r_fall": -100, "r_timeout": -50,
    "max_steps": 100, "closed_loop": True, "use_blink": False, "n_actions": 4, "move_speed": 100, "game_speed": 100,
}
STANDARD_EPISODE = {"epsilon_milli": 100, "alpha_milli": 500, "gamma_milli": 1000}
STANDARD_CELL = 2


def standard_runs(log: LabLog) -> list[tuple[str, int]]:
    """(file, run) pairs made under the standard cliff-walk settings, cold start, in file order."""
    warm = {(w["file"], w["run"]) for w in log.warm}
    cells = {c["file"]: c["cell"] for c in log.cal}
    keep = []
    for header in log.run:
        key = (header["file"], header["run"])
        if key in warm or cells.get(header["file"]) != STANDARD_CELL:
            continue
        if all(header.get(name) == value for name, value in STANDARD_RUN.items()):
            keep.append(key)
    return keep


def late_training_table(log: LabLog, last: int = 40, min_train: int = 100) -> list[dict]:
    """One row per standard run with at least `min_train` training episodes: its last `last` of them."""
    rows = []
    for file, run in standard_runs(log):
        episodes = [e for e in log.ep if e["file"] == file and e["run"] == run]
        training = [e for e in episodes if e["mode"] == 0]
        if len(training) < min_train:
            continue
        if any(e[name] != value for e in training for name, value in STANDARD_EPISODE.items()):
            continue
        late = training[-last:]
        goal_steps = [e["steps"] for e in late if e["outcome"] == 1]
        evaluation = [e for e in episodes if e["mode"] == 1]
        rows.append({
            "file": file,
            "run": run,
            "algo": ALGOS[training[0]["algo"]],
            "training_episodes": len(training),
            "minutes": round((training[-1]["t"] - (training[0]["t"] if len(training) > 1 else 0)) / 60, 1),
            "first_goal_episode": next((e["episode"] for e in training if e["outcome"] == 1), None),
            "late_n": len(late),
            "late_mean_return": statistics.fmean(e["ret"] for e in late),
            "late_falls": sum(e["outcome"] == 2 for e in late),
            "late_fall_rate": sum(e["outcome"] == 2 for e in late) / len(late),
            "late_mean_edge_dist": statistics.fmean(e["mean_edge_dist"] for e in late),
            "late_median_goal_steps": statistics.median(goal_steps) if goal_steps else None,
            "eval_n": len(evaluation),
            "eval_goals": sum(e["outcome"] == 1 for e in evaluation),
            "eval_timeouts": sum(e["outcome"] == 3 for e in evaluation),
            "eval_falls": sum(e["outcome"] == 2 for e in evaluation),
            "eval_median_goal_steps": (statistics.median([e["steps"] for e in evaluation if e["outcome"] == 1])
                                       if any(e["outcome"] == 1 for e in evaluation) else None),
        })
    return rows


def permutation_p(first: list[float], second: list[float]) -> float:
    """Exact two-sided permutation test on the difference of means between two small groups.

    In words: of all the ways to deal these run results into two groups of these sizes, the share
    that gives a gap at least as large as the one observed. With 3 runs against 3 the smallest
    possible value is 0.1, so this test can never call a 3-against-3 difference significant at 0.05.
    """
    pooled = list(first) + list(second)
    observed = abs(statistics.fmean(first) - statistics.fmean(second))
    hits = total = 0
    for chosen in itertools.combinations(range(len(pooled)), len(first)):
        group = [pooled[i] for i in chosen]
        rest = [pooled[i] for i in range(len(pooled)) if i not in chosen]
        total += 1
        if abs(statistics.fmean(group) - statistics.fmean(rest)) >= observed - 1e-12:
            hits += 1
    return hits / total


def by_algorithm(rows: list[dict]) -> dict:
    """Per algorithm: the run-level values of each late-training measure, with mean and range."""
    measures = ["late_mean_return", "late_fall_rate", "late_mean_edge_dist"]
    out: dict = {"algorithms": {}, "tests": {}}
    groups: dict[str, list[dict]] = {}
    for row in rows:
        groups.setdefault(row["algo"], []).append(row)
    for algo, members in groups.items():
        out["algorithms"][algo] = {
            "runs": len(members),
            "pooled_late_falls": sum(m["late_falls"] for m in members),
            "pooled_late_n": sum(m["late_n"] for m in members),
            **{name: {"values": [m[name] for m in members],
                      "mean": statistics.fmean(m[name] for m in members),
                      "min": min(m[name] for m in members),
                      "max": max(m[name] for m in members)} for name in measures},
        }
    if len(groups) == 2 and all(len(members) >= 2 for members in groups.values()):
        (_, a), (_, b) = sorted(groups.items())
        for name in measures:
            out["tests"][name] = permutation_p([m[name] for m in a], [m[name] for m in b])
    return out


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("logs", nargs="+")
    parser.add_argument("--last", type=int, default=40)
    parser.add_argument("--min-train", type=int, default=100)
    args = parser.parse_args(argv)
    rows = late_training_table(parse_log(*args.logs), args.last, args.min_train)
    if not rows:
        print("No standard cliff-walk run with enough training episodes in these logs.")
        return 1
    for row in sorted(rows, key=lambda r: (r["algo"], r["file"], r["run"])):
        print(f"{row['algo']:<11} {row['file'][:44]:<44} run {row['run']}: {row['training_episodes']} training episodes in "
              f"{row['minutes']} min; last {row['late_n']}: return {row['late_mean_return']:+.1f}, "
              f"falls {row['late_falls']}/{row['late_n']}, edge distance {row['late_mean_edge_dist']:.2f} m; "
              f"evaluation {row['eval_goals']}/{row['eval_n']} goals, {row['eval_timeouts']} timeouts")
    summary = by_algorithm(rows)
    print()
    for algo, stats in sorted(summary["algorithms"].items()):
        print(f"{algo}: {stats['runs']} runs; late falls pooled {stats['pooled_late_falls']}/{stats['pooled_late_n']}; "
              + "; ".join(f"{name[5:]} mean {values['mean']:.2f} (range {values['min']:.2f} to {values['max']:.2f})"
                          for name, values in stats.items() if isinstance(values, dict)))
    for name, p in summary["tests"].items():
        print(f"exact permutation test on run means, {name[5:]}: p = {p:.2f}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
