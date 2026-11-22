# Log format

The script logs with the Workshop action "Log To Inspector". With
"Enable Workshop Inspector Log File" on (see `setup.md`), Overwatch writes each entry to
`Documents\Overwatch\Workshop\Log-<date>-<time>.txt` as

```
[HH:MM:SS] RLLAB,<KIND>,<comma-separated values>
```

The clock is time since the match started. The Workshop Inspector (Esc > Open Workshop Inspector)
shows the file's full path at the top of its Log panel.

The Workshop prints numbers with two decimals. So alpha, gamma and epsilon are logged times 1000 as
whole numbers, and Q-values in the log are rounded to 0.01.

## One file per match, with one exception

A new file starts with every match. A new file also starts when the host changes team or goes to
spectate, and that file begins with a copy of everything the match has logged so far. Keep only the
last file of a match, or every episode is counted twice. `python -m rllab.sanity <files>` reports a
match that appears in two files.

## SPAWN: one line per match

`spawn_calls` = Tracer creations + 10 x Widowmaker creations. `11` means each bot appeared on the
first try; `12` would mean Tracer needed a second try.

## CAL: one line per run, the measured arena

`floor_y, x_min, x_max, z_min, z_max, cell, run_speed, coast_dist, act_duration`

## RUN: one line per run, the settings

`run, experiment, algo, q_init, r_step, r_goal, r_fall, r_timeout, r_killed, r_hit, max_steps, closed_loop, use_health_bit, use_blink, n_actions, move_speed, game_speed`

- experiment: 0 cliff walk, 1 cliff walk + Widowmaker, 2 arena demo
- algo: 0 SARSA, 1 Q-learning

A new run starts at match start and whenever the Q-table is cleared.

## WARM: a run that started from a carried-over table

`run, table_size`. Written by builds made with `tools/warm_start.py`. It is followed at once by the
table itself, as `Q` lines with episode 0.

## EP: one line per episode

`run, episode, algo, mode, epsilon_milli, alpha_milli, gamma_milli, return, steps, outcome, mean_edge_dist, hits, t`

- mode: 0 training, 1 greedy evaluation
- outcome: 1 goal, 2 fell, 3 timeout, 4 killed
- mean_edge_dist: Tracer's distance from the island edge in metres, averaged over the steps she
  ended on the island
- hits: Widowmaker hits taken
- t: seconds since match start

## STEP: one line per action (only when "Log every step to the Inspector" is on)

`run, episode, step, s, a, r, s2, a2, terminal, explore, q_old, q_new, target`

- a, a2: 0 forward, 1 back, 2 inland, 3 edge, 4 Blink
- explore: True when the action came from the random draw
- q_old, q_new: Q(s, a) before and after the game's own update
- target: the learning target the game used
- On a terminal step s2 is the last observed state and a2 is a leftover; neither is used.

`analysis/rllab/replay.py` re-computes target and q_new from these lines.

## Q: the Q-table (every N episodes, default 50)

`run, episode, s, q0, q1, q2, q3, q4` for every state whose row has been updated.

## FAIL: the script stopped and why

`stage, details`. Stages: `island` (the map did not measure like Workshop Island), `spawn` (a bot
did not appear after five tries), `throttle` (Tracer did not move in the speed test), `botlost`
(a bot left the match mid-run). The same reason is on the HUD in red. No episodes are logged after a
FAIL line.

## Checking a log before you trust it

```powershell
cd analysis
..\.venv\Scripts\python -m rllab.sanity ..\data\logs\<file>.txt   # real play? each match once?
..\.venv\Scripts\python -m rllab.replay ..\data\logs\<file>.txt   # were the updates computed correctly?
```

`sanity` exists because of a real incident: a log full of well-formed, mathematically consistent
episodes that no bot had played (see `limitations.md`, "Bot slots look empty in the lobby"). Its
test is time: an episode that averages under 0.05 s per step cannot have been played.

## No seed

The Workshop has no way to set or read the seed of its random numbers. Runs cannot be repeated
draw for draw. Repeat a run several times and compare distributions.

## If the log file is not available

The same numbers are kept in global variables you can read in the Workshop Inspector:
`histReturn` and `histOutcome` hold the first 990 episodes of the run, `cnt` holds the outcome
counts, `Q` holds the table. The Inspector's last button, marked (x), copies every variable to the
clipboard as text. The HUD shows the counts and the rolling mean. The log file is the intended
route and it works on 2.25.1.0.
