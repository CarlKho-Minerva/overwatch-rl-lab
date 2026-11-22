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
| 9 | RANDOM WALK | uniform random policy; two TD(0) value tables and a Monte Carlo one | TD alpha 0.1 and 0.5; 200 episodes | 1, 2, 4 |
| 10 | PLANNER | value iteration on the grid's rules, then walks it | 40 episodes | 3 |
| 11 | POLICY GRADIENT | REINFORCE with a state baseline, softmax | step 0.02, baseline rate 0.2 | 7 |
| 12 | ACTOR-CRITIC | one-step actor-critic, softmax | actor step 0.1, critic rate 0.2 | 7 |
| 13 | MONTE CARLO + OPTIMISM | Monte Carlo control | every Q starts at 40 | 5, 9 |
| 14 | Q, 16 COARSE STATES | Q-learning told only its row and quarter of the strip | alpha 0.5, epsilon 0.1 | 6 |
| 15 | Q, ROW ONLY | Q-learning told only its row | alpha 0.5, epsilon 0.1 | 6 |

Lecture numbers are David Silver's 2015 UCL course. Settings were fixed before any run and not tuned.

## The lecture 10 build: a runner against a blocker

`workshop/compiled/night-school-duel.txt` (source `workshop/night/night_duel.opy`) puts one Q-learning runner
on each strip and a bot from the other team in its way. Before each episode the blocker picks one of the four
rows and stands in it at column 6. The game is zero-sum: the blocker's score for an episode is the runner's
return with the sign flipped. Four conditions rotate: the blocker always in the edge row, or learning its row
as a four-armed bandit (step 0.1, one random pick in ten); the runner told only its own cell, or also the
blocker's row (192 states). Runs are 120 training episodes with a 40-step limit, then 10 evaluation episodes
with both sides frozen.

Two things found in the game while building it:

- A bot held by "Start Forcing Player Position" has no collision. A planner told to walk the edge row went
  straight through a pinned enemy bot, eleven steps to the goal, every time. A bot that is teleported and left
  standing blocks completely: the same planner bumped 34 times and ran out of steps. The blocker is therefore
  teleported, never pinned.
- A second "Start Forcing Player Position" on a bot that is already pinned does not move it.

Extra log fields in this build: the last field of an `E` line is the row the blocker stood in, and a `B` line
at the end of each run gives the blocker's four scores and how many training episodes it stood in each row.
On `E` lines "slips" then counts bumps into the blocker (a step that did not reach the cell it aimed for).

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
| `P` | bot, run, episode, kind (0 TD(0) values with step 0.1, 1 Monte Carlo values, 2 visits, 3 TD(0) values with step 0.5), row, twelve values. Random-walk bot, at episodes 10, 30, 100 and at the end (200) |
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

## The game's chat filter edits your numbers

Found on 2026-11-22. Overwatch runs its text filter over Workshop strings, log lines included. A number that
contains a filtered run of digits is written with stars: an episode time of 1488.56 seconds reached the log
file as `****.56`. It is rare (one line in about 40,000 that night) and it can hit any field. The reader in
`rllab/night.py` counts such lines; where only a time was starred it uses the line's own clock stamp, and
otherwise it leaves the line out and says how many.

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

## The hidden-wall build (partial observability)

`workshop/compiled/night-school-pomdp.txt` (source `workshop/night/night_pomdp.opy`, version 1102). Ten Q-learning
runners on the usual strip (alpha 0.5, epsilon 0.1, 200 training episodes, a 40-step limit). For every episode one
square at column 6 is shut: the one in the edge row or the one in the second row, drawn at random. A runner who
walks at it does not move and pays for the step. The script enforces the wall, so each of the ten bots has her own.
A red ball above the strip marks each bot's wall for a spectator; the bots are not shown it.

The runner's true situation is (her square, which square is shut). The three conditions differ only in what she is told:

| Condition | What she is told | States |
|---|---|---|
| RUNNER BLIND | her square | 48 |
| RUNNER REMEMBERS BUMPS | her square, and a memory of this episode: no bump yet, or the row of the square she failed to enter | 48 x 3 used |
| RUNNER SEES THE WALL | her square and the wall's row | 48 x 2 |

The memory is the smallest belief state: it is built from what happened to her, not from being told.

### Named before the first run (2026-11-22, committed 07:06 Pacific, before any block had finished)

- A run is counted if it completed its 20 test crossings (learning and exploring off, a fresh random wall each).
- Measures, per run: the share of the 20 test crossings that reach the goal, and the mean steps per test crossing
  with a crossing that does not finish counted as the 40-step limit.
- Planned comparisons: REMEMBERS against BLIND, and SEES against REMEMBERS, on both measures. Interval from
  resampling runs, p from shuffling labels, as for the first night.
- Training return is reported but is not a measure: a route that avoids the wall also moves away from the edge,
  which changes how often the one-in-ten random step ends in a fall.
- Expected before looking: REMEMBERS reaches the goal more often than BLIND; SEES needs slightly fewer steps than
  REMEMBERS (she never pays for the bump). A blind runner can still do well if she learns the long way round through
  the third row, where no wall ever stands. If most blind runners find that route the first comparison will be small,
  and that is a result too.

### Checks

`night-school-pomdp-probe.txt` (version 9402) is the scripted check: every bot takes the same 16-step walk with the
wall forced into the edge row (five steps forward, two bumps, around through the second row, one bump from the far
side, on to the goal), two episodes under each condition. `analysis/tests/test_pomdp.py` rebuilds what each bot
should have been told at every step. In the game on 2026-11-22: 2,304 steps, 432 bumps, 144 episodes, all as
expected, and every table entry recomputed.

The first version of the check (9401) failed once in 438 bumps: a bot arrived a little long on the square before the
wall and drifted over the line into the shut square while standing at it. The script now puts a bot that ends a step
inside the shut square back where the step began. `rllab.night.wall_check` runs on every hidden-wall log.

### A simulation run while the first block was still playing (2026-11-22, 07:20 Pacific)

`analysis/sim/hidden_wall_sim.js` plays the same experiment by the grid's rules alone (no game, no slips), 300 runs
per condition. It was written after the measures above were committed and before any block had finished. For the
long strip it predicts the opposite of what was expected above: after 200 training episodes BLIND reaches the goal
in 91.9% of test crossings, REMEMBERS in 74.0%, SEES in 66.6%. The reason is in the routes: with a wall in only two
of the four rows, a blind runner can always get through by the third row, and she has the fewest states to learn.
The richer states cost episodes. By 400 episodes the three are level on reaching the goal (96 to 99%) and the
order in steps is the expected one (REMEMBERS 15.0, SEES 15.7, BLIND 16.8). The long-strip runs in the game are
reported as they come out, against the measures named above.

### The short strip: a wall with no way round (named before its first run, 2026-11-22, 07:22 Pacific)

`workshop/compiled/night-school-pomdp4.txt` (source `night_pomdp4.opy`, version 1103). Same three runners, same
learning rule and rewards, two changes chosen from the simulation: the wall can stand in any of the four rows
(column 3), and the goal is at column 5 so that 200 episodes are enough to learn the task. Now there is no row a
runner can always get through. A runner told only her square needs two different moves on the same square,
depending on something she is not given.

- Same counting rule, same two measures, same two planned comparisons (REMEMBERS against BLIND, SEES against
  REMEMBERS) as above. Three blocks planned: thirty runs, ten per condition.
- Predicted by the simulation (300 runs each, 200 training episodes): test crossings reaching the goal BLIND 46.6%,
  REMEMBERS 97.5%, SEES 99.8%; steps per test crossing 24.5, 7.2, 6.0. More training does not help BLIND in the
  simulation (48.0% after 1,000 episodes).
- The game differs from the simulation in having real movement (slips, about 0.2 per 1,000 steps on the first night)
  and real time limits. If the game disagrees with the simulation by more than the intervals allow, that is reported.
- Scripted check: `night-school-pomdp4-probe.txt` (version 9403), the same idea as 9402 on the short strip: a 10-step
  walk with three bumps, wall forced into the edge row.
  In the game on 2026-11-22 at 07:37, before the first short-strip block: 2,230 steps, 669 bumps, 223 episodes, all as
  expected (10 steps, return 40, three bumps), every table entry recomputed.

## The same task on a language model

`llm/hidden_order.py` moves the three runners onto a local model served by Ollama: a customer wants one of four things,
the ticket is basic or flex, the first message fits two of the four wishes, and the agent can ask, look the booking up,
or take a final step that cannot be undone. Four conditions change only what the model is shown each turn (the latest
message; the latest message and its own notes; the whole transcript; the transcript and the hidden facts). The customer
is scripted, so the exact belief after every message is known, and before each step a second call asks the model for
its own. `python llm/hidden_order.py --selftest` checks the world's rules with scripted agents and no model.
`llm/summarise.py` writes `data/llm/summary.json`; `llm/live.py` serves a page where a person plays the customer.
Results and what they do not show: `course/lesson-11-partial-observability.md`.

### A larger model, named before its run (2026-11-22, 07:41 Pacific)

The first model was gemma4:12b (96 cases: 6 of 24 right with the latest message only, 23 of 24 with its own notes,
24 of 24 with the whole transcript, 24 of 24 when told). Next, the same 96 cases on gemma4:31b. Expected before
looking: shown only the latest message, the larger model still fails most "cannot fly as booked" cases, because the
two facts it needs are never on the screen together; whatever it gains will come from guessing, which shows up as
final steps taken early. With notes or the whole transcript it should be at or near 24 of 24.
