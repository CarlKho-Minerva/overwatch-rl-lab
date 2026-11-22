# Night School: ten bots, sixteen methods, no hands

The first build of this lab runs one Tracer and one method at a time, and a person switches between them.
The Night School build (`workshop/night/`, compiled to `workshop/compiled/night-school.txt`) runs ten Tracer
bots at once on two mirrored strips, gives each its own table and method, schedules runs and greedy
evaluation itself, and restarts the match when a block is done. It is meant to be left running.

Import it exactly like the standard build (`docs/setup.md`). Six seconds after the match starts the bots
spawn; nothing needs to be pressed, and the host needs no hero-select click.

## What a block is

- Ten bots: five on the island's -z edge (Team 1, "top" on the overhead camera) and five on the +z edge
  (Team 2, "bottom", mirrored).
- Each bot does **runs**. A run is one condition from the table below: 150 training episodes (or 18 minutes,
  whichever comes first), then 10 greedy evaluation episodes with learning frozen, then its tables are logged.
- A bot's condition for a run is `(bot index + offset + run number) mod 16`. The offset is drawn at random
  when the match starts, so across matches every bot meets every condition and no condition is tied to one
  bot or one edge. The Workshop has no random seed; the offset is in the log.
- No bot starts a new run after 14 minutes. When every bot has finished, the script logs a closing line and
  restarts the match. A new match starts a new log file.

## The conditions

All use reward -1 per step, +50 goal, -100 fall, -50 timeout at 100 steps, discount 1.

| # | Name on the bot | Method | Settings | Lecture |
|---|---|---|---|---|
| 0 | SARSA | SARSA | alpha 0.5, epsilon 0.1 | 5 |
| 1 | Q-LEARNING | Q-learning | alpha 0.5, epsilon 0.1 | 5 |
| 2 | EXPECTED SARSA | Expected SARSA | alpha 0.5, epsilon 0.1 | 5 |
| 3 | Q + FADING EXPLORATION | Q-learning | epsilon = 1 / (1 + episode / 5), floor 0.01 | 5, 9 |
| 4 | Q + OPTIMISM | Q-learning | every Q starts at 40, epsilon 0 | 9 |
| 5 | DYNA-Q | Dyna-Q | 20 planning updates per real step, epsilon 0.1 | 8 |
| 6 | MONTE CARLO | every-visit Monte Carlo control | alpha 0.2, epsilon 0.1 | 4, 5 |
| 7 | SARSA LAMBDA | SARSA(lambda), replacing traces | lambda 0.8, alpha 0.3, epsilon 0.1 | 4, 5 |
| 8 | Q + COUNT BONUS | Q-learning | bonus 10 / sqrt(visits + 1), epsilon 0 | 9 |
| 9 | RANDOM WALK | uniform random policy; TD(0) and Monte Carlo value tables | TD alpha 0.1; 300 episodes | 1, 2, 4 |
| 10 | PLANNER | value iteration on the grid's rules, then walks it | 40 episodes | 3 |
| 11 | POLICY GRADIENT | REINFORCE with a state baseline, softmax | step 0.02, baseline rate 0.2 | 7 |
| 12 | ACTOR-CRITIC | one-step actor-critic, softmax | actor step 0.1, critic rate 0.2 | 7 |
| 13 | MONTE CARLO + OPTIMISM | Monte Carlo control | every Q starts at 40 | 5, 9 |
| 14 | Q, 16 COARSE STATES | Q-learning told only its row and quarter of the strip | alpha 0.5, epsilon 0.1 | 6 |
| 15 | Q, ROW ONLY | Q-learning told only its row | alpha 0.5, epsilon 0.1 | 6 |

Lecture numbers are David Silver's 2015 UCL course. Settings were fixed before any run and not tuned.

## Speed

The Workshop cannot run faster than real time. Three things raise throughput: the bots run at 200% move
speed (measured 12.0 m/s, coast 0.5 m), ten learn at once, and Dyna-Q learns from replayed moves between
real steps. Move speed is a Workshop Setting; it changes the physics a little, so it is in the log header
and slips are counted (a slip is a step that did not end on the cell it aimed for).

## Log lines

Every line starts with `NS,` after the game's own `[HH:MM:SS]` stamp. Numbers print with two decimals.

| Line | Fields |
|---|---|
| `M` | version, bots, Team 1 bots, cell (m), run speed (m/s), coast (m), move speed %, evaluation episodes, step limit, evaluation step limit, gamma x1000, r_step, r_goal, r_fall, r_timeout, condition offset, spawn calls, number of conditions |
| `CAL` | floor y, x min, x max, z min, z max, grid x origin, move timeout (s) |
| `H` | bot, run, condition, algorithm, epsilon x1000 (-1000 = fading), alpha x1000, initial Q, planning steps, lambda x1000, bonus, training episodes, side (0 top, 1 bottom), seconds since block start, state detail (0 cell, 1 quarter, 2 row) |
| `E` | bot, run, episode (evaluation continues the count), mode (0 training, 1 evaluation), return, steps, outcome (1 goal, 2 fell, 3 timeout), mean distance from the edge (m), slips, seconds since block start |
| `S` | bot, run, step in run, s, a, r, s', a', terminal, explored, Q before, Q after the real step's update, target, epsilon x1000. First 30 steps of each run, one-step methods only |
| `F` | bot, run, condition, complete (1) or cut short (0), training episodes, goals, falls, timeouts, evaluation episodes, goals, falls, timeouts, real steps, slips, seconds |
| `Q` | bot, run, state, four values (action preferences for the two policy-gradient bots), visits. One line per visited state at the end of a run |
| `P` | bot, run, episode, kind (0 TD(0) values, 1 Monte Carlo values, 2 visits), row, twelve values. Random-walk bot, at episodes 10, 30, 100 and at the end |
| `V` | bot, run, sweep, largest change in that sweep. Planner |
| `L` | seconds, server load now, average, peak, episodes, real steps, estimated log bytes. Once a minute |
| `X` | reason (1 all bots done, 2 log budget, 3 time limit), seconds, episodes, real steps, estimated log bytes, server load now, average, peak. Last line of a block |
| `FAIL` | stage (`island`, `spawn`, `throttle`), details |

Actions: 0 forward, 1 back, 2 inland, 3 toward the edge.

## The Inspector stops recording, and the log file stops with it

Found on 2026-11-21. The Workshop Inspector records what a script does, and when its store is full it
stops, with no message on screen and none in the file. "Log To Inspector" lines stop reaching the log file
at that moment while the match carries on. With ten bots:

| How the script logged | The log file stopped after |
|---|---|
| Inspector recording on throughout | 80 seconds |
| Recording off, switched on around each log line | 7 minutes 43 seconds |
| Lines queued and written in one frame a second, recording on only for that frame | see `docs/verification.md` |

The single-bot build hit the same wall after about 24 minutes of per-step logging (the file stopped at
256 KB, which looked like a size limit and was not). A match restart clears the store.

So: the script queues its lines and one rule writes the queue once a second, and it keeps its own estimate
of bytes written so that a block ends well before 256 KB in any case. If you add logging, add it through the
`LOG` macro.

## Checking a log

```
cd analysis
../.venv/bin/python -m rllab.night_report <logs or folder> --runs    # one line per match, run and condition
../.venv/bin/python -m rllab.night_summary <folder> <out folder>     # summary.json and figures
../.venv/bin/python -m pytest -q tests/test_night.py                 # reference maths, golden walk, replay
```

- **Golden walk** (`workshop/night/night_golden.opy`): every bot takes the same scripted four-episode walk
  under every condition and logs its tables. `tests/test_night.py` recomputes each table with the reference
  implementation in `rllab/night.py` and compares to the two decimals the game prints. Logs of the walks run
  in the game are in `data/logs/night/`.
- **Replay**: the first 30 steps of every run of the one-step methods are recomputed from the run's starting
  table. Dyna-Q's lines are checked for arithmetic only, because its imagined updates are not logged.
- **Sanity**: episode numbers are consecutive and no run steps faster than real movement allows.

## Leaving it unattended

Nothing in this repository presses keys or clicks. The script restarts its own match. If you want a watcher
outside the game (for a restart that does not fire, or a lobby the game closes), that is your own tooling;
keep it to menus in a private custom game.
