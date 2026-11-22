"""Game 4, Back From Spawn: Monte Carlo (BLUE) against TD(0) (ORANGE) predicting the walk from spawn to the point.

Reference maths for every formula the game computes, the same known values its CHECK lines use, a simulation that
backs the answer to question 3, and a replay of a saved log through the reference maths.
"""
import random

import pytest

from rllab import games

LOG = games.newest(4)
ALPHA, PRIOR_LEG, NLEGS = 0.5, 3, 5
TOL = 0.02


def step(old, target, alpha=ALPHA):
    """Both predictors: move the guess a fixed fraction of the way toward the target."""
    return old + alpha * (target - old)


def td_target(leg_time, next_guess):
    """ORANGE (TD(0)): the leg just walked plus its own guess for the ring just reached (0 at the point)."""
    return leg_time + next_guess


def returns(legs):
    """BLUE (Monte Carlo): the real time left from each ring, the sum of this walk's legs from there on."""
    out, g = [0.0] * len(legs), 0.0
    for i in range(len(legs) - 1, -1, -1):
        g += legs[i]
        out[i] = g
    return out


def swing(values):
    """How far a guess moved in total over the walks: the sum of the size of each change."""
    return sum(abs(b - a) for a, b in zip(values, values[1:]))


def prior():
    return [PRIOR_LEG * (NLEGS - i) for i in range(NLEGS)]


def test_reference_values_match_the_game_checks():
    assert PRIOR_LEG * NLEGS == 15
    assert td_target(5, 12) == 17
    assert step(15, 17) == 16
    assert step(15, 21) == 18
    r = returns([5, 1.5, 1.5, 5, 1.5])
    assert r[0] == 14.5 and r[3] == 6.5
    assert swing([15, 18, 16, 17]) == 6


def simulate(seed, clear=1.5, mud=5.0, noise=(-0.3, 0.8)):
    """One game with the game's draw rules and typical leg times. Returns the spawn guess's total movement, BLUE and ORANGE."""
    r = random.Random(seed)
    mc, td = prior(), prior()
    hb, ho = [mc[0]], [td[0]]
    counts = [1, 2, 4, 5]
    r.shuffle(counts)
    for w in range(5):
        if w == 3:
            m = [1 if r.random() < 0.4 else 0 for _ in range(5)]
        else:
            c = counts[w if w < 3 else w - 1]
            picks = [0] + r.sample(range(1, 5), c - 1) if w == 0 else r.sample(range(5), c)
            m = [1 if i in picks else 0 for i in range(5)]
        t = [(mud if x else clear) + r.uniform(*noise) for x in m]
        n = 2 if w == 3 else 5
        for k in range(n):
            td[k] = step(td[k], td_target(t[k], 0 if k == 4 else td[k + 1]))
        if n == 5:
            g = returns(t)
            mc = [step(mc[i], g[i]) for i in range(5)]
        hb.append(mc[0])
        ho.append(td[0])
    return swing(hb), swing(ho)


def test_question_3_answer_holds_for_the_game_draw_rules():
    """BLUE's spawn guess moves more than ORANGE's: checked on 3,000 simulated games with the game's draw rules."""
    wins = sum(1 for s in range(3000) if (lambda b, o: b > o)(*simulate(s)))
    assert wins / 3000 > 0.97


def close(a, b):
    return a is None or b is None or abs(a - b) <= TOL


@pytest.mark.skipif(LOG is None, reason="no saved log of game 4 in data/logs/games")
def test_game_4_log():
    log = games.parse(LOG)
    assert games.problems(log, 4, min_questions=5, min_selftests=7) == []
    assert sorted(a["qid"] for a in log["A"]) == [1, 2, 3, 4, 5]
    setup = games.events(log, "setup")[0]
    assert setup[0] == ALPHA and setup[1] == PRIOR_LEG
    counts = games.events(log, "counts")[0]
    assert sorted(counts) == [1, 2, 4, 5]

    walks = games.events(log, "walk")
    legs = games.events(log, "leg")
    tds = games.events(log, "td")
    mcs = games.events(log, "mc")
    assert len(walks) == 5
    assert walks[0][1] == 1, "leg 1 of walk 1 is always mud"
    full = [w for w in walks if w[6] == 5]
    assert [sum(w[1:6]) for w in full] == counts, "mud legs on the full walks follow the logged shuffled list"
    assert [w[6] for w in walks] == [5, 5, 5, 2, 5]

    mc, td = prior(), prior()
    hb, ho = [mc[0]], [td[0]]
    for w in range(5):
        wl = [x for x in legs if x[0] == w]
        assert len(wl) == walks[w][6]
        assert [x[2] for x in wl] == walks[w][1:1 + len(wl)], "each leg's mud matches the walk's draw"
        wt = [x for x in tds if x[0] == w]
        assert len(wt) == len(wl)
        for leg, rec in zip(wl, wt):
            k, t = leg[1], leg[3]
            target = td_target(t, 0 if k == 4 else td[k + 1])
            new = step(td[k], target)
            assert rec[1] == k
            assert close(rec[2], td[k]) and close(rec[3], target) and close(rec[4], new), (w, k, rec, td[k], target, new)
            td[k] = new
        wm = [x for x in mcs if x[0] == w]
        if walks[w][6] == 5:
            g = returns([x[3] for x in wl])
            assert len(wm) == 5
            for rec in wm:
                i = rec[1]
                new = step(mc[i], g[i])
                assert close(rec[2], mc[i]) and close(rec[3], g[i]) and close(rec[4], new), (w, i, rec, mc[i], g[i], new)
                mc[i] = new
        else:
            assert wm == [], "Monte Carlo must not learn from the cut walk"
            assert games.events(log, "cut")[0] == [w, 2]
        hb.append(mc[0])
        ho.append(td[0])

    sw = games.events(log, "swing")[0]
    assert close(sw[0], swing(hb)) and close(sw[1], swing(ho))
    finals = {f[0]: f[1:] for f in games.events(log, "final")}
    assert all(close(a, b) for a, b in zip(finals[0], mc))
    assert all(close(a, b) for a, b in zip(finals[1], td))
