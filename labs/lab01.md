# Lab 01: Exploration and risky routes

**Time:** about 40 minutes in game. **Build:** `workshop/compiled/overwatch-rl-lab.txt`.

## The question

Tracer starts at the left end of the edge row and the goal is at the right end. The shortest route
runs along the edge: 11 moves. Epsilon is the chance that any one move is random instead of her
best guess. One random move in four points off the island.

**Predict before you run anything.** Write your answers down.

1. With epsilon = 0.1, what share of training episodes will end in a fall once she has clearly
   learned a route (say, episodes 80 to 120)? Guess a number.
2. With epsilon = 0.3, will she walk the same route? If not, how many rows further inland?

A way to reason about question 1: on the edge row a move is random with chance epsilon and a
random move goes off the edge with chance 1/4. Over 11 edge-row moves the chance of at least one
fall is 1 - (1 - epsilon/4)^11.

## What to change

Only one Workshop Setting between the two runs: **2 Learning > Exploration probability epsilon**.

- Run A: algorithm SARSA, epsilon 0.1, everything else default. 120 episodes.
- Run B: Esc > Show Lobby > Settings > Workshop Settings (the orange hammer tile), set epsilon 0.3,
  Esc, Restart Match. 120 episodes.

(You can nudge epsilon live with Crouch + Primary / Secondary Fire, but a restart keeps the two runs
clean: each gets its own log file and starts from an empty table.)

## What to watch in Overwatch

- The floor arrows. They start as dots. Which cells get an arrow first, and do the edge-row arrows
  ever point up (off the edge)?
- The orange `(EXPLORING)` tag on the action line at the top. Watch what happens when it shows up
  while she is on the edge row.
- Top right: `FELL` against `GOAL` for training episodes.
- After episode 120 press Reload (R) for greedy evaluation and watch five episodes. Which row does
  she walk when nothing is random?

## Graph

```powershell
cd analysis
..\.venv\Scripts\python -m rllab.plots ..\data\logs\<run A>.txt ..\data\logs\<run B>.txt --out figures\lab01
```

Look at the middle panel (share of episodes ending in a fall) and the bottom panel (mean distance
from the edge). Each run is one line; the legend gives n.

## Reflect

Did the fall rate you measured for epsilon = 0.1 match the 1 - (1 - epsilon/4)^11 estimate? If it
came out lower, look at the bottom panel for the reason.

## Coding exercise (3 lines)

In `workshop/agents/tabular.opy`, `chooseAction` explores with a fixed epsilon. Make exploration
fade: replace the condition

```
if isTraining and random.uniform(0, 1) < epsilon:
```

with one that uses `epsilon / (1 + epCount / 50)`. Rebuild (`npm run build`), paste, run 120
episodes and compare the fall rate over the last 40 episodes with Run A.
