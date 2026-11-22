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


STOPS_DIR = games.LOGS.parents[2] / "workshop" / "games"


@pytest.mark.parametrize("n", GAMES)
@pytest.mark.parametrize("auto", [True, False])
def test_stops_match_the_page(n, auto):
    """Each game is played beside its lecture's page, stop by stop. The stops the game announces (RLG,G) must be
    1, 2, ... n in order, and n must be the number of stops written for the page (workshop/games/gNN_stops.json)."""
    import json
    f = STOPS_DIR / f"g{n:02d}_stops.json"
    if not f.exists():
        pytest.skip(f"game {n} has no stops file yet")
    stops = json.loads(f.read_text(encoding="utf-8"))["stops"]
    assert [s["n"] for s in stops] == list(range(1, len(stops) + 1)) and len(stops) >= 4
    for s in stops:
        for key in ("after", "title", "silver", "do", "predict", "saw"):
            assert str(s.get(key, "")).strip(), f"stop {s['n']} has no {key}"
        text = " ".join(str(v) for v in s.values())
        assert "\u2014" not in text and "\u2013" not in text and "!" not in text, f"stop {s['n']}: a dash or an exclamation mark"
    import re
    body = (STOPS_DIR / f"g{n:02d}_body.opy").read_text(encoding="utf-8")
    assert int(re.search(r"#!define STOPS (\d+)", body).group(1)) == len(stops), "the game and its stops file disagree on how many stops"
    page = STOPS_DIR.parents[1] / "course" / (f"lecture-{n:02d}.md" if n <= 10 else "lesson-11-partial-observability.md")
    text = page.read_text(encoding="utf-8")
    assert text.count("> **Alt+Tab") == len(stops), "the course page does not carry every stop"
    order = [int(x) for x in re.findall(r"> \*\*Alt\+Tab · game \d+ · stop (\d+) of", text)]
    assert order == list(range(1, len(stops) + 1)), "the stops do not run in order down the course page"
    path = games.newest(n, auto=auto)
    if path is None:
        pytest.skip(f"game {n} has no {'automatic' if auto else 'hand-played'} log")
    log = games.parse(path)
    if not log["G"]:
        pytest.skip(f"game {n}: its newest {'automatic' if auto else 'hand-played'} log predates the stops")
    assert [g["stop"] for g in log["G"]] == list(range(1, len(stops) + 1))
