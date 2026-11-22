# Lecture 7: Policy Gradient

*David Silver's lecture 7 (UCL, 2015), gone through in his order and re-explained with the Tracer experiments on Workshop Island. The lecture and its slides are his: [video](https://www.youtube.com/watch?v=KHZVXao4qXs), [course page](https://davidstarsilver.wordpress.com/teaching/). The words below are a re-explanation. Every island number comes from the logged runs in this repository.*

Two Tracers kept the same kind of brain: a habit table saying how strongly she leans toward each move on each square. The one named POLICY GRADIENT learned to step off the edge almost at once and never reached the goal in 14 of 15 runs. The one named ACTOR-CRITIC crossed cleanly in all 17 runs. This lecture asks how to learn habits directly, and why the two parted ways. The answer: the gradient says which way to push your habits, but how you judge each move (by the whole ending, or by a critic's step-by-step guess) decides where the push goes.

**Play it first:** [Game 7: Counter-Pick](../workshop/games/g07.md), an Overwatch custom game for this lecture that you play yourself (paste `workshop/compiled/game-07.txt` into a custom game's settings). It asks you to predict before it shows you.

## The lecture in order

### [05:03](https://www.youtube.com/watch?v=KHZVXao4qXs&t=303s) Give the policy its own adjustable numbers
Until now bots learned values (expected future reward) and acted epsilon-greedily on them (best move, sometimes a random one). Silver now parametrises the policy, the rule for choosing a move, directly: numbers he calls u (the slides write θ) that set each action's probability in each state, held in a table, a linear rule or a neural network. `π_θ(s, a) = P[a | s, θ]`
In words: the policy is the chance of action a in state s, and θ sets those chances.
**On the island:** POLICY GRADIENT and ACTOR-CRITIC each hold a "tabular softmax policy", four preferences for each of 48 squares. The value-based bots (SARSA, Q-LEARNING, MONTE CARLO and the rest) hold move scores instead.

### [10:26](https://www.youtube.com/watch?v=KHZVXao4qXs&t=626s) Why bother: smoother learning, huge action sets, randomness on purpose
Small policy steps avoid the swings of value methods, and the true gradient reaches at least a local optimum (a peak, maybe not the highest). The main reason, he says: value methods need a max over actions every step, hopeless with a trillion actions or continuous robot torques. Third, policies can be stochastic (random on purpose). The cost: plain policy gradient is slower and noisier.
**On the island:** four moves make the max trivial, and PLANNER's fixed route earns 39 every time.

### [14:29](https://www.youtube.com/watch?v=KHZVXao4qXs&t=869s) Rock-paper-scissors: the best policy can be random
Any fixed choice is exploited: always rock, always lose to paper. The only Nash equilibrium (neither player gains by changing alone) plays each option a third of the time.
**On the island:** in the exploratory lecture 10 build, a learning blocker facing a runner who saw her row spread over all four rows (0.36, 0.28, 0.14, 0.21); four short runs cannot tell a mixed strategy from unfinished learning.

### [15:26](https://www.youtube.com/watch?v=KHZVXao4qXs&t=926s) The aliased gridworld: two squares that look the same
The slide shows five squares in a top corridor, money below the middle one, skulls below the two ends. Squares two and four are grey. At [15:30] Silver says this arises when the Markov property fails (what you see no longer tells you everything that matters): the world is partially observed, or, equivalently, your features hide something. At [16:20] he fixes the features: "outside wall to the north and I move east", and so on for every wall and move.

At [17:49] a student names the problem: each grey square has walls north and south only, so "grey square, moving west" gives the same features in both. At [18:15] Silver draws the consequence: a deterministic policy must choose the same move in both, and a value function must give them equal values, so greedy goes always west or always east. Take always west. From the right grey square, west reaches the middle and drops onto the money. From the left one, west reaches the corner, the corner sends her east, back to grey, west again. Greedy oscillates forever; epsilon-greedy, for a long time.

At [19:15] the fix: east or west with probability 0.5 in grey squares, which reaches the money in a few steps. At [19:54]: "whenever state aliasing occurs, a stochastic policy can do better than a deterministic policy." At [20:02] he squares this with lecture 2's theorem that every MDP has a deterministic optimal policy: that assumes a perfect state description.
`π_θ(wall to N and S, move E) = 0.5`
In words: when she cannot tell which grey square she is in, a coin flip beats every fixed choice.
**On the island:** Q, ROW ONLY sees only her row. Her case is milder: forward is right in every edge-row square, but forward and back both seem to lead "to the place she is already in", so she dithers (47.1 steps per episode against 18.6 for full Q-learning; 3 of 10 runs clean at test). The planned hidden-wall build is the island's grey squares: RUNNER BLIND meets two situations that look identical. It has no results yet.

### [20:42](https://www.youtube.com/watch?v=KHZVXao4qXs&t=1242s) What "better" means: three objectives
With a start state, use the start value. In tasks that never end, use the average value over visited states, or average reward per step. All three give essentially the same gradient direction.
`J_1(θ) = V^πθ(s_1)`
In words: a policy's score is the reward it collects on average from the start.
**On the island:** the expected return of a crossing. The best is 39; the exact start value under RANDOM WALK is -114.4.

### [26:37](https://www.youtube.com/watch?v=KHZVXao4qXs&t=1597s) The blunt way: nudge each number and measure
Gradient-free search works, but gradients are usually more efficient. The crudest is finite differences: nudge one parameter, measure, repeat for each. It works even for non-differentiable policies, but a million parameters means a million noisy evaluations. At [30:19], RoboCup's AIBO dogs: 12 gait numbers, a dozen runs up the field per gradient step, and a much faster walk.
`∂J/∂θ_k ≈ (J(θ + ε u_k) − J(θ)) / ε`
In words: the slope along one dial is how much the score changes when you turn it slightly.
**On the island:** Not run on the island; it would need many crossings for each of 192 nudged preferences, per step.

### [33:46](https://www.youtube.com/watch?v=KHZVXao4qXs&t=2026s) The score function, for softmax and Gaussian policies
The likelihood-ratio trick multiplies and divides the policy's gradient by the policy, giving policy times gradient of log policy. That gradient of the log, the score function, is what maximum-likelihood learning follows to make an action more likely, and it makes the gradient an average over the bot's own moves. For softmax (probability proportional to e raised to a preference, [36:41]) the score is the chosen action's features minus the average features. For a Gaussian policy over continuous actions [39:25], it is action minus mean, times features, over the variance. Both say "how much more than usual am I doing something" [41:14].
`∇θ log π_θ(s,a) = φ(s,a) − E_πθ[φ(s,·)]`
In words: the push is "this was the move I made" minus "how likely I was to make it".
**On the island:** in a table, the chosen move gets 1 minus its probability and each other move gets minus its probability.

### [41:45](https://www.youtube.com/watch?v=KHZVXao4qXs&t=2505s) The policy gradient theorem
For a one-step problem (a contextual bandit), the gradient of expected reward is the expected score times reward, with no model needed. At [46:32] the multi-step version swaps the reward for Q, the long-run value of the action. Where supervised learning pushes toward a teacher's action, here each action taken is pushed by how good it was.
`∇θ J(θ) = E_πθ[∇θ log π_θ(s,a) Q^πθ(s,a)]`
In words: make good moves more likely in proportion to how good they are.
**On the island:** Q for stepping off from row 0 is about -101; Q for forward is what the two bots estimate differently.

### [48:26](https://www.youtube.com/watch?v=KHZVXao4qXs&t=2906s) REINFORCE: the real return stands in for Q
Monte Carlo policy gradient plugs in the return (rewards from that step to the end), nudging each step after the episode. The puck at [50:56] learns smoothly but takes around 100 million iterations: slow and high variance [52:28].
`Δθ_t = α ∇θ log π_θ(s_t, a_t) v_t`
In words: after the episode, push each move by its score times the reward that followed, times a step size α.
**On the island:** POLICY GRADIENT, with a per-state baseline, step 0.02. A beginner rarely sees the +50; of the endings she sees, stepping off at once (-101) beats wandering then falling (about -110) or timing out (-150). She fell in 96.5 of every 100 training episodes; last-40 return -101.6.

### [52:54](https://www.youtube.com/watch?v=KHZVXao4qXs&t=3174s) Actor-critic: a learned judge replaces the raw return
The actor holds the policy and acts; the critic estimates value with any evaluation method from earlier lectures, and the actor moves where it points. In the Q actor-critic [57:14], a linear TD(0) critic lets both update every step. His Venn diagram [1:01:37]: actor-critic methods hold both a value and a policy. At [1:05:27], on local optima: a table softmax following the gradient is known to reach the global optimum; with neural networks neither family is guaranteed.
`Δθ = α ∇θ log π_θ(s,a) Q_w(s,a)`
In words: push each move by the critic's opinion of it, not by one noisy ending.
**On the island:** ACTOR-CRITIC is one-step, with a TD(0) critic (actor step 0.1, critic 0.2).

### [1:07:03](https://www.youtube.com/watch?v=KHZVXao4qXs&t=4023s) Baselines and the advantage
Subtract any baseline that depends only on the state: its expected effect is zero, because action probabilities sum to 1 and a constant's gradient is 0. Noise falls; direction holds. Using the state value V leaves the advantage, Q minus V (Silver calls it D): how much better than usual this action is here.
`∇θ J(θ) = E_πθ[∇θ log π_θ(s,a) A^πθ(s,a)]`
In words: push up moves that beat your usual result from that square.
**On the island:** POLICY GRADIENT had this baseline. Stepping off really was better than her usual ending, so it still got pushed up.

### [1:13:06](https://www.youtube.com/watch?v=KHZVXao4qXs&t=4386s) The TD error is a sample of the advantage
With the true V, the TD error's expected value given state and action is Q minus V. At [1:14:47]: "the TD error is an unbiased sample of the advantage function." So the critic learns only V. His picture: you thought you were winning, made a move, now think you are losing; that move was probably bad.
`δ = r + γ V_v(s') − V_v(s)`
In words: the surprise after one step is the verdict on the move just made.
**On the island:** this is ACTOR-CRITIC. Her critic's guess for an unvisited square starts at zero, far above -101, so forward kept looking better than the edge: 7.1 falls per 100.

### [1:17:14](https://www.youtube.com/watch?v=KHZVXao4qXs&t=4634s) Eligibility traces for the actor
The actor can use any time scale too: full return minus baseline (unbiased, noisy) or the one-step TD target (less noise, some bias from bootstrapping, that is, leaning on its own estimates). A trace of recent scores mixes them: backward TD(λ) with the score in place of the value gradient, run online.
`e_{t+1} = λ e_t + ∇θ log π_θ(s,a)`, `Δθ = α δ e`
In words: keep a fading memory of recent pushes and apply each surprise to all of them.
**On the island:** Not run on the island for an actor; SARSA LAMBDA uses traces for values only (11.8 falls per 100 against 16.3 for SARSA).

### [1:23:44](https://www.youtube.com/watch?v=KHZVXao4qXs&t=5024s) An unbiased critic, a deterministic shortcut, and the summary
A critic could bend the gradient. Compatible function approximation says it does not if the critic's features are the policy's score and its weights minimise squared error. At [1:26:06] he adds his group's deterministic policy gradient (not on these slides): for continuous actions, follow the critic's slope with respect to the action. At [1:30:07]: "I'm going to skip the natural actor critic." The summary [1:30:32]: every variant pushes by score times some value estimate and differs only in the critic.
**On the island:** Not run on the island; both would need a continuous action, such as a running angle.

## What the island measured for this lecture

| Measure | Policy gradient | Actor-critic | Q-learning |
|---|---|---|---|
| Runs | 15 | 17 | 11 |
| Falls per 100 training episodes (95% interval) | 96.5 (93.2 to 98.9) | 7.1 (6.8 to 7.5) | 26.5 (22.4 to 30.4) |
| Mean return, first 40 / last 40 | -112.3 / -101.6 | -45.4 / 34.7 | -57.6 / 7.5 |
| Runs never reaching the goal | 14 | 0 | 0 |
| Runs with 10 clean test crossings | 0/15 | 17/17 | 11/11 |

Last-40 return differences: actor-critic minus policy gradient 136.35 (135.66 to 137.17); policy gradient minus Q-learning -109.08 (-117.07 to -101.30); actor-critic minus Q-learning 27.27 (18.72 to 34.83). Falls, actor-critic minus Q-learning: -19.38 (-23.31 to -15.09). All four are exploratory, uncorrected for multiple comparisons; only SARSA against Q-learning on falls was planned. They show that, with untuned settings and 150 episodes, judging moves by the whole ending taught a softmax policy to step off, and a TD critic prevented it. MONTE CARLO, also judging by the ending, fell the same way (98.3 per 100). They do not show that REINFORCE fails in general: Silver's puck needed about 100 million iterations, and the bots' step sizes differ (0.02 against 0.1).

## Guess first

<details><summary>A new POLICY GRADIENT Tracer has seen three endings: wandered then fell (about -110), timed out (-150), stepped straight off (-101). Which move does REINFORCE with a baseline strengthen most?</summary>
Stepping off. It is the best ending she knows, so it beats her baseline; the +50 never enters her sums. Hence 14 of 15 runs never reached the goal.
</details>

<details><summary>ACTOR-CRITIC has the same kind of habit table but bootstraps like lecture 4's TD. Does she learn to jump?</summary>
No. Her verdict on a move is the TD error, which leans on the critic's guess for the next square, starting at zero, well above -101. Forward looks good before she sees the goal. All 17 runs clean.
</details>

<details><summary>Lecture 2 proved every MDP has a deterministic optimal policy. Does the aliased gridworld break that?</summary>
No. The theorem needs the true state. The agent sees only wall features, which two squares share, so what it observes is not an MDP [20:02].
</details>

<details><summary>Does subtracting a baseline change the average direction of the update, its noise, or both?</summary>
Only the noise: the baseline term averages to zero because probabilities sum to 1 [1:07:03]. So it could not stop POLICY GRADIENT from learning to step off.
</details>

<details><summary>On the full strip, would PLANNER do better with a coin flip somewhere?</summary>
No. The strip is fully observed and nearly deterministic (0.21 slips per 1,000 steps), so a fixed route is optimal: 39 every time. Randomness pays only against an adaptive opponent or under aliasing.
</details>

<details><summary>Lecture 5's MONTE CARLO control and this lecture's REINFORCE are different families. What shared habit made both fail on the island?</summary>
Both judge a move by the complete return after it, and early on the best return either has seen is stepping off. MONTE CARLO fell 98.3 times per 100, POLICY GRADIENT 96.5. Every TD learner reached the goal in every run.
</details>

## Cards

- Q: What do value-based, policy-based and actor-critic methods store? | A: Values; a policy; both.
- Q: Two reasons a stochastic policy can be optimal? | A: An exploiting opponent; aliased states needing different moves.
- Q: Why does greedy fail in the aliased gridworld? | A: Both grey squares share features, so it goes one way in both and bounces forever from one.
- Q: What is the score function? | A: The gradient of the log policy: the push that makes the chosen action likelier.
- Q: Policy gradient theorem? | A: Gradient of the objective equals expected score times Q of the action taken.
- Q: What does REINFORCE use for Q? | A: The actual return from that step to the episode's end.
- Q: Why subtract a baseline? | A: Lower variance, same expected gradient; with V it turns Q into the advantage.
- Q: Why can the TD error stand in for the advantage? | A: With the true V, its expected value is Q minus V.

## In language-model terms

A language model is a softmax policy, exactly: a preference for every token, the next drawn in proportion to e raised to it. The score for a sampled token is one for the token drawn minus its probability, the island habit table's arithmetic. Silver's main reason, no max over a vast action set, fits.

In tau-bench an agent reads a conversation, calls tools, and is scored at the end on whether a simulated customer's task was done (not from the lecture). Pushing up the tokens of well-scored conversations is REINFORCE; the average score of several attempts at the same task is a baseline; a model scoring partial conversations is a critic.

The island's trap is an analogy there: an agent that rarely sees success may learn the least-bad ending, such as handing off early. The mapping breaks in two places. An episode is thousands of token choices, so the noise is far worse. And the agent sees the conversation, not the customer's real wishes: partial observability, with sampling temperature as the grey squares' coin flip.

## The thread to partial observability

At [15:30] Silver ties aliasing to the loss of the Markov property, and treats "partially observed" and "my features hide something" as one situation. At [20:02] he limits the deterministic-policy theorem to a perfect state description. A policy reading only the current observation can need randomness, which greedy value methods cannot give, since aliased states get one value and so one action. Carry forward two remedies: randomise, the best a memoryless policy can do, or remember (an agent recalling its last move could leave the left grey square without a coin flip; this point is not from the lecture). The planned hidden-wall build sets RUNNER BLIND beside RUNNER REMEMBERS BUMPS, the smallest possible memory.

## Experiments the lecture asks for that the island has not run

- A softmax policy-gradient runner in the hidden-wall blind condition against greedy Q-learning: tests whether randomness beats a fixed habit under aliasing.
- REINFORCE with and without baseline, longer, at several step sizes.
- Actor-critic with a trace on the actor: tests whether credit reaches early moves faster.
- Finite differences on the 192 preferences: the cost of a gradient without the score function.
- A Gaussian policy over a continuous running angle, where policy methods matter most.
