# Lecture 2: Markov Decision Processes

*David Silver's lecture 2 (UCL, 2015), gone through in his order and re-explained with the Tracer experiments on Workshop Island. The lecture and its slides are his: [video](https://www.youtube.com/watch?v=lfHX2hHRMVQ), [course page](https://davidstarsilver.wordpress.com/teaching/). The words below are a re-explanation. Every island number comes from the logged runs in this repository.*

Tracer stands on one of 48 squares beside a drop, picks one of four moves, and the game tells her where she landed and what it cost. Silver's second lecture gives the form for writing that down, the Markov decision process, and a question with an exact answer: how many points each square is worth, under a given way of moving and under the best one. A random walker's start square is worth -114.4 on paper and she averaged -112.7 in the game; under the best policy (rule for choosing moves) it is worth 39, which the PLANNER computed in 13 sweeps and then walked without a fall.

## The lecture in order

### [00:50](https://www.youtube.com/watch?v=lfHX2hHRMVQ&t=50s) An MDP describes the world, not the learner
Silver puts the Markov decision process (MDP) on the environment side of last week's agent-and-environment picture. He starts with the "nice case": fully observable, the agent told the state, nothing hidden. He claims almost every problem fits: continuous control, partially observable problems, and bandits (MDPs with one state).
**On the island:** The strip in full. States: 48 squares (4 rows, 12 columns), with two endings, the goal at the right end of row 0 and the drop. Actions: forward, back, inland, toward the edge. Transitions: one square that way; off the grid on the left, right or inland, she stays put; toward the edge from row 0, she falls. Rewards: -1 per step, +50 at the goal, -100 for a fall, -50 if 100 steps pass. Discount 1. Each bot is told her square after every move.

### [03:26](https://www.youtube.com/watch?v=lfHX2hHRMVQ&t=206s) The Markov property: the present is enough
A state is Markov when, once you know it, the rest of the history adds nothing to predicting what comes next: "the future is independent of the past given the present." Then one transition probability per pair of states describes everything; stacked, they form the transition matrix, each row summing to 1.
`P[S(t+1) | S(t)] = P[S(t+1) | S(1), ..., S(t)]`
In words: adding the whole past to the present state does not change the odds of the next state.
**On the island:** Square plus move fixes the next square: 0.21 slips (steps that missed their target) per 1,000 steps, so the table is nearly all zeros and ones. Q, ROW ONLY, told only her row, is not Markov (see Guess first).

### [07:28](https://www.youtube.com/watch?v=lfHX2hHRMVQ&t=448s) The student chain, and a clock folded into the state
A Markov process (or Markov chain) is a set of states plus a transition matrix: no actions, no rewards. His cartoon student drifts between three classes, Facebook (a 0.9 self-loop), the Pub, Pass and Sleep, a terminal state that loops on itself forever. A sample, or episode, is one random run such as C1 C2 C3 Pass Sleep. At 11:35, asked about Facebook growing less addictive over time, he says: add a counter to the state, and it is Markov again.
`<S, P>`
In words: a Markov process is just the list of states and the table of moves between them.
**On the island:** The 100-step limit is such a counter. Strictly, the square alone is not Markov, since whether a step triggers the -50 depends on how many steps have passed. Every bot was blind to it.

### [13:08](https://www.youtube.com/watch?v=lfHX2hHRMVQ&t=788s) Rewards, the return, and why discount
Add rewards and a discount and the chain becomes a Markov reward process (MRP): -2 per class, -1 per Facebook step, +1 at the pub, +10 for passing. The return G is the sum of all future rewards, each shrunk by the discount gamma per step of delay; it is one random sample, with no average in it. Why discount: distrust of your own model, maths that keeps cycles finite, interest, and animals' taste for sooner reward. Undiscounted is fine when every sequence ends.
`G(t) = R(t+1) + γ R(t+2) + γ² R(t+3) + ...`
In words: the next reward, plus the one after scaled by gamma, plus the next scaled by gamma twice, and so on.
**On the island:** Discount 1 is allowed because every episode ends (goal, fall, or 100 steps), and the -1 per step does a discount's job. The best return is 39 (eleven steps, then +50); stepping straight off is -101.

### [23:19](https://www.youtube.com/watch?v=lfHX2hHRMVQ&t=1399s) Value is the average return from a state
The value v(s) is the expected return from state s. Averaging many sample returns (from Class 1 with gamma 1/2, the first is -2.25) estimates it. The returns are random, but "the value function is not a random quantity." With gamma 0, Class 2 is worth its immediate -2; with gamma 0.9 it rises to 0.9, because the +10 ahead now counts.
`v(s) = E[G(t) | S(t) = s]`
In words: a state's value is the return you get from it on average.
**On the island:** RANDOM WALK's mean return, -112.7 over 2,308 episodes (standard error 0.46), is this kind of estimate of the start square's value.

### [29:11](https://www.youtube.com/watch?v=lfHX2hHRMVQ&t=1751s) The Bellman equation, and its one-shot solution
A state's value equals the immediate reward plus the discounted value of the next state, averaged over where you land: a one-step look-ahead, drawn as a backup diagram. His check for Class 3 with gamma 1: 4.3 = -2 + 0.6 * 10 + 0.4 * 0.8. The equation is linear, so a small MRP is solved by one matrix inverse, at a cost growing with the cube of the number of states; large ones need the next lectures' iterative methods.
`v = R + γPv, so v = (I - γP)^(-1) R`
In words: value here is reward here plus gamma times the average value next; stack every state's equation and invert once.
**On the island:** The random walker's -114.4 was solved from these equations, one per square, using the written-down rules (time limit left out).

### [43:15](https://www.youtube.com/watch?v=lfHX2hHRMVQ&t=2595s) Actions turn it into a Markov decision process
The MDP adds a finite set of actions: one transition matrix per action, rewards that may depend on the action. In the student MDP the arcs become choices; only the pub stays random. The Pub is now an action leading to a chance node, where the environment rolls its dice; every other arc hides a chance node with probability 1.
`P(a; s, s') = P[S(t+1) = s' | S(t) = s, A(t) = a]`
In words: where you land now depends on what you chose as well as where you stood.
**On the island:** Four tables, one per move, almost every chance node with a single outcome. The -100 belongs to one action in one row: toward the edge from row 0.

### [46:15](https://www.youtube.com/watch?v=lfHX2hHRMVQ&t=2775s) A policy is the rule for choosing
A policy, pi, gives the chance of each action in each state. It depends only on the current state, not the time, which is enough because the state carries everything. Fix a policy and the MDP collapses back into an MRP, with dynamics averaged over its choices.
`P_π(s, s') = Σ_a π(a|s) P(a; s, s')`
In words: under a fixed policy, each next-state chance is the policy-weighted mix over actions.
**On the island:** RANDOM WALK puts 1/4 on each move everywhere, which flattens the strip into an MRP and makes her values linear to solve. SARSA's epsilon-greedy policy moves at random one time in ten (epsilon 0.1).

### [50:49](https://www.youtube.com/watch?v=lfHX2hHRMVQ&t=3049s) Two values, tied by the Bellman expectation equation
v_pi(s) is the expected return from s following pi; q_pi(s, a) is the expected return after first taking a, then following pi, and it is what you consult to choose. v is the policy-weighted average of the q's; q is the reward plus the transition-weighted average of the next v's. Under a 50-50 policy he checks Class 3: 7.4 = 0.5 * (1 + 0.2 * -1.3 + 0.4 * 2.7 + 0.4 * 7.4) + 0.5 * 10.
`v_π(s) = Σ_a π(a|s) [ R(s, a) + γ Σ_s' P(a; s, s') v_π(s') ]`
In words: average over your own choices, then over the environment's dice, of reward plus the value of where you land.
**On the island:** The random walker's four terms at the start are back (blocked, she pays 1 and stays), forward, inland, and the edge (-101). Solved: start -114.4, far inland corner -135.5.

### [1:07:57](https://www.youtube.com/watch?v=lfHX2hHRMVQ&t=4077s) Optimal value: the most any policy can get
v*(s) is the largest v_pi(s) over all policies; q*(s, a) likewise after committing to a. In the student MDP with gamma 1, v* is 10, 8, 6 back from the end, and the pub's q* of 8.4 loses to studying's 10. "If you have Q star, you're done": take the action with the biggest q*.
`v*(s) = max over π of v_π(s)`
In words: the best score any policy at all could expect from this state.
**On the island:** The PLANNER's start value is 39. From the rules (arithmetic, not a measurement), a square in row r, column c is worth 50 - (11 - c) - r under the best policy; the inland corner behind the start (row 3, column 0) is worth 36.

### [1:15:42](https://www.youtube.com/watch?v=lfHX2hHRMVQ&t=4542s) A best policy always exists, and one that never flips a coin
One policy beats another only if it is at least as good in every state, a partial ordering. The theorem: every MDP has a policy at least as good as all others; there may be several, and all reach v* and q*. Choosing the largest-q* action with probability 1 gives one, so a deterministic optimal policy always exists.
`π*(a|s) = 1 if a = argmax_a q*(s, a), else 0`
In words: always take the move with the best optimal action value.
**On the island:** The PLANNER walks greedily on her values: 10 runs, 0.0 falls per 100 episodes, 11.0 steps per episode, all 10 runs with 10 clean test crossings. From inland squares several routes are optimal, since the order of moves does not change the count.

### [1:21:47](https://www.youtube.com/watch?v=lfHX2hHRMVQ&t=4907s) Bellman optimality: maximise your choices, average the dice
The optimal values obey the same look-ahead with a maximum at your own choice. At the chance node, "There's no max here. We don't get to pick where the wind blows us." His check: Class 1 = 6 = max{-2 + 8, -1 + 6}. The max makes the equation non-linear, with no closed form in general, so it is solved by iteration: value and policy iteration next lecture, Q-learning and Sarsa later.
`v*(s) = max_a [ R(s, a) + γ Σ_s' P(a; s, s') v*(s') ]`
In words: a square's best value is the best, over moves, of the step's reward plus the average best value where it leads.
**On the island:** The PLANNER is value iteration, sweeping this equation until the largest change is under 0.001: 13 sweeps, largest changes 101, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 48, 0.00. Check at the start: forward -1 + 40 = 39, back -1 + 39 = 38, inland -1 + 38 = 37, edge -101; the max is 39.

### [1:40:21](https://www.youtube.com/watch?v=lfHX2hHRMVQ&t=6021s) The extensions stay on the slides
Out of time, Silver spends about a minute on the extensions slide, not examinable, naming them without detail: infinite and continuous MDPs (an airplane or helicopter, perhaps continuous time), partially observable MDPs (the agent sees the robot's camera, not the Markov state), and average-reward MDPs. Unspoken, on the slides only: the POMDP definition with an observation function, histories, belief states and belief trees, the continuous-control cases (LQR, Hamilton-Jacobi-Bellman), and ergodic average reward.
`b(h) = ( P[S(t) = s1 | H(t) = h], ..., P[S(t) = sn | H(t) = h] )` (slides only)
In words: a belief state lists the chance of each true state, given everything seen so far.
**On the island:** Not run yet. The hidden-wall build is planned and running, with no results.

## What the island measured for this lecture

| Bot | Lecture role | Paper value, start square | Measured | Falls per 100 (95% interval) |
|---|---|---|---|---|
| RANDOM WALK | fixed policy, so an MRP | -114.4 (time limit ignored) | mean -112.7 (standard error 0.46), 2,308 episodes, goal by luck in 1.0% | 97.4 (96.9 to 97.9), 11 runs |
| PLANNER | value iteration on the optimality equation | 39 | 39.0 in the first and last 40 episodes; first goal in episode 1 | 0.0 (0.0 to 0.0), 10 runs |

The random walker scored 1.7 points above the paper value, more than three times the standard error, so sampling noise alone is an unlikely cause. The paper value leaves out the 100-step limit, which caps the longest wanderings; that is one candidate, untested. The PLANNER, planning from the rules alone, matched the best return every episode. Neither is one of the night's comparisons; only SARSA against Q-learning (falls) was planned in advance. Not shown: that the format fits a world with real dice, or how fast a bot learns these values.

## Guess first

<details><summary>Under the random walk, which is worse to stand on: the start square beside the drop, or the far inland corner?</summary>
The inland corner, -135.5 against -114.4. Inland she wanders longer, paying 1 a step, and falls anyway. Value belongs to a square and a policy together.
</details>

<details><summary>Lecture 1 split planning (you have the rules) from learning (you only have experience). The PLANNER reached the goal in episode 1; SARSA's median first goal was episode 11. Which side explains the gap?</summary>
Planning. The PLANNER was handed the transition and reward tables, the model in lecture 1's terms, and solved the optimality equation before her first step. SARSA had to discover the same facts by falling.
</details>

<details><summary>Lecture 1 separated the environment's state from the agent's state. Is Q, ROW ONLY's state Markov?</summary>
No. Two squares in the same row have different futures but look identical to her. She dithers: 47.1 steps per episode against 18.6 with the full table.
</details>

<details><summary>Silver warns that undiscounted cycles can give infinite returns. The island uses discount 1 and has back-and-forth cycles. Are its returns finite?</summary>
Yes. Every episode ends at the goal, in a fall, or at 100 steps, and Silver says undiscounted is fine when every sequence terminates.
</details>

<details><summary>From the inland corner behind the start square, does the PLANNER have one best route or several?</summary>
Several. She needs three moves toward the edge and eleven forward, and inland squares are never dangerous, so the order does not change the return. From the start square there is only one: eleven moves forward.
</details>

<details><summary>Can the optimality equation for the island be solved with one matrix inverse, like the random walker's values?</summary>
No. The max over actions makes it non-linear, with no closed form in general. The PLANNER iterated, 13 sweeps.
</details>

## Cards

- Q: The Markov property? | A: Given the present state, the past adds nothing to predicting the future.
- Q: The five parts of an MDP? | A: States, actions, transition probabilities per action, rewards, discount factor gamma.
- Q: Return versus value? | A: The return is one episode's random total; the value is its average from that state.
- Q: When is discount 1 safe? | A: When every episode is sure to end, as on the island.
- Q: Fixing a policy does what to an MDP? | A: Turns it into a Markov reward process.
- Q: v_pi versus q_pi? | A: v_pi scores a state; q_pi scores one action in that state, then following pi.
- Q: Expectation versus optimality equation? | A: One averages over choices, the other maximises; both average over the dice.
- Q: Why no matrix inverse for v*? | A: The max makes the equation non-linear; it needs iteration such as value iteration.

## In language-model terms

Take a model working a tau-bench task (not from the lecture: a model serves a simulated customer and calls database tools, passing if the database ends right). The state is the conversation plus the database; an action is a message or tool call; the customer's and tools' replies are the transitions, the customer being the environment's dice; the reward is pass or fail at the end, and discount 1 fits because episodes end. A state's value is the chance the task passes from here.

The structure is exact in one place: a fixed model at a fixed temperature is a stochastic policy, one run is a random return, and a pass rate over many runs estimates the value. Elsewhere it is only an analogy. The action set is every possible string, nobody writes the transition table down, so there is no PLANNER.

It breaks at full observability. The customer's real goal sits in instructions the model never sees, so from the model's side the task is partially observable, the case this lecture leaves on the slides.

## The thread to partial observability

This lecture assumes the state is fully observed and says so in its first minutes. Three spoken moments point past it. At 02:33 Silver claims "any partially observed problem can be completely converted into an MDP." At 11:35 he shows how: put what you need, a counter, into the state. At 1:33:34 he describes a state that includes the observations seen so far, a belief without the word. The slides finish it: the history is always Markov, and so is a belief. On the island every bot was blind to the step clock, and the planned hidden-wall build makes the gap deliberate, with RUNNER REMEMBERS BUMPS carrying the smallest possible belief. Carry one rule forward: when your state is not Markov, add memory until it is.

## Experiments the lecture asks for that the island has not run

- Exact random-walk value with the step count in the state: whether the 100-step limit explains the 1.7-point gap.
- PLANNER with gamma 0.9: discounting changes the values, and it would show whether the route changes too.
- A noisy strip (random sideways pushes): whether the PLANNER's plan survives real dice.
- Exact values of the final SARSA and Q-LEARNING policies, square by square: Silver's partial ordering, whether either is better everywhere.
