"""Game 10, The Peek: a 2x2 zero-sum matrix game (Tracer peeks LEFT or RIGHT, the Widowmaker holds LEFT or RIGHT).

Reference maths for every number the game computes, and a check of the game's own log against it.
"""
from fractions import Fraction as F

import pytest

from rllab import games

GAME = 10
LOG = games.newest(GAME)

# His points for (pick, aim), 1 = left and 0 = right. Hers are the negative (zero-sum).
PAY = {(0, 0): -1, (0, 1): 1, (1, 0): 3, (1, 1): -2}


def solve():
    """Value and safe mixes of a 2x2 zero-sum game with no saddle point (the equalising formulas)."""
    a, b, c, d = PAY[1, 1], PAY[1, 0], PAY[0, 1], PAY[0, 0]
    den = a + d - b - c
    return F(a * d - b * c, den), F(d - c, den), F(d - b, den)


def her_odds(nL, nN, aL, aA):
    """Her best answer to his counts (aim left when he peeks left more than 2 in 7), and her odds of aiming left:
    half her best answer, half her own past share of left aims."""
    br = 1 if 7 * nL > 2 * nN else 0
    return br, F(br * aA + aL, 2 * aA)


def expected(pick, q):
    return q * PAY[pick, 1] + (1 - q) * PAY[pick, 0]


def self_play(T=300, every=20):
    """Fictitious play: each side answers the other's counts so far. Integer tests, so the result is exact."""
    nL, N, mL, M = 1, 2, 1, 2
    last, flips, pay, snaps = -1, 0, 0, []
    for t in range(1, T + 1):
        tr = 1 if 7 * mL < 4 * M else 0
        wi = 1 if 7 * nL > 2 * N else 0
        if last >= 0 and tr != last:
            flips += 1
        last = tr
        pay += PAY[tr, wi]
        nL, N, mL, M = nL + tr, N + 1, mL + wi, M + 1
        if t % every == 0:
            snaps.append([t, nL, N, mL, M, tr, wi])
    return nL, N, mL, M, flips, pay, snaps


def test_reference_values():
    v, p, q = solve()
    assert (v, p, q) == (F(1, 7), F(2, 7), F(4, 7))
    # The game's CHECK lines.
    assert abs(float(v) - 0.143) < 0.011 and abs(float(p) - 0.286) < 0.011 and abs(float(q) - 0.571) < 0.011
    # The safe mix pays the same whatever she does, and her mix holds him to the same: the minimax value.
    assert p * PAY[1, 1] + (1 - p) * PAY[0, 1] == v == p * PAY[1, 0] + (1 - p) * PAY[0, 0]
    assert q * PAY[1, 1] + (1 - q) * PAY[1, 0] == v == q * PAY[0, 1] + (1 - q) * PAY[0, 0]
    # The mix leans away from the better corner.
    assert p < F(1, 2)
    # Always left gets punished by always-left aiming; her best answer to always-left is to aim left.
    assert PAY[1, 1] < PAY[1, 0] and -PAY[1, 1] > -PAY[1, 0]
    assert her_odds(4, 4, 1, 2) == (1, F(3, 4))
    assert her_odds(1, 7, 1, 2) == (0, F(1, 4))
    assert her_odds(2, 7, 1, 2)[0] == 0  # exactly 2 in 7: she stays on right
    assert expected(0, v) == 2 * v - 1


def test_self_play_reference():
    nL, N, mL, M, flips, pay, snaps = self_play()
    assert (nL, N, mL, M, flips, pay) == (86, 302, 166, 302, 12, 55)
    assert abs(nL / N - 0.285) < 0.011 and abs(mL / M - 0.55) < 0.011
    assert len(snaps) == 15 and snaps[-1] == [300, 86, 302, 166, 302, 1, 0]


@pytest.mark.skipif(LOG is None, reason="no saved log of game 10 in data/logs/games")
def test_peek_log():
    log = games.parse(LOG)
    assert games.problems(log, GAME) == []
    assert len(log["A"]) == 6
    setup = games.events(log, "setup")[0]
    v, p, q = solve()
    assert setup[:4] == [PAY[1, 1], PAY[1, 0], PAY[0, 1], PAY[0, 0]]
    assert abs(setup[4] - float(v)) < 0.02 and abs(setup[5] - float(p)) < 0.02 and abs(setup[6] - float(q)) < 0.02

    peeks = games.events(log, "peek")
    assert [e[0] for e in peeks] == list(range(1, 15))
    assert [e[1] for e in peeks] == [1] * 4 + [2] * 5 + [3] * 5
    nL, nN, aL, aA, score, ev_sum, followed = 0, 0, 1, 2, 0, F(0), 0
    phase_pay = {1: 0, 2: 0, 3: 0}
    for n, phase, pick, lnL, lnN, lbr, laL, laA, lq, u, aim, pay, lev, die, says, tmo in peeks:
        assert (lnL, lnN, laL, laA) == (nL, nN, aL, aA), f"peek {n}: counts"
        if phase == 1:
            br, qq = 0, F(0)
            assert aim == 0 and u == -1
        else:
            br, qq = her_odds(nL, nN, aL, aA)
            assert 0 <= u <= 99
            assert aim == (1 if u * 2 * aA < 100 * (br * aA + aL) else 0), f"peek {n}: her draw"
        assert lbr == br and abs(lq - float(qq)) < 0.02, f"peek {n}: her odds"
        assert pay == PAY[pick, aim]
        assert abs(lev - float(expected(pick, qq))) < 0.02, f"peek {n}: expected points"
        if phase == 3:
            assert 0 <= die <= 6 and says == (1 if die < 2 else 0)
            followed += pick == says
        else:
            assert die == -1 and says == -1
        score += pay
        ev_sum += expected(pick, qq)
        phase_pay[phase] += pay
        nL, nN = nL + pick, nN + 1
        if phase >= 2:
            aL, aA = aL + aim, aA + 1
    for ph, ppay, npk in games.events(log, "phase"):
        assert ppay == phase_pay[ph] and npk == (4 if ph == 1 else 5)
    end = games.events(log, "end")[0]
    assert end[0] == score and abs(end[1] - float(ev_sum)) < 0.02 and end[2:] == [followed, nL, nN]
    if log["M"][0]["autoplay"] == 1:
        # The stand-in peeks left 4 times, then 1 0 0 1 0, then follows the die.
        assert [e[2] for e in peeks[:9]] == [1, 1, 1, 1, 1, 0, 0, 1, 0]
        assert all(e[2] == e[14] for e in peeks[9:])

    _, _, _, _, flips, sp_pay, snaps = self_play()
    logged = games.events(log, "sp")
    assert len(logged) == len(snaps)
    for got, want in zip(logged, snaps):
        # A field the game's text filter starred out reads as None; every other field must match exactly.
        assert all(g is None or g == w for g, w in zip(got, want)), f"self-play snapshot {want[0]}"
    spend = games.events(log, "spend")[0]
    assert spend[:2] == [flips, sp_pay]
    assert abs(spend[2] - 86 / 302) < 0.02 and abs(spend[3] - 166 / 302) < 0.02
