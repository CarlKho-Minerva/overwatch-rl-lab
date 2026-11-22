# The course games: one Workshop mode per lecture

Each lecture of the course has its own custom game, played by a person. The player is the agent, the opponent, the
teacher or the critic; before each reveal the game asks for a prediction; the idea is met in the hands first and named
after. Every game is built on something an Overwatch player already knows.

| # | Game | Lecture | The Overwatch metaphor | Checked in the real game | Paste this into a custom game |
|---|---|---|---|---|---|
| 1 | [No Coach](g01.md) | Introduction to Reinforcement Learning | Your first minutes on a new map with no callouts and no coach, only the scoreboard. | yes, 2026-11-22 09:45 | `../compiled/game-01.txt` |
| 2 | [Mini or Mega](g02.md) | Markov decision processes | The mini health pack close by against the mega across the map: take the small thing now, or walk for the big one. Worths 15 and 50 (75 and 250 health, | yes, 2026-11-22 09:46 | `../compiled/game-02.txt` |
| 3 | [The Whiteboard](g03.md) | Planning by Dynamic Programming | Drawing the dive on the whiteboard before the round. | yes, 2026-11-22 09:47 | `../compiled/game-03.txt` |
| 4 | [Back From Spawn](g04.md) | Model-Free Prediction | The walk back from spawn to the fight: you re-guess your arrival at every corner, or only find out when you get there. Silver's "driving home" example | yes, 2026-11-22 09:49 | `../compiled/game-04.txt` |
| 5 | [Slippery Boots](g05.md) | Model-Free Control | Holding a ledge while an enemy Lucio is around. Do you plan for the boops you will take, or for the player you wish you were? | yes, 2026-11-22 09:51 | `../compiled/game-05.txt` |
| 6 | [Callouts](g06.md) | Value Function Approximation | Callouts. "Mid is hot" is three words for many exact spots: one sighting tells the team about a whole area. Fast, and sometimes wrong. | yes, 2026-11-22 09:52 | `../compiled/game-06.txt` |
| 7 | [Counter-Pick](g07.md) | Policy Gradient | Counter-picking. Here Tracer beats Widowmaker, Widowmaker beats Pharah, Pharah beats Tracer; the screen says this is the game's rule, not a claim abou | yes, 2026-11-22 09:53 | `../compiled/game-07.txt` |
| 8 | [Recall](g08.md) | Integrating Learning and Planning | Tracer's Recall rewinds her; the replaying bot does Recall on its memory. The moving gap is the enemy rotating: your read on their setup goes stale. | yes, 2026-11-22 09:54 | `../compiled/game-08.txt` |
| 9 | [Loot Boxes](g09.md) | Exploration and Exploitation | Loot boxes with hidden odds and a fixed number of opens: sticking to your main, or trying a hero that might be better. | yes, 2026-11-22 09:55 | `../compiled/game-09.txt` |
| 10 | [The Peek](g10.md) | Classic Games | Peeking a Widowmaker: you swing the fast left flank or the safe right corner, she holds her scope on one. What you win, she loses. | yes, 2026-11-22 09:56 | `../compiled/game-10.txt` |
| 11 | [Sombra's Room](g11.md) | The wall she cannot see (partial observability) | An invisible Sombra waits in one of two rooms. Your ping is Hanzo's sonic arrow, right 8 times in 10. In the last round it is Widowmaker's infra-sight | yes, 2026-11-22 09:58 | `../compiled/game-11.txt` |

## Loading a game

Create a custom game, open Settings, and paste the contents of the game's file from `workshop/compiled/` (copy the
whole file, then press the paste button in the Summary panel). Start the match. The game gives you its hero and tells
you the controls on screen. Answers to its questions are left click, right click and melee.

## How a game is checked

A person cannot be scripted, so every game has a second build (`gNN_auto.opy`) in which a bot stands in for the
player and makes a fixed sequence of choices. That build is loaded into the real game; it runs the whole game, checks
its own arithmetic with self-test lines, and writes a log. `analysis/tests/test_game_NN.py` recomputes the game's
numbers from that log (`data/logs/games/`). "Checked" in the table means that run reached its closing line with every
self-test passing and its test passed. It does not mean a person has found the game fun, or clear. The shared core is
`common.opy`; the log format is at the top of that file and in `analysis/rllab/games.py`.
