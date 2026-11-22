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

## Played beside a page, stop by stop

Each game is used together with the page for its lecture. The reader reads a part of the lecture, switches to the
game, and the game is waiting at the same numbered stop to show what the lecturer meant; then he switches back.
So a game is cut into 6 to 8 stops, and three things hold:

- `STOP(k)` (in `common.opy`) starts stop k: it shows "STOP k OF n" beside the title and logs `RLG,G`.
- At a stop the game waits for the person for as long as he likes. No wait for his input times out, a round's clock
  starts at his first move, and anything that used to start by itself (a race, bots playing each other) now starts
  on a button the game already uses, logged as `RLG,E,<game>,go,<stop>`.
- `workshop/games/gNN_stops.json` holds the page's text for each stop: what the lecturer has just said, what to do
  in the game, what to commit to first, and what was just seen. Its `after` field names the part of the lecture the
  stop follows. `analysis/tests/test_games_play.py` checks that the stops a game announces are exactly these, in order.

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
RLG,G,<game>,<stop>
RLG,Q,<game>,<question id>
RLG,A,<game>,<question id>,<answer>,<correct answer>,<right>,<seconds he took>
RLG,E,<game>,<event name>,<values...>
RLG,L,<game>,<seconds sampled>,<server load, mean>,<highest peak in play>,<highest peak in the first 10 seconds>
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
- **A match's first seconds read over the load line whatever the script does.** Restarting a custom game reads
  128 in the first ten seconds with a near-empty mode (game 0), and 128 to 165 with any of the course games. That
  burst is the match starting. The core keeps it apart from the load during play (the fifth field of `RLG,L`) and
  starts each game's own setup at 4 seconds, after it. The stand-in runs had missed the burst only because they
  began sampling a second later than the human build.
- **A button that is held when a question opens answers it.** The answer rules fire the moment their conditions are
  true, and a Tracer player holds fire out of habit. The core now waits for all three answer buttons to be let go
  before it shows a question.
- **A teleport does not turn the player.** Five games left a person looking wherever he spawned, sometimes away
  from the board. Every game now names the way he faces at the start (`HOME_FACING`), and the core sets it whenever
  it puts him home.
- **Left and right depend on where he stands.** A prompt said "the right-hand pit" for a pit that was on the left
  from the start pad. The board now labels the thing itself.
- **On Tracer the right mouse button is also Blink.** A right-click answer threw the player 7.5 m forward, off
  his pad in two games and toward the edge in a third. Disallowing secondary fire does not stop it: Blink is ability
  1. The core switches ability 1 off while a question is up (`setAbility1Enabled`, so a game that keeps Blink off
  for good with `disallowButton` is not undone), and a game that takes a right click outside a question keeps Blink
  off itself.
- **`destroyAllInWorldText` destroys everyone's text.** Three games redrew their boards with it and wiped the core's
  floating question for the rest of the game: a person saw the options row vanish after the first redraw. Games now
  remove only the text ids they made, and the core makes the question's text for each question.
- **Text drawn over text cannot be read, and the top of the screen is shared.** The left block is one column whose
  rows are centred on its widest row; the right block is the same from the right edge; a top-centre row runs into
  both. Measured at 16:9, one character takes 0.80% of the screen's width in the header slot, 0.47% in the subheader
  slot and 0.61% in the text slot. The rule the games follow: right block rows at most 58 text characters, left
  block at most 88 (110 for the coach line), no top-centre rows, progress-bar labels at most 44.
- **The log has to say when a question appears.** A script that presses before the question is up is not playing
  like a person (and on Tracer a right press is a Blink). The core writes `RLG,Q` when the question is on screen and
  the answer line now ends with the seconds the answer took.
- **A bot is never late and never holds a key down.** Three defects could only happen to a person: a pick that timed
  out into an endless repeat, a key held across two reads, a locked room that said nothing. Each was found by
  reading the human branch line by line, then by playing it.
