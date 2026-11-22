"""Game 2, Mini or Mega: discounted pack values and the one-step (Bellman) rule along a row of pads."""
import pytest

from rllab import games

LOG = games.newest(2)

MINI_R, MEGA_R = 15, 50          # what each pack is worth
MINI_D, MEGA_D = 3, 10           # pads from the start
START_I, MEGA_I = 3, 13          # pad 0 holds the mini, pad 13 the mega
G2, STEP = 0.9, -1               # part 2: discount and step cost
TOL = 0.02                       # the game prints two decimals


def discounted(worth, gamma, steps):
    """A pack `steps` pads away, seen from the start: its worth shrunk by gamma once per pad."""
    return worth * gamma ** steps


def best_pack(gamma):
    """1 when the mega is worth more under this discount, 0 when the mini is."""
    return 1 if discounted(MEGA_R, gamma, MEGA_D) > discounted(MINI_R, gamma, MINI_D) else 0


def row_to_mega(gamma=G2, cost=STEP):
    """Pad values under 'always walk to the mega', by the one-step rule from the mega backward (pads 1 to 13)."""
    v = [None] * 14
    v[MEGA_I] = MEGA_R
    for i in range(MEGA_I - 1, 0, -1):
        v[i] = cost + gamma * v[i + 1]
    return v


def row_to_mini(gamma=G2, cost=STEP):
    """Pad values under 'always walk to the mini' (pads 0 to 12)."""
    v = [None] * 14
    v[0] = MINI_R
    for i in range(1, MEGA_I):
        v[i] = cost + gamma * v[i - 1]
    return v


def closed_form(worth, steps, gamma=G2, cost=STEP):
    """The same value without the loop: worth x gamma^d plus the discounted sum of d step costs."""
    return worth * gamma ** steps + cost * (1 - gamma ** steps) / (1 - gamma)


def test_reference_values():
    # The same numbers the game's CHECK lines use.
    assert abs(discounted(MINI_R, 0.5, MINI_D) - 1.875) < 1e-9
    assert abs(discounted(MEGA_R, 0.8, MEGA_D) - 5.369) < 0.001
    assert abs(discounted(MINI_R, 0.9, MINI_D) - 10.935) < 1e-9
    assert abs(discounted(MEGA_R, 0.9, MEGA_D) - 17.434) < 0.001
    assert abs(0.3 ** (1 / 7) - 0.842) < 0.001
    assert [best_pack(g) for g in (0.5, 0.8, 0.9, 1)] == [0, 0, 1, 1]
    # The switch: 15 g^3 = 50 g^10 at g^7 = 0.3.
    s = 0.3 ** (1 / 7)
    assert abs(discounted(MINI_R, s, MINI_D) - discounted(MEGA_R, s, MEGA_D)) < 1e-9
    m, n = row_to_mega(), row_to_mini()
    assert m[MEGA_I - 1] == 44 and abs(m[MEGA_I - 2] - 38.6) < 1e-9 and abs(m[MEGA_I - 3] - 33.74) < 1e-9
    assert abs(m[START_I] - 10.921) < 0.001
    assert abs(n[START_I] - 8.225) < 1e-9
    assert abs(m[START_I] - (60 * 0.9 ** 10 - 10)) < 1e-9
    for i in range(1, MEGA_I + 1):
        assert abs(m[i] - closed_form(MEGA_R, MEGA_I - i)) < 1e-9
    for i in range(0, MEGA_I):
        assert abs(n[i] - closed_form(MINI_R, i)) < 1e-9
    # A value belongs to a pad and a way of walking: at the start the mega walk is better, one pad back the mini.
    assert m[START_I] > n[START_I] and n[START_I - 1] > m[START_I - 1]
    # Question 6's wrong options: forgetting the discount, forgetting the step cost.
    assert abs((38.6 - 1) - 37.6) < 1e-9 and abs(0.9 * 38.6 - 34.74) < 1e-9


@pytest.mark.skipif(LOG is None, reason="no saved log of game 2 in data/logs/games")
def test_mini_or_mega_log():
    log = games.parse(LOG)
    assert games.problems(log, 2) == []
    assert sorted(a["qid"] for a in log["A"]) == [1, 2, 3, 4, 5, 6, 7]
    assert games.events(log, "bot")[0][0] == 1

    dials = games.events(log, "dial")
    assert len(dials) == 4
    assert sorted(round(d[1], 2) for d in dials) == [0.5, 0.8, 0.9, 1.0]
    for rnd, g, v_mini, v_mega, best in dials:
        assert abs(v_mini - discounted(MINI_R, g, MINI_D)) < TOL
        assert abs(v_mega - discounted(MEGA_R, g, MEGA_D)) < TOL
        assert best == best_pack(g)
    # Each dial question's correct answer was the pack the arithmetic picked.
    by_q = {a["qid"]: a for a in log["A"]}
    for rnd, g, v_mini, v_mega, best in dials:
        assert by_q[1 + rnd]["correct"] == best

    walked = games.events(log, "walked")
    assert len(walked) == 4
    for rnd, g, best, arrived in walked:
        assert best == best_pack(g)
        assert arrived is True

    m, n = row_to_mega(), row_to_mini()
    pads = games.events(log, "pad")
    assert len([p for p in pads if p[0] == 0]) == 13 and len([p for p in pads if p[0] == 1]) == 13
    for policy, i, v in pads:
        ref = (m if policy == 0 else n)[i]
        assert abs(v - ref) < TOL, (policy, i, v, ref)

    walk = games.events(log, "walk")
    assert walk, "no pad was checked during the walk"
    for i, v, nxt in walk:
        assert abs(v - m[i]) < TOL
        if i < MEGA_I:
            assert abs(nxt - m[i + 1]) < TOL
            assert abs(v - (STEP + G2 * nxt)) < TOL
    n_walk, n_ok, reached = games.events(log, "walkdone")[0]
    assert n_walk == len(walk)
    assert n_ok == len([w for w in walk if w[0] < MEGA_I])
    if log["M"][0]["autoplay"] == 1:
        assert reached == 1
        assert all(a["right"] == 1 for a in log["A"])
    end = games.events(log, "end")[0]
    assert end[1] == len(log["A"])
