"""Game 11, Sombra's Room: a belief moved by Bayes' rule, and the price of finding out (lesson 11, partial observability).

The reference maths below is the game's arithmetic in plain Python. The log test recomputes every belief, every
entering value and every one-more-ping value from the readings the game logged, and checks them against what the game
printed (two decimals, so within 0.02).
"""
import pytest

from rllab import games

LOG = games.newest(11)

W_EMPTY, L_HERS, PING_COST, ACC, KL, SWEEPS = 10, 30, 1, 0.8, 10, 40
TOL = 0.02


def post(p, r, a):
    """Belief that Sombra is LEFT after a reading r (0 LEFT, 1 RIGHT) from a ping right a of the time."""
    if r == 0:
        return p * a / (p * a + (1 - p) * (1 - a))
    return p * (1 - a) / (p * (1 - a) + (1 - p) * a)


def room_ev(room, p):
    return W_EMPTY * (1 - p) - L_HERS * p if room == 0 else W_EMPTY * p - L_HERS * (1 - p)


def enter_ev(p):
    return max(room_ev(0, p), room_ev(1, p))


def lat_p(n):
    return 1 / (1 + 4 ** (-n))


def solve_plan():
    """Value iteration over the belief ladder, in place, exactly as the game sweeps it. Returns (V, threshold rung)."""
    v = [enter_ev(lat_p(i - KL)) for i in range(2 * KL + 1)]
    for _ in range(SWEEPS):
        for i in range(1, 2 * KL):
            p = lat_p(i - KL)
            pl = p * ACC + (1 - p) * (1 - ACC)
            v[i] = max(enter_ev(p), -PING_COST + pl * v[i + 1] + (1 - pl) * v[i - 1])
    n_star = next(i - KL for i in range(KL, 2 * KL + 1) if enter_ev(lat_p(i - KL)) >= v[i] - 0.0001)
    return v, n_star


V, N_STAR = solve_plan()


def ping_q(p, n, a):
    """What one more ping, then the best plan, is worth at belief p (ladder rung n)."""
    if a > 0.99:
        return -PING_COST + p * enter_ev(1) + (1 - p) * enter_ev(0)
    pl = p * a + (1 - p) * (1 - a)
    return -PING_COST + pl * V[n + KL + 1] + (1 - pl) * V[n + KL - 1]


def test_reference_values():
    # The same values as the game's CHECK lines.
    assert abs(post(0.5, 0, 0.8) - 0.8) < 1e-9
    assert abs(post(post(0.5, 0, 0.8), 0, 0.8) - 0.9412) < 1e-4
    assert abs(post(post(0.5, 0, 0.8), 1, 0.8) - 0.5) < 1e-9
    assert abs(post(0.5, 1, 0.8) - 0.2) < 1e-9
    assert abs(lat_p(2) - 0.9412) < 1e-4 and abs(lat_p(-1) - 0.2) < 1e-9
    assert abs(enter_ev(0.8) - 2) < 1e-9 and abs(enter_ev(0.5) + 10) < 1e-9
    assert post(0.5, 0, 1) == 1
    assert abs(V[KL] - 80 / 17) < 1e-4          # 4.7059: the best plan at 50/50
    assert abs(V[KL + 1] - 97 / 17) < 1e-4      # 5.7059: at 80%, keep pinging
    assert abs(V[KL + 2] - 130 / 17) < 1e-4     # 7.6471: at 94%, enter
    assert N_STAR == 2
    assert abs(ping_q(0.5, 0, 1.0) - 9) < 1e-9
    # At 80% one more ping (then the best plan) beats entering; at 94% it does not.
    assert ping_q(0.8, 1, ACC) > enter_ev(0.8)
    assert ping_q(lat_p(2), 2, ACC) < enter_ev(lat_p(2))
    # Value iteration has converged: one more sweep changes nothing.
    for i in range(1, 2 * KL):
        p = lat_p(i - KL)
        assert abs(max(enter_ev(p), ping_q(p, i - KL, ACC)) - V[i]) < 1e-9


def _close(a, b):
    return a is not None and abs(a - b) <= TOL


@pytest.mark.skipif(LOG is None, reason="no saved log of game 11 in data/logs/games")
def test_game_11_log():
    log = games.parse(LOG)
    assert games.problems(log, 11, min_questions=6, min_selftests=4) == []

    plan = games.events(log, "plan")[0]
    assert plan[0] == N_STAR
    assert _close(plan[1], lat_p(N_STAR))
    assert _close(plan[2], V[KL]) and _close(plan[3], V[KL + 1]) and _close(plan[4], V[KL + 2])
    assert _close(plan[5], 9)

    hides = {h[0]: (h[1], h[2]) for h in games.events(log, "hide")}
    assert sorted(hides) == [1, 2, 3, 4, 5]
    assert all(hides[r][1] == 0.8 for r in (1, 2, 3, 4)) and hides[5][1] == 1

    pings = games.events(log, "ping")
    enters = {e[0]: e for e in games.events(log, "enter")}
    assert sorted(enters) == [1, 2, 3, 4, 5]
    total = 0
    for r in range(1, 6):
        hidden, a = hides[r]
        p, n = 0.5, 0
        mine = [x for x in pings if x[0] == r]
        assert [x[1] for x in mine] == list(range(1, len(mine) + 1))
        for x in mine:
            _, _, reading, p_before, p_after, enter_now, pq = x
            assert reading in (0, 1)
            assert _close(p_before, p)
            assert _close(enter_now, enter_ev(p))
            assert _close(pq, ping_q(p, n, a))
            p = post(p, reading, a)
            n += 1 if reading == 0 else -1
            assert _close(p_after, p)
            if a == 1:
                assert reading == hidden        # a perfect ping never lies
        _, room, her, belief, r_ev, enter_now, pq, reward, n_pings = enters[r]
        assert her == hidden and n_pings == len(mine)
        assert _close(belief, p)
        assert _close(r_ev, room_ev(room, p))
        assert _close(enter_now, enter_ev(p))
        assert _close(pq, ping_q(p, n, a))
        assert reward == (W_EMPTY if room != hidden else -L_HERS)
        total += reward - PING_COST * len(mine)

    # Question 2's right answer depends on whether round 1's first two pings agreed.
    r1 = [x for x in pings if x[0] == 1]
    q2 = [q for q in log["A"] if q["qid"] == 2][0]
    assert q2["correct"] == (2 if r1[0][2] == r1[1][2] else 0)

    gain50, gain94 = games.events(log, "voi")[0]
    assert _close(gain50, V[KL] - enter_ev(0.5))
    assert _close(gain94, V[KL + 2] - ping_q(lat_p(2), 2, ACC))

    n_good, score, right, asked = games.events(log, "score")[0]
    assert score == total
    assert n_good == sum(1 for e in enters.values() if e[1] != e[2])
    assert asked == len(log["A"]) == 6
