"""Checks against real logs written by Overwatch (data/logs/).

Nothing here is simulated. If the folder holds no logs with STEP lines the
replay tests are skipped, not passed.
"""

from pathlib import Path

import pytest

from rllab.logs import COLUMNS, parse_log
from rllab.replay import replay

LOG_DIR = Path(__file__).resolve().parents[2] / "data" / "logs"
LOGS = sorted(LOG_DIR.glob("*.txt"))


def test_parser_handles_a_literal_line(tmp_path):
    sample = tmp_path / "Log-sample.txt"
    sample.write_text(
        "[00:00:04] RLLAB,CAL,0,-20,20,-20,20,2,5.98,0.25,0.33\n"
        "[00:00:21] RLLAB,EP,1,3,0,0,100,500,1000,-129,29,2,4.11,0,21.25\n"
        "[00:00:22] some other workshop line\n"
        "[00:00:23] RLLAB,EP,broken\n",
        encoding="utf-8",
    )
    log = parse_log(sample)
    assert log.cal[0]["run_speed"] == pytest.approx(5.98)
    assert log.ep[0]["ret"] == -129 and log.ep[0]["outcome"] == 2 and log.ep[0]["clock"] == 21
    assert len(log.skipped) == 1, "a malformed RLLAB line must be reported, not dropped"


def test_every_record_kind_has_a_column_list():
    assert set(COLUMNS) == {"CAL", "RUN", "EP", "STEP", "Q"}


@pytest.mark.skipif(not LOGS, reason="no real logs in data/logs yet")
def test_real_logs_parse_without_skipped_lines():
    log = parse_log(*LOGS)
    assert not log.skipped, f"unparsed RLLAB lines, first: {log.skipped[:1]}"
    assert log.cal and log.run


@pytest.mark.skipif(not LOGS, reason="no real logs in data/logs yet")
@pytest.mark.parametrize("path", LOGS, ids=lambda p: p.name)
def test_in_game_updates_match_the_reference(path):
    log = parse_log(path)
    if not log.step:
        pytest.skip("this log was recorded without per-step logging")
    report = replay(log)
    assert report.steps_checked > 0
    assert not report.mismatches, "\n".join(report.mismatches[:10])


@pytest.mark.skipif(not LOGS, reason="no real logs in data/logs yet")
def test_real_island_measurement_is_stable_across_matches():
    log = parse_log(*LOGS)
    widths = {round(c["x_max"] - c["x_min"], 1) for c in log.cal}
    assert len(widths) == 1, f"the island measured differently between matches: {widths}"
