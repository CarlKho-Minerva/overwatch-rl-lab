# Episode 8: Integrating Learning and Planning

*Outline for one episode of a video series, "RL with Overwatch". Footage: the island runs in this repository.*

**Title:** Twenty Steps in Her Head

**Cold open:** two Tracers at the left end of the edge row, DYNA-Q and Q-LEARNING over their heads; both take early random steps and Q-LEARNING walks off the edge.

**Beats:**
1. Ten bots running both edges at double speed. "The game cannot run faster, so we ask how much she learns per step."
2. DYNA-Q on a square, arrows flickering on squares she has visited. "After every real step she replays 20 remembered moves."
3. Arrows near the goal spreading back toward the start. "News from the goal travels backward while her feet are still."
4. Both score lines over the first 40 episodes. "Early on, the thinking bot scored about 26 points more per episode."
5. Both bots falling after a late random step. "Planning cannot stop the random step."
6. PLANNER crossing in eleven steps. "Given the true rules, a planner never falls."

**The experiment shown:** DYNA-Q against Q-LEARNING, mean return over the first 40 episodes (-31.7 against -57.6) and the last 40 (15.1 against 7.5, inconclusive).

**Closing line:** "Act at the world's speed; think at your own."
