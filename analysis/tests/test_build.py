"""The OverPy sources must compile with no warnings, and the output must contain the lab's rules.

Compiling proves the text is well-formed Workshop code. It does not prove the mode
behaves correctly in the game; docs/verification.md lists what was run in Overwatch.
"""

import shutil
import subprocess
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
NODE = shutil.which("node")


@pytest.mark.skipif(NODE is None or not (ROOT / "node_modules" / "overpy").exists(), reason="run `npm install` first")
def test_sources_compile_cleanly():
    result = subprocess.run([NODE, "tools/build.mjs"], cwd=ROOT, capture_output=True, text=True, encoding="utf-8")
    assert result.returncode == 0, result.stdout + result.stderr
    assert "0 warnings" in result.stdout


def test_compiled_text_has_the_expected_rules():
    compiled = (ROOT / "workshop" / "compiled" / "overwatch-rl-lab.txt").read_text(encoding="utf-8")
    for name in (
        "Calibration: measure the island",
        "Arena: spawn Tracer and Widowmaker",
        "Environment: carry out action curA and observe the result",
        "Agent: epsilon-greedy action for state selS",
        "Experiment: one episode",
        "Widowmaker: scripted fire",
    ):
        assert name in compiled, f"rule missing from compiled output: {name}"
    assert "Workshop Island" in compiled


def test_the_two_targets_are_the_only_difference_between_the_algorithms():
    source = (ROOT / "workshop" / "agents" / "experiment.opy").read_text(encoding="utf-8")
    assert source.count("algo == Algo.SARSA") == 1, "the algorithm must branch in exactly one place"
    assert "tdTarget = reward + gamma * Q[nextS * NA + nextA]" in source
    assert "tdTarget = reward + gamma * sorted(Q.slice(nextS * NA, nAct)).last()" in source
    # Exploration is decided in chooseAction, which must not look at the algorithm.
    agent = (ROOT / "workshop" / "agents" / "tabular.opy").read_text(encoding="utf-8")
    chooser = agent.split("def chooseAction():")[1].split("def updateGlyph():")[0]
    assert "algo" not in chooser
