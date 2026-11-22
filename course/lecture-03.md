# Lecture 3: Planning by Dynamic Programming

*David Silver's lecture 3 (UCL, 2015), gone through in his order and re-explained with the Tracer experiments on Workshop Island. The lecture and its slides are his: [video](https://www.youtube.com/watch?v=Nd1-UUMVfz4), [course page](https://davidstarsilver.wordpress.com/teaching/). The words below are a re-explanation. Every island number comes from the logged runs in this repository.*

Almost every Tracer on the island found the cliff by walking off it. PLANNER never did: she was handed the rules of the strip (where each move leads, what it pays), stood still while she did the arithmetic, then walked the eleven-step edge route in all 10 of her runs without a fall. The question is what that arithmetic is. The answer: given the full rules of a world, you compute exactly how good any behaviour is, and the best one, by repeating the Bellman equation from lecture 2 as an update until the numbers stop moving.

## The lecture in order

### [02:26](https://www.youtube.com/watch?v=Nd1-UUMVfz4&t=146s) Dynamic programming optimises a step-by-step plan by reusing answers to smaller problems
"Dynamic" means the problem unfolds in steps. "Programming" is the mathematical sense, as in linear programming: optimising a plan, which for us is a policy (the rule for choosing an action in each state). It needs two properties. Optimal substructure: the best whole is built from best pieces, as the shortest path to the wall is the shortest path to a midpoint plus the shortest path on from there. Overlapping subproblems: the pieces recur, so you solve each once and store it. MDPs (lecture 2's model: states, actions, transition chances, rewards, discount) have both: the Bellman equation splits the problem, and the value function stores the answers, "like a cache of all the good information".
**On the island:** the best way to the goal from a given square is a subproblem every route through it reuses. PLANNER stores one answer per square and never searches whole routes.

### [08:08](https://www.youtube.com/watch?v=Nd1-UUMVfz4&t=488s) Planning: the model is given, and you want a policy's value or the best policy
Planning is not full reinforcement learning: someone hands you the MDP itself, like the Atari game's source code instead of its screen. Prediction asks: given the MDP and a policy, what is its value function (expected total reward from each state)? Control asks: given only the MDP, what are the optimal values and an optimal policy?
**On the island:** both were answered from the written rules. Prediction: the uniform random policy is worth exactly -114.4 from the start square. Control: PLANNER's table and her greedy walk, return 39, the best possible.

### [13:07](https://www.youtube.com/watch?v=Nd1-UUMVfz4&t=787s) Policy evaluation: repeat the Bellman expectation equation as an update
Start every state at zero. Sweep over all states, replacing each value by a one-step look-ahead: the policy's average, over actions and over where the world sends you, of reward plus your current guess for the next state. Repeat. A synchronous sweep computes the whole new table from the old one.
`v_{k+1}(s) = sum_a pi(a|s) * ( R(s,a) + gamma * sum_s' P(s'|s,a) * v_k(s') )`
In words: new value equals the policy-weighted average of reward now plus the discounted old value of the next state (gamma is the discount, P the chance of each next state).
**On the island:** the random policy's exact values come from this: each square averages, over four moves taken a quarter of the time each, -1 plus the next square's value, with -100 for a fall. The discount is 1.

### [19:28](https://www.youtube.com/watch?v=Nd1-UUMVfz4&t=1168s) The small gridworld: a random walk's values, and a better policy for free
A 4 by 4 grid, terminal squares in two corners, -1 per step, random moves. From zeros, sweep one gives -1 everywhere but the corners; sweep two gives -2 in the middle and -1.75 beside a corner. Converged, the values read as expected steps to finish, up to 22 on the slide. The slide's second column picks, at each stage, the move that looks best under the current numbers: after three sweeps that greedy policy is already optimal, long before the values converge.
**On the island:** the strip is this grid with a cliff. Exact random-policy values: -114.4 at the start, -135.5 at the far inland corner (worse: she wanders longer, then falls anyway). RANDOM WALK actually averaged -112.7 (standard error 0.46) over 2,308 episodes of 14.9 steps, reaching the goal by luck in 1.0%.

### [29:41](https://www.youtube.com/watch?v=Nd1-UUMVfz4&t=1781s) Policy iteration: evaluate, act greedily, repeat, until nothing changes
Evaluate the policy; improve it by taking, in every state, the action with the best look-ahead; repeat. Silver says it reaches the optimal policy from any start. His example is Jack's Car Rental (a problem from Sutton and Barto's textbook, not from the lecture): two lots of up to 20 cars, Poisson rentals and returns, up to five cars moved overnight, $10 a rental. Starting from "move nothing", the policy stops changing after about four rounds.
**On the island:** Not run on the island. PLANNER used value iteration; the experiment would evaluate the random policy exactly, act greedily, count rounds until the arrows stop changing.

### [46:02](https://www.youtube.com/watch?v=Nd1-UUMVfz4&t=2762s) Why acting greedily can never make things worse
The greedy policy pi' picks the action with the highest action value q (the value of that action now, then the old policy pi after). That is at least as good as pi's own action, so one greedy step then pi beats pi; unroll it step by step and pi' beats pi everywhere. If improvement stops, the Bellman optimality equation holds, so the policy is optimal.
`q_pi(s, pi'(s)) = max_a q_pi(s, a) >= q_pi(s, pi(s)) = v_pi(s)`
In words: the best-looking action, then the old policy, is worth at least the old policy, in every state.
Greedy is not short-sighted; it "doesn't mean that we only look at one step of immediate reward", because the next state's value sums the whole future.
**On the island:** the +50 is eleven steps from the start, yet one-step greedy choices get PLANNER there, because her values already carry the news of the goal.

### [58:40](https://www.youtube.com/watch?v=Nd1-UUMVfz4&t=3520s) You need not finish evaluating before you improve
In the gridworld, everything after sweep three changed nothing about the greedy policy: "iterations 4 to infinity of our inner loop as being wasted work". Modified policy iteration stops evaluation early, at a tolerance epsilon or after k sweeps, and still converges. With k equal to 1 it is value iteration, which Silver calls probably the most popular DP method.
**On the island:** PLANNER uses the tolerance rule: sweep until the largest change in a sweep is under 0.001.

### [1:01:50](https://www.youtube.com/watch?v=Nd1-UUMVfz4&t=3710s) The principle of optimality: optimal from here means optimal from everywhere reachable
An optimal policy is an optimal first action followed by an optimal policy from wherever you land. The theorem: a policy is optimal from a state if and only if it is optimal from every state reachable from it. Unreachable states have zero probability and drop out.
**On the island:** the edge route is optimal from the start because it is optimal from every edge square it passes. The row-only bot, told only her row, cannot tell forward from back: 47.1 steps per episode against 18.6 for the full table.

### [1:03:45](https://www.youtube.com/watch?v=Nd1-UUMVfz4&t=3825s) Value iteration: work backwards from the end, without knowing where the end is
If you knew the next states' optimal values, one look-ahead with a max would give this state's. Value iteration applies that to every state, repeatedly, from any start. In his shortest-path grid the right values spread one step outward per sweep until the far corner reads -6 at the seventh table. It never needs to know where the goal is, so it handles loops, randomness and no goal at all. It keeps no explicit policy, and a midway table "might not be the value for any real policy".
`v_{k+1}(s) = max_a ( R(s,a) + gamma * sum_s' P(s'|s,a) * v_k(s') )`
In words: new value equals the best action's reward plus the discounted old value of where it leads.
**On the island:** PLANNER settled in 13 sweeps. Largest change per sweep: 101, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 48, 0.00. The 101 is a fall plus one step (stepping off is worth -101). After that, good news travels back one column per sweep, so the biggest change stays nearly level; the last sweep changes nothing and ends the loop.

### [1:24:03](https://www.youtube.com/watch?v=Nd1-UUMVfz4&t=5043s) The summary slide, and what a sweep costs
Silver says "if you get this slide, you're doing well". Prediction: Bellman expectation equation, giving iterative policy evaluation. Control: policy iteration (expectation equation plus greedy improvement) or value iteration (optimality equation), with modified policy iteration between them. With n states and m actions a sweep costs on the order of m times n squared; on action values, m squared times n squared.
`cost per sweep = O(m * n^2)`
In words: every state checks every action against every possible next state.
**On the island:** 47 non-goal squares, 4 moves, one next square per move: a sweep is instant, which is why PLANNER could be exact.

### [1:29:03](https://www.youtube.com/watch?v=Nd1-UUMVfz4&t=5343s) Asynchronous DP: update single states, in a good order
States can be updated one at a time, in any order, and still converge if every state keeps being picked. In-place DP keeps one table and always uses the newest values; a corridor swept from the goal back to the start is solved in one sweep, and swept the other way gains nothing ("the ordering really matters"). Prioritised sweeping first updates the state whose value would change most (largest Bellman error). Real-time DP updates only states the agent actually visits.
**On the island:** PLANNER is in place. Her one column per sweep fits an order that does not run goal-first; the island fact sheet does not record her order, so a reversed sweep is untested.

### [1:36:30](https://www.youtube.com/watch?v=Nd1-UUMVfz4&t=5790s) Full-width backups need the model and every branch; sample backups need neither
Each backup here is full width: every action, every next state, known probabilities. That is costly (the curse of dimensionality: states multiply with each variable; at 10 to the 170 states not even one backup fits) and it needs the model. Later lectures use sample backups: one action, one observed transition, one update, with cost independent of the number of states and no model needed. Silver leaves the convergence proof to the slides: measured by the largest gap in any state, each backup brings two value tables at least a factor gamma closer, so they converge to one unique fixed point.
`||T(u) - T(v)||_inf <= gamma * ||u - v||_inf`
In words: a Bellman backup T shrinks the worst-state gap between any two guesses by at least gamma.
**On the island:** SARSA, Q-LEARNING and the rest do sample backups from real runs, and pay in falls: Q-learning fell 26.5 times per 100 training episodes. With discount 1 the contraction slide does not apply as written; convergence rests on every episode ending (not from the lecture).

## What the island measured for this lecture

| Bot | Runs | Falls per 100 training episodes (95% interval) | Mean return, first 40 / last 40 | Clean test runs | Steps per episode |
|---|---|---|---|---|---|
| PLANNER | 10 | 0.0 (0.0 to 0.0) | 39.0 / 39.0 | 10/10 | 11.0 |
| RANDOM WALK | 11 | 97.4 (96.9 to 97.9) | -111.3 / -113.3 | n/a | 14.9 |

Neither bot was in a planned comparison (the only planned one was SARSA against Q-learning on falls), so this is description. PLANNER took 13 sweeps, reached the goal in her first episode every run, and scored the maximum. Her 0.0 to 0.0 interval shows she is deterministic, not that planning is robust: her rules had no slips, while the game slipped 0.21 times per 1,000 steps, so a wrong model was never tested. For prediction, DP says the start is worth -114.4 under the random policy; RANDOM WALK averaged -112.7 (standard error 0.46). The gap of 1.7 is several standard errors (my arithmetic), so probably not luck; the island fact sheet does not explain it, and one candidate is that the exact sum ignores the 100-step limit. The exact values also became lecture 4's yardstick (Monte Carlo table error 15.3 after 200 episodes, TD step 0.1 at 85.6).

## Guess first

<details><summary>PLANNER's biggest change per sweep was 101, then 49 ten times, 48, then 0.00. Why 13 sweeps and not 1?</summary>
A sweep lets each square see only as far as its neighbours' current values. The +50 reached the squares beside the goal in sweep one and moved back one column per sweep, so the start, eleven columns away, waited. The last sweep only confirms nothing changed.
</details>

<details><summary>Under the random policy, which is worse: the start, beside the cliff, or the far inland corner?</summary>
The inland corner: -135.5 against -114.4. Distance from the edge does not save a random walker. She just pays -1 a step for longer, then falls.
</details>

<details><summary>(With lecture 2) To get RANDOM WALK's exact values, which Bellman equation do you iterate?</summary>
The expectation equation, which averages over the random policy's moves. Iterating the optimality equation (the max) gives the best policy's values, 39 from the start, which describe PLANNER, not a bot moving at random.
</details>

<details><summary>(With lecture 1) PLANNER and Q-LEARNING both end up crossing. Which solved the reinforcement learning problem as lecture 1 defined it?</summary>
Q-LEARNING. Lecture 1 split planning (model given) from reinforcement learning (environment unknown, learn by interacting). PLANNER was handed the model, so her result says nothing about a world whose rules nobody wrote down.
</details>

<details><summary>In the gridworld, greedy after three sweeps was already optimal. Would PLANNER's table after 6 sweeps give a clean walk from the start?</summary>
Probably not; not run. With news moving one column per sweep, squares near the start have not seen the goal after 6 sweeps, so their choices rest on step costs alone.
</details>

<details><summary>(With lecture 2) If PLANNER's rules said one step in ten slips sideways at random, would her best route still hug the edge?</summary>
Not run. Value iteration handles randomness as is (the sum over next states gains terms). With -100 waiting, each edge step would risk a fall, so the route would likely move inland.
</details>

## Cards

- Q: "Programming" in dynamic programming means? | A: Optimising a plan (a policy), as in linear programming, not writing code.
- Q: The two properties DP needs? | A: Optimal substructure and overlapping subproblems.
- Q: Planning versus reinforcement learning? | A: Planning is given the MDP's rules; RL must learn from interaction.
- Q: Iterative policy evaluation? | A: Repeatedly replace each value by the policy-weighted look-ahead until values settle.
- Q: Policy iteration in one line? | A: Evaluate, act greedily, repeat; it converges to an optimal policy.
- Q: Value iteration versus modified policy iteration? | A: Value iteration is modified policy iteration with one evaluation sweep (k = 1).
- Q: PLANNER's sweeps, and why so many? | A: 13; the goal's news moved back one column per sweep.
- Q: Full-width versus sample backup? | A: Full width uses the model and every branch; a sample backup uses one real transition.

## In language-model terms

Take a model that reads a conversation, calls tools and is scored on tau-bench, where a simulated customer makes a request and a database answers. Planning would need the full transition table: for every conversation and reply, the chance of each next customer message and database state. The customer is itself a language model, so full-width DP fails for Silver's reason at 1:36:30: not one backup is affordable.

What carries over is the shape of policy iteration. Teams run a fixed agent (prompt, model, tools) many times, change it toward what scored best, and evaluate again. But evaluation is by samples (lecture 4), and the improvement theorem does not transfer: it needs exact evaluation and a greedy change in every state, and a prompt edit is neither.

A learned scorer of partial conversations (a reward model or verifier) is a fair analogy for the value function as a cache: it stores how a conversation usually ends from here. Only an analogy: nothing makes it a Bellman fixed point. The mapping breaks hardest on the state: DP assumes you can name it, and in tau-bench what matters most, what the customer actually wants, is not yet in the transcript.

## The thread to partial observability

This lecture assumes the agent knows its state and the whole model. The principle of optimality depends on it: behaving optimally from the next state only makes sense if that state summarises everything that matters. The row-only bot shows the cost of a state that does not (47.1 steps per episode, unable to tell forward from back). In the hidden-wall build, running now, a square at column 6 is shut at random each episode, so the next square depends on something the runner is not told. A planner there would plan over beliefs (her guess about which square is shut, updated by bumps), the standard extension of value iteration (not from the lecture). Carry forward: a value function is a cache keyed by state, and is only as good as that state.

## Experiments the lecture asks for that the island has not run

- Sweep goal-first, in place, and count sweeps against the measured 13.
- Run synchronous value iteration (two tables) beside in-place and compare sweep counts.
- Policy iteration from the random policy, checking whether one greedy round already gives the edge route, as in the gridworld.
- Give PLANNER a slip model (one step in ten random) and see whether her route moves inland, then walk it.
- Real-time DP: back up only squares a walking bot visits, and count backups to a clean crossing.
