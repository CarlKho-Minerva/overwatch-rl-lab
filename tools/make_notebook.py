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
    ("md", """## 4. Learning curves (training episodes, cliff walk only)

Top: return per episode. Middle: share of episodes that ended in a fall. Bottom: mean distance
from the edge. Each line is one run, smoothed over 20 episodes; the legend gives n. Only runs on
the standard arena are drawn (closed-loop moves, four actions).

One run per algorithm is a single sample, and the Workshop cannot seed its random numbers.
Treat a gap between the lines as a lead to repeat, not as a result."""),
    ("code", """# Standard arena only: closed-loop moves, four actions. Blink and fixed-duration runs are a different environment.
standard = (learning["closed_loop"] == True) & (learning["use_blink"] == False)
cliff = learning[(learning["experiment_name"] == "cliff walk") & (learning["mode_name"] == "training") & standard]
if len(cliff):
    figure = learning_curves(cliff, window=20)
    figure.savefig(ROOT / "analysis" / "figures" / "learning_curves.png", dpi=160)
    display(figure)
else:
    print("No cliff-walk training episodes in data/logs yet.")"""),
    ("md", """## 5. SARSA against Q-learning, late training

The last 40 training episodes of each cliff-walk run. This is the comparison Lab 02 asks about:
return, fall rate and distance from the edge while both are still exploring."""),
    ("code", """late = cliff.sort_values("episode").groupby(["file", "run", "algo_name"]).tail(40)
table = late.groupby(["algo_name", "file", "run"]).agg(
    episodes=("ret", "size"), mean_return=("ret", "mean"), fall_rate=("fell", "mean"),
    goal_rate=("goal", "mean"), mean_steps=("steps", "mean"), mean_edge_dist=("mean_edge_dist", "mean"),
).round(2)
table"""),
    ("md", """## 6. Greedy evaluation

Episodes run with exploration off and learning frozen (Reload in game). If there are none yet,
this table is empty."""),
    ("code", """evaluation = learning[learning["mode_name"] == "evaluation"]
evaluation.groupby(["experiment_name", "algo_name", "file", "run"]).agg(
    episodes=("ret", "size"), mean_return=("ret", "mean"), goal_rate=("goal", "mean"),
    fall_rate=("fell", "mean"), mean_steps=("steps", "mean"), mean_edge_dist=("mean_edge_dist", "mean"),
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
