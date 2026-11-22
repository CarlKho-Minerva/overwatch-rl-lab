"""Summarise Night School logs: one line per match, one per run, then one per condition.

    python -m rllab.night_report <log files or folders>   [--runs] [--json out.json]

A log that was cut off (no block-end line) is still read; its runs count as incomplete.
"""
from __future__ import annotations

import json
import statistics as st
import sys
from pathlib import Path

from . import night as ns


def collect(paths):
    files = []
    for p in paths:
        p = Path(p)
        files += sorted(p.glob("*.txt")) if p.is_dir() else [p]
    return [m for m in (ns.parse(f) for f in files) if m.header]


def run_rows(matches):
    """One dict per run, with its episodes attached."""
    rows = []
    for m in matches:
        eps_by: dict = {}
        for e in m.episodes:
            eps_by.setdefault((e["bot"], e["run"]), []).append(e)
        for key, info in sorted(m.runs.items()):
            if "cond" not in info:
                continue
            eps = eps_by.get(key, [])
            train = [e for e in eps if e["mode"] == 0]
            ev = [e for e in eps if e["mode"] == 1]
            rows.append({
                "match": Path(m.path).name, "version": m.header["version"], "move_speed": m.header["move_speed"],
                "bot": key[0], "run": key[1], "cond": info["cond"], "algo": info["algo"], "side": info.get("side"),
                "complete": info.get("complete", 0), "train": train, "eval": ev,
                # A run that used its whole time allowance is a finished run with fewer episodes, not a broken one.
                "capped": int(info.get("complete", 0) == 0 and info.get("seconds") is not None
                              and info["seconds"] >= m.header.get("run_max_min", 18) * 60 - 2 and len(train) >= 20),
                "steps": info.get("steps"), "slips": info.get("slips"), "seconds": info.get("seconds"),
            })
    return rows


def first_goal(train):
    for e in train:
        if e["outcome"] == 1:
            return e["ep"]
    return None


def mean(xs):
    xs = list(xs)
    return sum(xs) / len(xs) if xs else float("nan")


def condition_table(rows, n_last=40, min_train=100):
    """Per condition: runs, falls per 100 training episodes, last-n mean return, evaluation success."""
    out = {}
    for cond in sorted({r["cond"] for r in rows}):
        rs = [r for r in rows if r["cond"] == cond and len(r["train"]) >= min(min_train, 1)]
        full = [r for r in rs if r["complete"] == 1 or r["capped"]]
        d = {"name": ns.CONDITION_NAMES[cond] if cond < len(ns.CONDITION_NAMES) else str(cond), "runs": len(rs), "complete": len(full)}
        if full:
            d["falls_per_100"] = mean(100 * sum(e["outcome"] == 2 for e in r["train"]) / len(r["train"]) for r in full)
            d["timeouts_per_100"] = mean(100 * sum(e["outcome"] == 3 for e in r["train"]) / len(r["train"]) for r in full)
            d["last_mean_return"] = mean(mean(e["ret"] for e in r["train"][-n_last:]) for r in full)
            d["last_edge"] = mean(mean(e["edge"] for e in r["train"][-n_last:]) for r in full)
            fg = [first_goal(r["train"]) for r in full]
            d["first_goal_median"] = st.median([x for x in fg if x]) if any(fg) else None
            d["never_reached_goal"] = sum(1 for x in fg if not x)
            ev = [r for r in full if r["eval"]]
            if ev:
                d["eval_goal_rate"] = mean(sum(e["outcome"] == 1 for e in r["eval"]) / len(r["eval"]) for r in ev)
                d["eval_clean_runs"] = sum(1 for r in ev if all(e["outcome"] == 1 for e in r["eval"]))
                d["eval_runs"] = len(ev)
            secs = [r["seconds"] / r["steps"] for r in full if r["steps"]]
            d["sec_per_step"] = mean(secs)
        out[cond] = d
    return out


def main(argv):
    show_runs = "--runs" in argv
    json_out = argv[argv.index("--json") + 1] if "--json" in argv else None
    paths = [a for i, a in enumerate(argv) if not a.startswith("--") and (i == 0 or argv[i - 1] != "--json")]
    matches = collect(paths)
    if not matches:
        print("no Night School logs found")
        return 1
    for m in matches:
        h = m.header
        checked, bad = ns.replay_steps(m)
        problems = ns.sanity(m)
        end = m.end
        steps = sum(e["steps"] for e in m.episodes)
        dur = max((e["t"] for e in m.episodes), default=0)
        print(f"{Path(m.path).name}: v{h['version']} {h['bots']} bots speed {h['move_speed']}% run {h['run_speed']} m/s coast {h['coast']} m | "
              f"{len(m.episodes)} episodes {steps} steps in {dur / 60:.1f} min ({steps / max(dur, 1):.1f} steps/s) | {m.nbytes / 1024:.0f} KB | "
              f"end {end.get('reason', 'CUT OFF')} | load peak {end.get('load_peak', max((l['load_peak'] for l in m.load), default='?'))} | "
              f"replay {checked - len(bad)}/{checked} | {'OK' if not problems else problems[:2]}{' | FAIL ' + str(m.fails) if m.fails else ''}")
    # Runs and the condition table cover the standard build only (versions 2xx); test and golden builds are 9xxx.
    rows = run_rows([m for m in matches if m.header.get("version", 0) < 1000])
    if show_runs:
        for r in rows:
            tr, ev = r["train"], r["eval"]
            print(f"  {r['match'][-12:-4]} bot {r['bot']} run {r['run']} {ns.CONDITION_NAMES[r['cond']]:<24} side {r['side']} complete {r['complete']}{'c' if r['capped'] else ' '} "
                  f"train {len(tr):>3} goal {sum(e['outcome'] == 1 for e in tr):>3} fell {sum(e['outcome'] == 2 for e in tr):>3} timeout {sum(e['outcome'] == 3 for e in tr):>3} "
                  f"first goal {first_goal(tr)} | eval {sum(e['outcome'] == 1 for e in ev)}/{len(ev)} | "
                  f"steps {r['steps']} slips {r['slips']} {(r['seconds'] / r['steps']) if r['steps'] else float('nan'):.2f} s/step")
    table = condition_table(rows)
    print(f"\n{'condition':<24} runs done  falls/100  timeouts/100  last-40 return  edge m  first goal  eval goal rate  clean evals  s/step")
    for cond, d in table.items():
        if not d.get("complete"):
            print(f"{d['name']:<24} {d['runs']:>4} {d['complete']:>4}")
            continue
        print(f"{d['name']:<24} {d['runs']:>4} {d['complete']:>4}  {d['falls_per_100']:>9.1f}  {d['timeouts_per_100']:>12.1f}  {d['last_mean_return']:>14.1f}  {d['last_edge']:>6.2f}  "
              f"{str(d['first_goal_median']):>10}  {d.get('eval_goal_rate', float('nan')):>14.2f}  {str(d.get('eval_clean_runs', '-')) + '/' + str(d.get('eval_runs', '-')):>11}  {d['sec_per_step']:.2f}")
    if json_out:
        Path(json_out).write_text(json.dumps({"matches": len(matches), "conditions": table}, indent=1, default=str))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
