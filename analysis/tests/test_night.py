"""Night School: the reference maths on its own, and the golden walk against a real log when one is present."""
from pathlib import Path

import pytest

from rllab import night as ns

ROOT = Path(__file__).resolve().parents[2]
GOLDEN_PLAN = [2, 0, 0, 3, 3] + [2] + [0] * 11 + [3] + [0, 0, 3] + [1, 2, 0, 1, 3] + [0] * 11
GOLDEN_LOGS = sorted((ROOT / "data" / "logs" / "night").glob("*golden*.txt"))
NIGHT_LOGS = sorted((ROOT / "data" / "logs" / "night").glob("*.txt"))


def test_golden_walk_shape():
    eps = ns.walk(GOLDEN_PLAN)
    assert [len(e) for e in eps] == [5, 13, 3, 16]
    assert [e[-1][2] for e in eps] == [-101, 49, -101, 49]          # fall, goal, fall, goal
    assert eps[3][0][3] == 0                                          # the blocked move stays on the start cell


def test_value_iteration_finds_the_edge_route():
    Q, deltas = ns.value_iteration()
    assert deltas[-1] < 0.001
    # From the start the best plan is 11 steps along the edge row: 11 steps at -1, then +50.
    assert max(Q[0:4]) == pytest.approx(39.0)
    assert Q[0] == pytest.approx(39.0)                                # forward is the best first move
    assert Q[3] == pytest.approx(-101.0)                              # toward the edge from row 0 is the fall


def test_sarsa_and_qlearning_differ_only_in_the_target():
    eps = ns.walk(GOLDEN_PLAN)
    a = ns.learn(ns.SARSA, eps, alpha=0.5)["Q"]
    b = ns.learn(ns.QL, eps, alpha=0.5)["Q"]
    assert a != b
    assert a[2 * 4 + 3] == b[2 * 4 + 3] == pytest.approx(-75.75)      # two falls from cell 2, learned the same way by both
    assert a[0] == pytest.approx(-13.625) and b[0] == pytest.approx(-0.75)   # SARSA blames the start for the fall that followed; Q-learning does not


def test_random_policy_value_is_bad_everywhere():
    V = ns.random_policy_values()
    assert all(v < 0 for i, v in enumerate(V) if i != ns.GOAL)
    assert V[0] > V[36]      # under a random walk the far inland corner is worse: she wanders longer and falls anyway


@pytest.mark.skipif(not GOLDEN_LOGS, reason="no golden-walk log in data/logs/night")
@pytest.mark.parametrize("path", GOLDEN_LOGS, ids=lambda p: p.name)
def test_golden_log_matches_reference(path):
    """Every table the game logged after the scripted walk equals the table recomputed here."""
    m = ns.parse(path)
    assert m.header["version"] in (9202, 9204)
    rules = ns.Rules(r_step=m.header["r_step"], r_goal=m.header["r_goal"], r_fall=m.header["r_fall"],
                     r_timeout=m.header["r_timeout"], max_steps=m.header["max_steps"], gamma=m.header["gamma_milli"] / 1000)
    eps = ns.walk(GOLDEN_PLAN, rules)
    seen_algos, compared = set(), 0
    for (bot, run), info in m.runs.items():
        if info.get("complete") != 1:
            continue
        algo = info["algo"]
        rows = m.qrows.get((bot, run), {})
        if algo == ns.DP:
            Q, deltas = ns.value_iteration(rules)
            logged = [s["delta"] for s in m.sweeps if s["bot"] == bot and s["run"] == run]
            assert len(logged) == len(deltas)
            ref, key = Q, "Q"
        elif algo == ns.RANDOM:
            ref_all = ns.learn(algo, eps, alpha=info["alpha_milli"] / 1000, gamma=rules.gamma)
            finals = [p for p in m.ptables if p["bot"] == bot and p["run"] == run and p["ep"] == 4]
            assert finals, "no value tables logged for the prediction bot"
            for p in finals:
                want = {0: ref_all["Vtd"], 1: ref_all["Vmc"], 2: ref_all["Nv"]}[p["kind"]]
                for c, v in enumerate(p["values"]):
                    assert v == pytest.approx(want[p["row"] * ns.NCOLS + c], abs=0.011), (bot, run, p["kind"], p["row"], c)
                    compared += 1
            seen_algos.add(algo)
            continue
        else:
            ref_all = ns.learn(algo, eps, alpha=info["alpha_milli"] / 1000, eps=max(info["eps_milli"], 0) / 1000,
                               lam=info["lam_milli"] / 1000, q_init=info["q_init"], gamma=rules.gamma)
            ref, key = (ref_all["theta"], "theta") if algo == ns.PG else (ref_all["Q"], "Q")
            for cell, (_, visits) in rows.items():
                assert visits == sum(ref_all["visits"][cell * 4: cell * 4 + 4]), (bot, run, cell)
        assert rows, f"no table logged for bot {bot} run {run}"
        for cell, (vals, _) in rows.items():
            for a, v in enumerate(vals):
                assert v == pytest.approx(ref[cell * 4 + a], abs=0.011), (bot, run, ns.ALGO_NAMES[algo], cell, a)
                compared += 1
        seen_algos.add(algo)
    assert compared > 200
    assert seen_algos >= {ns.SARSA, ns.QL, ns.ESARSA, ns.MC, ns.LAMBDA, ns.RANDOM, ns.DP, ns.PG}


@pytest.mark.skipif(not NIGHT_LOGS, reason="no Night School logs in data/logs/night")
@pytest.mark.parametrize("path", NIGHT_LOGS, ids=lambda p: p.name)
def test_night_logs_replay_and_sanity(path):
    """Every logged step of the one-step methods matches the textbook update; every log is real play."""
    m = ns.parse(path)
    assert not ns.sanity(m)
    checked, bad = ns.replay_steps(m)
    assert not bad, bad[:3]
