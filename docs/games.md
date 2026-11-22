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
`analysis/tests/test_game_NN.py` recomputes the game's numbers from it. All eleven games were run this way in the real
game on 2026-11-22. Game 11 was also driven with real key presses and clicks. The other ten have been played only by
their stand-in, so this checks that a game runs and that its numbers are right, not that it is clear or fun.

## Log lines

```
RLG,M,<game>,<version>,<autoplay>
RLG,T,<game>,<name>,<expected>,<got>,<ok>
RLG,A,<game>,<question id>,<answer>,<correct answer>,<right>
RLG,E,<game>,<event name>,<values...>
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
- Server load was not measured for these games. The overnight lab overloaded the server by formatting long strings
  inside HUD calls every frame; the games build their strings when something changes.
