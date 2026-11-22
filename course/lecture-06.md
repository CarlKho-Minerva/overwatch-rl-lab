# Lecture 6: Value Function Approximation

*David Silver's lecture 6 (UCL, 2015), gone through in his order and re-explained with the Tracer experiments on Workshop Island. The lecture and its slides are his: [video](https://www.youtube.com/watch?v=UoPei5o4fps), [course page](https://davidstarsilver.wordpress.com/teaching/). The words below are a re-explanation. Every island number comes from the logged runs in this repository.*

Every bot on the island so far kept a table: one number for each of 48 squares and 4 moves. Silver's sixth lecture asks what replaces the table when states are too many to list, store or learn one by one. His answer: a function with a few adjustable weights, trained toward the same Monte Carlo and TD targets as before, so that learning in one state moves the estimate in similar states. The island ran the mildest version, two Q-learning bots told less about where they stand: one learned faster than the full table, the other crossed cleanly in only 3 of 10 runs.

## The lecture in order

### [01:34](https://www.youtube.com/watch?v=UoPei5o4fps&t=94s) Tables stop working when states cannot be listed
Backgammon has about 10 to the 20 states, Go about 10 to the 170, and a robot in continuous space infinitely many. "You can't just build a table anymore." The table will not fit in memory, and even if it did, learning each entry separately needs too much experience. Silver wants generalisation: standing here and standing one millimetre to the right should not be learned twice.
**On the island:** The game reports Tracer's position as continuous coordinates, and the lab snaps it to one of 48 squares. So even the full-table Q-LEARNING bot uses a hand-made approximation: every point inside a 2 m square counts as the same state.

### [05:45](https://www.youtube.com/watch?v=UoPei5o4fps&t=345s) Replace the table with a function that has weights
The fix is a function that takes a state and returns an estimated value, controlled by a weight vector w much shorter than the list of states. `v̂(s, w) ≈ vπ(s)`. In words: a small set of numbers w should give roughly the true value of following the policy π (the bot's rule for choosing a move) from any state. For action values (how good a move is in a state) Silver shows two shapes: feed in a state and one action and get one number, or feed in a state and get every action's value at once, as the Atari player did.
**On the island:** Counting from the setup, Q-LEARNING has 192 numbers, Q, 16 COARSE STATES has 16 groups times 4 moves, 64, and Q, ROW ONLY has 4 rows times 4 moves, 16. Each smaller bot keeps one number per move per group of squares; the groups are where generalisation happens.

### [12:44](https://www.youtube.com/watch?v=UoPei5o4fps&t=764s) Differentiable approximators, trained by gradient descent
Silver keeps to approximators with a gradient (linear sums of features, neural networks), so he knows how each weight changes the output. He warns that the data is unlike supervised data: the target moves as the policy improves, and consecutive samples are correlated because they come from one trajectory. Pretending an oracle gives the true value, he derives stochastic gradient descent, a small weight change after each sample. `Δw = α (vπ(S) − v̂(S, w)) ∇w v̂(S, w)`. In words: move the weights by the step size α times the error times the direction in which the weights raise the estimate.
**On the island:** An oracle existed for one question. The lab solved the random policy exactly: the start square is worth -114.4 and the far inland corner -135.5. Those values scored the RANDOM WALK value tables.

### [21:58](https://www.youtube.com/watch?v=UoPei5o4fps&t=1318s) Features and the linear value function
A feature is one number describing the state: distance from a landmark, a market trend, which pieces are on a chess board. The simplest approximator is a weighted sum. `v̂(S, w) = x(S)ᵀw` and `Δw = α (vπ(S) − v̂(S, w)) x(S)`. In words: add up each feature times its weight, and move each weight by step size times error times how strongly its feature was on. The error surface is a bowl, so gradient descent finds the single best answer. A feature that is off gets no update: with no queen on the board, the "have a queen" weight is not blamed.
**On the island:** Not run on the island. The experiment would give Q-learning a few real-valued features per move (distance from edge, distance to goal) and test whether a weighted sum can express "never step off in row 0".

### [28:50](https://www.youtube.com/watch?v=UoPei5o4fps&t=1730s) Table lookup is a special case of the linear method
"Table lookup is a special case of linear function approximation." Give each state its own feature, 1 in that state and 0 elsewhere (a one-hot vector). The weighted sum then picks out one weight, and that weight is the table entry. The earlier lectures need no special machinery.
**On the island:** This is the exact description of the reduced bots. Q, 16 COARSE STATES is linear Q-learning with one-hot features over 16 groups (her row and which quarter of the strip, three columns to a quarter). Q, ROW ONLY has 4 groups. Grouping states this way is state aggregation, the mildest approximation there is: fixed, hand-chosen features that never overlap.

### [30:54](https://www.youtube.com/watch?v=UoPei5o4fps&t=1854s) No oracle: paste in the return or the TD target
With no supervisor, Silver substitutes a target from experience. For Monte Carlo it is the return, the actual total reward to the episode's end: "the returns become the supervisor." It is unbiased but noisy, so Monte Carlo prediction converges even with a neural network. The TD target is `R + γ v̂(S′, w)`. In words: one real reward, then trust your own estimate of the next state. It is biased, yet linear TD prediction still converges close to the best answer (Tsitsiklis and Van Roy). Eligibility traces now sit on the weights, one per feature.
**On the island:** Only tables raced. Typical error against the exact values after 10 episodes: TD step 0.1 at 112.7, TD step 0.5 at 100.5, Monte Carlo 25.9; after 200: 85.6, 46.5, 15.3. All tables started at zero while most true values are below -100.

### [45:57](https://www.youtube.com/watch?v=UoPei5o4fps&t=2757s) Why the gradient ignores the target
A student asks why the update does not also differentiate the TD target. Silver: information should flow from later to earlier, because later estimates have seen more real reward; pulling the later one back gives wrong values even with a table. These are residual gradient methods, and he advises against them unless you know what you are doing.
**On the island:** Not run on the island. Adding the second gradient term to a RANDOM WALK TD table and scoring it against -114.4 would test it.

### [48:58](https://www.youtube.com/watch?v=UoPei5o4fps&t=2938s) Control: approximate policy iteration, every step
Control is lecture 5's loop: estimate action values, act epsilon-greedily (the best move, except a random one with small probability epsilon), repeat, updating after every step. An approximator may be unable to represent the best values at all, and Silver warns these methods usually oscillate near the answer rather than settle.
**On the island:** Both reduced bots are this loop exactly, Q-learning with epsilon 0.1 on one-hot group features. Runs with 10 clean test crossings: full table 11/11, 16 groups 10/10, row only 3/10.

### [56:21](https://www.youtube.com/watch?v=UoPei5o4fps&t=3381s) Mountain car: continuous state, linear Sarsa
A car must rock back and forth to climb out of a valley; its state is position and velocity. Linear Sarsa with coarse coding (overlapping tiles; every tile containing the state is on and gets nudged) grows a spiral-shaped value surface. Asked whether a better state description would simplify it, Silver says good features can make the true value far easier to learn; that is where knowledge goes in.
**On the island:** The 16 coarse states are coarse coding with one tiling and no overlap. Q, ROW ONLY shows bad features: with no column, forward and back look identical, so none of her 16 weights can say "go right".

### [1:04:31](https://www.youtube.com/watch?v=UoPei5o4fps&t=3871s) Bootstrapping helps, and it can blow up
Across several tasks, lambda of 1 (pure Monte Carlo) does badly from variance, TD(0) better, the best lambda in between: bootstrapping is worth keeping. Then Baird's counterexample: TD updates swept over all states, off-policy, send the weights to infinity. The prediction table: on-policy TD converges with tables and linear features but not non-linear ones; off-policy TD can diverge even when linear. Gradient TD, following the true gradient of the projected Bellman error with one correction term, converges in every column.
**On the island:** Lambda was compared only with tables: SARSA LAMBDA fell 11.8 times per 100 training episodes against SARSA's 16.3, a difference of -4.51 (95% interval -6.21 to -2.78), exploratory. No divergence could appear: the full tables sit in the all-ticks column.

### [1:08:59](https://www.youtube.com/watch?v=UoPei5o4fps&t=4139s) The control table: chattering, and Q-learning's cross
With linear features, Monte Carlo control and Sarsa get a bracketed tick: they chatter, getting close to the best values, stepping away and coming back, without ever shooting off. Q-learning gets a cross. Asked about practice, Silver says naive Q-learning or Sarsa with a neural network very often blows up, while linear methods mostly behave.
**On the island:** Q, 16 COARSE STATES is off-policy Q-learning with linear features, a cross cell, and all 10 runs reached the goal. A cross means divergence is possible, not certain, and aggregation is known to be a stable case (not from the lecture). The island logged returns, not weights, so it cannot say whether she chattered.

### [1:12:25](https://www.youtube.com/watch?v=UoPei5o4fps&t=4345s) Batch methods: fit all the experience, and replay it
Gradient descent uses each sample once and throws it away. Batch methods fit everything seen so far: "life is one big training set for an agent." The least squares fit minimises the summed squared error. Experience replay reaches it: store the experience, sample at random, repeat the gradient step. Random order also breaks the correlation between consecutive steps.
**On the island:** Not run on the island. The nearest bot, DYNA-Q, makes 20 extra updates per real step from a remembered table model (lecture 8, not replay itself). Her mean return over the first 40 episodes beat Q-learning's by 25.98 (interval 15.53 to 36.25), exploratory.

### [1:17:27](https://www.youtube.com/watch?v=UoPei5o4fps&t=4647s) DQN on Atari: replay plus a frozen target
The Atari player is Q-learning with a convolutional network reading the last 4 frames and outputting values for 18 joystick positions. It stores about a million transitions and trains on random minibatches of 64. Targets come from an older frozen copy of the network, swapped every few thousand steps, so the target does not move with every update. "I wouldn't claim this is the most aesthetically satisfying idea," he says, yet both tricks matter: Breakout scores 316.81 with both, 3.17 with neither. One network and one set of settings served 50 games.
**On the island:** Not run on the island. A small network on Tracer's raw position, trained with and without replay and a frozen target, would show both tricks at island scale.

### [1:26:40](https://www.youtube.com/watch?v=UoPei5o4fps&t=5200s) Least squares: jump straight to the answer
With linear features, set the average update to zero and solve. `w = (Σ x(sₜ) x(sₜ)ᵀ)⁻¹ Σ x(sₜ) vₜ`. In words: the best weights come from one matrix inversion sized by the number of features, not states. That costs order N cubed for N features, or N squared per step with Sherman-Morrison. With returns or TD targets this gives LSMC and LSTD, which converge on and off policy. LSPI alternates such fits with greedy improvement and solved a 50-state chain in seven iterations.
**On the island:** Not run on the island. LSTD on RANDOM WALK's logged steps would give a value table in one solve, against TD's error of 85.6 after 200 episodes.

## What the island measured for this lecture

Three Q-learning bots, same settings (alpha 0.5, epsilon 0.1), told different amounts about where they stand.

| | Q-LEARNING (48 squares) | Q, 16 COARSE STATES | Q, ROW ONLY |
|---|---|---|---|
| Runs | 11 | 10 | 10 |
| Falls per 100 training episodes (95% interval) | 26.5 (22.4 to 30.4) | 16.3 (12.1 to 21.0) | 42.5 (39.0 to 45.7) |
| Mean return, first 40 / last 40 episodes | -57.6 / 7.5 | -13.2 / 14.3 | -114.3 / -76.0 |
| Episode of first goal (median) | 13 | 5 | 24 |
| Runs with 10 clean test crossings | 11/11 | 10/10 | 3/10 |
| Steps per training episode | 18.6 | 17.6 | 47.1 |

Against the full table, the 16-group bot fell less, -10.15 per 100 (interval -15.99 to -4.13, p 0.0074), and the row-only bot fell more, 15.97 (10.62 to 21.32), with a late return lower by 83.48 (interval -107.47 to -60.97 for the difference). All are exploratory first looks, uncorrected for the number of comparisons (only SARSA against Q-learning was planned). Grouping helped where grouped squares behave alike (the edge is the same along the strip) and hurt where it erased what she needed (which way the goal is). The 16-group bot's late-return edge over the full table has no interval, so it is not a result. Not tested: learned or overlapping features, a network, replay, least squares, divergence.

## Guess first

<details><summary>Q, ROW ONLY knows her row but not her column. Does she fall more often or less often than the full-table bot?</summary>
More: 42.5 falls per 100 episodes against 26.5. She learns "not toward the edge in row 0" fast, since it holds in every column. But forward and back look identical to her, so she paces the edge row for 47.1 steps an episode, and each random exploratory move there is another chance to fall (that link is an inference, not a separate measurement).
</details>

<details><summary>Q, 16 COARSE STATES first reaches the goal at a median of episode 5. Before or after the full table?</summary>
Before: the full table's median is 13. Each update moves a weight shared by three squares, so one experience teaches three places. The generalisation is correct here because neighbouring columns really are alike.
</details>

<details><summary>Lecture 4 compared Monte Carlo and TD targets. With a neural network, which keeps a convergence guarantee for prediction?</summary>
Monte Carlo. The return is an unbiased sample, so the update is true stochastic gradient descent and reaches a local optimum. The TD target uses the network's own estimate and can diverge with non-linear approximators. Bootstrapping still usually learns faster, so Silver looks for safe TD variants.
</details>

<details><summary>Lecture 5's SARSA and Q-learning, both on linear features: which can diverge?</summary>
Q-learning, because it is off-policy. Linear SARSA only chatters. The 16-group bot is off-policy Q-learning on linear features and stayed stable, which fits: a cross means divergence is possible, and one-hot grouping is a well-behaved case.
</details>

<details><summary>Give Q, ROW ONLY experience replay, so she trains many times on each step. Does she stop pacing?</summary>
No. Replay converges to the least squares fit for her features, and her features cannot separate forward from back. More passes squeeze out what the features can express, never more. Only a better description of position fixes her.
</details>

<details><summary>Lecture 3's PLANNER solved the strip in 13 sweeps. Why not run her on Go?</summary>
Each sweep visits every state, and Go has about 10 to the 170: the table would not fit and the sweeps would not finish. She also needs the rules written down. Approximation answers the first problem; model-free targets the second.
</details>

## Cards

- Q: Two reasons tables fail at scale? | A: Too many states to store, and too slow to learn each separately.
- Q: What is a linear value function? | A: A weighted sum of state features: x(s) dot w.
- Q: Linear gradient update in words? | A: Step size times prediction error times feature value.
- Q: Why is table lookup a special case? | A: One-hot features, one per state; the sum picks out one weight, the table entry.
- Q: Monte Carlo versus TD target under approximation? | A: The return is unbiased but noisy; the TD target is biased because it uses the approximator's own estimate.
- Q: What does Baird's counterexample show? | A: Off-policy TD with linear features can send the weights to infinity.
- Q: What does "chatter" mean? | A: Getting near the best values, stepping away, returning, never settling, never diverging.
- Q: DQN's two stabilisers? | A: Experience replay from stored transitions, and targets from an older, frozen copy of the network.

## In language-model terms

A language-model agent in tau-bench reads a conversation with a simulated customer, calls tools on a database, and is scored at the end on whether the database is right. Its state is the conversation so far, which no table could list, so any value estimate for it must be a function approximator. Here the mapping is exact: a value head reading the conversation and predicting the score is this lecture's non-linear v-hat, with learned features in place of hand-made ones (the "discovery problem" Silver sets aside at [23:12]).

Generalisation cuts both ways, as on the island: two conversations that share features but need different actions get the same confident estimate, the row-only bot's trouble (an analogy, not a measurement of any model). The mapping breaks at the action. DQN maximises over 18 joystick positions; an agent's action is a whole message or tool call, and Silver notes at [1:03:07] that the max is hard when actions are not a short list. The tables still warn: learning from logs of older agent versions is off-policy, and off-policy bootstrapping through a network has crosses in every cell.

## The thread to partial observability

State aggregation is partial observability chosen by the designer. Q, ROW ONLY's next square depends on a column she is not told, so from her side the world is no longer Markov. The lecture assumes features summarise a fully observed state. DQN's input stacks the last 4 frames, a short history where one frame would not show motion (that reason is not stated in the lecture). Carry forward: an approximator can only be as good as what its inputs tell apart, and the final lesson's fix is memory, not more weights. The hidden-wall build, planned and running now, tests this by hiding one fact from the runner and, in one condition, letting her remember her bumps.

## Experiments the lecture asks for that the island has not run

- Offset tilings over Tracer's real position with linear Sarsa: generalisation without aliasing.
- Q-learning on real-valued features (distance from edge, distance to goal): chattering or growing weights.
- LSTD on RANDOM WALK's logged steps: one solve against TD's slow tables.
- A small network on raw position, with and without replay and a frozen target: DQN's ablation in miniature.
- Off-policy linear TD on random-walk logs evaluating the greedy policy: Baird-style weight growth.
