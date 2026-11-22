"""The run-level comparison: which runs count, and the exact permutation test."""

from pathlib import Path

import pytest

from rllab.compare import late_training_table, permutation_p, standard_runs
from rllab.logs import parse_log

ROOT = Path(__file__).resolve().parents[2]
LOGS = sorted((ROOT / "data" / "logs").glob("*.txt"))


def test_permutation_test_hand_cases():
    # Complete separation, 3 against 3: 2 of the 20 deals are this extreme.
    assert permutation_p([1, 2, 3], [7, 8, 9]) == pytest.approx(0.1)
    # Identical groups: every deal is at least as extreme as a gap of zero.
    assert permutation_p([5, 5], [5, 5]) == pytest.approx(1.0)
    # 2 against 2 with complete separation: 2 of 6 deals.
    assert permutation_p([0, 1], [10, 11]) == pytest.approx(2 / 6)


@pytest.mark.skipif(not LOGS, reason="no real logs in data/logs yet")
def test_only_standard_cold_start_cliff_runs_are_compared():
    log = parse_log(*LOGS)
    chosen = standard_runs(log)
    headers = {(r["file"], r["run"]): r for r in log.run}
    assert chosen
    for key in chosen:
        header = headers[key]
        assert header["experiment"] == 0 and header["use_blink"] is False and header["closed_loop"] is True
        assert header["q_init"] == 0 and header["r_fall"] == -100 and header["move_speed"] == 100
    names = {file for file, _ in chosen}
    assert not any("nondefault" in name or "widowmaker" in name or "blink" in name or "demo" in name for name in names)


@pytest.mark.skipif(not LOGS, reason="no real logs in data/logs yet")
def test_late_training_rows_are_full_runs():
    rows = late_training_table(parse_log(*LOGS))
    assert rows
    for row in rows:
        assert row["training_episodes"] >= 100 and row["late_n"] == 40
        assert 0 <= row["late_fall_rate"] <= 1
