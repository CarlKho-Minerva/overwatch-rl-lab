"""The analysis set must hold real play only, each match once."""

from pathlib import Path

import pytest

from rllab.logs import parse_log
from rllab.sanity import duplicate_matches, too_fast_episodes

ROOT = Path(__file__).resolve().parents[2]
LOGS = sorted((ROOT / "data" / "logs").glob("*.txt"))
BOT_LOST = ROOT / "data" / "logs" / "diagnostics" / "2026-11-21_warm_start_sarsa_then_tracer_bot_displaced_at_0209.txt"


@pytest.mark.skipif(not LOGS, reason="no real logs in data/logs yet")
def test_no_episode_in_the_analysis_set_is_impossibly_fast():
    fast = too_fast_episodes(parse_log(*LOGS))
    assert not fast, [(e["file"], e["run"], e["episode"], round(e["seconds_per_step"], 3)) for e in fast[:5]]


@pytest.mark.skipif(not LOGS, reason="no real logs in data/logs yet")
def test_no_match_is_in_the_analysis_set_twice():
    assert duplicate_matches(parse_log(*LOGS)) == []


@pytest.mark.skipif(not BOT_LOST.exists(), reason="diagnostic log not present")
def test_the_check_catches_the_real_bot_loss_log():
    # Episodes 1 to 6 are real. The Tracer bot was displaced during episode 7 (match time 2:09), so that
    # episode is part play, part not, and escapes the pace test; every episode from 8 on is caught.
    log = parse_log(BOT_LOST)
    fast = too_fast_episodes(log)
    assert len(fast) >= 20
    assert min(e["episode"] for e in fast) == 8


def test_duplicate_detection_on_a_copied_file(tmp_path):
    line = "[00:00:0{n}] RLLAB,EP,1,{n},0,0,100,500,1000,-10{n},{n},2,1.5,0,{n}.25\n"
    body = "".join(line.format(n=n) for n in (1, 2, 3))
    (tmp_path / "a.txt").write_text(body, encoding="utf-8")
    (tmp_path / "b.txt").write_text(body + "[00:00:09] RLLAB,EP,1,4,0,0,100,500,1000,-104,4,2,1.5,0,9.25\n", encoding="utf-8")
    assert duplicate_matches(parse_log(tmp_path / "a.txt", tmp_path / "b.txt")) == [("a.txt", "b.txt")]
