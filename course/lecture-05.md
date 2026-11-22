# Lecture 5: Model-Free Control

*David Silver's lecture 5 (UCL, 2015), gone through in his order and re-explained with the Tracer experiments on Workshop Island. The lecture and its slides are his: [video](https://www.youtube.com/watch?v=0g4j2k_Ggc4), [course page](https://davidstarsilver.wordpress.com/teaching/). The words below are a re-explanation. Every island number comes from the logged runs in this repository.*

On the island, Tracers never told the rules learn to walk a strip beside a deadly drop, and two of them, SARSA and Q-LEARNING, differ by one line of arithmetic. SARSA ends up further from the edge and falls less while learning; Q-LEARNING hugs the edge and falls more, yet her final route is the better one. This lecture explains why: SARSA learns the value of the walker she really is, stumbles included, while Q-LEARNING learns the value of a perfect walker while stumbling.

## The lecture in order

### [04:09](https://www.youtube.com/watch?v=0g4j2k_Ggc4&t=249s) Two ways to learn: on the job, or over someone's shoulder
Control means finding the best behaviour in an unknown world, where lecture 4's prediction only scored a fixed one. On-policy learning is "learning on the job": you learn about the policy (the rule for choosing a move) you are following. Off-policy learning is "looking over someone's shoulder": you learn about one policy from experience made by another, such as a robot watching a human steer an arm.
**On the island:** SARSA, SARSA LAMBDA and MONTE CARLO are on-policy: each learns about her own slightly random walking. Q-LEARNING is off-policy: she walks with random steps but learns about a version of herself that never takes one.

### [05:35](https://www.youtube.com/watch?v=0g4j2k_Ggc4&t=335s) The loop from lecture 3, and why it needs action values
The frame is generalised policy iteration: evaluate the current policy, improve it, repeat. First try: evaluate by Monte Carlo (average real returns) and improve greedily. Two things break. Acting greedily skips parts of the world, so they are never learned. And greedy choice over V, the value of each state, needs a model to see where each move lands [09:53]. Q, the action value, scores each state and move together, so improvement is just reading off the top score. `pi'(s) = argmax_a Q(s, a)`. In words: in each state, pick the move with the largest stored score, no look-ahead needed.
**On the island:** PLANNER runs this loop with the rules written down. Every learner instead keeps a table of 48 squares by 4 moves. She never needs to know that "toward the edge" from row 0 is a fall, only that its score is very low.

### [13:27](https://www.youtube.com/watch?v=0g4j2k_Ggc4&t=807s) The two doors, and epsilon-greedy
The left door gives 0, the right gives +1, then +3, so a greedy chooser opens the right door forever and never learns the left one's worth. The fix, which Silver says is surprisingly hard to beat, is epsilon-greedy: with small probability epsilon pick a move at random, otherwise the best-scoring one. `pi(a|s) = epsilon/m + 1 - epsilon` for the greedy move, `epsilon/m` for the others. In words: with m moves, the best gets nearly all the probability and every other move keeps a small, never-zero share.
**On the island:** epsilon is 0.1 with 4 moves, so in row 0 the edge move has a 0.025 chance every step. Over eleven edge-row steps that is about a 24% chance of a fall (arithmetic, not a measurement), near Q-LEARNING's measured 26.5 per 100 episodes; a rough match, since her route is not always the edge row.

### [17:41](https://www.youtube.com/watch?v=0g4j2k_Ggc4&t=1061s) Epsilon-greedy is still an improvement
His one slide of maths proves that going epsilon-greedy on an epsilon-greedy policy's Q values never makes things worse, because the best move's value beats any weighted average of move values. Unrolled with the Bellman equation (lecture 2's one-step consistency rule) [18:43], this gives `v_pi'(s) >= v_pi(s)`. In words: soften greed with a little randomness and each round still helps. A student asks whether this says how much to explore. It does not.
**On the island:** Not run on the island. The test: freeze each table every 10 episodes and check that her policy's exact value never drops.

### [25:37](https://www.youtube.com/watch?v=0g4j2k_Ggc4&t=1537s) GLIE: explore forever, become greedy in the end
GLIE (greedy in the limit with infinite exploration) demands two things: every state and move tried infinitely often, and the policy tending to greedy. Epsilon = 1/k on episode k does it. GLIE Monte Carlo control updates after each episode: `Q(S,A) <- Q(S,A) + (1/N(S,A)) (G - Q(S,A))`. In words: each visited pair's score becomes the running average of the returns that followed it. It converges to the best action values, and finds the best blackjack policy [35:20]. On starting values [32:48] he corrects himself mid-answer: a 1/N average erases them on the first visit, but with a constant step size they matter.
**On the island:** no bot is strictly GLIE. Most keep epsilon at 0.1. MONTE CARLO uses a constant step of 0.2, and MONTE CARLO + OPTIMISM starts every Q at 40, which Silver's remark says should matter. It did not: late return differed by 0.27 (-0.51 to 1.14), inconclusive.

### [41:01](https://www.youtube.com/watch?v=0g4j2k_Ggc4&t=2461s) SARSA: TD on action values, improved every step
Swap Monte Carlo for TD learning (lecture 4's update-from-the-next-guess method) and improve the policy every step. The name spells the update: State, Action, Reward, next State, next Action. `Q(S,A) <- Q(S,A) + alpha (R + gamma Q(S',A') - Q(S,A))`. In words: nudge the score of what she just did toward the reward plus the score of the move she has actually chosen next (alpha is the step size, gamma the discount). The target samples the Bellman equation for the policy being followed, so SARSA is on-policy at its root [48:03].
**On the island:** SARSA uses alpha 0.5, epsilon 0.1. Her next move is sometimes random, so an edge square inherits the cost of her own stumbles there, and she drifts inland.

### [48:12](https://www.youtube.com/watch?v=0g4j2k_Ggc4&t=2892s) When SARSA converges, and the windy gridworld
SARSA reaches the best action values if the policies are GLIE and the step sizes shrink correctly (their sum infinite, the sum of their squares finite). In practice, he says, people ignore both and it usually works. In the windy gridworld (fixed step and epsilon, wind pushing the agent up, -1 per step), the first episode takes about 2,000 steps, then episodes speed up sharply, staying "bubbly" because epsilon never decays.
**On the island:** the same shape. SARSA's median first goal came at episode 11, Q-LEARNING's at 13; RANDOM WALK reached it by luck in 1.0% of episodes. Fixed epsilon is why both keep falling.

### [53:36](https://www.youtube.com/watch?v=0g4j2k_Ggc4&t=3216s) n-step SARSA and the lambda return
As in lecture 4 there is a spectrum. An n-step target adds n real rewards, then bootstraps (leans on the table's own guess) n steps later. `q_t(n) = R_t+1 + gamma R_t+2 + ... + gamma^n Q(S_t+n, A_t+n)`. In words: count n real rewards, then guess the rest. SARSA(lambda) averages all of them with weights `(1 - lambda) lambda^(n-1)`. In words: short looks weigh most, each longer one a factor lambda less. Lambda 1 is Monte Carlo; lambda 0 is plain SARSA.
**On the island:** SARSA LAMBDA uses lambda 0.8; MONTE CARLO is the far end.

### [1:02:01](https://www.youtube.com/watch?v=0g4j2k_Ggc4&t=3721s) Eligibility traces: credit flows back in one episode
The forward view waits for the episode's end, so Silver gives the backward view: a second table, the eligibility trace, marking how recently and often each state and move was used. `E_t(s,a) = gamma lambda E_t-1(s,a) + 1(S_t = s, A_t = a)`, then every pair moves by `alpha delta E(s,a)`. In words: each surprise (delta, the TD error) is shared out to recent moves in proportion to their trace. In his gridworld, one-step SARSA learns about one more move per episode; SARSA(lambda) updates most of the path at once. Lambda "defeats the tyranny of the time step" [1:10:14].
**On the island:** SARSA LAMBDA fell less than SARSA, 11.8 against 16.3 per 100 (difference -4.51, interval -6.21 to -2.78, exploratory). Her median first goal came at episode 14, later than SARSA's 11.

### [1:19:55](https://www.youtube.com/watch?v=0g4j2k_Ggc4&t=4795s) Why learn off-policy, and why importance sampling mostly fails
Off-policy learning follows a behaviour policy mu while evaluating a target policy pi. Reasons: learn from humans, reuse old experience (as in his Atari work), learn the best policy while exploring, learn many policies from one stream of life. Importance sampling reweights each sample by how much likelier it is under pi. `G^(pi/mu) = [pi(A_t|S_t)/mu(A_t|S_t)] ... [pi(A_T|S_T)/mu(A_T|S_T)] G_t`. In words: multiply one ratio per step across the episode. For Monte Carlo the product almost never matches, and "in practice it's just useless" [1:27:09]. TD needs one ratio, far better but still able to blow up.
**On the island:** Not run on the island. Judging the 11-step greedy route from RANDOM WALK's logs would weight a matching episode by 4^11, about 4.2 million (arithmetic), and every other by zero.

### [1:28:46](https://www.youtube.com/watch?v=0g4j2k_Ggc4&t=5326s) Q-learning: bootstrap from the move you would have made
Q-learning needs no ratios. She acts with her behaviour policy but bootstraps from the target policy's move. When the target is greedy, that move's score is the maximum: `Q(S,A) <- Q(S,A) + alpha (R + gamma max_a' Q(S',a') - Q(S,A))`. In words: nudge the score of what she did toward the reward plus the best score available where she landed, whatever she does next. It samples the Bellman optimality equation; behaviour stays epsilon-greedy, the target is greedy, and it converges to the best action values [1:33:59].
**On the island:** Q-LEARNING uses alpha 0.5, epsilon 0.1. An edge square keeps its perfect-walk score because the max ignores her stumbles, so she keeps walking there and pays for them.

### [1:34:04](https://www.youtube.com/watch?v=0g4j2k_Ggc4&t=5644s) The cliff walk: on the slides, not in the talk
Silver never discusses the lab's central example. He states Q-learning's convergence at [1:33:59], calls it a standard idea at [1:34:04], and at [1:34:10] starts to wrap up. The pseudocode, demo and cliff slides pass unmentioned in all three witnesses. Slide 40 shows a grid with -1 per step, -100 for stepping into "The Cliff", a "safe path" along the far row and an "optimal path" beside the cliff, and a plot over 500 episodes where SARSA's reward per episode settles near -25 and Q-learning's near -50 (read by eye). Its unspoken point (the slide gives no epsilon): SARSA learns the safe route and earns more while learning; Q-learning learns the optimal route and keeps falling.
**On the island:** the direction matches. SARSA earned more over the last 40 episodes (22.3 against 7.5), fell less (16.3 against 26.5 per 100) and walked 3.88 m from the edge against 2.07 m. The island adds what the slide lacks: with exploring off, Q-LEARNING crossed cleanly in 11 of 11 runs, SARSA in 13 of 16.

### [1:34:10](https://www.youtube.com/watch?v=0g4j2k_Ggc4&t=5650s) The table that ties dynamic programming to TD
Each dynamic-programming backup (a full average over outcomes, using the model) has a twin built from one real step. Iterative policy evaluation becomes TD learning; Q-policy iteration becomes SARSA; Q-value iteration, from the Bellman optimality equation, becomes Q-learning. `x <-alpha y` means `x <- x + alpha (y - x)`. In words: where DP takes an expectation, TD takes one sample and moves a step toward it.
**On the island:** PLANNER is the left column; RANDOM WALK's TD tables, SARSA and Q-LEARNING are the right.

## What the island measured for this lecture

| Bot | Runs | Falls per 100 training episodes (95% interval) | Mean return, last 40 | Distance from edge, last 40 (m) | Runs with 10 clean test crossings |
|---|---|---|---|---|---|
| SARSA | 16 | 16.3 (15.3 to 17.4) | 22.3 | 3.88 | 13/16 |
| Q-LEARNING | 11 | 26.5 (22.4 to 30.4) | 7.5 | 2.07 | 11/11 |
| EXPECTED SARSA | 9 | 13.2 (12.0 to 14.4) | 27.3 | 3.56 | 9/9 |
| SARSA LAMBDA | 14 | 11.8 (10.5 to 13.2) | 22.4 | 5.06 | 13/14 |
| MONTE CARLO | 10 | 98.3 (97.7 to 98.8) | -102.2 | 0.18 | 0/10 |

The one comparison planned before the night was SARSA against Q-LEARNING on falls: -10.14 per 100 (95% interval -14.18 to -5.83, p 0.0000, 16 and 11 runs). The rest are first looks, uncorrected for the number of comparisons: SARSA stood 1.82 m further from the edge (1.38 to 2.23) and earned 14.86 more (5.43 to 23.42); EXPECTED SARSA, a variant not in this lecture, fell 13.30 less than Q-LEARNING (-17.50 to -8.96); MONTE CARLO earned 124.55 less than SARSA (-128.57 to -119.83) and never reached the goal. A beginner never sees the +50, and stepping off at once (-101) beats wandering then falling, so judging moves by whole endings teaches her to step off; TD bots lean on unknown squares valued at zero. What this does not show: one step size and epsilon per method, 150 episodes, one night, no GLIE bot, so nothing tests Silver's convergence theorems; MONTE CARLO's failure concerns constant-step, fixed-epsilon Monte Carlo, not GLIE Monte Carlo control.

## Guess first

<details><summary>SARSA and Q-LEARNING both take one random step in ten all run. Which falls more while learning?</summary>
Q-LEARNING: 26.5 per 100 against 16.3, the night's planned comparison (difference -10.14, interval -14.18 to -5.83). Her edge scores assume she never stumbles, so she keeps walking the edge and her random steps take her over. SARSA's scores include her stumbles, so she moves inland.
</details>

<details><summary>Switch exploring off for the test crossings. Whose table gives the more reliable crossing?</summary>
Q-LEARNING: 11 of 11 runs crossed cleanly every time, against 13 of 16 for SARSA. Her target was always greedy, so her table describes the best route; SARSA's describes a stumbling walker.
</details>

<details><summary>Lecture 3's PLANNER walked greedily on state values V. Why can't a learning bot do the same with a V learned from experience?</summary>
Greedy choice on V means asking where each move lands, which needs the rules PLANNER had. Q already scores each move, so greedy choice is reading the largest entry [09:53].
</details>

<details><summary>In lecture 4, Monte Carlo was the most accurate predictor on the island. Will MONTE CARLO be the best controller?</summary>
No: 98.3 falls per 100 and no goal in any run. Predicting a fixed walker is not choosing moves from your own early estimates. Early returns show only falls and timeouts, and stepping off at once is the least bad, so she learns to jump.
</details>

<details><summary>Q + FADING EXPLORATION uses epsilon = 1/(1 + episode/5) with a floor of 0.01. Is she GLIE?</summary>
Not strictly: the floor means she never becomes fully greedy. Her falls against Q-LEARNING differed by 1.44 per 100 (-3.25 to 6.17), inconclusive.
</details>

<details><summary>Using RANDOM WALK's 2,308 logged episodes, you estimate the greedy route's value by off-policy Monte Carlo. What do the weights look like?</summary>
Each step's ratio is 4 when the random move matches the greedy one and 0 otherwise. Nearly every episode gets weight 0; an exact 11-step match gets about 4.2 million (arithmetic). That is the variance Silver calls useless.
</details>

## Cards

- Q: On-policy learning? | A: Learning about the policy you are following, random moves included.
- Q: Off-policy learning? | A: Learning about a target policy from experience made by a different behaviour policy.
- Q: Why Q and not V for model-free control? | A: Greedy choice over V needs the rules to look ahead; over Q it does not.
- Q: Epsilon-greedy? | A: With probability epsilon a random move, otherwise the best-scoring move.
- Q: GLIE? | A: Every state and move tried infinitely often, and the policy becoming greedy. Example: epsilon = 1/k.
- Q: SARSA target? | A: R + gamma Q(S', A'), with A' the move she will actually take next.
- Q: Q-learning target? | A: R + gamma max over a' of Q(S', a'), the best move from the next state.
- Q: Why does off-policy Monte Carlo fail? | A: Importance ratios multiply over the whole episode, so variance explodes.

## In language-model terms

A tool-using agent in tau-bench (a model talks to a simulated customer and calls tools such as order lookup or cancellation) runs episodes: one conversation, scored at the end on whether the database ends up right. Generalised policy iteration maps onto training: score conversations, shift the model toward what scored well, repeat. Sampling temperature is epsilon only by analogy.

The cliff transfers as a caution. A plan best under perfect execution can be poor for an agent that sometimes slips, and some tool calls (cancel, refund) cannot be undone, like the edge. Judging a strategy with the slips included is the SARSA question; judging it by flawless execution is the Q-learning question.

The off-policy part is close to exact. Training on transcripts from an older model or from people is off-policy learning, and a long transcript's probability ratio under two models is a product over hundreds of tokens, which explodes as Silver says. The mapping breaks at the table: the state is the whole conversation, and there is no Q table.

## The thread to partial observability

Every table here is indexed by the true state, and every convergence result assumes the agent sees it. Exploration is information gathering: in the two-doors example the agent's beliefs can be wrong, and only trying the doors fixes them [15:28]. The eligibility trace is a memory of recent history, used for credit, never for choosing a move. On the island, Q, ROW ONLY sees only her row, so different squares look identical to her; she fell 42.5 times per 100 against 26.5 for full Q-LEARNING and dithered along the edge. The hidden-wall build being run now asks whether a small memory of bumps can stand in for a state she is not told. Carry forward: these guarantees hold only when the table's index is the full state.

## Experiments the lecture asks for that the island has not run

- SARSA and Q-LEARNING with epsilon = 1/k and no floor, run long: GLIE should pull SARSA back to the edge row.
- Monte Carlo control as on the slide (1/N averages, epsilon = 1/k): is the jumping caused by constant steps and fixed epsilon, or by the method.
- n-step SARSA for n = 1, 2, 4, 8, 16: where on the spectrum learning to jump begins.
- PLANNER's route judged from RANDOM WALK's logs, full-episode against one-step importance sampling: the variance gap.
- Silver's windy-gridworld plot for the island: episodes completed against real steps.
