"""Night School logs: parser and reference maths.

The Night School build (workshop/night/) logs lines that start with ``NS,``. This module reads them into
plain Python structures and re-implements every learning rule the game runs, so a table the game logged
can be recomputed outside the game and compared. Column lists: docs/night-school.md.
"""
from __future__ import annotations

import math
import re
from dataclasses import dataclass, field
from pathlib import Path

NCOLS, NROWS, NCELLS, NA = 12, 4, 48, 4
START, GOAL = 0, 11
ALGO_NAMES = ["sarsa", "qlearning", "expected_sarsa", "dyna", "monte_carlo", "sarsa_lambda", "random", "planner", "policy_gradient"]
SARSA, QL, ESARSA, DYNA, MC, LAMBDA, RANDOM, DP, PG = range(9)
CONDITION_NAMES = ["SARSA", "Q-learning", "Expected SARSA", "Q + fading exploration", "Q + optimism", "Dyna-Q",
                   "Monte Carlo", "SARSA(lambda)", "Q + count bonus", "Random walk", "Planner", "Policy gradient"]
LINE = re.compile(r"^\[(\d+):(\d+):(\d+)\] NS,([A-Z]+),(.*)$")


def _num(x: str):
    if x in ("True", "False"):
        return x == "True"
    try:
        return int(x)
    except ValueError:
        try:
            return float(x)
        except ValueError:
            return x


@dataclass
class Match:
    path: str
    header: dict = field(default_factory=dict)
    cal: list = field(default_factory=list)
    runs: dict = field(default_factory=dict)        # (bot, run) -> dict(header fields, footer fields)
    episodes: list = field(default_factory=list)    # dicts
    steps: list = field(default_factory=list)       # dicts
    qrows: dict = field(default_factory=dict)       # (bot, run) -> {cell: ([q0..q3], visits)}
    ptables: list = field(default_factory=list)     # dicts: bot, run, ep, kind, row, values
    sweeps: list = field(default_factory=list)      # dicts: bot, run, sweep, delta
    load: list = field(default_factory=list)
    end: dict = field(default_factory=dict)
    fails: list = field(default_factory=list)
    nbytes: int = 0


M_FIELDS = ["version", "bots", "team1_bots", "cell", "run_speed", "coast", "move_speed", "eval_eps", "max_steps",
            "eval_max_steps", "gamma_milli", "r_step", "r_goal", "r_fall", "r_timeout", "cond_offset", "spawn_calls", "nconds"]
H_FIELDS = ["bot", "run", "cond", "algo", "eps_milli", "alpha_milli", "q_init", "plan_n", "lam_milli", "bonus", "train_eps", "side", "t0"]
F_FIELDS = ["bot", "run", "cond", "complete", "train_done", "goals", "falls", "timeouts", "eval_done", "eval_goals",
            "eval_falls", "eval_timeouts", "steps", "slips", "seconds"]
E_FIELDS = ["bot", "run", "ep", "mode", "ret", "steps", "outcome", "edge", "slips", "t"]
S_FIELDS = ["bot", "run", "t", "s", "a", "r", "s2", "a2", "terminal", "explore", "q_old", "q_new", "target", "eps_milli"]
X_FIELDS = ["reason", "seconds", "episodes", "steps", "log_bytes", "load", "load_avg", "load_peak"]
L_FIELDS = ["seconds", "load", "load_avg", "load_peak", "episodes", "steps", "log_bytes"]


def parse(path) -> Match:
    """Read one log file written by a Night School match."""
    m = Match(path=str(path))
    data = Path(path).read_text(encoding="utf-8", errors="replace")
    m.nbytes = len(data.encode("utf-8"))
    for line in data.splitlines():
        hit = LINE.match(line.strip())
        if not hit:
            continue
        kind, vals = hit.group(4), [_num(v) for v in hit.group(5).split(",")]
        if kind == "M":
            m.header = dict(zip(M_FIELDS, vals))
        elif kind == "CAL":
            m.cal = vals
        elif kind == "H":
            d = dict(zip(H_FIELDS, vals))
            m.runs[(d["bot"], d["run"])] = d
        elif kind == "F":
            d = dict(zip(F_FIELDS, vals))
            m.runs.setdefault((d["bot"], d["run"]), {}).update({k: v for k, v in d.items() if k not in ("bot", "run", "cond")})
        elif kind == "E":
            m.episodes.append(dict(zip(E_FIELDS, vals)))
        elif kind == "S":
            m.steps.append(dict(zip(S_FIELDS, vals)))
        elif kind == "Q":
            m.qrows.setdefault((vals[0], vals[1]), {})[vals[2]] = (vals[3:7], vals[7])
        elif kind == "P":
            m.ptables.append({"bot": vals[0], "run": vals[1], "ep": vals[2], "kind": vals[3], "row": vals[4], "values": vals[5:17]})
        elif kind == "V":
            m.sweeps.append({"bot": vals[0], "run": vals[1], "sweep": vals[2], "delta": vals[3]})
        elif kind == "L":
            m.load.append(dict(zip(L_FIELDS, vals)))
        elif kind == "X":
            m.end = dict(zip(X_FIELDS, vals))
        elif kind == "FAIL":
            m.fails.append(vals)
    return m


# ---------------------------------------------------------------------------
# Reference environment: the grid's rules, exactly as the Workshop script scores them.
# ---------------------------------------------------------------------------
@dataclass
class Rules:
    r_step: float = -1
    r_goal: float = 50
    r_fall: float = -100
    r_timeout: float = -50
    max_steps: int = 100
    gamma: float = 1.0


def move(s: int, a: int):
    """Where action a leads from cell s by the grid's rules: (next cell, fell)."""
    col, row = s % NCOLS, s // NCOLS
    tc, tr = col + (1, -1, 0, 0)[a], row + (0, 0, 1, -1)[a]
    if tr < 0:
        return s, True
    if tc < 0 or tc >= NCOLS or tr >= NROWS:
        return s, False
    return tr * NCOLS + tc, False


def walk(plan, rules: Rules = Rules()):
    """Follow a fixed list of actions from the start cell. Returns episodes of (s, a, r, s2, a2, terminal)."""
    episodes, ep, s, i = [], [], START, 0
    while i < len(plan):
        a = plan[i]
        s2, fell = move(s, a)
        r, terminal = rules.r_step, False
        if fell:
            r, terminal = r + rules.r_fall, True
        elif s2 == GOAL:
            r, terminal = r + rules.r_goal, True
        elif len(ep) + 1 >= rules.max_steps:
            r, terminal = r + rules.r_timeout, True
        a2 = plan[i + 1] if (not terminal and i + 1 < len(plan)) else None
        ep.append((s, a, r, s2, a2, terminal))
        i += 1
        if terminal:
            episodes.append(ep)
            ep, s = [], START
        else:
            s = s2
    if ep:
        episodes.append(ep)
    return episodes


# ---------------------------------------------------------------------------
# Reference learners. Each takes the same transitions the game saw and returns the tables it should hold.
# ---------------------------------------------------------------------------
def learn(algo: int, episodes, alpha: float, eps: float = 0.1, lam: float = 0.0, q_init: float = 0.0, gamma: float = 1.0):
    """Apply one learning rule to a list of episodes. Returns dict(Q, theta, Vtd, Vmc, Nv, visits)."""
    Q = [q_init] * (NCELLS * NA)
    theta = [0.0] * (NCELLS * NA)
    Vtd, Vmc, Nv = [0.0] * NCELLS, [0.0] * NCELLS, [0] * NCELLS
    visits = [0] * (NCELLS * NA)
    for ep in episodes:
        E = [0.0] * (NCELLS * NA)
        buf_s, buf_r = [], []
        for (s, a, r, s2, a2, terminal) in ep:
            i = s * NA + a
            row2 = Q[s2 * NA: s2 * NA + NA]
            if algo == SARSA:
                tgt = r + (0 if terminal else gamma * Q[s2 * NA + a2])
                Q[i] += alpha * (tgt - Q[i])
            elif algo in (QL, DYNA):
                tgt = r + (0 if terminal else gamma * max(row2))
                Q[i] += alpha * (tgt - Q[i])
            elif algo == ESARSA:
                tgt = r + (0 if terminal else gamma * ((1 - eps) * max(row2) + eps * sum(row2) / 4))
                Q[i] += alpha * (tgt - Q[i])
            elif algo == LAMBDA:
                tgt = r + (0 if terminal else gamma * Q[s2 * NA + a2])
                delta = tgt - Q[i]
                E[i] = 1.0
                Q = [q + alpha * delta * e for q, e in zip(Q, E)]
                E = [e * gamma * lam for e in E]
            elif algo in (MC, PG):
                buf_s.append(i)
                buf_r.append(r)
            elif algo == RANDOM:
                tgt = r + (0 if terminal else gamma * Vtd[s2])
                Vtd[s] += alpha * (tgt - Vtd[s])
                buf_s.append(s)
                buf_r.append(r)
            visits[i] += 1
        g = 0.0
        if algo == MC:
            for k in range(len(buf_s) - 1, -1, -1):
                g = gamma * g + buf_r[k]
                Q[buf_s[k]] += alpha * (g - Q[buf_s[k]])
        elif algo == RANDOM:
            for k in range(len(buf_s) - 1, -1, -1):
                g = gamma * g + buf_r[k]
                Nv[buf_s[k]] += 1
                Vmc[buf_s[k]] += (g - Vmc[buf_s[k]]) / Nv[buf_s[k]]
        elif algo == PG:
            for k in range(len(buf_s) - 1, -1, -1):
                g = gamma * g + buf_r[k]
                i = buf_s[k]
                s, a = i // NA, i % NA
                row = theta[s * NA: s * NA + NA]
                mx = max(row)
                p = [math.e ** (x - mx) for x in row]
                z = sum(p)
                delta = g - Vtd[s]
                Vtd[s] += 0.2 * delta
                for b in range(NA):
                    theta[s * NA + b] += alpha * delta * ((1 if b == a else 0) - p[b] / z)
                Q[i] += 0.2 * (g - Q[i])
    return {"Q": Q, "theta": theta, "Vtd": Vtd, "Vmc": Vmc, "Nv": Nv, "visits": visits}


def value_iteration(rules: Rules = Rules(), max_sweeps: int = 60, tol: float = 0.001):
    """In-place value iteration on the grid's rules, in the game's sweep order. Returns (Q, deltas per sweep)."""
    Q = [0.0] * (NCELLS * NA)
    deltas = []
    for _ in range(max_sweeps):
        d = 0.0
        for k in range(NCELLS):
            if k == GOAL:
                continue
            for a in range(NA):
                s2, fell = move(k, a)
                if fell:
                    q = rules.r_step + rules.r_fall
                else:
                    q = rules.r_step + (rules.r_goal if s2 == GOAL else rules.gamma * max(Q[s2 * NA: s2 * NA + NA]))
                d = max(d, abs(q - Q[k * NA + a]))
                Q[k * NA + a] = q
        deltas.append(d)
        if d < tol:
            break
    return Q, deltas


def random_policy_values(rules: Rules = Rules(), sweeps: int = 20000):
    """Exact value of the uniform random policy on the grid's rules (time limit ignored), by iteration."""
    V = [0.0] * NCELLS
    for _ in range(sweeps):
        d = 0.0
        for s in range(NCELLS):
            if s == GOAL:
                continue
            v = 0.0
            for a in range(NA):
                s2, fell = move(s, a)
                if fell:
                    v += rules.r_step + rules.r_fall
                elif s2 == GOAL:
                    v += rules.r_step + rules.r_goal
                else:
                    v += rules.r_step + rules.gamma * V[s2]
            v /= NA
            d = max(d, abs(v - V[s]))
            V[s] = v
        if d < 1e-9:
            break
    return V


# ---------------------------------------------------------------------------
# Checks on a real log
# ---------------------------------------------------------------------------
def replay_steps(m: Match, tol: float = 0.011):
    """Recompute the per-step lines of the one-step methods from the start of each run.

    The game logs the first steps of every run. Starting from the run's initial table, apply the textbook
    update to each logged transition and compare the target and the new Q with what the game logged.
    Dyna-Q plans between real steps (imagined updates are not logged), so for it only the arithmetic of
    each line is checked: q_new = q_old + alpha * (target - q_old).
    Returns (number checked, list of mismatches).
    """
    gamma = m.header.get("gamma_milli", 1000) / 1000
    by_run: dict = {}
    for s in m.steps:
        by_run.setdefault((s["bot"], s["run"]), []).append(s)
    checked, bad = 0, []
    for key, rows in by_run.items():
        run = m.runs.get(key)
        if not run or "algo" not in run:
            continue
        algo, alpha = run["algo"], run["alpha_milli"] / 1000
        rows.sort(key=lambda r: r["t"])
        if [r["t"] for r in rows] != list(range(len(rows))):
            continue    # a gap: the table cannot be rebuilt
        Q = [float(run["q_init"])] * (NCELLS * NA)
        for r in rows:
            i = r["s"] * NA + r["a"]
            row2 = Q[r["s2"] * NA: r["s2"] * NA + NA]
            eps = r["eps_milli"] / 1000
            if algo == DYNA:
                want_new = r["q_old"] + alpha * (r["target"] - r["q_old"])
                ok = abs(want_new - r["q_new"]) <= tol + alpha * 0.011
            else:
                if algo == SARSA:
                    tgt = r["r"] + (0 if r["terminal"] else gamma * Q[r["s2"] * NA + r["a2"]])
                elif algo == QL:
                    tgt = r["r"] + (0 if r["terminal"] else gamma * max(row2))
                elif algo == ESARSA:
                    tgt = r["r"] + (0 if r["terminal"] else gamma * ((1 - eps) * max(row2) + eps * sum(row2) / 4))
                else:
                    break
                new = Q[i] + alpha * (tgt - Q[i])
                ok = abs(Q[i] - r["q_old"]) <= tol and abs(tgt - r["target"]) <= tol and abs(new - r["q_new"]) <= tol
                Q[i] = new
            checked += 1
            if not ok:
                bad.append((key, r))
    return checked, bad


def episodes_from_steps(m: Match, bot: int, run: int):
    """Rebuild episodes of (s, a, r, s2, a2, terminal) from a run's logged step lines."""
    rows = sorted((s for s in m.steps if s["bot"] == bot and s["run"] == run), key=lambda r: r["t"])
    eps, ep = [], []
    for r in rows:
        ep.append((r["s"], r["a"], r["r"], r["s2"], None if r["terminal"] else r["a2"], bool(r["terminal"])))
        if r["terminal"]:
            eps.append(ep)
            ep = []
    if ep:
        eps.append(ep)
    return eps


def sanity(m: Match):
    """Things that must hold for a log to be real play. Returns a list of problems (empty = fine)."""
    problems = []
    if not m.header:
        problems.append("no match header")
        return problems
    for e in m.episodes:
        if e["steps"] <= 0:
            problems.append(f"episode with no steps: {e}")
    by_run: dict = {}
    for e in m.episodes:
        by_run.setdefault((e["bot"], e["run"]), []).append(e)
    for key, eps in by_run.items():
        nums = [e["ep"] for e in eps]
        if nums != list(range(1, len(nums) + 1)):
            problems.append(f"bot {key[0]} run {key[1]}: episode numbers are not 1..n")
        run = m.runs.get(key, {})
        if "seconds" in run and run.get("steps"):
            if run["seconds"] / run["steps"] < 0.04:
                problems.append(f"bot {key[0]} run {key[1]}: {run['seconds'] / run['steps']:.3f} s per step is too fast to be real movement")
    return problems
