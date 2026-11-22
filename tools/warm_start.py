"""Carry a learned Q-table into a new match.

The Workshop forgets every variable when a match restarts. This tool turns the
Workshop Inspector's own export into a build that starts from that table.

1. In the match you want to keep: Esc > Open Workshop Inspector, click the last
   icon in the row under the timeline, the one marked (x). It copies every
   variable to the clipboard.
2. Run:   python tools/warm_start.py            (reads the clipboard)
      or  python tools/warm_start.py saved.txt  (reads a saved copy)
3. Paste the result into Overwatch (Settings > paste > Confirm) and start.
   The tool leaves the compiled build on the clipboard and in
   workshop/compiled/variant-warm-start.txt.

Only the Q-table is carried over. Counters, the algorithm and every setting
come from the build and the Workshop Settings menu as usual.
"""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TABLE_SIZE = 960  # 192 states x 5 actions


def read_clipboard() -> str:
    result = subprocess.run(
        ["powershell.exe", "-NoProfile", "-Command", "Get-Clipboard -Raw"],
        capture_output=True, text=True, encoding="utf-8",
    )
    if result.returncode:
        raise SystemExit("Could not read the clipboard: " + result.stderr.strip())
    return result.stdout


def parse_q(text: str) -> list[float]:
    match = re.search(r"Global\.Q\s*=\s*Array\((.*?)\);", text, re.S)
    if not match:
        raise SystemExit("No 'Global.Q = Array(...)' line found. Copy the variables with the Inspector's (x) button first.")
    try:
        values = [float(item) for item in match.group(1).split(",")]
    except ValueError as error:
        raise SystemExit(f"The Q-table holds something that is not a number: {error}")
    if len(values) != TABLE_SIZE:
        raise SystemExit(f"Expected {TABLE_SIZE} Q-values, found {len(values)}. Was this copied from the Overwatch RL Lab?")
    return values


def main(argv: list[str]) -> int:
    text = Path(argv[0]).read_text(encoding="utf-8-sig") if argv else read_clipboard()
    values = parse_q(text)
    learned = sum(1 for value in values if value != 0)
    literal = ", ".join(f"{value:g}" for value in values)
    variant = ROOT / "workshop" / "variants" / "warm_start.opy"
    variant.write_text(
        "/* Variant written by tools/warm_start.py: the standard build, starting from a carried-over Q-table. */\n\n"
        "#!allowMacroRedeclaration\n"
        '#!include "../defaults.opy"\n\n'
        "#!define WARM_START true\n"
        "#!define DEF_LOG_STEPS true\n"
        f"#!define WARM_Q [{literal}]\n\n"
        '#!include "../lab.opy"\n',
        encoding="utf-8",
        newline="\n",
    )
    build = subprocess.run(
        ["node", "tools/build.mjs", "workshop/variants/warm_start.opy"],
        cwd=ROOT, capture_output=True, text=True, encoding="utf-8",
    )
    print(build.stdout.strip())
    if build.returncode:
        print(build.stderr.strip())
        raise SystemExit("The warm-start build did not compile.")
    compiled = ROOT / "workshop" / "compiled" / "variant-warm-start.txt"
    subprocess.run(
        ["powershell.exe", "-NoProfile", "-Command", f"Get-Content -Raw '{compiled}' -Encoding UTF8 | Set-Clipboard"],
        check=True,
    )
    print(f"Carried over {learned} learned Q-values (of {TABLE_SIZE}). The build is on the clipboard and in {compiled}.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
