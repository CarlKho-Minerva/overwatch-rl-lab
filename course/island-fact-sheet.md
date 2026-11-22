# The Overwatch RL Lab: the island fact sheet

Everything below was measured in the real game on the night of 2026-11-21.

## The setup

- Game: Overwatch 2, the official Workshop (scripting) mode, map Workshop Island: a flat square platform 40 m by 40 m
  with a deadly drop on every side. No simulator: bots really walk, really fall.
- The task ("the cliff walk"): a strip of 48 squares beside the edge, 4 rows deep and 12 columns long, 2 m per square.
  Row 0 is the row next to the drop. A bot starts at the left end of row 0 and must reach the right end of row 0 (the goal).
- State: which of the 48 squares the bot stands in, read from its real position after each move.
- Actions: forward (toward the goal end), back, inland (away from the edge), toward the edge. One action = one real run
  to the next square (about a quarter of a second at the double running speed used that night).
- A move off the grid on the left, right or inland side does nothing (the bot stays) and still costs a step. A move
  toward the edge from row 0 is a real fall.
- Rewards: -1 per step, +50 for reaching the goal, -100 for a fall, -50 if 100 steps pass without finishing. Discount 1.
  Best possible return: 39 (eleven steps along the edge row). Stepping straight off the edge: -101.
- The bots are Tracer (the fast Overwatch hero). The lab's first build also had a scripted Widowmaker (a sniper) who
  shot at Tracer in the inland rows; she was not in the overnight run.
- Ten Tracer bots ran at once, five on the far edge of the island and five on the near edge (mirrored). Each bot keeps
  its own table and learns by its own method. A "run" is one bot's whole education from nothing: 150 training episodes
  (or 18 minutes), then 10 test crossings with learning and exploring switched off. Which method a bot got was rotated.
- An episode = one attempt (start to goal, fall, or step limit). "Falls per 100" = training episodes that ended in a fall, per 100.
- "Slip" = a step that did not land on the square it aimed for. Measured: 0.21 per 1,000 steps. The real game is very nearly deterministic.
- Totals: 28,372 episodes, 517,518 real steps, 180 finished runs, 5.6 hours of game time,
  25.6 real steps a second (the earlier single-bot build did about 2.2).
- Every method's arithmetic was checked in the game: a scripted walk run under each method, each bot's final table
  recomputed outside the game, all equal. 4,043 logged steps recomputed, 0 mismatches.

## The cast (name over the bot, what it does, settings)

| Bot | Method in textbook words | Settings |
|---|---|---|
| RANDOM WALK | uniform random policy; two TD(0) value tables (step 0.1 and 0.5) and an every-visit Monte Carlo value table follow it | 200 episodes |
| PLANNER | value iteration on the grid's rules (in place, sweeps until the largest change is under 0.001), then walks greedily | no learning from experience |
| SARSA | on-policy TD control | alpha 0.5, epsilon 0.1 |
| Q-LEARNING | off-policy TD control | alpha 0.5, epsilon 0.1 |
| EXPECTED SARSA | target = expectation over the epsilon-greedy policy | alpha 0.5, epsilon 0.1 |
| MONTE CARLO | every-visit Monte Carlo control, constant step | alpha 0.2, epsilon 0.1 |
| MONTE CARLO + OPTIMISM | the same, every Q starts at 40 | alpha 0.2, epsilon 0.1 |
| SARSA LAMBDA | SARSA(lambda), replacing traces | lambda 0.8, alpha 0.3, epsilon 0.1 |
| Q, 16 COARSE STATES | Q-learning told only its row and which quarter of the strip (state aggregation) | alpha 0.5, epsilon 0.1 |
| Q, ROW ONLY | Q-learning told only its row | alpha 0.5, epsilon 0.1 |
| POLICY GRADIENT | REINFORCE with a per-state baseline, tabular softmax policy | step 0.02 |
| ACTOR-CRITIC | one-step actor-critic, tabular softmax policy, TD(0) critic | actor step 0.1, critic 0.2 |
| DYNA-Q | Q-learning plus 20 planning updates per real step from a learned table model | alpha 0.5, epsilon 0.1 |
| Q + FADING EXPLORATION | epsilon = 1 / (1 + episode / 5), floor 0.01 | alpha 0.5 |
| Q + OPTIMISM | every Q starts at 40, epsilon 0 (always greedy) | alpha 0.5 |
| Q + COUNT BONUS | greedy on Q + 10 / sqrt(visits + 1), epsilon 0 | alpha 0.5 |

Settings were fixed before any run and not tuned.

## Results per method (all finished runs)

| Method | Runs | Falls per 100 training episodes (95% interval) | Mean return, first 40 episodes | Mean return, last 40 episodes | Distance from edge, last 40 (m) | Episode of first goal (median) | Runs that never reached the goal | Runs with 10 clean test crossings | Steps per training episode |
|---|---|---|---|---|---|---|---|---|---|
| SARSA | 16 | 16.3 (15.3 to 17.4) | -58.7 | 22.3 | 3.88 | 11 | 0 | 13/16 | 25.1 |
| Q-learning | 11 | 26.5 (22.4 to 30.4) | -57.6 | 7.5 | 2.07 | 13 | 0 | 11/11 | 18.6 |
| Expected SARSA | 9 | 13.2 (12.0 to 14.4) | -47.4 | 27.3 | 3.56 | 11 | 0 | 9/9 | 21.3 |
| Q + fading exploration | 9 | 27.9 (25.4 to 30.3) | -86.3 | 23.6 | 1.83 | 17 | 0 | 9/9 | 18.2 |
| Q + optimism | 10 | 7.2 (7.0 to 7.3) | -33.0 | 38.0 | 2.24 | 11 | 0 | 10/10 | 19.6 |
| Dyna-Q | 9 | 24.4 (18.6 to 29.5) | -31.7 | 15.1 | 2.07 | 13 | 0 | 9/9 | 12.9 |
| Monte Carlo | 10 | 98.3 (97.7 to 98.8) | -108.0 | -102.2 | 0.18 | None | 10 | 0/10 | 4.6 |
| SARSA(lambda) | 14 | 11.8 (10.5 to 13.2) | -54.7 | 22.4 | 5.06 | 14 | 0 | 13/14 | 25.6 |
| Q + count bonus | 10 | 7.1 (6.8 to 7.4) | -46.3 | 37.0 | 2.58 | 13 | 0 | 10/10 | 22.1 |
| Random walk | 11 | 97.4 (96.9 to 97.9) | -111.3 | -113.3 | 2.03 | 37 | 2 | n/a | 14.9 |
| Planner | 10 | 0.0 (0.0 to 0.0) | 39.0 | 39.0 | 1.50 | 1 | 0 | 10/10 | 11.0 |
| Policy gradient | 15 | 96.5 (93.2 to 98.9) | -112.3 | -101.6 | 0.33 | 6 | 14 | 0/15 | 6.4 |
| Actor-critic | 17 | 7.1 (6.8 to 7.5) | -45.4 | 34.7 | 4.21 | 10 | 0 | 17/17 | 25.0 |
| Monte Carlo + optimism | 9 | 97.7 (97.1 to 98.3) | -108.7 | -101.9 | 0.16 | None | 9 | 0/9 | 5.1 |
| Q, 16 coarse states | 10 | 16.3 (12.1 to 21.0) | -13.2 | 14.3 | 2.97 | 5 | 0 | 10/10 | 17.6 |
| Q, row only | 10 | 42.5 (39.0 to 45.7) | -114.3 | -76.0 | 2.25 | 24 | 0 | 3/10 | 47.1 |

## Planned and exploratory comparisons (difference = first minus second; interval from resampling runs; p from shuffling labels)

| Comparison | Which | Mean A | Mean B | Difference | 95% interval | p | Runs A/B |
|---|---|---|---|---|---|---|---|
| sarsa_vs_q_falls | SARSA vs Q-learning | 16.35 | 26.48 | -10.14 | -14.18 to -5.83 | under 0.001 | 16/11 |
| sarsa_vs_q_edge | SARSA vs Q-learning | 3.88 | 2.07 | 1.82 | 1.38 to 2.23 | under 0.001 | 16/11 |
| sarsa_vs_q_return | SARSA vs Q-learning | 22.34 | 7.48 | 14.86 | 5.43 to 23.42 | 0.0035 | 16/11 |
| dyna_vs_q_falls | Dyna-Q vs Q-learning | 24.37 | 26.48 | -2.11 | -9.06 to 4.49 | 0.5681 | 9/11 |
| dyna_vs_q_return | Dyna-Q vs Q-learning | 15.07 | 7.48 | 7.59 | -3.19 to 18.58 | 0.2202 | 9/11 |
| fading_vs_q_falls | Q + fading exploration vs Q-learning | 27.93 | 26.48 | 1.44 | -3.25 to 6.17 | 0.6111 | 9/11 |
| optimism_vs_q_falls | Q + optimism vs Q-learning | 7.20 | 26.48 | -19.28 | -23.28 to -15.11 | under 0.001 | 10/11 |
| bonus_vs_q_falls | Q + count bonus vs Q-learning | 7.09 | 26.48 | -19.40 | -23.37 to -15.22 | under 0.001 | 10/11 |
| mc_vs_sarsa_return | Monte Carlo vs SARSA | -102.21 | 22.34 | -124.55 | -128.57 to -119.83 | under 0.001 | 10/16 |
| pg_vs_q_return | Policy gradient vs Q-learning | -101.60 | 7.48 | -109.08 | -117.07 to -101.30 | under 0.001 | 15/11 |
| lambda_vs_sarsa_falls | SARSA(lambda) vs SARSA | 11.84 | 16.35 | -4.51 | -6.21 to -2.78 | under 0.001 | 14/16 |
| ac_vs_pg_return | Actor-critic vs Policy gradient | 34.75 | -101.60 | 136.35 | 135.66 to 137.17 | under 0.001 | 17/15 |
| ac_vs_q_return | Actor-critic vs Q-learning | 34.75 | 7.48 | 27.27 | 18.72 to 34.83 | under 0.001 | 17/11 |
| mcopt_vs_mc_return | Monte Carlo + optimism vs Monte Carlo | -101.93 | -102.21 | 0.27 | -0.51 to 1.14 | 0.5671 | 9/10 |
| coarse_vs_q_falls | Q, 16 coarse states vs Q-learning | 16.33 | 26.48 | -10.15 | -15.99 to -4.13 | 0.0074 | 10/11 |
| rowonly_vs_q_falls | Q, row only vs Q-learning | 42.45 | 26.48 | 15.97 | 10.62 to 21.32 | under 0.001 | 10/11 |
| rowonly_vs_q_return | Q, row only vs Q-learning | -76.00 | 7.48 | -83.48 | -107.47 to -60.97 | under 0.001 | 10/11 |
| coarse_vs_rowonly_falls | Q, 16 coarse states vs Q, row only | 16.33 | 42.45 | -26.12 | -31.51 to -20.28 | under 0.001 | 10/10 |
| dyna_vs_q_first | Dyna-Q vs Q-learning | -31.66 | -57.64 | 25.98 | 15.53 to 36.25 | 0.0007 | 9/11 |
| dyna_vs_q_steps | Dyna-Q vs Q-learning | 1,942.33 | 2,793.82 | -851.48 | -1,019.15 to -673.20 | 0.0001 | 9/11 |
| ac_vs_q_falls | Actor-critic vs Q-learning | 7.11 | 26.48 | -19.38 | -23.31 to -15.09 | under 0.001 | 17/11 |
| esarsa_vs_q_falls | Expected SARSA vs Q-learning | 13.19 | 26.48 | -13.30 | -17.50 to -8.96 | 0.0001 | 9/11 |

Only SARSA against Q-learning (falls) was planned before the night. The rest are first looks, uncorrected for the number of comparisons.

## Other measured facts

- Random walk: 2,308 episodes, mean return -112.7 (standard error 0.46), mean length 14.9 steps,
  goal reached by luck in 1.0% of episodes. Exact value of the start square under the random policy (solved from the
  written-down rules, time limit ignored): -114.4. Exact value of the far inland corner: -135.5 (worse than the start: she wanders longer and falls anyway).
- Planner: 13 sweeps to settle; largest change per sweep: 101, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 48, 0.00.
  Good news travels back one column per sweep. In 10 runs she never fell.
- Prediction (typical error of each value table against the exact values, weighted by visits): after 10 episodes TD step 0.1: 112.7,
  TD step 0.5: 100.5, Monte Carlo: 25.9. After 200 episodes: 85.6, 46.5, 15.3.
  All tables start at zero; most true values are below -100. Monte Carlo was closest throughout; TD from a zero start is slow here.
- Why Monte Carlo control and REINFORCE "jump": a beginner never sees the +50. Of the endings she does see, stepping off at once (-101)
  beats wandering then falling (about -110) or timing out (-150). Methods that judge a move by the whole ending learn to step off.
  TD methods lean on the next square's estimate, which starts at zero (far better than -101), so "forward into the unknown" keeps
  looking better than "off the edge". An optimistic start did not rescue Monte Carlo. Actor-critic (same softmax policy, TD critic) did not jump.
- Row-only bot: she learns the edge at once but cannot tell forward from back (both lead, as far as she can tell, to the place she
  is already in), so she dithers along the edge row: 47.1 steps per episode against 18.6 for the full table.
- Dyna-Q learned faster early (first 40 episodes) and was level with Q-learning by the last 40; it does not reduce falls from random steps.
- Optimism and the count bonus: about 11 falls per 150-episode run, roughly one per fatal edge move, then none.

## The two-player build (lecture 10, exploratory, 12 short runs)

A second bot from the other team (the "blocker") stands in one of the four rows at column 6 for a whole episode. Enemy heroes cannot walk
through each other, so she is a real obstacle. Zero-sum: the blocker's score is the runner's return with the sign flipped. The runner is
Q-learning with a 40-step limit; runs were nine minutes (66 to 99 training episodes), so runners were still early in learning.
Conditions: the blocker always in the edge row ("fixed") or learning her row as a four-armed bandit ("learns"); the runner told only her own
square ("blind") or also the blocker's row ("sees", 192 states).

| Condition | Runs | Runner's mean return, last 40 episodes | Goal reached, last 40 | Bumps per episode | Blocker's share of rows 0-3, last third |
|---|---|---|---|---|---|
| Runner blind, blocker fixed | 1 | -14.0 | 70% | 0.20 | [1.0, 0.0, 0.0, 0.0] |
| Runner blind, blocker learns | 2 | -46.1 | 41% | 0.47 | [0.18, 0.0, 0.06, 0.76] |
| Runner sees, blocker fixed | 5 | -35.1 | 48% | 0.22 | [1.0, 0.0, 0.0, 0.0] |
| Runner sees, blocker learns | 4 | -66.4 | 29% | 0.46 | [0.36, 0.28, 0.14, 0.21] |

The blind runner facing a hidden blocker is a partially observable problem: the next square depends on something she is not told.

## Things found about the game itself (usable as asides)

- The game's recorder silently stops when its store fills, and the log file with it (80 seconds with ten bots). Fixed by queueing log lines.
- The game's chat filter rewrote a logged time of 1488.56 as ****.56.
- A bot the script pins in place has no body: another bot walks straight through it. A bot left standing blocks completely.
- The game cannot run faster than real time. Speed came from double running speed, ten bots at once, and Dyna-Q's imagined updates.

## Earlier single-bot evening (one run each, normal running speed)

SARSA: 4 falls in its last 40 training episodes; Q-learning: 10 in 40. With exploration off, Q-learning crossed cleanly 12 of 12 times in 13 steps;
the SARSA table sent her pacing between two squares until the step limit. That lead is what the overnight repeats confirmed.

## Speed: what the script measured

- The Workshop's speed setting (slow motion) cannot go above 100%: the game never runs faster than real time.
- At double running speed the bot slides 0.5 m after she stops running (the script measures this at the start of every match and cuts each run that much short); the single-bot build at normal speed measured 0.25 m.
- Server load, as the game reports it to the script, peaked at 147% of budget over the night and averaged 39%.

## How the prediction tables average

- RANDOM WALK's Monte Carlo value table: every-visit, plain running average (step 1/k on the k-th visit to a square).
- Her two TD(0) tables: constant steps 0.1 and 0.5. Checkpoints were logged after 10, 30, 100 and 200 episodes; the brief quotes 10 and 200.

## The hidden-wall build (the lesson on partial observability; being run 2026-11-22, NO RESULTS YET)

- Ten Q-learning Tracers on the usual strip. For every episode one square at column 6 is shut: the one in the edge
  row or the one in the second row, drawn at random. A runner who walks at it does not move and pays for the step.
- Her true situation is (her square, which square is shut). Three conditions differ only in what she is told:
  RUNNER BLIND (her square only, so two different situations look the same to her),
  RUNNER REMEMBERS BUMPS (her square plus a memory of this episode: no bump yet, or the row she bumped into),
  RUNNER SEES THE WALL (her square and the wall's row: the fully observed version).
- Named in advance as the measure: the 20 test crossings with learning and exploring off at the end of each run
  (share reaching the goal, steps taken).
- Why it is in the course: the memory is the smallest possible "belief state". It is built from what happened to her,
  not from being told. The lesson then moves the same idea onto a language-model agent in a customer-service
  benchmark, where the hidden thing is what the customer wants and what the database holds.
