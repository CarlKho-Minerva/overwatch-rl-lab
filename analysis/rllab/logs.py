"""Parse the Workshop Inspector log files written by Overwatch.

Overwatch writes them to  Documents/Overwatch/Workshop/Log-<date>.txt  when
Options > Gameplay > General > "Enable Workshop Inspector Log File" is on.
Every line this lab writes starts with RLLAB. Column lists: docs/logging.md.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from pathlib import Path

LINE = re.compile(r"^\[(\d+):(\d+):(\d+)\]\s+RLLAB,([A-Z]+),(.*)$")

COLUMNS = {
    "CAL": ["floor_y", "x_min", "x_max", "z_min", "z_max", "cell", "run_speed", "coast_dist", "act_duration"],
    "RUN": [
        "run", "experiment", "algo", "q_init", "r_step", "r_goal", "r_fall", "r_timeout", "r_killed", "r_hit",
        "max_steps", "closed_loop", "use_health_bit", "use_blink", "n_actions", "move_speed", "game_speed",
    ],
    "EP": [
        "run", "episode", "algo", "mode", "epsilon_milli", "alpha_milli", "gamma_milli", "ret", "steps",
        "outcome", "mean_edge_dist", "hits", "t",
    ],
    "STEP": [
        "run", "episode", "step", "s", "a", "r", "s2", "a2", "terminal", "explore", "q_old", "q_new", "target",
    ],
    "Q": ["run", "episode", "s", "q0", "q1", "q2", "q3", "q4"],
    "SPAWN": ["spawn_calls"],
    "WARM": ["run", "table_size"],
}

OUTCOMES = {0: "running", 1: "goal", 2: "fell", 3: "timeout", 4: "killed"}
ALGOS = {0: "SARSA", 1: "Q-learning"}
EXPERIMENTS = {0: "cliff walk", 1: "cliff walk + Widowmaker", 2: "arena demo"}
MODES = {0: "training", 1: "evaluation"}


def _value(text: str):
    if text == "True":
        return True
    if text == "False":
        return False
    try:
        number = float(text)
    except ValueError:
        return text
    return int(number) if number.is_integer() else number


@dataclass
class LabLog:
    """All RLLAB records of one or more log files, as lists of dicts in file order."""

    cal: list[dict] = field(default_factory=list)
    run: list[dict] = field(default_factory=list)
    ep: list[dict] = field(default_factory=list)
    step: list[dict] = field(default_factory=list)
    q: list[dict] = field(default_factory=list)
    spawn: list[dict] = field(default_factory=list)
    warm: list[dict] = field(default_factory=list)
    fail: list[dict] = field(default_factory=list)
    skipped: list[str] = field(default_factory=list)

    def table(self, kind: str) -> list[dict]:
        return {"CAL": self.cal, "RUN": self.run, "EP": self.ep, "STEP": self.step, "Q": self.q, "SPAWN": self.spawn, "WARM": self.warm}[kind]


def parse_log(*paths: str | Path) -> LabLog:
    """Read one or more log files. Each record also gets `file` and `clock` (seconds on the log's own clock).

    A line that starts with RLLAB but has the wrong number of fields is kept in
    `skipped` rather than dropped silently.
    """
    log = LabLog()
    for path in paths:
        path = Path(path)
        with path.open(encoding="utf-8", errors="replace") as handle:
            for raw in handle:
                match = LINE.match(raw.strip())
                if not match:
                    if "RLLAB" in raw:
                        log.skipped.append(raw.rstrip("\n"))
                    continue
                hours, minutes, seconds, kind, rest = match.groups()
                if kind == "FAIL":
                    # Free-form: the script stopped during setup. First field names the stage.
                    log.fail.append({"file": path.name, "stage": rest.split(",")[0], "detail": rest})
                    continue
                names = COLUMNS.get(kind)
                values = rest.split(",")
                if names is None or len(values) != len(names):
                    log.skipped.append(raw.rstrip("\n"))
                    continue
                record = {name: _value(value) for name, value in zip(names, values)}
                record["file"] = path.name
                record["clock"] = int(hours) * 3600 + int(minutes) * 60 + int(seconds)
                log.table(kind).append(record)
    return log


def episodes_frame(log: LabLog):
    """Episodes as a pandas DataFrame with readable columns added."""
    import pandas as pd

    frame = pd.DataFrame(log.ep)
    if frame.empty:
        return frame
    frame["algo_name"] = frame["algo"].map(ALGOS)
    frame["mode_name"] = frame["mode"].map(MODES)
    frame["outcome_name"] = frame["outcome"].map(OUTCOMES)
    for name in ("epsilon", "alpha", "gamma"):
        frame[name] = frame[f"{name}_milli"] / 1000.0
    frame["fell"] = frame["outcome"] == 2
    frame["goal"] = frame["outcome"] == 1
    return frame
