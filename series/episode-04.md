# Episode 4: Model-Free Prediction

*Outline for one episode of a video series, "RL with Overwatch". Footage: the island runs in this repository.*

- Title: "Three Bookkeepers and a Falling Tracer"
- Cold open: RANDOM WALK, name over her head, takes three random steps and drops off the edge; the score line reads -101.
- Beat 1: the empty strip. "Nobody picks better moves today; we only measure each square for a random walker."
- Beat 2: an episode replayed, every crossed square lighting up when she falls. "Monte Carlo waits for the fall, then writes the real total on every square."
- Beat 3: the replay, one square updating per step. "TD writes after every step: one point lost, plus its guess for the next square."
- Beat 4: an edge square going from 0 to -50.5. "Zero is about 100 points too hopeful, and TD corrects a little at a time."
- Beat 5: score lines for the three tables at 10 and 200 episodes. "Here Monte Carlo was closest both times; in Silver's walk TD wins."
- Experiment shown: the three tables on one random walker.
- Closing line: "Same walker, same steps, three answers; the gap between them is bias against noise."
