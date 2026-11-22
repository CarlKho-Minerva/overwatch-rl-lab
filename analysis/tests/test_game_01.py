"""Game 1, No Coach: five identical rings, a score, and nothing else.

Hidden rules: every second of a round costs 1, one ring pays +50 and ends the round, one ring sends a -20 bill that
arrives when the round ends, the other three pay 0. Rounds 1 to 3 share one hidden layout; round 4 redraws it and the
+50 ring moves.
"""
import math

import pytest

from rllab import games

GAME = 1
LOG = games.newest(GAME)
PAY_GOAL, BILL, RING_DIST = 50, 20, 13
HOME = (0.0, 0.0, -3.0)


def round_total(found: int, secs: int, trap: int) -> int:
    """A round's total: +50 if the paying ring was reached, minus 1 per second, minus 20 if the billing ring was touched."""
    return PAY_GOAL * found - secs - BILL * trap


def ring_pos(k: int):
    a = math.radians(90 + 72 * k)
    return (HOME[0] + RING_DIST * math.cos(a), 0.0, HOME[2] + RING_DIST * math.sin(a))


def test_round_total_reference():
    # The same values as the game's CHECK lines.
    assert round_total(1, 3, 0) == 47
    assert round_total(1, 12, 1) == 18
    assert round_total(0, 120, 0) == -120
    assert round_total(1, 3, 0) - round_total(1, 12, 1) == 29


def test_rings_are_equally_far_and_on_the_island():
    for k in range(5):
        p = ring_pos(k)
        assert abs(math.dist(p, HOME) - 13) < 1e-9
        assert -20 < p[0] < 20 and -20 < p[2] < 20
    # neighbouring rings are further apart than two ring radii, so one step can never touch two rings
    assert math.dist(ring_pos(0), ring_pos(1)) > 2 * 1.6


@pytest.mark.skipif(LOG is None, reason="no saved log of game 1 in data/logs/games")
def test_game_01_log():
    log = games.parse(LOG)
    assert games.problems(log, GAME) == []
    assert len(log["A"]) == 6

    layouts = {v[0]: (v[1], v[2]) for v in games.events(log, "layout")}
    assert set(layouts) == {1, 4}
    for goal, trap in layouts.values():
        assert goal in range(5) and trap in range(5) and goal != trap
    assert layouts[4][0] != layouts[1][0], "round 4 must move the +50 ring"

    rounds = {v[0]: v[1:] for v in games.events(log, "round")}
    assert sorted(rounds) == [1, 2, 3, 4]
    touches = games.events(log, "touch")
    for r, (found, secs, trap, total) in rounds.items():
        assert abs(total - round_total(found, secs, trap)) < 0.02, f"round {r} total"
        goal, trap_ring = layouts[4] if r == 4 else layouts[1]
        mine = [t for t in touches if t[0] == r]
        rings = [t[1] for t in mine]
        assert len(rings) == len(set(rings)), "each ring pays at most once a round"
        assert found == (1 if goal in rings else 0)
        assert trap == (1 if trap_ring in rings else 0)
        for _, ring, reward, t in mine:
            assert reward == (PAY_GOAL if ring == goal else 0)
            assert t <= secs
        if found:
            assert rings[-1] == goal, "the +50 ring ends the round"

    gap = games.events(log, "gap")[0]
    assert gap[0] == rounds[1][3] and gap[1] == rounds[2][3] and abs(gap[2] - (gap[1] - gap[0])) < 0.02
    assert games.events(log, "vanish") == [[3]]

    # Question 2 ("will your total change?") is right exactly when the late bill came in round 1.
    q2 = [a for a in log["A"] if a["qid"] == 2][0]
    assert q2["correct"] == rounds[1][2]


def test_stops_file_matches_game_and_page():
    """One page entry per stop, each after a real part of the lecture page, in page order."""
    import json
    import re
    from pathlib import Path

    games_dir = Path(__file__).resolve().parents[2] / "workshop" / "games"
    n_stops = int(re.search(r"#!define STOPS (\d+)", (games_dir / "g01_body.opy").read_text()).group(1))
    body = (games_dir / "g01_body.opy").read_text()
    assert [int(k) for k in re.findall(r"STOP\((\d+)\)", body)] == list(range(1, n_stops + 1))
    stops = json.loads((games_dir / "g01_stops.json").read_text())["stops"]
    assert [s["n"] for s in stops] == list(range(1, n_stops + 1))
    page = Path(__file__).resolve().parents[2] / "course" / "lecture-01.md"
    if page.exists():
        stamps = re.findall(r"^### \[([0-9:]+)\]", page.read_text(), flags=re.M)
        where = [stamps.index(s["after"]) for s in stops]
        assert where == sorted(where)
    for s in stops:
        for k in ("title", "silver", "do", "predict", "saw"):
            assert s[k] and len(s[k]) < 420 and "\u2014" not in s[k] and "\u2013" not in s[k] and "!" not in s[k]
