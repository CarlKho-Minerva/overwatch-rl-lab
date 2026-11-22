# Verification record

What has been checked, how, and what has not. Session: 2026-11-21, Overwatch 2.25.1.0 (Steam,
Windows), OverPy 9.7.21. Five matches in one private lobby, about 57 minutes of match time in total.
Their log files are in `data/logs/`, and the screenshots in `docs/img/` are from the same session.

A compile proves the text is well-formed Workshop code. It says nothing about behaviour in the
game. Every line under "Run in Overwatch" was seen in the game or read from a log the game wrote.

## Run in Overwatch

| Claim | Evidence |
|---|---|
| The compiled text imports | The five test builds (`workshop/compiled/variant-*.txt`) were each pasted with the Settings paste button; mode name and Workshop Island appeared in the Summary each time. The standard build was not pasted: see the next section |
| Skirmish on Workshop Island starts and the rules run | Every match reached `STATUS: READY` in about 6 s |
| The island is measured by ray casts | `CAL` line identical in all five logs: x -20 to 20, z -20 to 20, floor 0 |
| Tracer and Widowmaker spawn as bots | Visible in every match; scoreboard shows both |
| Tracer moves under throttle control, at a measured speed | 5.98 m/s, coast 0.25 m, in all five logs |
| Scripted patrol (Milestone 1) | `2026-11-21_demo_patrol.txt`: 20 laps, each 17 steps along the planned cells, each ending on the goal, return 33 |
| Episode reset puts Tracer back on the start cell | 313 completed episodes across the logs; every one starts in state 0 |
| A step off the edge is a real fall and is scored | 78 episodes ended `FELL`; first one at match time 0:08 of the SARSA run |
| The step limit ends an episode | 1 training timeout (Q-learning, episode 5), 3 evaluation timeouts (SARSA) |
| The match clock stays frozen | Hero select showed 30:00 after a restart; HUD showed 29:59 for 26 minutes |
| The learning updates are computed correctly | Replay of 6,978 logged steps: all 6,085 updates (3,117 SARSA, 2,968 Q-learning) match the reference within the log's 0.01 rounding; all 313 episode returns re-add |
| Exploration happens at the set rate | 611 exploratory draws in 6,085 training steps: 10.0 % at epsilon 0.1 |
| The policy arrows, HUD and counters display | `docs/img/` screenshots |
| The Q-table is logged every 50 episodes | 94 `Q` lines in each long run (episodes 50 and 100) |
| Host keys: pause, train/eval, switch algorithm, new run, camera | Pause seen on the HUD; the others read from the log (evaluation episodes after Reload; `RUN` 2 with the other algorithm after Ability 2; `RUN` 3 after holding Ultimate) and a first-person screenshot after Quick Melee |
| The Workshop Settings menu lists the lab's settings | Seen in the lobby: six groups, sliders and toggles with the right defaults |
| The Inspector log file works on this install | Both switches were Off by default; after turning them On the game wrote one file per match |
| Widowmaker fires scoped shots that hit | `2026-11-21_widowmaker_sarsa.txt`: 12 hits in 11 episodes |
| One hit puts Tracer at or below half health; two kill her | State index jumps by 48 after the first hit (episode 3, step 15); 4 episodes ended `KILLED`, each with 2 hits |
| A killed Tracer is revived for the next episode | Episodes continued normally after each kill |
| Blink as a fifth action | `2026-11-21_blink_fixed_duration_qlearning.txt`: 70 Blink steps. Of the 52 that did not end the episode, 28 gained 4 columns, 19 gained 5, 3 gained fewer, and 2 gained none; those 2 were the only ones pressed with no charge left |
| Fixed-duration moves drift | Same log: of 31 unblocked forward moves, 29 gained one column and 2 gained two |

## First results (one run per algorithm, no seed: treat as a lead, not a finding)

Same settings for both: epsilon 0.1, alpha 0.5, gamma 1, step -1, goal +50, fall -100.

| | SARSA | Q-learning |
|---|---|---|
| Training episodes | 115 in 22.9 min | 119 in 21.0 min |
| First goal | episode 12 | episode 13 |
| Last 40 training episodes: mean return | +18.2 | -1.3 |
| Last 40: episodes ending in a fall | 4 (10 %) | 10 (25 %) |
| Last 40: mean distance from the edge | 3.88 m | 2.40 m |
| Last 40: median steps when the goal was reached | 17 | 15 |
| Greedy evaluation afterwards | 3 episodes, all timed out (policy loop between cells 20 and 21) | 12 episodes, all reached the goal in 13 steps, return 37 |

In words: while both were still exploring, the SARSA Tracer kept about a cell and a half further
from the drop, fell less than half as often and earned more per episode. With exploration switched
off, the Q-learning table gave a clean, short crossing and the SARSA table did not. A 4-in-40
against 10-in-40 gap can come from chance alone (two-sided Fisher exact test p = 0.14), so repeat
the runs before believing the size of it.

## Compiled and unit-tested only

- **The standard build, `workshop/compiled/overwatch-rl-lab.txt`, was never pasted into the game.**
  It is the same source as the five builds that were, with three differences: per-step logging
  defaults to Off, and the Experiment and Algorithm choices are menu entries instead of being fixed.
  Those two menu entries are the same kind of setting as "Start mode", which was seen working. The
  desktop was in use before this last check could be run.
- The last code change of the session (a new run always starts in training) was imported with the
  Widowmaker and Blink builds, but no new run was started in those matches, so that line never ran.
- The epsilon controls on Crouch + Primary / Secondary Fire. The rules compile; no key combination
  was sent in the game.
- "Start paused", "Initial Q-value" other than 0, "Game speed percent" below 100, Tracer move speed
  other than 100 %, cell size other than 2 m, gap other than 0.5 m, and reward values other than
  the defaults. The settings appear in the menu with the right defaults; none was changed.
- "Reward per hit" other than 0.
- "Tracer observes her own health" = Off (Lab 05's run B).
- The calibration fallback for a map with no floor under the origin, and the red status lines for
  a wrong map, missing bot slots or a Tracer that does not move.

## Not checked

- More than one human in the lobby, a spectating host, or a host on Team 2.
- Sessions longer than 26 minutes of match time. The server-load shutdown was never triggered, but
  nothing here shows it cannot be.
- Carrying a Q-table across a match restart through the Inspector's copy button.
- Any game version other than 2.25.1.0, and any text language other than English.
- Repeats. Every result above is a single run.

## How to repeat the checks

```powershell
npm run build
.venv\Scripts\python -m pytest -q                                   # 25 tests
cd analysis; ..\.venv\Scripts\python -m rllab.replay (Get-ChildItem ..\data\logs\*.txt)
```
