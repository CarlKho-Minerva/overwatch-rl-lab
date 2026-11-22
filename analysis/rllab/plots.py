"""Learning curves and algorithm comparisons from real episode logs.

Usage:  python -m rllab.plots data/logs/<file>.txt [...] --out analysis/figures
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from .logs import episodes_frame, parse_log

# Colourblind-safe pair (Okabe-Ito blue and vermillion).
COLOURS = {"SARSA": "#0072B2", "Q-learning": "#D55E00"}


def summary_table(frame):
    """One row per file, run, algorithm and mode: episode counts and rates."""
    grouped = frame.groupby(["file", "run", "algo_name", "mode_name"], sort=False)
    table = grouped.agg(
        episodes=("ret", "size"),
        mean_return=("ret", "mean"),
        goal_rate=("goal", "mean"),
        fall_rate=("fell", "mean"),
        mean_steps=("steps", "mean"),
        mean_edge_dist=("mean_edge_dist", "mean"),
        epsilon=("epsilon", "last"),
        alpha=("alpha", "last"),
        gamma=("gamma", "last"),
    )
    return table.reset_index()


def learning_curves(frame, window: int = 20):
    """Three stacked panels over training episodes: return, falls, distance from the edge."""
    import matplotlib

    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    training = frame[frame["mode_name"] == "training"]
    figure, axes = plt.subplots(3, 1, figsize=(8, 9), sharex=True)
    panels = [
        ("ret", "Return per episode"),
        ("fell", "Share of episodes\nending in a fall"),
        ("mean_edge_dist", "Mean distance from\nthe island edge (m)"),
    ]
    # One thin line per run. Where an algorithm has several runs, a thick line is their mean,
    # drawn only over the episodes that every one of those runs reached.
    smoothed: dict[str, list] = {}
    for (file, run, algo), group in training.groupby(["file", "run", "algo_name"], sort=False):
        group = group.sort_values("episode").reset_index(drop=True)
        curves = {column: group[column].astype(float).rolling(window, min_periods=1).mean() for column, _ in panels}
        smoothed.setdefault(algo, []).append(curves)
    for algo, runs in smoothed.items():
        colour = COLOURS.get(algo, "0.3")
        several = len(runs) > 1
        shared = min(len(curves["ret"]) for curves in runs)
        for axis, (column, _) in zip(axes, panels):
            for curves in runs:
                axis.plot(range(1, len(curves[column]) + 1), curves[column], color=colour,
                          linewidth=0.9 if several else 1.8, alpha=0.45 if several else 1.0,
                          label=None if several else f"{algo} (1 run)")
            if several:
                mean = sum(curves[column].iloc[:shared].to_numpy() for curves in runs) / len(runs)
                axis.plot(range(1, shared + 1), mean, color=colour, linewidth=2.2,
                          label=f"{algo}: mean of {len(runs)} runs (thin lines: each run)")
    for axis, (_, title) in zip(axes, panels):
        axis.set_ylabel(title)
        axis.grid(alpha=0.3)
        axis.spines[["top", "right"]].set_visible(False)
    axes[0].legend(frameon=False, fontsize=9)
    axes[-1].set_xlabel("Training episode")
    figure.suptitle(
        "Tracer on the Workshop Island edge: training episodes logged by the game\n"
        f"(every line is a rolling mean over {window} episodes)",
        fontsize=11,
    )
    figure.tight_layout()
    return figure


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("logs", nargs="+")
    parser.add_argument("--out", default="analysis/figures")
    parser.add_argument("--window", type=int, default=20)
    args = parser.parse_args(argv)

    log = parse_log(*args.logs)
    frame = episodes_frame(log)
    if frame.empty:
        print("FAILED: no EP lines found in these logs.")
        return 1
    table = summary_table(frame)
    print(table.to_string(index=False, float_format=lambda value: f"{value:.2f}"))
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    table.to_csv(out / "summary.csv", index=False)
    if (frame["mode_name"] == "training").any():
        figure = learning_curves(frame, args.window)
        figure.savefig(out / "learning_curves.png", dpi=160)
        print(f"wrote {out / 'learning_curves.png'} and {out / 'summary.csv'}")
    else:
        print(f"no training episodes in these logs; wrote {out / 'summary.csv'} only")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
