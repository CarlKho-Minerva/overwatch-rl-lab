# Lab 02: SARSA versus Q-learning

**Time:** about 60 minutes in game. **Build:** `workshop/compiled/overwatch-rl-lab.txt`.

This is the experiment the lab was built for (David Silver's Lecture 5; Sutton and Barto,
Example 6.6).

## The question

> Does an agent trained with SARSA learn to stay farther from the edge of Workshop Island than one
> trained with Q-learning, when both keep exploring?

Both agents explore the same way (epsilon = 0.1) and both learn from every step, falls included.
They differ in one line: what they assume happens next.

- SARSA scores a move by the action she will really take next, random ones included.
- Q-learning scores a move by the best action available next, as if she would never slip.

**Predict before you run anything.**

1. Which algorithm has the higher fall rate during training (episodes 80 to 150)?
2. Which has the higher mean return during training?
3. Press Reload after training so nothing is random. Which algorithm now gets the higher return?
   Is your answer the same as for question 2?

## What to change

Only **2 Learning > Algorithm**.

- Run A: SARSA, 150 training episodes, then Reload and 10 evaluation episodes.
- Run B: restart the match with Q-learning (or press Ability 2, which switches the algorithm and
  clears the table), 150 training episodes, then 10 evaluation episodes.

Independent variable: the algorithm. Measured: return per episode, share of episodes ending in a
fall, mean distance from the edge. Held fixed: epsilon 0.1, alpha 0.5, gamma 1, rewards, arena.

## What to watch in Overwatch

- The arrows in the edge row (top row from the overhead camera) against the row behind it. Under
  Q-learning the edge row should fill with right-pointing arrows. Under SARSA, look for the arrows
  near the start pointing down (inland) first.
- Which row Tracer actually runs along once she is reliably reaching the goal.
- During evaluation: count her steps. 11 is the edge route; 13 is one row inland; 15 is two rows.
- If an evaluation episode ends in `TIMEOUT` with Tracer pacing between two cells, you have found a
  policy loop: two cells whose best-rated moves point at each other. Training hides it, because
  every pass lowers both values until another move wins. With learning frozen nothing breaks the
  loop. This happened in the first recorded SARSA run (`data/logs/2026-11-21_cliffwalk_sarsa.txt`,
  episodes 116 to 118, cells 20 and 21). Press Reload, train 30 more episodes, and evaluate again.

## Graph

```powershell
cd analysis
..\.venv\Scripts\python -m rllab.plots ..\data\logs\<sarsa>.txt ..\data\logs\<qlearning>.txt --out figures\lab02
```

Three panels, one line per algorithm: return, fall rate, distance from the edge. The table printed
above the figure splits training from evaluation; question 3 is answered by its evaluation rows.

One run per algorithm is one sample. The Workshop has no seed, so repeat each run two or three
times before you trust a small gap.

## Reflect

Q-learning learned the shorter route and still earned less during training. In one or two
sentences: which of the two is "better", and what would you have to know about how the agent will
be used to answer that?

## Coding exercise (4 lines)

Add Expected SARSA. In `workshop/agents/experiment.opy`, the target is chosen in one `if`. Add a
third branch (use `algo == 2`) whose target averages over what the behaviour policy would do:

```
tdTarget = reward + gamma * ((1 - epsilon) * <max of the row> + epsilon * <mean of the row>)
```

The row is `Q.slice(nextS * NA, nAct)`; its max is `sorted(row).last()`. The Workshop has no sum,
so write the mean out for four actions. Add "Expected SARSA" to the Algorithm setting in
`environment/config.opy` and to `ALGO_NAMES` in `ui/hud.opy`. Then add its target to
`analysis/rllab/reference.py` with one test, so the replay check covers it.
