# Episode 3: Planning by Dynamic Programming

*Outline for one episode of a video series, "RL with Overwatch". Footage: the island runs in this repository.*

**Working title:** The Bot Who Never Fell

**Cold open (first 10 seconds):** nine Tracers on the strip, names over their heads, tumbling off the edge one by one; at the left end, PLANNER standing still.

1. Edge squares get arrows away from the drop; squares beside the goal light up. "Sweep one: stepping off costs 101, and the goal is one step from its neighbours."
2. Arrows fill in one column per sweep, right to left, score line "largest change: 49". "Each sweep, the news of the goal moves back one column."
3. Counter at 13, score line 0.00. "Sweep thirteen changes nothing. That is how she knows she is done."
4. PLANNER walks the edge row, score line 39. "Eleven steps beside the drop, the best possible return, and in 10 runs she never fell."
5. RANDOM WALK wandering and falling, score line -114.4. "The same sums predict a random walker: -114.4. She averaged -112.7."

**Experiment shown:** value iteration on the strip, 13 sweeps as arrows, then the greedy walk.

**Closing line:** "She never fell because she was never surprised. Every bot from here on learns the rules by breaking them."
