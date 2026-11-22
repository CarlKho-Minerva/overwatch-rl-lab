# Lab 03: Learning rate and convergence

**Time:** about 60 minutes in game. **Build:** `workshop/compiled/variant-verify-sarsa.txt`
(the same mode with per-step logging already on).

## The question

Alpha is how far each update moves a Q-value toward its new target: 1 replaces the old value,
0.1 moves a tenth of the way.

On this island a move almost always does the same thing, so there is little noise to average
away. The exception is the edge row, where a random next action sometimes means a fall.

**Predict before you run anything.**

1. Which alpha reaches the goal first: 0.1, 0.5 or 1.0?
2. With alpha = 1.0 and SARSA, what happens to the Q-value of "forward" in an edge-row cell on the
   step after Tracer happens to explore off the edge from the next cell? Work it out from
   Q <- Q + alpha * (target - Q) before you look.
3. Which alpha gives the steadiest policy arrows after 100 episodes?

## What to change

Only **2 Learning > Learning rate alpha**: 0.1, then 0.5, then 1.0. SARSA, epsilon 0.1,
100 episodes each, one match restart between runs.

## What to watch in Overwatch

- How many episodes pass before `GOAL` first ticks up (top right).
- Arrow flicker. With alpha = 1.0 watch one edge-row cell and count how often its arrow changes in
  a minute. Do the same at alpha = 0.1.
- The rolling mean on the second line at the top.

## Graph

```powershell
cd analysis
..\.venv\Scripts\python -m rllab.plots ..\data\logs\<a01>.txt ..\data\logs\<a05>.txt ..\data\logs\<a10>.txt --out figures\lab03
```

All three runs are SARSA, so the lines share a colour; read them by the legend's run labels, or
plot one file at a time. The summary table lists alpha per run.

For question 2, follow one Q-value through the step log:

```powershell
Select-String "RLLAB,STEP" ..\data\logs\<a10>.txt | Select-String ",5,0,"    # state 5, action forward
```

Columns 11 and 12 are that Q-value before and after each update.

## Reflect

Silver's convergence conditions ask for step sizes that shrink over time. Here alpha is constant.
What did the constant alpha buy you in the first 30 episodes, and what did it cost in the last 30?

## Coding exercise (3 lines)

Give every state-action pair its own shrinking step size. Add a global array `visits` (declare it
in `environment/state.opy`, reset it in `resetLearning`), add 1 to `visits[curS * NA + curA]`
before the update in `agents/experiment.opy`, and use `1 / visits[...]` in place of `alpha`.
Run 100 episodes and compare the arrow flicker with alpha = 0.5.
