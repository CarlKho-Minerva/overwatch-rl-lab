"""Game 9, Loot Boxes (lecture 9, exploration and exploitation): the reference maths and the log check.

Four boxes with hidden chances 0.2, 0.4, 0.55 and 0.7 (shuffled per game), 30 opens. Every box has a fixed stack of
30 results drawn at the start; whoever opens a box for the k-th time gets its k-th result. Three strategies play the
same stacks in step with the player: greedy, greedy with one random open in ten (the coin), and UCB1 (the optimist).
"""
import math

import numpy as np
import pytest

from rllab import games

LOG = games.newest(9)
ODDS = [0.2, 0.4, 0.55, 0.7]
PMAX = 0.7
TOL = 0.02


# ---------------------------------------------------------------------------
# Reference maths, the same values the game's CHECK lines use
# ---------------------------------------------------------------------------
def game_ln(x):
    """The game has no natural log: ln x = 1024 (u - u^2/2 + u^3/3), u = x^(1/1024) - 1."""
    u = max(x, 1) ** (1 / 1024) - 1
    return 1024 * (u - u * u / 2 + u * u * u / 3)


def at_least_3_of_4(p):
    return 4 * p ** 3 * (1 - p) + p ** 4


def greedy_lockout(odds=ODDS):
    """Greedy opens each box once, then always the best average. If the best box loses its first open while another
    box wins its first, the best box's average stays 0 below a positive one, and it is never opened again."""
    best = max(odds)
    others_all_lose = math.prod(1 - p for p in odds if p != best)
    return (1 - best) * (1 - others_all_lose)


def best_case(paid, opened, t):
    """UCB1: average plus sqrt(2 ln t / n), with t the opens made so far in all."""
    return paid / opened + math.sqrt(2 * game_ln(t) / opened)


def coin_floor_per_100(odds=ODDS, eps=0.1):
    """Even with perfect averages, the coin opens a random box 1 time in 10: this much regret per 100 opens."""
    return 100 * eps * sum(max(odds) - p for p in odds) / len(odds)


def regret(counts, odds):
    return sum(n * (max(odds) - p) for n, p in zip(counts, odds))


def test_reference_values():
    assert abs(game_ln(8) - math.log(8)) < 1e-4 and abs(game_ln(300) - math.log(300)) < 1e-4
    assert abs(game_ln(8) - 2.079) < 0.011 and abs(game_ln(300) - 5.704) < 0.011
    assert abs(at_least_3_of_4(0.4) - 0.179) < 0.001 and abs(at_least_3_of_4(0.55) - 0.391) < 0.001
    assert round(100 * at_least_3_of_4(0.4)) == 18 and round(100 * at_least_3_of_4(0.55)) == 39
    assert abs(greedy_lockout() - 0.2352) < 1e-9 and math.floor(100 * greedy_lockout()) == 23
    assert abs(best_case(0, 1, 8) - 2.039) < 0.011 and abs(best_case(4, 6, 8) - 1.499) < 0.011
    assert abs(coin_floor_per_100() - 2.375) < 1e-9 and round(10 * coin_floor_per_100()) / 10 == 2.4
    assert abs(regret([1, 2, 3, 4], ODDS) - 1.55) < 1e-9


def simulate(strategy, opens, games_n, seed):
    """Average regret curve of a strategy on the four boxes (vectorised over games)."""
    rng = np.random.default_rng(seed)
    p = np.array(ODDS)
    n = np.zeros((games_n, 4))
    s = np.zeros((games_n, 4))
    reg = np.zeros(opens)
    rows = np.arange(games_n)
    total = 0.0
    for t in range(opens):
        if t < 4:
            a = np.full(games_n, t)
        else:
            score = s / n + (np.sqrt(2 * math.log(t) / n) if strategy == "optimist" else 0)
            a = score.argmax(axis=1)
            if strategy == "coin":
                x = rng.integers(0, 40, games_n)
                a = np.where(x < 4, x, a)
        n[rows, a] += 1
        s[rows, a] += rng.random(games_n) < p[a]
        total += (PMAX - p[a]).mean()
        reg[t] = total
    return reg


def test_the_story_holds_in_expectation():
    """What the screen says: the coin's bill per 100 opens never falls under 2.4, the optimist's shrinks, greedy's
    stays high; at 300 opens the coin is still ahead of the optimist, which passes it only after thousands."""
    curves = {k: simulate(k, 300, 2000, 1) for k in ("greedy", "coin", "optimist")}
    win = {k: (c[99], c[199] - c[99], c[299] - c[199]) for k, c in curves.items()}
    assert win["optimist"][2] < 0.7 * win["optimist"][0]
    assert win["coin"][2] > coin_floor_per_100()
    assert win["greedy"][2] > win["coin"][2] and win["greedy"][2] > 0.75 * win["greedy"][1]
    assert curves["coin"][299] < curves["optimist"][299]
    long_coin, long_opt = simulate("coin", 8000, 200, 2), simulate("optimist", 8000, 200, 3)
    assert long_coin[999] < long_opt[999] and long_opt[7999] < long_coin[7999]


# ---------------------------------------------------------------------------
# The log check
# ---------------------------------------------------------------------------
def argmax_ok(scores, chosen):
    return scores[chosen] >= max(scores) - 0.002


@pytest.mark.skipif(LOG is None, reason="no saved log of game 9 in data/logs/games")
def test_loot_boxes_log():
    log = games.parse(LOG)
    assert games.problems(log, 9) == []
    assert len(log["A"]) == 5

    odds = games.events(log, "odds")[0]
    assert sorted(odds) == ODDS
    table = [[None] * 30 for _ in range(4)]
    for v in games.events(log, "draws"):
        b, h, vals = v[0], v[1], v[2:]
        table[b][15 * h: 15 * h + 15] = vals
    assert all(x in (0, 1) for row in table for x in row)
    coin = [None] * 30
    for v in games.events(log, "coin"):
        coin[15 * v[0]: 15 * v[0] + 15] = v[1:]
    assert all(0 <= x <= 39 for x in coin)

    # The player's opens: each pays its box's next result; totals and regret add up
    opens = games.events(log, "open")
    ubs = {v[0]: v[1:] for v in games.events(log, "ub")}
    assert [v[0] for v in opens] == list(range(1, 31))
    n, s, tot, reg = [0] * 4, [0] * 4, 0, 0.0
    for t, box, k, pay, g_tot, g_reg in opens:
        assert k == n[box] and pay == table[box][k]
        n[box] += 1
        s[box] += pay
        tot += pay
        reg += PMAX - odds[box]
        assert g_tot == tot and abs(g_reg - reg) < TOL
        for i in range(4):
            want = 9 if n[i] == 0 else best_case(s[i], n[i], t)
            assert abs(ubs[t][i] - want) < TOL, (t, i, ubs[t][i], want)

    # The strategies: each logged choice is the strategy's own rule, and pays the same stacked result
    steps = games.events(log, "step")
    assert [v[0] for v in steps] == list(range(1, 31))
    sn = [[0] * 4 for _ in range(3)]
    ss = [[0] * 4 for _ in range(3)]
    stot, sreg = [0] * 3, [0.0] * 3
    for t, x, *picks in steps:
        assert x == coin[t - 1]
        for k in range(3):
            a, pay = picks[2 * k], picks[2 * k + 1]
            if t - 1 < 4:
                assert a == t - 1
            elif k == 1 and x < 4:
                assert a == x
            else:
                bonus = (lambda m: math.sqrt(2 * game_ln(t - 1) / m)) if k == 2 else (lambda m: 0)
                scores = [ss[k][i] / sn[k][i] + bonus(sn[k][i]) for i in range(4)]
                assert argmax_ok(scores, a), (t, k, scores, a)
            assert pay == table[a][sn[k][a]]
            sn[k][a] += 1
            ss[k][a] += pay
            stot[k] += pay
            sreg[k] += PMAX - odds[a]
        if t in (8, 16, 24, 30):
            r = [v for v in games.events(log, "round") if v[1] == t][0]
            assert r[2] == sum(o[3] for o in opens[:t])
            assert abs(r[3] - sum(PMAX - odds[o[1]] for o in opens[:t])) < TOL
            for k in range(3):
                assert r[4 + 2 * k] == stot[k] and abs(r[5 + 2 * k] - sreg[k]) < TOL

    end = games.events(log, "end")[0]
    assert end[0] == tot and abs(end[1] - reg) < TOL
    for k in range(3):
        assert end[2 + 2 * k] == stot[k] and abs(end[3 + 2 * k] - sreg[k]) < TOL
    assert end[8] == log["X"][-1]["right"]

    # The replays: 20 games of 300 opens per strategy; regret from the logged counts
    rep = games.events(log, "replay")
    assert len(rep) == 9
    for k, c, *rest in rep:
        counts, avg = rest[:4], rest[4]
        assert sum(counts) == 20 * 100 * (c + 1)
        assert abs(avg - regret(counts, odds) / 20) < TOL
        # every strategy opens each box once per game before anything else
        assert min(counts) >= 20
