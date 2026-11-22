"""Game 0, the core check: the shared core of the course games, proven in the real game."""
import pytest

from rllab import games

LOG = games.newest(0)


def test_bayes_reference():
    assert abs(0.8 * 0.8 / (0.8 * 0.8 + 0.2 * 0.2) - 0.941) < 0.001


@pytest.mark.skipif(LOG is None, reason="no saved log of game 0 in data/logs/games")
def test_core_check_log():
    log = games.parse(LOG)
    assert games.problems(log, 0, min_questions=1, min_selftests=2) == []
    assert log["M"][0]["autoplay"] == 1
    assert games.events(log, "pad")[0][0] is True and games.events(log, "home")[0][0] is True
    assert log["A"][0]["right"] == 1
