"""Read the log lines the course games write (RLG,...), one Workshop mode per lecture.

    RLG,M,<game>,<version>,<autoplay>
    RLG,T,<game>,<name>,<expected>,<got>,<ok>
    RLG,G,<game>,<stop>                                          a numbered stop begins (the lecture's page has the same stops)
    RLG,Q,<game>,<question id>                                   the question is on screen
    RLG,A,<game>,<question id>,<answer>,<correct answer>,<right>,<seconds he took>
    RLG,E,<game>,<event name>,<values...>
    RLG,L,<game>,<seconds sampled>,<server load, mean>,<highest peak in play>,<highest peak in the first 10 seconds>
    RLG,X,<game>,<seconds>,<predictions right>,<predictions made>,<self-tests ok>,<self-tests failed>

The game prints numbers to two decimals, and its chat filter can replace some digit runs with stars; a starred
field is returned as None.
"""
from __future__ import annotations

import re
from pathlib import Path

LINE = re.compile(r"^\[(\d+):(\d+):(\d+)\] RLG,([A-Z]),(.*)$")
LOGS = Path(__file__).resolve().parents[2] / "data" / "logs" / "games"


def _val(x: str):
    x = x.strip()
    if x in ("True", "False"):
        return x == "True"
    if "*" in x:
        return None
    try:
        return int(x)
    except ValueError:
        try:
            return float(x)
        except ValueError:
            return x


def parse(path) -> dict:
    """All RLG lines of one log file: {"M": [...], "T": [...], "A": [...], "E": [...], "X": [...]}, each a list of dicts."""
    out = {"M": [], "T": [], "A": [], "E": [], "X": [], "L": [], "Q": [], "G": [], "path": str(path)}
    for line in Path(path).read_text(encoding="utf-8", errors="replace").splitlines():
        m = LINE.match(line.strip())
        if not m:
            continue
        t = int(m.group(1)) * 3600 + int(m.group(2)) * 60 + int(m.group(3))
        kind, f = m.group(4), [_val(x) for x in m.group(5).split(",")]
        if kind == "T" and len(f) > 5:
            # a self-test's name may hold commas: the last three fields are expected, got and ok
            f = [f[0], ",".join(str(x) for x in f[1:-3])] + f[-3:]
        if kind == "M" and len(f) >= 3:
            out["M"].append({"t": t, "game": f[0], "version": f[1], "autoplay": f[2]})
        elif kind == "T" and len(f) >= 5:
            out["T"].append({"t": t, "game": f[0], "name": f[1], "expected": f[2], "got": f[3], "ok": f[4]})
        elif kind == "A" and len(f) >= 5:
            out["A"].append({"t": t, "game": f[0], "qid": f[1], "answer": f[2], "correct": f[3], "right": f[4], "seconds": f[5] if len(f) > 5 else None})
        elif kind == "Q" and len(f) >= 2:
            out["Q"].append({"t": t, "game": f[0], "qid": f[1]})
        elif kind == "G" and len(f) >= 2:
            out["G"].append({"t": t, "game": f[0], "stop": f[1]})
        elif kind == "E" and len(f) >= 2:
            out["E"].append({"t": t, "game": f[0], "name": f[1], "v": f[2:]})
        elif kind == "L" and len(f) >= 4:
            # server load over the whole game, read once a second: seconds sampled, mean of the averages, highest peak
            out["L"].append({"t": t, "game": f[0], "samples": f[1], "load_avg": f[2], "load_peak": f[3], "load_start": f[4] if len(f) > 4 else None})
        elif kind == "X" and len(f) >= 6:
            out["X"].append({"t": t, "game": f[0], "seconds": f[1], "right": f[2], "asked": f[3], "self_ok": f[4], "self_bad": f[5]})
    return out


def newest(game: int, auto: bool = True):
    """The newest saved log of a game (gNN_auto_*.txt from the automatic check, gNN_play_*.txt from a person playing), or None."""
    files = sorted(LOGS.glob(f"g{game:02d}_{'auto' if auto else 'play'}_*.txt"))
    return files[-1] if files else None


def events(log: dict, name: str) -> list:
    return [e["v"] for e in log["E"] if e["name"] == name]


def problems(log: dict, game: int, min_questions: int = 4, min_selftests: int = 4) -> list:
    """What every game's log must satisfy. An empty list means the run was complete and its own arithmetic checked out."""
    bad = []
    if not log["M"] or log["M"][0]["game"] != game:
        bad.append("no header line for this game")
    if not log["X"]:
        bad.append("the game did not reach its closing line")
    elif log["X"][-1]["self_bad"] != 0:
        bad.append(f"{log['X'][-1]['self_bad']} self-test(s) failed in the game")
    fails = [t["name"] for t in log["T"] if t["ok"] != 1]
    if fails:
        bad.append("failed self-tests: " + ", ".join(map(str, fails)))
    if len(log["T"]) < min_selftests:
        bad.append(f"only {len(log['T'])} self-test lines")
    if len(log["A"]) < min_questions:
        bad.append(f"only {len(log['A'])} prediction questions were asked")
    if log["X"] and log["X"][-1]["asked"] != len(log["A"]):
        bad.append("the closing line and the answer lines disagree on how many questions were asked")
    return bad
