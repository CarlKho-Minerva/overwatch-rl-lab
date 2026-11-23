# The course games: one Workshop mode per lecture

Each lecture of the course has its own custom game, played by a person, with that lecture's page open beside it. The
lecturer states an idea in theory; the page then says Alt+Tab, and the game is waiting at the same numbered stop to
show what he meant. The player is the agent, the opponent, the teacher or the critic; before each reveal the game asks
for a prediction. Every game is built on something an Overwatch player already knows.

**Stops** is how many numbered stops the game shares with its page ([course/](../../course/README.md)). The linked
file holds the page's text for each one: what the lecturer has just said, what to do in the game, what to commit to
first, and what was just seen. The game waits at every stop for as long as the reader takes.

| # | Game | Lecture | The Overwatch metaphor | Stops | Run by a stand-in bot | Server load (average, peak in play, peak at the start) | Played with real keys | Paste this into a custom game |
|---|---|---|---|---|---|---|---|---|
| 1 | [No Coach](g01.md) | Introduction to Reinforcement Learning | Your first minutes on a new map, with no callouts, no coach and only the scoreboard. | [7](g01_stops.json) | yes, 2026-11-22 13:41 | 4, peak 21, start 135 | yes, 2026-11-22 14:26, 6 answers | `../compiled/game-01.txt` |
| 2 | [Mini or Mega](g02.md) | Markov decision processes | The mini health pack close by against the mega across the map: take the small thing now, or walk for the big one. | [8](g02_stops.json) | yes, 2026-11-22 13:43 | 6, peak 44, start 118 | yes, 2026-11-22 14:20, 7 answers | `../compiled/game-02.txt` |
| 3 | [The Whiteboard](g03.md) | Planning by Dynamic Programming | The coach's whiteboard before the round: the whole plan, worked out before anyone leaves spawn. | [7](g03_stops.json) | yes, 2026-11-22 13:44 | 6, peak 45, start 137 | yes, 2026-11-22 14:23, 6 answers | `../compiled/game-03.txt` |
| 4 | [Back From Spawn](g04.md) | Model-Free Prediction | The walk back from spawn: re-guess your arrival at every corner, or find out when you get there. | [8](g04_stops.json) | yes, 2026-11-22 13:46 | 4, peak 21, start 113 | yes, 2026-11-22 14:39, 5 answers | `../compiled/game-04.txt` |
| 5 | [Slippery Boots](g05.md) | Model-Free Control | Holding a ledge with an enemy Lucio around: do you plan for the boops you will take, or for the player you wish you were? | [6](g05_stops.json) | yes, 2026-11-22 13:47 | 5, peak 56, start 122 | yes, 2026-11-22 14:33, 5 answers | `../compiled/game-05.txt` |
| 6 | [Callouts](g06.md) | Value Function Approximation | Callouts: "mid is hot" covers many exact spots, so one sighting tells the team about a whole area. | [6](g06_stops.json) | yes, 2026-11-22 13:48 | 5, peak 40, start 130 | yes, 2026-11-22 14:12, 6 answers | `../compiled/game-06.txt` |
| 7 | [Counter-Pick](g07.md) | Policy Gradient | Counter-picking, against a bot that is quietly learning to counter-pick you. | [8](g07_stops.json) | yes, 2026-11-22 13:50 | 7, peak 33, start 127 | yes, 2026-11-22 14:05, 5 answers | `../compiled/game-07.txt` |
| 8 | [Recall](g08.md) | Integrating Learning and Planning | Tracer's Recall rewinds her; the replaying bot does Recall on its memory, over and over. | [6](g08_stops.json) | yes, 2026-11-22 13:51 | 9, peak 40, start 117 | yes, 2026-11-22 14:29, 5 answers | `../compiled/game-08.txt` |
| 9 | [Loot Boxes](g09.md) | Exploration and Exploitation | Loot boxes with hidden odds and a fixed number of opens: stick to your main, or try a hero that might be better. | [8](g09_stops.json) | yes, 2026-11-22 13:53 | 5, peak 23, start 135 | yes, 2026-11-22 14:09, 5 answers | `../compiled/game-09.txt` |
| 10 | [The Peek](g10.md) | Classic Games | Peeking a Widowmaker: the fast left flank or the safe right corner, while she scopes one. | [6](g10_stops.json) | yes, 2026-11-22 13:55 | 5, peak 23, start 121 | yes, 2026-11-22 14:45, 6 answers | `../compiled/game-10.txt` |
| 11 | [Sombra's Room](g11.md) | The wall she cannot see (partial observability) | Your ping is Hanzo's sonic arrow, except this one is right only 8 times in 10. | [7](g11_stops.json) | yes, 2026-11-22 13:56 | 4, peak 25, start 122 | yes, 2026-11-22 14:16, 6 answers | `../compiled/game-11.txt` |

## Loading a game

Create a custom game, open Settings, and paste the contents of the game's file from `workshop/compiled/` (copy the
whole file, then press the paste button in the Summary panel). Start the match. The game gives you its hero and tells
you the controls on screen. Answers to its questions are left click, right click and melee.

## How a game is checked

A person cannot be scripted, so every game has a second build (`gNN_auto.opy`) in which a bot stands in for the
player and makes a fixed sequence of choices. That build is loaded into the real game; it runs the whole game, checks
its own arithmetic with self-test lines, and writes a log. `analysis/tests/test_game_NN.py` recomputes the game's
numbers from that log (`data/logs/games/`). "Run by a stand-in bot" in the table means that run reached its closing
line with every self-test passing and its test passed.

**Server load** is the game's own reading (a percentage of what the game allows a mode; its warning line is 100),
taken once a second for the whole game, from the hand-played run where there is one. "Peak in play" is the highest
reading after the first 10 seconds. "Peak at the start" is the burst in those first seconds, when the engine starts
the map and every rule sets up at once.

**Played with real keys** is a second check, on the build a person plays (the one in the last column). A script on
another machine sent real key presses and mouse buttons to the game window, walked the player by holding W, A, S and
D, answered every question, and confirmed each step in the game's log (`data/logs/games/gNN_play_<time>.txt`). It
shows that the buttons, the walking and every wait work for a person. It does not show that a person finds the game
clear or fun: only a person playing can say that. The shared core is `common.opy`; the log format is at the top of
that file and in `analysis/rllab/games.py`.
