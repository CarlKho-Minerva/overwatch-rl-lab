"""Hidden-wall build: the check on its own (against a made-up log), and against real logs when they are present."""
from pathlib import Path

import pytest

from rllab import night
from rllab.night import Match, NCELLS, wall_check

ROOT = Path(__file__).resolve().parents[2]
PROBE_LOGS = sorted((ROOT / "data" / "logs" / "night").glob("*v9402*.txt"))
POMDP_LOGS = sorted((ROOT / "data" / "logs" / "night").glob("*v1102*.txt"))

# The scripted walk of night_pomdp_probe.opy, wall forced into the edge row (square 6):
# five steps forward, two bumps, around through the second row, one bump from the far side, on to the goal.
PLAN = [0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 3, 1, 0, 0, 0, 0]
CELLS = [0, 1, 2, 3, 4, 5, 5, 5, 17, 18, 19, 7, 7, 8, 9, 10, 11]
MEMS = [0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]


def fake_match(agg, break_at=None):
    m = Match(path="made up")
    m.header = {"version": 9402}
    m.runs[(0, 0)] = {"agg": agg, "algo": 1, "alpha_milli": 500, "q_init": 0}
    for ep in range(2):
        for i, a in enumerate(PLAN):
            mult = {0: lambda k: 0, 3: lambda k: 0, 4: lambda k: MEMS[k]}[agg]
            s, s2 = CELLS[i] + NCELLS * mult(i), CELLS[i + 1] + NCELLS * mult(i + 1)
            if break_at == (ep, i):
                s2 = CELLS[i + 1]          # the memory "forgets"
            last = i == len(PLAN) - 1
            m.steps.append({"bot": 0, "run": 0, "t": ep * len(PLAN) + i, "s": s, "a": a, "r": 49 if last else -1, "s2": s2,
                            "a2": 0, "terminal": 1 if last else 0})
        m.episodes.append({"bot": 0, "run": 0, "ep": ep + 1, "mode": 0, "ret": 34, "steps": 16, "outcome": 1, "slips": 3, "station": 0})
    return m


@pytest.mark.parametrize("agg", [0, 3, 4])
def test_wall_check_accepts_the_scripted_walk(agg):
    out = wall_check(fake_match(agg))
    assert out["bad"] == [] and out["checked"] == 32 and out["bumps"] == 6 and out["slips"] == 0


def test_wall_check_catches_a_memory_that_forgets():
    out = wall_check(fake_match(4, break_at=(1, 8)))
    assert out["bad"], "a bot whose memory went back to empty after a bump must be reported"


def test_wall_check_catches_walking_through_the_wall():
    m = fake_match(0)
    m.steps[5]["s2"] = 6        # she arrived in the wall's square
    m.steps[6]["s"] = 6
    assert wall_check(m)["bad"]


@pytest.mark.skipif(not PROBE_LOGS, reason="no hidden-wall probe log in data/logs/night")
@pytest.mark.parametrize("path", PROBE_LOGS, ids=lambda p: p.name)
def test_probe_log_is_the_scripted_walk(path):
    m = night.parse(path)
    out = wall_check(m)
    assert out["runs"] >= 3 and out["bad"] == [], out["bad"][:5]
    checked, bad = night.replay_steps(m)
    assert checked > 0 and bad == []
    clean = [e for e in m.episodes if e["mode"] == 0 and e["steps"] == 16]
    assert clean, "no episode took the 16 scripted steps"
    for e in clean:
        assert e["outcome"] == 1 and abs(e["ret"] - 34) < 0.01 and e["slips"] == 3 and e["station"] == 0
    aggs = {m.runs[k].get("agg") for k in m.runs}
    assert {0, 3, 4} <= aggs
    # a remembering bot's reported states over a clean episode are the squares, plus 48 from the first bump on
    for (bot, run), info in m.runs.items():
        if info.get("agg") != 4:
            continue
        eps = night.episodes_from_steps(m, bot, run)
        full = [ep for ep in eps if len(ep) == 16]
        assert full
        for ep in full:
            assert [x[0] for x in ep] == [c + NCELLS * k for c, k in zip(CELLS[:-1], MEMS[:-1])]


@pytest.mark.skipif(not POMDP_LOGS, reason="no hidden-wall log in data/logs/night")
@pytest.mark.parametrize("path", POMDP_LOGS, ids=lambda p: p.name)
def test_hidden_wall_logs_are_consistent(path):
    m = night.parse(path)
    out = wall_check(m)
    assert out["checked"] > 0 and out["bad"] == [], out["bad"][:5]
    checked, bad = night.replay_steps(m)
    assert checked > 0 and bad == []
