"""Game 7, Counter-Pick: a softmax bot learns to counter-pick the player by REINFORCE with a baseline.

Reference maths for every formula the game computes, on the same values its CHECK lines use, then a replay of the
logged rounds: from the logged picks and draws alone, the odds, the bot's pick, the reward, the preferences, the
baseline, the player's mix and both exploitability numbers must come out as the game logged them.
"""
import math

import pytest

from rllab import games

LOG = games.newest(7)
ALPHA_SMALL, ALPHA_BIG, BETA = 0.6, 2.5, 0.25
TOL = 0.02


def softmax(h):
    m = max(h)
    e = [math.exp(x - m) for x in h]
    s = sum(e)
    return [x / s for x in e]


def reward(b, y):
    """The bot's reward for pick b against the player's pick y. 0 Tracer beats 1 Widowmaker beats 2 Pharah beats 0."""
    return 1 if y == (b + 1) % 3 else (-1 if b == (y + 1) % 3 else 0)


def draw_pick(k, p):
    u = (k + 0.5) / 1000
    return 0 if u < p[0] else (1 if u < p[0] + p[1] else 2), u


def learn(h, base, pick, r, alpha):
    """REINFORCE with a baseline on a softmax over three preferences; then the baseline moves a quarter of the way."""
    p = softmax(h)
    adv = r - base
    h = [h[j] + alpha * adv * ((1 if j == pick else 0) - p[j]) for j in range(3)]
    return h, base + BETA * (r - base)


def exploit(f):
    """Wins minus losses per round for a perfect counter-picker against the mix f."""
    return max(f[1] - f[2], f[2] - f[0], f[0] - f[1])


def test_reference_maths():
    assert abs(softmax([0, 0, 0])[0] - 0.333) < 0.001
    assert abs(softmax([1, 0, 0])[0] - 0.576) < 0.001
    h, base = learn([0, 0, 0], 0, 2, 1, ALPHA_SMALL)
    assert abs(h[2] - 0.4) < 1e-9 and abs(h[0] + 0.2) < 1e-9 and abs(base - 0.25) < 1e-9
    assert reward(2, 0) == 1 and reward(1, 0) == -1 and reward(1, 1) == 0
    assert reward(0, 1) == 1 and reward(1, 2) == 1
    assert exploit([1, 0, 0]) == 1
    assert abs(exploit([1 / 3, 1 / 3, 1 / 3])) < 1e-9
    assert exploit([0.5, 0.5, 0]) == 0.5
    assert abs(0.9 + 0.1 / 3 - 0.933) < 0.001
    # Exploitability is never negative: the three answers sum to zero.
    for f in ([0.2, 0.3, 0.5], [0.6, 0.1, 0.3], [0, 0, 1]):
        assert exploit(f) >= 0


def test_reference_story():
    """The game's claims hold in the reference: one hero repeated raises its counter; a big step swings harder."""
    import random
    rng = random.Random(7)
    ends = []
    for _ in range(400):
        h, base = [0, 0, 0], 0
        for _ in range(6):
            b, _u = draw_pick(rng.randint(0, 999), softmax(h))
            h, base = learn(h, base, b, reward(b, 0), ALPHA_SMALL)
        ends.append(softmax(h)[2])
    ends.sort()
    assert ends[len(ends) // 2] > 0.6          # Pharah (beats Tracer) climbs from a third
    # One win from even odds: the small step lifts the pick to 48%, the big one to 86%.
    assert abs(softmax(learn([0, 0, 0], 0, 0, 1, ALPHA_SMALL)[0])[0] - 0.477) < 0.001
    assert softmax(learn([0, 0, 0], 0, 0, 1, ALPHA_BIG)[0])[0] > 0.84


def close(a, b):
    return a is None or b is None or abs(a - b) <= TOL


@pytest.mark.skipif(LOG is None, reason="no saved log of game 7 in data/logs/games")
def test_counter_pick_log():
    log = games.parse(LOG)
    assert games.problems(log, 7, min_questions=5, min_selftests=4) == []
    picks = games.events(log, "pick")
    odds = {e[0]: e for e in games.events(log, "odds")}
    prefs = {e[0]: e for e in games.events(log, "pref")}
    mixes = {e[0]: e for e in games.events(log, "mix")}
    resets = [e[0] for e in games.events(log, "reset")]
    assert len(picks) == 15 and len(resets) == 1 and len(mixes) == 9
    h, base, cnt, n = [0, 0, 0], 0.0, [0, 0, 0], 0
    for rnd, phase, you, k, bot, r in picks:
        if rnd - 1 in resets:
            h, base = [0, 0, 0], 0.0
        p = softmax(h)
        o = odds[rnd]
        assert all(close(o[1 + j], p[j]) for j in range(3)), (rnd, o, p)
        alpha = ALPHA_BIG if phase == 2 else ALPHA_SMALL
        assert close(o[4], alpha) and close(o[5], base)
        if k is not None:
            mine, u = draw_pick(k, p)
            edge = min(abs(u - p[0]), abs(u - p[0] - p[1]))
            assert mine == bot or edge < 0.005, (rnd, k, p, bot)
        assert r == reward(bot, you)
        h, base = learn(h, base, bot, r, alpha)
        pr = prefs[rnd]
        assert all(close(pr[1 + j], h[j]) for j in range(3)) and close(pr[4], base), (rnd, pr, h, base)
        if phase == 0:
            assert you == picks[0][2]       # phase A: the same hero every round
        else:
            cnt[you] += 1
            n += 1
            f = [c / n for c in cnt]
            m = mixes[rnd]
            assert all(close(m[1 + j], f[j]) for j in range(3))
            assert close(m[4], exploit(f)) and close(m[5], exploit(softmax(h)))
    if log["M"][0]["autoplay"] == 1:
        # The stand-in's fixed answers: every question right except the step-size one.
        assert [a["right"] for a in log["A"]] == [1, 1, 1, 1, 0]
