"""The language-model version of the hidden-wall task: the world's rules, checked with scripted agents (no model needed)."""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "llm"))
import hidden_order as ho  # noqa: E402
import summarise  # noqa: E402


def test_world_rules_with_scripted_agents():
    assert ho.selftest() == 0


def test_best_plan_is_lookup_first_for_a_cannot_fly_opener():
    # averaged over the four cases of that opener: look up first = 2.5 steps, ask first = 3
    cases = [(w, t) for w in ("cancel", "change_date") for t in ho.TICKETS]
    assert sum(ho.fewest_steps(w, t) for w, t in cases) / len(cases) == 2.5
    eps = [ho.run_episode(ho.perfect_agent, None, w, t, 0, "full") for w, t in cases]
    assert all(e["steps"][0]["step"] == "lookup_booking" and e["outcome"] == "right" and not e["premature"] for e in eps)


def test_a_guess_before_the_facts_are_in_is_counted_as_premature():
    def hasty(world, condition, notes):
        return "refuse", "", ""
    e = ho.run_episode(hasty, None, "cancel", "basic", 0, "full")
    assert e["outcome"] == "right" and e["premature"]          # right by luck is still early
    e = ho.run_episode(hasty, None, "cancel", "flex", 0, "full")
    assert e["outcome"] == "wrong" and e["premature"]


def test_summary_of_the_logged_runs_adds_up():
    files = sorted((ROOT / "data" / "llm").glob("hidden_order_*.jsonl"))
    for f in files:
        s = summarise.summarise(f)
        for c, d in s["conditions"].items():
            assert d["right"] + d["wrong"] + d["no_final"] == d["cases"]
            assert d["right_but_premature"] <= d["premature"] <= d["cases"]
        eps = [json.loads(line) for line in f.read_text().splitlines() if line.strip()]
        for e in eps:       # every logged final step is scored against the world's own rule
            want = ho.right_final(e["wish"], e["ticket"])
            assert e["right_final"] == want and (e["outcome"] == "right") == (e["final"] == want)
