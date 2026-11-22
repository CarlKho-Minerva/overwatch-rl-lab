# The course games: how they are built and checked

One Workshop mode per lecture, played by a person. The index, with each game's idea and Overwatch metaphor, is
[workshop/games/README.md](../workshop/games/README.md). This page is for whoever changes a game or adds one.

## Files

- `workshop/games/common.opy`: the shared core every game includes. It provides the learner (the human host, or a
  stand-in bot), queued logging, self-tests, the prediction question, the coach line and the closing line.
- `workshop/games/gNN_body.opy`: the game. `gNN.opy` and `gNN_auto.opy` are two-line wrappers that set `AUTOPLAY` to
  false or true and include the body.
- `workshop/games/gNN.md`: the design note. `analysis/tests/test_game_NN.py`: reference maths and the log check.
- `workshop/compiled/game-NN.txt` is what a person pastes into a custom game; `game-NN-auto.txt` is the automatic check.

## The automatic check

In the `_auto` build a bot stands in for the player and makes a fixed sequence of choices, so the whole game runs in
the real game with nobody at the keyboard. The game tests its own formulas when it starts (`CHECK` lines), logs every
event the test needs, and writes a closing line. The log is saved to `data/logs/games/gNN_auto_<time>.txt` and
`analysis/tests/test_game_NN.py` recomputes the game's numbers from it. This checks that a game runs and that its
numbers are right. It never runs the lines only a person reaches: the waits for his buttons and for his walking.

## The real-input check

The stand-in never presses a key, so the build a person plays gets a second check. `hplay.py` (kept with the PC helper
scripts, outside this repository) loads `game-NN.txt` into the real game and plays it to its closing line from another
machine with real input: key presses and mouse buttons sent to the game window. It answers every question with a
button, walks by holding W, A, S and D for the time a distance takes, and confirms each step in the game's own log
before the next. The log is saved to `data/logs/games/gNN_play_<time>.txt` and `analysis/tests/test_games_play.py`
checks it: the human build's header, a closing line, no failed self-test, every question answered by a button and not
by its timeout, and the server load. The table in [workshop/games/README.md](../workshop/games/README.md) is written
from those logs and shows, for each game, when each check last passed.

What this still does not show: whether a person finds a game clear, or fun. A script that knows the answers is not a
learner.

## Log lines

```
RLG,M,<game>,<version>,<autoplay>
RLG,T,<game>,<name>,<expected>,<got>,<ok>
RLG,A,<game>,<question id>,<answer>,<correct answer>,<right>
RLG,E,<game>,<event name>,<values...>
RLG,L,<game>,<seconds sampled>,<server load, mean over the game>,<highest peak over the game>
RLG,X,<game>,<seconds>,<predictions right>,<predictions made>,<self-tests ok>,<self-tests failed>
```

`analysis/rllab/games.py` reads them. The game prints numbers to two decimals.

## What the real game taught us on the day (each cost a failed run)

- **A macro argument must not share a name with a variable.** OverPy macros are text substitution. A macro with an
  argument called `old`, in a file with a global `old`, used the global. The game's own self-test caught it
  (expected 16, got 8.50).
- **Variable names go through the game's text filter.** A build with a global whose name contained a filtered word
  would not import: "Global variable '58' has an invalid name". Rename it; the compiler does not warn.
- **A player facing +z has +x on his left.** A game with a "left room" at negative x had the two rooms the wrong way round.
- **A HUD line lays its header, subheader and text side by side.** A question with its options in one line ran off both
  edges, and long lines on the left and right of the screen reach the middle. The prediction question is now floating
  text a few metres in front of the player's eyes, which is clear of every HUD line.
- **The match clock sits under the top of the screen.** The core hides the game mode's own HUD for human players.
- **A hidden window can hold the foreground.** Not a game fact, but it stopped the checks: the helper that clicks
  through the menus refuses to click unless Overwatch is in front, and after the PC's services restarted an invisible
  window was. Minimising and restoring the game window brings it forward.
- **The game's load readings look back two seconds.** A reading taken at the closing line showed the quiet
  debrief, not the busy middle. The core now reads the average and the peak once a second for the whole game and
  writes one `RLG,L` line at the end. The overnight lab overloaded the server by formatting long strings inside HUD
  calls every frame; the games build their strings when something changes.
- **A button that is held when a question opens answers it.** The answer rules fire the moment their conditions are
  true, and a Tracer player holds fire out of habit. The core now waits for all three answer buttons to be let go
  before it shows a question.
- **A teleport does not turn the player.** Five games left a person looking wherever he spawned, sometimes away
  from the board. Every game now names the way he faces at the start (`HOME_FACING`), and the core sets it whenever
  it puts him home.
- **Left and right depend on where he stands.** A prompt said "the right-hand pit" for a pit that was on the left
  from the start pad. The board now labels the thing itself.
- **A bot is never late and never holds a key down.** Three defects could only happen to a person: a pick that timed
  out into an endless repeat, a key held across two reads, a locked room that said nothing. Each was found by
  reading the human branch line by line, then by playing it.
