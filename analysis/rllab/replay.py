"""Check the in-game learning updates against the reference maths.

With "Log every step to the Inspector" on, the game writes one STEP line per
action: state, action, reward, next state, next action, and the Q-value before
and after its own update. This module starts from an empty table, applies the
reference update to the same transitions, and compares every number the game
logged with the number the reference gets.

It replays what happened. It does not simulate the environment.

Usage:  python -m rllab.replay data/logs/<file>.txt [...]
"""

from __future__ import annotations

import sys
from collections import defaultdict
from dataclasses import dataclass, field

from . import reference
from .logs import ALGOS, LabLog, parse_log

# The Workshop prints numbers rounded to two decimals, so a logged value can sit
# up to 0.005 away from the true one. The game stores 32-bit floats; allow for that too.
TOLERANCE = 0.0051 + 1e-3


@dataclass
class ReplayReport:
    steps_checked: int = 0
    updates_checked: int = 0
    episodes_checked: int = 0
    mismatches: list[str] = field(default_factory=list)
    explore_steps: int = 0
    training_steps: int = 0
    by_algo: dict = field(default_factory=lambda: defaultdict(int))

    @property
    def ok(self) -> bool:
        return not self.mismatches and self.steps_checked > 0


def replay(log: LabLog, tolerance: float = TOLERANCE) -> ReplayReport:
    report = ReplayReport()
    headers = {(r["file"], r["run"]): r for r in log.run}
    episodes = {(e["file"], e["run"], e["episode"]): e for e in log.ep}
    tables: dict[tuple, dict[tuple[int, int], float]] = {}
    returns: dict[tuple, float] = defaultdict(float)
    counts: dict[tuple, int] = defaultdict(int)

    def bad(message: str) -> None:
        if len(report.mismatches) < 50:
            report.mismatches.append(message)

    for step in log.step:
        run_key = (step["file"], step["run"])
        ep_key = (step["file"], step["run"], step["episode"])
        where = f"{step['file']} run {step['run']} episode {step['episode']} step {step['step']}"
        header = headers.get(run_key)
        episode = episodes.get(ep_key)
        if header is None:
            bad(f"{where}: no RUN header for this run")
            continue
        if episode is None:
            # The log ended in the middle of this episode: its alpha and gamma were never written.
            continue
        q_init = float(header["q_init"])
        n_actions = int(header["n_actions"])
        table = tables.setdefault(run_key, {})

        def q(state: int, action: int) -> float:
            return table.get((state, action), q_init)

        alpha = episode["alpha_milli"] / 1000.0
        gamma = episode["gamma_milli"] / 1000.0
        training = episode["mode"] == 0
        s, a, r, s2, a2 = step["s"], step["a"], float(step["r"]), step["s2"], step["a2"]
        terminal = bool(step["terminal"])

        report.steps_checked += 1
        returns[ep_key] += r
        counts[ep_key] += 1

        if abs(q(s, a) - float(step["q_old"])) > tolerance:
            bad(f"{where}: Q(s,a) before the update is {step['q_old']} in the game, {q(s, a):.4f} in the replay")

        next_row = [q(s2, action) for action in range(n_actions)]
        target = reference.td_target(episode["algo"], r, gamma, next_row, a2, terminal, n_actions)
        if abs(target - float(step["target"])) > tolerance:
            bad(f"{where}: target is {step['target']} in the game, {target:.4f} in the replay ({ALGOS[episode['algo']]})")

        if training:
            new_value = reference.td_update(q(s, a), alpha, target)
            table[(s, a)] = new_value
            report.updates_checked += 1
            report.training_steps += 1
            report.explore_steps += int(bool(step["explore"]))
            report.by_algo[ALGOS[episode["algo"]]] += 1
        else:
            new_value = q(s, a)
        if abs(new_value - float(step["q_new"])) > tolerance:
            bad(f"{where}: Q(s,a) after the update is {step['q_new']} in the game, {new_value:.4f} in the replay")

    for ep_key, total in returns.items():
        episode = episodes[ep_key]
        report.episodes_checked += 1
        if counts[ep_key] != episode["steps"]:
            bad(f"{ep_key}: {counts[ep_key]} STEP lines but the EP line says {episode['steps']} steps")
        elif abs(total - float(episode["ret"])) > tolerance * max(1, counts[ep_key]):
            bad(f"{ep_key}: rewards sum to {total:.2f} but the EP line says return {episode['ret']}")

    # Logged Q-table dumps must agree with the replayed table at that point only if
    # the dump was written at the end of the log; they are checked in the tests instead.
    return report


def main(argv: list[str]) -> int:
    if not argv:
        print(__doc__)
        return 2
    log = parse_log(*argv)
    report = replay(log)
    print(f"files: {len(argv)}   STEP lines checked: {report.steps_checked}   updates checked: {report.updates_checked}")
    print(f"episodes whose return and step count were re-added: {report.episodes_checked}")
    for name, count in sorted(report.by_algo.items()):
        print(f"  {name}: {count} training updates")
    if report.training_steps:
        share = report.explore_steps / report.training_steps
        print(f"exploratory draws: {report.explore_steps} of {report.training_steps} training steps ({share:.1%})")
    if log.skipped:
        print(f"WARNING: {len(log.skipped)} RLLAB lines could not be parsed; first: {log.skipped[0]}")
    if report.steps_checked == 0:
        print("FAILED: no STEP lines found. Turn on 'Log every step to the Inspector' and run again.")
        return 1
    if report.mismatches:
        print(f"FAILED: {len(report.mismatches)} mismatches (first 10 shown)")
        for line in report.mismatches[:10]:
            print("  " + line)
        return 1
    print("OK: every logged target and Q-value matches the reference update.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
