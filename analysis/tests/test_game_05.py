"""Game 5, Slippery Boots: lane values beside a drop, with and without the one-in-ten random move (lecture 5)."""
import random

import numpy as np
import pytest

from rllab import games

LOG = games.newest(5)

NR, NC, GOAL, EPS = 4, 12, 11, 0.1
DR = [0, 0, 1, -1]   # moves: 0 forward, 1 back, 2 inland, 3 toward the drop
DC = [1, -1, 0, 0]


def policy(cell, lane):
    """The lane walker's own move (lane 0 edge, 1 inland, 2 two pads inland, used only to check inland is the best)."""
    r, c = divmod(cell, NC)
    row = {0: 0, 1: 1, 2: 2}[lane]
    if lane == 0:
        return 3 if r > 0 else 0
    if c == NC - 1:
        return 3
    return 2 if r < row else (3 if r > row else 0)


def move(cell, d):
    """Where move d takes you from cell: -1 is over the drop; off the other sides of the grid you stay put."""
    r, c = divmod(cell, NC)
    r2, c2 = r + DR[d], c + DC[d]
    if r2 < 0:
        return -1
    if c2 < 0 or c2 > NC - 1 or r2 > NR - 1:
        return cell
    return r2 * NC + c2


def probs(cell, lane, eps):
    p0 = policy(cell, lane)
    return [(1 - eps + eps / 4) if d == p0 else eps / 4 for d in range(4)]


def evaluate(lane, eps, step=-1.0, goal=50.0, fall=-100.0, tol=0.0005):
    """The game's own routine: Gauss-Seidel policy evaluation, cells in descending order, stop when no value moves 0.0005."""
    v = [0.0] * (NR * NC)
    sweeps = 0
    for _ in range(200):
        sweeps += 1
        delta = 0.0
        for k in range(NR * NC - 1, -1, -1):
            if k == GOAL:
                continue
            s = 0.0
            for d, p in enumerate(probs(k, lane, eps)):
                if p <= 0:
                    continue
                k2 = move(k, d)
                s += p * (step + (fall if k2 < 0 else (goal if k2 == GOAL else v[k2])))
            delta = max(delta, abs(s - v[k]))
            v[k] = s
        if delta < tol:
            break
    return v[0], sweeps


def exact(lane, eps, step=-1.0, goal=50.0, fall=-100.0):
    """The same values by solving the linear Bellman equations directly."""
    n = NR * NC
    a, b = np.eye(n), np.zeros(n)
    for k in range(n):
        if k == GOAL:
            continue
        for d, p in enumerate(probs(k, lane, eps)):
            k2 = move(k, d)
            b[k] += p * step
            if k2 < 0:
                b[k] += p * fall
            elif k2 == GOAL:
                b[k] += p * goal
            else:
                a[k, k2] -= p
    return float(np.linalg.solve(a, b)[0])


def simulate(lane, eps, n, seed):
    rng = random.Random(seed)
    total = 0.0
    for _ in range(n):
        cell, g = 0, 0.0
        while True:
            d = rng.randrange(4) if rng.random() < eps else policy(cell, lane)
            cell = move(cell, d)
            g -= 1
            if cell < 0:
                g -= 100
                break
            if cell == GOAL:
                g += 50
                break
        total += g
    return total / n


def step_reward(new):
    return -1 + (-100 if new < 0 else (50 if new == GOAL else 0))


def test_lane_values():
    # The values the game's CHECK lines use.
    assert abs(EPS / 4 - 0.025) < 1e-12
    assert abs(1 - (1 - EPS / 4) ** 11 - 0.243) < 0.001
    assert evaluate(0, 0)[0] == 39 and evaluate(1, 0)[0] == 37
    assert abs(evaluate(0, EPS)[0] - 0.41) < 0.005
    assert abs(evaluate(1, EPS)[0] - 30.31) < 0.005
    assert abs(evaluate(0, EPS, 0, 0, 1)[0] - 0.26) < 0.002
    assert abs(evaluate(1, EPS, 0, 0, 1)[0] - 0.034) < 0.001
    # The iteration stops close to the exact answer.
    for lane in (0, 1):
        for eps in (0, EPS):
            assert abs(evaluate(lane, eps)[0] - exact(lane, eps)) < 0.005
            assert abs(evaluate(lane, eps, 0, 0, 1)[0] - exact(lane, eps, 0, 0, 1)) < 0.001
    # The reversal the game reveals, and that inland (one pad in) beats going two pads in.
    assert evaluate(0, 0)[0] > evaluate(1, 0)[0]
    assert evaluate(1, EPS)[0] > evaluate(2, EPS)[0] > evaluate(0, EPS)[0]


def test_simulation_agrees():
    assert abs(simulate(0, EPS, 20000, 5) - exact(0, EPS)) < 2.5
    assert abs(simulate(1, EPS, 20000, 6) - exact(1, EPS)) < 1.5


def test_moves():
    assert move(0, 3) == -1 and move(0, 1) == 0 and move(0, 2) == NC and move(NC + 11, 0) == NC + 11
    assert step_reward(GOAL) == 49 and step_reward(-1) == -101 and step_reward(5) == -1


@pytest.mark.skipif(LOG is None, reason="no saved log of game 5 in data/logs/games")
def test_slippery_boots_log():
    log = games.parse(LOG)
    assert games.problems(log, 5) == []
    assert len(log["A"]) >= 5
    model = {(v[0], v[1]): v[2] for v in games.events(log, "model")}
    for lane in (0, 1):
        for boop in (0, 1):
            assert abs(model[(lane, boop)] - evaluate(lane, EPS if boop else 0)[0]) < 0.02
    fall = {v[0]: v[1] for v in games.events(log, "fall")}
    for lane in (0, 1):
        assert abs(fall[lane] - evaluate(lane, EPS, 0, 0, 1)[0]) < 0.02

    steps = games.events(log, "step")
    selffalls = games.events(log, "selffall")
    crosses = games.events(log, "cross")
    lanes = games.events(log, "lane")
    assert [c[0] for c in crosses] == [1, 2, 3, 4]
    assert [x[0] for x in lanes] == [1, 2, 3, 4]
    assert [x[1] for x in lanes] == [0, 0, 1, 1]  # the stand-in's fixed lane choices
    for x in steps:
        crossing, k, prev, seen, roll, mv, new, reward, boop_on = x
        if boop_on == 1 and roll == 1:
            assert new == move(prev, mv), x
        else:
            assert new == seen, x
        assert abs(reward - step_reward(new)) < 0.02, x
    for c in crosses:
        crossing, lane, boop_on, n_steps, n_boops, outcome, ret = c[:7]
        mine = [x for x in steps if x[0] == crossing]
        assert len(mine) == n_steps
        assert [x[1] for x in mine] == list(range(1, n_steps + 1))
        assert n_boops == sum(1 for x in mine if x[8] == 1 and x[4] == 1)
        total = sum(x[7] for x in mine) - 100 * sum(1 for s in selffalls if s[0] == crossing)
        assert abs(ret - total) < 0.02
        assert lane == [x[1] for x in lanes if x[0] == crossing][0]
        assert boop_on == (0 if crossing == 1 else 1)
        if outcome == 1:
            assert mine[-1][6] == GOAL
        elif outcome == 2:
            assert mine and mine[-1][6] == -1 or any(s[0] == crossing for s in selffalls)
        # Each walk starts on the start pad and every step leaves the pad the last one ended on.
        if mine:
            assert mine[0][2] == 0
            for a, b in zip(mine, mine[1:]):
                assert b[2] == a[6]
