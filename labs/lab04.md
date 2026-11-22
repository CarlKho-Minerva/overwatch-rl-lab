# Lab 04: Reward shaping and unintended behaviour

**Time:** about 60 minutes in game. **Build:** `workshop/compiled/overwatch-rl-lab.txt`.

## The question

The agent does what the rewards pay for, which is not always what you meant. Three small changes,
each of which sounds harmless.

**Predict before you run anything.** For each, write what Tracer will do after 80 episodes.

1. **No step cost.** Reward per action = 0 (goal +50, fall -100 unchanged), gamma = 1.
2. **A cheap fall.** Reward per action = -10, fall = -20, timeout = -1000. Count it up: a clean
   11-step edge run now returns 11 x -10 + 50 = -60. An immediate step off the edge returns
   -10 + -20 = -30.
3. **A harsh timeout with a short clock.** Defaults, but episode duration = 15 steps and
   timeout = -300.

## What to change

One group at a time, in **3 Rewards** and **1 Experiment > Episode duration**. Q-learning,
epsilon 0.1, 80 episodes each, a match restart between them.

## What to watch in Overwatch

1. No step cost: does she head for the goal, or wander? Watch the step count on the top line and
   how often `TIMEOUT` ticks up. With no cost per step and gamma = 1, a 90-step route and an
   11-step route are worth the same.
2. Cheap fall: watch the arrow on the start cell. If it points up, she has learned that the
   fastest way to stop losing points is to jump.
3. Harsh timeout: watch the last few steps of an episode that is running long.

## Graph

```powershell
cd analysis
..\.venv\Scripts\python -m rllab.plots ..\data\logs\<case1>.txt ..\data\logs\<case2>.txt ..\data\logs\<case3>.txt --out figures\lab04
```

The printed table is the main result here: goal rate, fall rate and mean steps per case.
Compare the mean return with the goal rate. In case 2 the return can go up while the goal rate
goes to zero.

## Reflect

In case 2 the agent is doing the right thing for the numbers it was given. Which single reward
would you change to get the crossing back, and why does changing gamma (try 0.9 in case 1) fix
case 1 without touching any reward?

Also: this lab treats a timeout as a terminal state with its own penalty (`docs/limitations.md`).
In case 3, what is the agent being punished for that it cannot see in its state?

## Coding exercise (4 lines)

Add a shaping bonus for progress. In `environment/cliffwalk.opy`, after `nextCell = obsCell`, add
`reward += 0.5 * (nextCell % NCOLS - curCell % NCOLS)` so each column gained pays +0.5 and each
column lost costs 0.5. Rebuild and run case 1 again. Then explain why this bonus cannot change
which route is best (it is a difference of a potential), while a flat "+0.5 for moving forward"
that is never taken back could.
