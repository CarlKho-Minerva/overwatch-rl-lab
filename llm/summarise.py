"""Summarise hidden-order runs: data/llm/hidden_order_<model>.jsonl -> data/llm/summary.json.

    python llm/summarise.py data/llm

Counts are reported as counts. The 24 cases per condition are every combination of wish, ticket type and opening
phrasing, run once at temperature 0, so they are a full sweep of a small scripted world, not a random sample.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

CONDITIONS = ["last", "notes", "full", "told"]
NAMES = {"last": "Latest message only", "notes": "Latest message and its own notes", "full": "Whole transcript", "told": "Transcript, and told the hidden facts"}


def mean(xs):
    xs = list(xs)
    return sum(xs) / len(xs) if xs else None


def summarise(path: Path) -> dict:
    eps = [json.loads(line) for line in path.read_text().splitlines() if line.strip()]
    out = {"model": eps[0].get("model") if eps else None, "episodes": len(eps), "conditions": {}}
    for c in CONDITIONS:
        es = [e for e in eps if e["condition"] == c]
        if not es:
            continue
        turns = [t for e in es for t in e["steps"]]
        # In the "told" condition the model has been given the hidden facts, so its belief should not match what the
        # transcript alone supports. The comparison is left out there.
        errs = [t["err"] for t in turns if t.get("err")] if c != "told" else []
        d = {"name": NAMES[c], "cases": len(es), "right": sum(e["outcome"] == "right" for e in es), "wrong": sum(e["outcome"] == "wrong" for e in es),
             "no_final": sum(e["outcome"] == "no final step" for e in es), "premature": sum(e["premature"] for e in es),
             "right_but_premature": sum(e["premature"] and e["outcome"] == "right" for e in es),
             "turns_mean": mean(e["turns"] for e in es), "fewest_mean": mean(e["fewest_steps"] for e in es),
             "extra_turns_mean": mean(e["turns"] - e["fewest_steps"] for e in es if e["outcome"] == "right"),
             "repeat_steps_mean": mean(e["repeat_steps"] for e in es),
             "belief_err_wish": mean(x["wish"] for x in errs), "belief_err_flex": mean(x["flex"] for x in errs),
             # the same error, split by whether the turn's visible message was the customer's or the booking system's
             "belief_err_wish_after_lookup": mean(t["err"]["wish"] for t in turns if t.get("err") and t["saw"].startswith("Booking system")) if c != "told" else None,
             "belief_err_flex_after_customer": mean(t["err"]["flex"] for t in turns if t.get("err") and t["saw"].startswith("Customer") and t["exact"]["flex"] in (0.0, 1.0)) if c != "told" else None,
             "first_step": {s: sum(e["steps"][0]["step"] == s for e in es) for s in sorted({e["steps"][0]["step"] for e in es})}}
        for group, label in ((0, "cant_fly"), (1, "add_something")):
            g = [e for e in es if (e["wish"] in ("cancel", "change_date")) == (group == 0)]
            d[f"right_{label}"] = sum(e["outcome"] == "right" for e in g)
            d[f"cases_{label}"] = len(g)
        out["conditions"][c] = d
    return out


def main(argv) -> int:
    folder = Path(argv[0])
    files = sorted(folder.glob("hidden_order_*.jsonl"))
    if not files:
        print(f"FAIL: no hidden_order_*.jsonl in {folder}", file=sys.stderr)
        return 1
    S = {"models": {}}
    for f in files:
        s = summarise(f)
        S["models"][s["model"]] = s
        for c, d in s["conditions"].items():
            print(f"{s['model']:14s} {c:6s} right {d['right']:2d}/{d['cases']}  wrong {d['wrong']:2d}  no final {d['no_final']:2d}  premature {d['premature']:2d}  turns {d['turns_mean']:.2f} (best {d['fewest_mean']:.2f})"
                  + (f"  belief err wish {d['belief_err_wish']:.2f} flex {d['belief_err_flex']:.2f}" if d["belief_err_wish"] is not None else "")
                  + (f"  after a lookup {d['belief_err_wish_after_lookup']:.2f}" if d.get("belief_err_wish_after_lookup") is not None else ""))
    (folder / "summary.json").write_text(json.dumps(S, indent=1))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
