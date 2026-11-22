"""Game 6, Callouts: three maps learn the danger of 12 pads from the same calls (lecture 6, value function approximation).

Each map's number for a pad is the plain average of the calls that fall in the pad's group, 0 when the group has no
call (the least-squares fit for one-hot group features). Its typical miss is the root mean square difference from
the truth over the 12 pads.
"""
from math import sqrt

import pytest

from rllab import games

TRUTH = [2, 1, 2, 1, 8, 9, 7, 8, 1, 9, 2, 1]
EXACT = list(range(12))
THIRDS = [i // 4 for i in range(12)]
ONE_WORD = [0] * 12
BUDGET, EXTRA = 6, 54
LOG = games.newest(6)


def fit(desc, pads, vals):
    """The map's number for every pad, and its typical miss against the truth."""
    s, c = {}, {}
    for p, v in zip(pads, vals):
        s[desc[p]] = s.get(desc[p], 0) + v
        c[desc[p]] = c.get(desc[p], 0) + 1
    est = [s.get(desc[i], 0) / max(1, c.get(desc[i], 0)) for i in range(12)]
    return est, sqrt(sum((e - t) ** 2 for e, t in zip(est, TRUTH)) / 12)


def split(pad):
    d = THIRDS[:]
    d[pad] = 3
    return d


def best(misses):
    """Index of the smallest miss; the first one wins a tie (the game's strict 'less than' comparisons)."""
    b = 0
    for i in (1, 2):
        if misses[i] < misses[b]:
            b = i
    return b


def test_reference_values():
    # The same values as the game's CHECK lines.
    assert fit(EXACT, [0], [5])[0][1] == 0
    assert fit(THIRDS, [0], [5])[0][3] == 5
    assert fit(EXACT, [2, 2], [6, 8])[0][2] == 7
    assert fit(EXACT, range(12), TRUTH)[1] == 0
    est, miss = fit(THIRDS, range(12), TRUTH)
    assert est[9] == 3.25 and abs(miss - 1.995) < 0.001
    assert abs(fit(ONE_WORD, range(12), TRUTH)[1] - 3.394) < 0.001
    assert abs(fit(split(9), range(12), TRUTH)[1] - 0.553) < 0.001
    # Only pad 10 (index 9) takes THIRDS' endless-scouting miss below half: the answer to question 6.
    floor_t = fit(THIRDS, range(12), TRUTH)[1]
    assert [p for p in range(12) if fit(split(p), range(12), TRUTH)[1] < floor_t / 2] == [9]
    # Question 5: of pads 5, 10 and 12, THIRDS stays most wrong on pad 10.
    est_t = fit(THIRDS, range(12), TRUTH)[0]
    assert max(range(3), key=lambda k: abs(est_t[[4, 9, 11][k]] - TRUTH[[4, 9, 11][k]])) == 1


def test_autoplay_plan_noise_free():
    # The stand-in scouts pads 1, 3, 5, 7, 9, 11. Without noise THIRDS wins after 6 calls and EXACT after 60.
    pads6 = [0, 2, 4, 6, 8, 10]
    m6 = [fit(d, pads6, [TRUTH[p] for p in pads6])[1] for d in (EXACT, THIRDS, ONE_WORD)]
    assert best(m6) == 1
    pads60 = pads6 + [k % 12 for k in range(EXTRA)]
    m60 = [fit(d, pads60, [TRUTH[p] for p in pads60])[1] for d in (EXACT, THIRDS, ONE_WORD)]
    assert best(m60) == 0 and m60[0] == 0


@pytest.mark.skipif(LOG is None, reason="no saved log of game 6 in data/logs/games")
def test_callouts_log():
    log = games.parse(LOG)
    assert games.problems(log, 6) == []
    assert games.events(log, "truth")[0] == TRUTH
    see = games.events(log, "see")
    assert len(see) == BUDGET + EXTRA
    pads = [v[1] for v in see]
    vals = [v[3] for v in see]
    for k, (n, p, noise, val) in enumerate(see):
        assert n == k and noise in (-1, 0, 1) and val == TRUTH[p] + noise
    assert pads[BUDGET:] == [k % 12 for k in range(EXTRA)]

    misses = {v[0]: v[1:4] for v in games.events(log, "miss")}
    ests = {(v[0], v[1]): v[2:14] for v in games.events(log, "est")}
    ref = {6: (pads[:BUDGET], vals[:BUDGET]), 60: (pads, vals), 0: (list(range(12)), TRUTH)}
    ref_miss = {}
    for stage, (pp, vv) in ref.items():
        ref_miss[stage] = []
        for m, d in enumerate((EXACT, THIRDS, ONE_WORD)):
            est, miss = fit(d, pp, vv)
            ref_miss[stage].append(miss)
            assert abs(misses[stage][m] - miss) < 0.02, (stage, m)
            assert all(abs(a - b) < 0.02 for a, b in zip(ests[(stage, m)], est)), (stage, m)

    answers = {a["qid"]: a for a in log["A"]}
    assert sorted(answers) == [1, 2, 3, 4, 5, 6]
    for qid, stage in ((1, 6), (2, 60)):
        m = sorted(ref_miss[stage])
        if m[1] - m[0] > 0.01:      # skip a near tie, where two decimals cannot settle it
            assert answers[qid]["correct"] == best(ref_miss[stage])
    e60, t60 = ref_miss[60][0], ref_miss[60][1]
    assert answers[3]["correct"] == (0 if e60 < 0.005 else (1 if e60 < t60 else 2))
    assert answers[4]["correct"] == 1 and answers[5]["correct"] == 1

    pick = games.events(log, "pick")[0]
    p = pick[0]
    d = split(p)
    for got, (pp, vv) in zip(pick[1:4], ((pads[:BUDGET], vals[:BUDGET]), (pads, vals), (list(range(12)), TRUTH))):
        assert abs(got - fit(d, pp, vv)[1]) < 0.02
    assert all(abs(a - b) < 0.02 for a, b in zip(ests[(0, 3)], fit(d, range(12), TRUTH)[0]))
    assert answers[6]["correct"] == (1 if fit(d, range(12), TRUTH)[1] < ref_miss[0][1] / 2 else 0)
    if log["M"][0]["autoplay"] == 1:
        assert pads[:BUDGET] == [0, 2, 4, 6, 8, 10] and p == 9
        assert all(a["right"] == 1 for a in log["A"])
