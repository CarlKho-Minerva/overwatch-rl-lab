"""The second check of each course game: the build a person plays, played to its end with real input.

A script on another machine sent real key presses and mouse buttons to the game window, walked the player by holding
W, A, S and D, and answered every question. Each saved log (data/logs/games/gNN_play_<time>.txt) must show that the
human build ran from its header to its closing line, that its self-tests passed, that every question was answered by
a button (not by its 90 second timeout), and that the server load during play stayed clear of 100, where the game
may shut a mode down. The newest automatic log gets the same load check. A game with no log of a kind is skipped, not
passed.

The load line holds two peaks. The first 10 seconds of a match are their own thing (the engine starts the map and
every rule sets up at once) and are reported, with a looser limit: a burst of a second or two there has never ended a
match in this project, while a load that stays near 100 during play is what the game's own warning is about.
"""
import pytest

from rllab import games

LOAD_LIMIT = 100        # the game's own reading, a percentage; "approaches or exceeds 100" is its warning line
START_LIMIT = 200       # the burst in a match's first 10 seconds: reported, and only an outright runaway fails
GAMES = range(1, 12)


@pytest.mark.parametrize("n", GAMES)
def test_played_with_real_input(n):
    path = games.newest(n, auto=False)
    if path is None:
        pytest.skip(f"game {n} has no log from a real-input play")
    log = games.parse(path)
    assert log["M"] and log["M"][0]["autoplay"] == 0, "this log is not from the build a person plays"
    assert games.problems(log, n) == []
    unanswered = [a["qid"] for a in log["A"] if a["answer"] is None or a["answer"] < 0]
    assert unanswered == [], f"questions that timed out with no button: {unanswered}"
    assert log["L"], "no server load line"
    assert log["L"][-1]["samples"] >= 30, "the load was sampled for under 30 seconds"
    assert log["L"][-1]["load_peak"] < LOAD_LIMIT
    assert log["L"][-1]["load_start"] is not None and log["L"][-1]["load_start"] < START_LIMIT


@pytest.mark.parametrize("n", GAMES)
def test_load_in_the_automatic_run(n):
    path = games.newest(n)
    if path is None:
        pytest.skip(f"game {n} has no automatic log")
    log = games.parse(path)
    assert log["L"], "no server load line"
    assert log["L"][-1]["samples"] >= 15, "the load was sampled for under 15 seconds"
    assert log["L"][-1]["load_peak"] < LOAD_LIMIT
    assert log["L"][-1]["load_start"] is not None and log["L"][-1]["load_start"] < START_LIMIT
