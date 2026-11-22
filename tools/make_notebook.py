"""Writes analysis/notebooks/learning_curves.ipynb and runs it against the logs in data/logs.

Usage (from the repository root):  .venv/Scripts/python tools/make_notebook.py
The notebook is generated from this file so its text and code stay reviewable in one place.
"""

from pathlib import Path

import nbformat
from nbclient import NotebookClient

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "analysis" / "notebooks" / "learning_curves.ipynb"

cells = [
    ("md", """# Overwatch RL Lab: learning curves from real game logs

Every number here comes from log files that Overwatch wrote while the Workshop mode ran
(`data/logs/*.txt`). Nothing is simulated. To add your own session, copy the newest file from
`Documents\\Overwatch\\Workshop\\` into `data/logs/` and run all cells again.

Column meanings: `docs/logging.md`."""),
    ("code", """import sys
from pathlib import Path

ROOT = Path.cwd().resolve()
while not (ROOT / "data" / "logs").exists():
    ROOT = ROOT.parent
sys.path.insert(0, str(ROOT / "analysis"))

import pandas as pd
from rllab.logs import parse_log, episodes_frame, EXPERIMENTS
from rllab.plots import summary_table, learning_curves
from rllab.replay import replay

files = sorted((ROOT / "data" / "logs").glob("*.txt"))
log = parse_log(*files)
episodes = episodes_frame(log)
print(f"{len(files)} log files, {len(log.ep)} episodes, {len(log.step)} logged steps")
assert not log.skipped, log.skipped[:3]"""),
    ("md", """## 1. What was measured about the arena

One `CAL` line per run: the island's edges as found by ray casts, and Tracer's timed run speed."""),
    ("code", """pd.DataFrame(log.cal)[["file", "x_min", "x_max", "z_min", "z_max", "floor_y", "cell", "run_speed", "coast_dist", "act_duration"]].drop_duplicates()"""),
    ("md", """## 2. Did the game compute the updates correctly?

Where per-step logging was on, the replay applies the reference update
(`analysis/rllab/reference.py`) to the transitions the game logged and compares every target and
every Q-value with what the game wrote. A mismatch would be listed here."""),
    ("code", """report = replay(log)
print(f"steps checked: {report.steps_checked}, updates checked: {report.updates_checked}, episodes re-added: {report.episodes_checked}")
print(dict(report.by_algo))
if report.training_steps:
    print(f"exploratory draws: {report.explore_steps / report.training_steps:.1%} of training steps")
print("mismatches:", report.mismatches[:5] if report.mismatches else "none")"""),
    ("md", """## 3. Episodes per run

One row per file, run, algorithm and mode. `fall_rate` and `goal_rate` are shares of episodes.
`mean_edge_dist` is Tracer's average distance from the island edge in metres (row 0 is centred
1.5 m from the edge, row 1 at 3.5 m)."""),
    ("code", """runs = pd.DataFrame(log.run)
runs["experiment_name"] = runs["experiment"].map(EXPERIMENTS)
learning = episodes.merge(runs[["file", "run", "experiment_name", "closed_loop", "use_blink"]], on=["file", "run"])
summary_table(learning).round(2)"""),
    ("md", """## 4. Learning curves (training episodes, standard cliff walk only)

Top: return per episode. Middle: share of episodes that ended in a fall. Bottom: mean distance
from the edge. Every line is smoothed over 20 episodes. A thin line is one run; where an algorithm
has several runs, the thick line is their mean.

Only runs made under the standard settings are drawn (cold start, closed-loop moves, four actions,
default rewards, epsilon 0.1, alpha 0.5, gamma 1). Runs with other settings are a different
experiment and would not be comparable."""),
    ("code", """from rllab.compare import standard_runs, late_training_table, by_algorithm
from rllab.sanity import too_fast_episodes, duplicate_matches

assert not too_fast_episodes(log), "some episodes are too fast to be real play"
assert not duplicate_matches(log), "a match is in data/logs twice"

keep = pd.DataFrame(standard_runs(log), columns=["file", "run"])
cliff = learning.merge(keep, on=["file", "run"])
cliff = cliff[cliff["mode_name"] == "training"]
if len(cliff):
    figure = learning_curves(cliff, window=20)
    figure.savefig(ROOT / "analysis" / "figures" / "learning_curves.png", dpi=160)
    display(figure)
else:
    print("No standard cliff-walk training episodes in data/logs yet.")"""),
    ("md", """## 5. SARSA against Q-learning, run by run

One row per full run (at least 100 training episodes). The `late_` columns cover the last 40
training episodes, when both agents are still exploring. This is the comparison Lab 02 asks about.
The `eval_` columns are the greedy episodes run straight afterwards, with exploration off."""),
    ("code", """rows = late_training_table(log)
runs_table = pd.DataFrame(rows)
runs_table[["algo", "file", "run", "training_episodes", "minutes", "first_goal_episode", "late_mean_return",
            "late_falls", "late_fall_rate", "late_mean_edge_dist", "late_median_goal_steps",
            "eval_n", "eval_goals", "eval_timeouts", "eval_falls", "eval_median_goal_steps"]].sort_values(["algo", "file", "run"]).round(2)"""),
    ("md", """## 6. The two algorithms compared at the level of runs

Each run is one sample, so the test below works on run means, not on episodes. It is an exact
permutation test: of all the ways to deal these runs into two groups, the share that gives a gap
at least as large as the one seen. With three runs against three, the smallest value it can ever
return is 0.10, so read it as "as separated as three runs each can show", not as proof."""),
    ("code", """summary = by_algorithm(rows)
for algo, stats in sorted(summary["algorithms"].items()):
    print(f"{algo}: {stats['runs']} runs, falls in late training {stats['pooled_late_falls']} of {stats['pooled_late_n']} episodes")
    for name in ("late_mean_return", "late_fall_rate", "late_mean_edge_dist"):
        values = stats[name]
        print(f"    {name[5:]:<15} runs: {[round(v, 2) for v in values['values']]}   mean {values['mean']:.2f}")
for name, p in summary["tests"].items():
    print(f"exact permutation test on run means, {name[5:]}: p = {p:.2f}")"""),
    ("md", """## 7. Everything else that was recorded

Runs under other settings (Widowmaker, Blink, non-default values, the scripted patrol), by mode.
These are checks that the features work, not experiments."""),
    ("code", """other = learning.merge(keep.assign(standard=True), on=["file", "run"], how="left")
other = other[other["standard"].isna()]
other.groupby(["experiment_name", "algo_name", "mode_name", "file", "run"]).agg(
    episodes=("ret", "size"), mean_return=("ret", "mean"), goal_rate=("goal", "mean"),
    fall_rate=("fell", "mean"), mean_steps=("steps", "mean"), hits=("hits", "sum"),
).round(2)"""),
]

notebook = nbformat.v4.new_notebook()
for kind, text in cells:
    notebook.cells.append(nbformat.v4.new_markdown_cell(text) if kind == "md" else nbformat.v4.new_code_cell(text))
notebook.metadata["kernelspec"] = {"display_name": "Python 3", "language": "python", "name": "python3"}

(ROOT / "analysis" / "figures").mkdir(parents=True, exist_ok=True)
OUT.parent.mkdir(parents=True, exist_ok=True)
NotebookClient(notebook, timeout=120, resources={"metadata": {"path": str(OUT.parent)}}).execute()
nbformat.write(notebook, OUT)
print(f"wrote and executed {OUT}")
