"""Checks that a log describes real play, not a script running on a missing bot.

On 2026-11-21 a player was moved onto the Tracer bot's lobby slot, which removed the bot. The script
(before the guard added that day) kept going: every "move" returned at once, so it logged 100-step
episodes that took two seconds. The learning maths in those lines is self-consistent, so the replay
check cannot see the problem. Time can: a real move takes about 0.45 s, and even a blocked move
takes 0.064 s.

Usage:  python -m rllab.sanity data/logs/<file>.txt [...]
"""

from __future__ import annotations

import sys

from .logs import LabLog, parse_log

# Seconds per step below which an episode cannot have been played by a bot that exists.
MIN_SECONDS_PER_STEP = 0.05
MIN_STEPS = 5


def too_fast_episodes(log: LabLog) -> list[dict]:
    """Episodes whose time per step is impossibly short. Each gets a `seconds_per_step` field."""
    previous: dict[tuple, float] = {}
    starts = {(r["file"], r["run"]): r["clock"] for r in log.run}
    flagged = []
    for episode in log.ep:
        key = (episode["file"], episode["run"])
        began = previous.get(key, starts.get(key))
        previous[key] = episode["t"]
        if began is None or episode["steps"] < MIN_STEPS:
            continue
        pace = (episode["t"] - began) / episode["steps"]
        if pace < MIN_SECONDS_PER_STEP:
            flagged.append({**episode, "seconds_per_step": pace})
    return flagged


def duplicate_matches(log: LabLog) -> list[tuple[str, str]]:
    """Pairs of files that hold the same match.

    When the host changes team or goes to spectate, Overwatch starts a new log file and writes the
    whole match so far into it again. Analysing both files would count every episode twice.
    """
    first_lines: dict[str, tuple] = {}
    for episode in log.ep:
        if episode["run"] == 1 and episode["episode"] <= 3:
            first_lines.setdefault(episode["file"], ())
            first_lines[episode["file"]] += ((episode["episode"], episode["ret"], episode["steps"], episode["t"]),)
    seen: dict[tuple, str] = {}
    pairs = []
    for name, signature in first_lines.items():
        if signature in seen:
            pairs.append((seen[signature], name))
        else:
            seen[signature] = name
    return pairs


def main(argv: list[str]) -> int:
    if not argv:
        print(__doc__)
        return 2
    log = parse_log(*argv)
    problems = 0
    for failure in log.fail:
        print(f"SETUP FAILURE in {failure['file']}: {failure['detail']}")
    fast = too_fast_episodes(log)
    for episode in fast[:10]:
        problems += 1
        print(
            f"TOO FAST: {episode['file']} run {episode['run']} episode {episode['episode']}: "
            f"{episode['steps']} steps at {episode['seconds_per_step']:.3f} s per step"
        )
    if len(fast) > 10:
        print(f"... and {len(fast) - 10} more too-fast episodes")
    for first, second in duplicate_matches(log):
        problems += 1
        print(f"SAME MATCH TWICE: {first} and {second} start with identical episodes; keep the longer file only")
    if not problems:
        print(f"OK: {len(log.ep)} episodes in {len(argv)} files, none impossibly fast, no match counted twice.")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
