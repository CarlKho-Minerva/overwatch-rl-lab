# Lab 05: Partial observations with Widowmaker

**Time:** about 60 minutes in game. **Build:** `workshop/compiled/variant-widow.txt`, or the main
build with **1 Experiment > Experiment** set to "Cliff walk + Widowmaker".

**Status:** read `docs/verification.md` first. It says how much of the Widowmaker experiment has
been run in the game and what has not.

## The setup

Widowmaker stands 6 m behind the grid, always facing Tracer, scoped. Every 2 seconds she fires,
but only if Tracer is inside the red ring (11 m). The inland rows near the middle of the grid are
inside the ring. The edge row is outside it. So the route that is safe from the drop is the route
she can shoot, and the route she cannot shoot is the one with the drop.

Tracer's state is her cell plus one bit: is she at or below half health? One scoped body shot
takes her below half. A second kills her.

## The question

Turn the health bit off (**5 Widowmaker > Tracer observes her own health** = Off). Now a healthy
Tracer and a one-shot-from-dead Tracer in the same cell look identical to the agent.

**Predict before you run anything.**

1. With the health bit **on**, will she learn different routes for "healthy" and "hurt"? Which
   one hugs the edge?
2. With the health bit **off**, what single route will she settle on? Closer to what the healthy
   policy or the hurt policy would choose?
3. Which setting gets killed more often after 150 episodes?

## What to change

Only **Tracer observes her own health**: On for run A, Off for run B. SARSA, epsilon 0.1,
150 episodes each.

## What to watch in Overwatch

- `KILLED` against `FELL` at the top right.
- Tracer's health bar when she crosses the ring, and what she does on the step after a hit.
  With the bit on, her next move can change. With it off, it cannot.
- The floor arrows show the "healthy" half of the table only. The "hurt" half is in the log:
  `Q` lines with state 48 to 95.

## Graph

```powershell
cd analysis
..\.venv\Scripts\python -m rllab.plots ..\data\logs\<health on>.txt ..\data\logs\<health off>.txt --out figures\lab05
```

Add the killed rate by hand from the table's outcome counts, or extend `summary_table` in
`analysis/rllab/plots.py` with `killed_rate=("outcome", lambda s: (s == 4).mean())`.

## Reflect

With the bit off the problem is no longer Markov from the agent's side: the same observation has
two different futures. SARSA and Q-learning both assume it is. What does each of them end up
learning the value of, when one "state" is secretly two?

There is a second hidden variable even with the health bit on: the shot clock. Where in a
2-second cycle Widowmaker is decides whether crossing the ring is free. How would you add it to
the state with one more bit, and what would it cost in table size?

## Coding exercise (5 lines)

Add the shot-clock bit. In `environment/cliffwalk.opy`, `observeState` builds `obsS`. Add
`if useClockBit and nextShotT - getTotalTimeElapsed() < 0.7: obsS += 2 * NCELLS` (reuse the Blink
slot, with Blink off), declare `useClockBit` in `environment/state.opy` and set it from a new
Workshop Setting in `environment/config.opy`. Run 150 episodes and compare the killed rate with
run A.
