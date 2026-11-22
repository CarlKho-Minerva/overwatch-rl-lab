"""Game 3, The Whiteboard: value iteration on a 5 by 5 board, one sweep per press.

Reference maths in plain Python for every number the game computes, then a check of the game's own log against it.
Pads: p = row * 5 + column. Moves: 0 = +column, 1 = +row, 2 = -column, 3 = -row; a step off the board stays put.
Each step costs 1, the goal pays 10, a pit costs 10; goal and pits end the dive (their number stays 0).
"""
import pytest

from rllab import games

N = 5
START, GOAL, PITS = 2, 23, (11, 13)
AUTO_PIT = 7
LOG = games.newest(3)
TOL = 0.02


def nxt(s, a):
    r, c = divmod(s, N)
    dr, dc = [(0, 1), (1, 0), (0, -1), (-1, 0)][a]
    r2, c2 = r + dr, c + dc
    if not (0 <= r2 < N and 0 <= c2 < N):
        return s
    return r2 * N + c2


def reward(s2, goal, pits):
    return -1 + (10 if s2 == goal else 0) - (10 if s2 in pits else 0)


def terminal(s, goal, pits):
    return s == goal or s in pits


def qvals(V, s, goal, pits):
    return [reward(nxt(s, a), goal, pits) + V[nxt(s, a)] for a in range(4)]


def sweep(V, goal, pits):
    """One synchronous sweep: every new number is built from the old table."""
    W = V[:]
    for s in range(N * N):
        if not terminal(s, goal, pits):
            W[s] = max(qvals(V, s, goal, pits))
    return W


def value_iteration(goal, pits):
    """Sweep from zeros until a sweep changes nothing. Returns the settled table, the number of sweeps (the last one
    changes nothing), the per-sweep (table, pads changed, biggest change), and the last sweep that changed each pad."""
    V = [0] * (N * N)
    tabs, last, k = [], [0] * (N * N), 0
    while True:
        W = sweep(V, goal, pits)
        k += 1
        changed = [s for s in range(N * N) if abs(W[s] - V[s]) > 1e-3]
        for s in changed:
            last[s] = k
        tabs.append((W, len(changed), max(abs(W[s] - V[s]) for s in range(N * N))))
        V = W
        if not changed:
            return V, k, tabs, last


def arrows(V, goal, pits, old=None):
    """The plan: the best move on each pad, ties to the lowest move number; an old move is kept while it is still best."""
    A = [-1] * (N * N)
    for s in range(N * N):
        if terminal(s, goal, pits):
            continue
        q = qvals(V, s, goal, pits)
        m = max(q)
        A[s] = old[s] if (old is not None and old[s] >= 0 and q[old[s]] >= m - 1e-3) else q.index(m)
    return A


def wrong_lines(old, V, goal, pits):
    """Old lines that are no longer a best move on the new map."""
    return sum(1 for s in range(N * N) if not terminal(s, goal, pits) and old[s] >= 0
               and qvals(V, s, goal, pits)[old[s]] < max(qvals(V, s, goal, pits)) - 1e-3)


def walk(A, goal, pits, start=START):
    s, ret, steps = start, 0, 0
    while not terminal(s, goal, pits) and steps < 40:
        s2 = nxt(s, A[s])
        ret += reward(s2, goal, pits)
        s, steps = s2, steps + 1
    return ret, steps


def bucket(n):
    return 0 if n == 0 else (1 if n <= 3 else 2)


def test_reference_matches_the_games_self_tests():
    V1 = sweep([0] * 25, GOAL, PITS)
    assert V1[22] == 9 and V1[START] == -1                       # CHECK one sweep: beside the goal, start pad
    assert 4 * sum(1 for s in range(25) if not terminal(s, GOAL, PITS)) == 88   # CHECK look-aheads per sweep
    V, k, tabs, last = value_iteration(GOAL, PITS)
    assert k == 8 and V[START] == 5                               # CHECK sweeps, start pad's settled number
    assert last[START] == 5 and max(last) == 7
    A = arrows(V, GOAL, PITS)
    assert walk(A, GOAL, PITS) == (5, 5)                          # CHECK walking the lines earns the start number
    pits2 = (PITS[0], AUTO_PIT)
    V2, k2, _, _ = value_iteration(GOAL, pits2)
    assert wrong_lines(A, V2, GOAL, pits2) == 5                   # CHECK old lines made wrong by the pit at pad 7
    assert k2 == 8


def test_reference_teaching_claims():
    V, k, tabs, last = value_iteration(GOAL, PITS)
    # News travels one pad per sweep: a pad's number settles on the sweep equal to its distance, at 10 - distance.
    for s in range(25):
        if not terminal(s, GOAL, PITS):
            assert V[s] == 10 - last[s]
    # Question 3: after two sweeps a -2 pad ringed by -2 pads exists (any plan would score it -3), and no pad shows -1.
    V2 = tabs[1][0]
    assert -1 not in V2
    ringed = [s for s in range(25) if not terminal(s, GOAL, PITS) and V2[s] == -2
              and all(V2[nxt(s, a)] == -2 for a in range(4))]
    assert ringed
    # Every move of the pit the game accepts leaves every pad a way to the goal, as the game checks.
    for p in range(25):
        if p in (START, GOAL) or p in PITS:
            continue
        Vp = value_iteration(GOAL, (PITS[0], p))[0]
        assert all(Vp[s] > 0 for s in range(25) if not terminal(s, GOAL, (PITS[0], p)))


def _close(got, want):
    return got is None or abs(got - want) <= TOL


def _rows(log, run):
    """{sweep: board} from the row lines of one run."""
    boards = {}
    for v in games.events(log, "row"):
        if v[0] != run or None in v[1:3]:
            continue
        boards.setdefault(v[1], [None] * 25)[v[2] * 5: v[2] * 5 + 5] = v[3:8]
    return boards


def _arrows(log, run):
    A = [None] * 25
    for v in games.events(log, "arrows"):
        if v[0] == run and v[1] is not None:
            A[v[1] * 5: v[1] * 5 + 5] = v[2:7]
    return A


def _check_run(log, run, goal, pits):
    V, k, tabs, _ = value_iteration(goal, pits)
    sweeps = [v for v in games.events(log, "sweep") if v[0] == run]
    assert [v[1] for v in sweeps] == list(range(1, k + 1)), f"run {run}: sweeps logged {[v[1] for v in sweeps]}"
    for v in sweeps:
        W, nchg, mx = tabs[v[1] - 1]
        assert _close(v[2], nchg) and _close(v[3], mx) and _close(v[4], W[START]), f"run {run} sweep {v[1]}: {v}"
    boards = _rows(log, run)
    for s, board in boards.items():
        want = tabs[s - 1][0]
        assert all(_close(g, w) for g, w in zip(board, want)), f"run {run} sweep {s}: {board} vs {want}"
    return V, k


@pytest.mark.skipif(LOG is None, reason="no saved log of game 3 in data/logs/games")
def test_whiteboard_log():
    log = games.parse(LOG)
    assert games.problems(log, 3) == []
    assert len(log["A"]) == 6
    m = games.events(log, "map")[0]
    start, goal, pits = m[0], m[1], (m[2], m[3])
    assert (start, goal, pits) == (START, GOAL, PITS)

    # The answer key the game worked out before the round.
    V, k, tabs, last = value_iteration(goal, pits)
    A = arrows(V, goal, pits)
    pre = games.events(log, "pre")[0]
    assert [x for x in pre] == [k, last[START], max(last), V[START], walk(A, goal, pits)[0]], pre

    # The first plan, sweep by sweep, and its lines.
    _check_run(log, 1, goal, pits)
    assert _arrows(log, 1) == A
    looks = games.events(log, "looks")[0]
    assert looks[0] == k and looks[2] == k * looks[1] * 4

    # The walk: what he scored follows from the pads he entered and how the walk ended.
    w = games.events(log, "walk")[0]
    steps, ret, vstart, end = w[0], w[1], w[2], w[3]
    assert _close(vstart, V[START])
    assert _close(ret, -steps + (10 if end == 1 else 0) - (10 if end == 2 else 0))
    if log["M"][0]["autoplay"] == 1:
        assert (steps, ret, end) == (last[START], V[START], 1)

    # The pit moves; the old lines it makes wrong, and the answer key of question 6.
    p = games.events(log, "pit")[0]
    pits2 = (pits[0], p[1])
    assert p[0] == pits[1]
    V2, k2, _, _ = value_iteration(goal, pits2)
    assert p[2] == wrong_lines(A, V2, goal, pits2)
    q6 = [a for a in log["A"] if a["qid"] == 6][0]
    assert q6["correct"] == bucket(p[2])

    # The second plan, and its lines (old lines kept where still best).
    _check_run(log, 2, goal, pits2)
    assert _arrows(log, 2) == arrows(V2, goal, pits2, old=A)
    rp = games.events(log, "replan")[0]
    assert rp[0] == k2 and rp[1] == p[2]
