# Architecture

One Workshop script. The game engine is the environment; the script is the agent, the experiment
runner and the dashboard. Python only reads the log files afterwards.

```
workshop/main.opy  ->  OverPy compiler  ->  workshop/compiled/overwatch-rl-lab.txt  ->  paste into Overwatch
                                                                                              |
                                                     Documents\Overwatch\Workshop\Log-*.txt  <-+
                                                                 |
                                         analysis/rllab (parse, replay check, plots, notebook)
```

## Source files

| File | What it holds |
|---|---|
| `workshop/main.opy` | Entry point with the standard defaults |
| `workshop/defaults.opy` | The default value of every Workshop Setting, one line each |
| `workshop/variants/*.opy` | Test builds: the same code with a few defaults changed. `demo`, `verify_sarsa`, `verify_qlearning`, `widow`, `blink_openloop` exercise each feature; `nondefault_cliff` and `nondefault_widow` move every setting off its default; `fail_*` trigger each setup failure on purpose; `warm_start` is written by `tools/warm_start.py` |
| `workshop/lab.opy` | Lobby settings (Skirmish on Workshop Island) and the include list |
| `environment/config.opy` | Constants and every Workshop Setting |
| `environment/state.opy` | Every global variable |
| `environment/calibration.opy` | Floor and edge measurement by ray casts |
| `environment/arena.opy` | Grid layout, bot spawn, speed measurement, reset, death and damage events |
| `environment/cliffwalk.opy` | One environment step: move the real Tracer, read the state, score the reward |
| `agents/tabular.opy` | Q-table, epsilon-greedy choice with random tie-break, policy arrows |
| `agents/experiment.opy` | Episode loop, the two learning targets, counters |
| `agents/widowmaker.opy` | Scripted scoped fire on a shot clock |
| `ui/controls.opy` | Host buttons |
| `ui/hud.opy` | HUD text, grid outline, policy arrows |
| `ui/logging.opy` | Log lines |

## The MDP

- **State:** which of the 48 cells Tracer stands in, read from her real position after each move.
  In the Widowmaker experiment one more bit says whether she is at or below half health. With Blink
  on, one more bit says whether Blink has no charge. 192 states at most.
- **Actions:** forward (+x, toward the goal), back (-x), inland (+z), edge (-z), and optionally
  Blink toward the goal.
- **One step:** the script turns Tracer to face the direction and starts a world-space throttle
  (the Workshop's "Start Throttle In Direction", the same input a player's movement keys give).
  In the default closed-loop mode it stops the throttle when she is one coast distance short of the
  next cell's centre, so she slides to a stop on it. In fixed-duration mode it stops after
  cell / speed seconds wherever she is. Then it waits until she is nearly still and reads her cell.
- **Blocked moves:** a move toward the left end, right end or inland side of the grid does nothing
  and still costs a step. Those sides are open floor; the grid is a rule there, not a wall.
- **The cliff:** a move toward the edge from row 0 is not blocked. In closed-loop mode the throttle
  stays on until she is actually falling. The fall is detected from her real height (more than
  1.2 m below the floor), and she is put back on the start cell before she hits the kill zone.
- **Rewards:** "reward per action" every step; plus the goal, fall, timeout or killed reward on the
  step that ends the episode; plus "reward per hit" for each Widowmaker hit in that step.
  Defaults: -1, +50, -100, -50, -100, 0.
- **Episode end:** reaching state 11 (goal), falling, being killed, or the step limit (default 100).
  All four are treated as terminal for the update: no bootstrapping.

## The learning loop (`agents/experiment.opy`)

```
s  <- observe;  a <- epsilon-greedy(s)
repeat:
    carry out a in the game  ->  r, s', terminal
    if terminal:      target <- r
    else:
        a' <- epsilon-greedy(s')                      # same line for both algorithms
        SARSA:        target <- r + gamma * Q[s', a']
        Q-learning:   target <- r + gamma * max_a Q[s', a]
    if training:      Q[s, a] <- Q[s, a] + alpha * (target - Q[s, a])
    s <- s';  a <- a'
```

The algorithm is tested in exactly one `if`. Action choice does not look at it. In greedy
evaluation epsilon is treated as 0 and the table is not updated.

The Q-table is one flat array, `Q[s * 5 + a]`, 960 numbers; the Workshop's limit is 1000 per array.

## Widowmaker

She always faces Tracer. In the Widowmaker experiment she holds her scope and presses primary fire
every "seconds between shots" (default 2), but only while Tracer is within "firing range"
(default 11 m, drawn as a red ring). The shot clock restarts with every episode. She stands 6 m
behind the grid's inland side, so with the default range the inland rows near the middle are
inside the ring and the edge row is outside it: staying safe from the drop means walking into her
sights, and the other way round.

## What the script refuses to do

It stops, with the reason in red on the HUD and a `FAIL` line in the log, rather than run on a
broken setup:

- the map does not measure like Workshop Island;
- a bot has not appeared after five tries;
- Tracer does not move when throttled;
- a bot leaves the match mid-run (checked before every episode and after every step; the step in
  progress is thrown away, with no update and no episode line).

The last one was added after a real incident in which the script logged plausible episodes for a
Tracer that no longer existed (`docs/limitations.md`). `analysis/rllab/sanity.py` checks old logs
for the same thing by timing.

## Tools around the script

| File | What it does |
|---|---|
| `tools/build.mjs` | Compiles every build, fails on any compiler warning |
| `tools/warm_start.py` | Turns the Workshop Inspector's variable export into a build that starts from that Q-table |
| `tools/make_notebook.py` | Writes and runs the analysis notebook from the logs in `data/logs` |
| `analysis/rllab/replay.py` | Re-computes every logged update with the reference maths |
| `analysis/rllab/sanity.py` | Flags episodes too fast to be real play, and a match that is in the data twice |
| `analysis/rllab/plots.py` | Learning curves and the per-run summary table |

## Why no external controller

Blizzard's rules forbid unauthorised automation of play. Everything that moves a hero here is a
Workshop action running on Blizzard's server inside a private custom game: no input injection into
gameplay, no memory reading, no network tricks.
