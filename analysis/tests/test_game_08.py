"""Game 8, Recall: Q-learning against Dyna-Q on a 7 by 3 pad maze whose wall gap moves (Lecture 8).

The game's dice are a small fixed generator (x -> 171 x mod 30269), seeded once and logged, so this file can replay
every race the game ran from the logged seed, the player's logged walk and his logged choices, and check every trip
length the game reported. The same arithmetic is in workshop/games/g08_body.opy.
"""
import struct

import pytest

from rllab import games

LOG = games.newest(8)

NC, NR, WALLCOL = 7, 3, 3
START, GOAL = 7, 13                 # pads (0, 1) and (6, 1); a pad is row * 7 + column
OLD_GAP_ROW, NEW_GAP_ROW = 0, 2
ALPHA, GAMMA = 0.5, 0.9
DICE_M, DICE_A, EPSX = 30269, 171, 3027   # explore when the dice show less than 3027 (one time in ten)
TRIPS, CAP, SHORT = 10, 200, 10
WALL_REPLAYS = 20
TIE_TOL = 3e-5      # version 1 logs only: how far from the 0.0001 margin a tie may be flipped. The game's 32-bit sums
                    # drift from any outside replay; on the 2026-11-22 log one tie at a gap of 1.107e-4 went the other way.
TIE_BAND = 3e-5     # version 2 logs: the game logs its tie set whenever a move is this close to the margin
OLD_GAP_MOVE = 2 * 4 + 0            # pad (2, 0) moving +x, through the old gap
NEW_GAP_PAD = 2 * NC + 3            # pad (3, 2)


def f32(v):
    return struct.unpack("f", struct.pack("f", v))[0]


def lcg(x):
    return (x * DICE_A) % DICE_M


def seed2_of(seed):
    return (seed * 7 + 13) % DICE_M or 1


def shut(c, r, gap):
    return c < 0 or c >= NC or r < 0 or r >= NR or (c == WALLCOL and r != gap)


def next_pad(s, a, gap):
    c, r = s % NC + [1, -1, 0, 0][a], s // NC + [0, 0, 1, -1][a]
    return s if shut(c, r, gap) else r * NC + c


def outcome(s, a, gap):
    """(next pad, reward); the goal is shown as next pad -1."""
    s2 = next_pad(s, a, gap)
    return (-1, 1) if s2 == GOAL else (s2, 0)


def q_new(q, r, next_max, rnd=float):
    return rnd(q + ALPHA * (r + GAMMA * next_max - q))


class Bot:
    def __init__(self, replaying, rnd=float):
        self.replaying, self.rnd = replaying, rnd
        self.Q = [0.0] * (NC * NR * 4)
        self.mS2, self.mR, self.seen = {}, {}, []
        # Ties: a move counts as tied with the best when it is within 0.0001 of it. When a move's gap to the best is
        # within TIE_TOL of that margin, 32-bit rounding in the game decides it, not the rule. Such decisions are
        # recorded by real-step clock (near), and the log check may flip them (flips) to find the game's branch.
        self.clock, self.near, self.flips, self.trip_end = 0, [], set(), []

    def remember(self, k, r, s2):
        if k not in self.mS2:
            self.seen.append(k)
        self.mS2[k], self.mR[k] = s2, r

    def best(self, s):
        return max(self.Q[s * 4:s * 4 + 4])

    def know(self):
        return sum(1 for s in range(NC * NR) if self.best(s) > 0)

    def race(self, seed, n_rep, gap, count_stale=False, race_id=0, logged_ties=None):
        x, y = seed, seed2_of(seed)
        trips, first_goal, stale, fix, through, steps = [], None, 0, -1, -1, 0
        for t in range(TRIPS):
            cur, n, at_goal = START, 0, False
            while not at_goal and n < CAP:
                x = lcg(x)
                if x < EPSX:
                    x = lcg(x)
                    a = x * 4 // DICE_M
                else:
                    row = self.Q[cur * 4:cur * 4 + 4]
                    m = max(row)
                    ties = [i for i in range(4) if row[i] >= m - 0.0001]
                    edge = [i for i in range(4) if abs((m - row[i]) - 0.0001) < TIE_TOL]
                    if edge:
                        self.near.append(self.clock)
                        if self.clock in self.flips:
                            ties = [i for i in range(4) if (i in ties) != (i in edge)]
                    if logged_ties is not None and (race_id, self.replaying * 1, steps + 1) in logged_ties:
                        # Version 2 logs: the game's own tie set where a move sat near the margin. It may differ
                        # from the rule only on moves within TIE_BAND of the margin; anything else is a real fault.
                        mask = logged_ties[(race_id, self.replaying * 1, steps + 1)]
                        game_ties = [i for i in range(4) if mask >> i & 1]
                        for i in range(4):
                            assert (i in game_ties) == (i in ties) or abs((m - row[i]) - 0.0001) < TIE_BAND, \
                                f"race {race_id} bot {self.replaying * 1} step {steps + 1}: tie set {mask} breaks the rule"
                        ties = game_ties
                    x = lcg(x)
                    a = ties[x * len(ties) // DICE_M]
                k = cur * 4 + a
                s2, r = outcome(cur, a, gap)
                self.Q[k] = q_new(self.Q[k], r, 0 if s2 < 0 else self.best(s2), self.rnd)
                n += 1
                steps += 1
                self.clock += 1
                if self.replaying:
                    self.remember(k, r, s2)
                    for _ in range(n_rep):
                        y = lcg(y)
                        pk = self.seen[y * len(self.seen) // DICE_M]
                        ps2 = self.mS2[pk]
                        ps = pk // 4
                        if count_stale and not shut(ps % NC, ps // NC, gap) and outcome(ps, pk % 4, gap)[0] != ps2:
                            stale += 1
                        self.Q[pk] = q_new(self.Q[pk], self.mR[pk], 0 if ps2 < 0 else self.best(ps2), self.rnd)
                    if count_stale and k == OLD_GAP_MOVE and fix < 0:
                        fix = steps
                    if count_stale and s2 == NEW_GAP_PAD and through < 0:
                        through = steps
                if s2 < 0:
                    at_goal = True
                else:
                    cur = s2
            trips.append(n)
            self.trip_end.append(self.clock)
            if at_goal and first_goal is None:
                first_goal = (t + 1, self.know())
        return {"trips": trips, "first_goal": first_goal, "stale": stale, "fix": fix, "through": through}


def first_short(trips):
    return next((i + 1 for i, n in enumerate(trips) if n <= SHORT), TRIPS + 1)


def answer_q2(plain, repl):
    a, b = first_short(plain), first_short(repl)
    return 0 if b < a else (1 if a < b else 2)


def answer_q3(total_now, total_before):
    if total_now * 3 < total_before * 2:
        return 0
    if total_now * 2 > total_before * 3:
        return 2
    return 1


def answer_q4(total_plain, total_repl):
    if total_repl * 4 > total_plain * 5:
        return 0
    if total_plain * 4 > total_repl * 5:
        return 1
    return 2


def answer_q5(fix, through):
    """Which comes later in the moved-gap race: fixing the old-gap memory (1 = finding the new gap is later)."""
    if fix < 0 and through < 0:
        return 2
    if through < 0 or (fix >= 0 and fix < through):
        return 1
    return 0


def chain(bot, seed, walk, r1, r2, rnd=float, flips=(), logged_ties=None):
    """The races one bot runs: bot (1, role) runs race 1; bot (2, role) runs race 2, then the moved-gap race 3."""
    first, role = bot
    b = Bot(role == 1, rnd)
    b.flips = set(flips)
    if role == 1:
        for k, r, s2 in walk:
            b.remember(k, r, s2)
    n_rep = (r1 if first == 1 else r2) if role == 1 else 0
    out = {first: b.race(seed, n_rep, OLD_GAP_ROW, race_id=first, logged_ties=logged_ties)}
    if first == 2:
        out[3] = b.race(seed, WALL_REPLAYS if role == 1 else 0, NEW_GAP_ROW, count_stale=role == 1, race_id=3,
                        logged_ties=logged_ties)
    return out, b


def play(seed, walk, r1, r2, rnd=float, flips=None):
    """Every race of one game: walk = [(move index, reward, next pad)], r1 and r2 = replays per real step."""
    flips = flips or {}
    out = {1: [None, None], 2: [None, None], 3: [None, None]}
    for bot in ((1, 0), (1, 1), (2, 0), (2, 1)):
        res, _ = chain(bot, seed, walk, r1, r2, rnd, flips.get(bot, ()))
        for race, v in res.items():
            out[race][bot[1]] = v
    return out


def search(bot, seed, walk, r1, r2, logged, rnd=float, budget=3000):
    """Find the near-margin tie decisions (see Bot) whose flipping reproduces the logged trips of this bot, or None.
    Only decisions whose gap is within TIE_TOL of the margin may flip; every other step must match the rule."""
    stack, seen = [frozenset()], set()
    while stack and budget > 0:
        flips = stack.pop()
        if flips in seen:
            continue
        seen.add(flips)
        budget -= 1
        res, b = chain(bot, seed, walk, r1, r2, rnd, flips)
        got = [n for race in sorted(res) for n in res[race]["trips"]]
        want = [n for race in sorted(res) for n in logged.get((race, bot[1]), [])]
        bad = next((i for i, (u, v) in enumerate(zip(got, want)) if u != v), None)
        if bad is None and len(got) == len(want):
            return res, flips
        if bad is None:
            return None
        last = max(flips, default=-1)
        cands = [c for c in b.near if last < c <= b.trip_end[bad]]
        stack.extend(flips | {c} for c in cands)    # the latest decision before the mismatch is tried first
    return None


def walk_from(moves, gap=OLD_GAP_ROW):
    s, out = START, []
    for a in moves:
        s2, r = outcome(s, a, gap)
        out.append((s * 4 + a, r, s2))
        if s2 < 0:
            break
        s = s2
    return out


# --- the reference, on the same values the game's CHECK lines use ---------------------------------------------------

def test_reference_values():
    assert q_new(0, 1, 0) == 0.5                          # first arrival at the goal
    assert abs(q_new(0, 0, 0.5) - 0.225) < 1e-9          # good news one pad back
    assert lcg(1) == 171 and lcg(171) == 29241
    assert 29241 * 4 // DICE_M == 3
    assert next_pad(7, 0, 0) == 8                         # start, step +x
    assert next_pad(9, 0, 0) == 9                         # into the wall: stay
    assert next_pad(2, 0, 0) == 3 and next_pad(2, 0, 2) == 2   # old gap open, then shut
    assert next_pad(16, 0, 2) == 17 and next_pad(16, 0, 0) == 16
    assert next_pad(20, 2, 0) == 20                       # off the maze: stay
    assert outcome(12, 0, 0) == (-1, 1)                   # onto the goal
    assert seed2_of(1) == 20
    assert answer_q3(100, 900) == 0 and answer_q3(95, 100) == 1 and answer_q3(900, 100) == 2
    assert answer_q5(4, 257) == 1 and answer_q5(30, 12) == 0 and answer_q5(4, -1) == 1 and answer_q5(-1, -1) == 2
    assert answer_q4(1700, 500) == 1 and answer_q4(500, 1700) == 0 and answer_q4(500, 520) == 2


def test_plain_bot_news_moves_one_pad_per_visit():
    # Lecture 5: after its first arrival, exactly one pad has a value above zero.
    for seed in (1, 77, 4242, 30268):
        p = Bot(False)
        res = p.race(seed, 0, OLD_GAP_ROW)
        assert res["first_goal"][1] == 1


def test_zero_replays_is_the_plain_bot():
    walk = walk_from([0, 0, 0, 3, 0, 0, 0, 0, 2])
    for seed in (5, 900, 17000):
        out = play(seed, walk, 0, 20)
        assert out[1][0]["trips"] == out[1][1]["trips"]


def test_replays_help_on_average():
    walk = walk_from([0, 0, 0, 3, 0, 0, 0, 0, 2])
    plain, repl = [], []
    for seed in range(1, 60):
        out = play(seed, walk, 0, 20)
        plain.append(sum(out[2][0]["trips"]))
        repl.append(sum(out[2][1]["trips"]))
    assert sum(repl) * 3 < sum(plain)


# --- the log of the automatic run ------------------------------------------------------------------------------------

@pytest.mark.skipif(LOG is None, reason="no saved log of game 8 in data/logs/games")
def test_recall_log():
    log = games.parse(LOG)
    assert games.problems(log, 8, min_questions=5, min_selftests=4) == []
    seed, seed2 = games.events(log, "seed")[0][:2]
    assert seed2 == seed2_of(seed)
    walk = [tuple(v[:3]) for v in games.events(log, "walk")]
    assert walk, "no walk lines"
    picks = {v[0]: v[1] for v in games.events(log, "pick")}
    trips = {}
    for race, role, t, n in (v[:4] for v in games.events(log, "trip")):
        trips.setdefault((race, role), []).append(n)
    # The game computes in 32-bit floats, so a tie decision near the 0.0001 margin can go either way outside it.
    ref = {1: [None, None], 2: [None, None], 3: [None, None]}
    if log["M"][0]["version"] >= 2:
        # Version 2: the game logged its tie set at every such decision; with those, the replay must match exactly.
        ties = {tuple(v[:3]): v[3] for v in games.events(log, "tie")}
        for bot in ((1, 0), (1, 1), (2, 0), (2, 1)):
            res, _ = chain(bot, seed, walk, picks[1], picks[2], logged_ties=ties)
            for race, v in res.items():
                assert v["trips"] == trips.get((race, bot[1])), f"race {race} bot {bot[1]}: {trips.get((race, bot[1]))} != {v['trips']}"
                ref[race][bot[1]] = v
    else:
        # Version 1 logged no tie sets: allow at most 6 flips, each at a tie within TIE_TOL of the margin.
        used = {}
        for bot in ((1, 0), (1, 1), (2, 0), (2, 1)):
            found = search(bot, seed, walk, picks[1], picks[2], trips)
            assert found is not None, f"bot {bot}: logged trips {trips} cannot be reproduced by the rule"
            res, used[bot] = found
            for race, v in res.items():
                ref[race][bot[1]] = v
        assert sum(len(f) for f in used.values()) <= 6, f"too many near-margin flips needed: {used}"
    # The race worked out before the prediction is the race then shown.
    for race, tp_silent, tp_shown, td_silent, td_shown, _n in (v[:6] for v in games.events(log, "pass")):
        assert tp_silent == tp_shown == sum(ref[race][0]["trips"])
        assert td_silent == td_shown == sum(ref[race][1]["trips"])
    # Lecture 5: the plain bot's first arrival leaves exactly one pad that knows the way.
    for race, role, t, count in (v[:4] for v in games.events(log, "firstgoal")):
        assert (t, count) == ref[race][role]["first_goal"]
        if race in (1, 2) and role == 0:
            assert count == 1
    know = games.events(log, "know")
    assert know and know[0][0] == 1
    stale, fix, through = games.events(log, "wall")[0][:3]
    assert (stale, fix, through) == (ref[3][1]["stale"], ref[3][1]["fix"], ref[3][1]["through"])
    # The answer key of each prediction is the race the player then watched.
    key = {a["qid"]: a["correct"] for a in log["A"]}
    assert key[1] == 0
    assert key[2] == answer_q2(ref[1][0]["trips"], ref[1][1]["trips"])
    assert key[3] == answer_q3(sum(ref[2][1]["trips"]), sum(ref[1][1]["trips"]))
    assert key[4] == answer_q4(sum(ref[3][0]["trips"]), sum(ref[3][1]["trips"]))
    assert key[5] == answer_q5(ref[3][1]["fix"], ref[3][1]["through"])
