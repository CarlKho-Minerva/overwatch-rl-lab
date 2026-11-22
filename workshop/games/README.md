# The course games: one Workshop mode per lecture

Each lecture of the course has its own custom game, played by a person. The player is the agent, the opponent, the
teacher or the critic; before each reveal the game asks for a prediction; the idea is met in the hands first and named
after. Every game is built on something an Overwatch player already knows.

| # | Game | Lecture | The Overwatch metaphor | Run by a stand-in bot | Server load (average, peak in play, peak at the start) | Played with real keys | Paste this into a custom game |
|---|---|---|---|---|---|---|---|
| 1 | [No Coach](g01.md) | Introduction to Reinforcement Learning | Your first minutes on a new map with no callouts and no coach, only the scoreboard. | yes, 2026-11-22 11:55 | 4, peak 19, start 85 | yes, 2026-11-22 13:04, 6 answers | `../compiled/game-01.txt` |
| 2 | [Mini or Mega](g02.md) | Markov decision processes | The mini health pack close by against the mega across the map: take the small thing now, or walk for the big one. Worths 15 and 50 (75 and 250 health, | yes, 2026-11-22 11:56 | 6, peak 42, start 129 | yes, 2026-11-22 12:33, 7 answers | `../compiled/game-02.txt` |
| 3 | [The Whiteboard](g03.md) | Planning by Dynamic Programming | Drawing the dive on the whiteboard before the round. | yes, 2026-11-22 11:57 | 5, peak 41, start 147 | yes, 2026-11-22 12:37, 6 answers | `../compiled/game-03.txt` |
| 4 | [Back From Spawn](g04.md) | Model-Free Prediction | The walk back from spawn to the fight: you re-guess your arrival at every corner, or only find out when you get there. Silver's "driving home" example | yes, 2026-11-22 11:59 | 4, peak 29, start 133 | yes, 2026-11-22 12:58, 5 answers | `../compiled/game-04.txt` |
| 5 | [Slippery Boots](g05.md) | Model-Free Control | Holding a ledge while an enemy Lucio is around. Do you plan for the boops you will take, or for the player you wish you were? | yes, 2026-11-22 12:01 | 7, peak 61, start 128 | yes, 2026-11-22 12:46, 5 answers | `../compiled/game-05.txt` |
| 6 | [Callouts](g06.md) | Value Function Approximation | Callouts. "Mid is hot" is three words for many exact spots: one sighting tells the team about a whole area. Fast, and sometimes wrong. | yes, 2026-11-22 12:02 | 4, peak 37, start 120 | yes, 2026-11-22 12:26, 6 answers | `../compiled/game-06.txt` |
| 7 | [Counter-Pick](g07.md) | Policy Gradient | Counter-picking. Here Tracer beats Widowmaker, Widowmaker beats Pharah, Pharah beats Tracer; the screen says this is the game's rule, not a claim abou | yes, 2026-11-22 12:03 | 8, peak 37, start 139 | yes, 2026-11-22 12:19, 5 answers | `../compiled/game-07.txt` |
| 8 | [Recall](g08.md) | Integrating Learning and Planning | Tracer's Recall rewinds her; the replaying bot does Recall on its memory. The moving gap is the enemy rotating: your read on their setup goes stale. | yes, 2026-11-22 12:04 | 11, peak 53, start 139 | yes, 2026-11-22 12:42, 5 answers | `../compiled/game-08.txt` |
| 9 | [Loot Boxes](g09.md) | Exploration and Exploitation | Loot boxes with hidden odds and a fixed number of opens: sticking to your main, or trying a hero that might be better. | yes, 2026-11-22 12:06 | 6, peak 27, start 122 | yes, 2026-11-22 12:23, 5 answers | `../compiled/game-09.txt` |
| 10 | [The Peek](g10.md) | Classic Games | Peeking a Widowmaker: you swing the fast left flank or the safe right corner, she holds her scope on one. What you win, she loses. | yes, 2026-11-22 12:07 | 7, peak 28, start 139 | yes, 2026-11-22 12:15, 6 answers | `../compiled/game-10.txt` |
| 11 | [Sombra's Room](g11.md) | The wall she cannot see (partial observability) | An invisible Sombra waits in one of two rooms. Your ping is Hanzo's sonic arrow, right 8 times in 10. In the last round it is Widowmaker's infra-sight | yes, 2026-11-22 12:09 | 4, peak 20, start 121 | yes, 2026-11-22 12:30, 6 answers | `../compiled/game-11.txt` |

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
