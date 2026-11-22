# Lecture 6: Value Function Approximation

*David Silver's lecture 6 (UCL, 2015), gone through in his order and re-explained with the Tracer experiments on Workshop Island. The lecture and its slides are his: [video](https://www.youtube.com/watch?v=UoPei5o4fps), [course page](https://davidstarsilver.wordpress.com/teaching/). The words below are a re-explanation. Every island number comes from the logged runs in this repository.*

In this lecture's game you are the scout: twelve pads lie in a row, each hiding a danger number, and you get only six reads to tell your team about all twelve. Silver's sixth lecture asks the same question at full size: every bot on the island so far kept a table, one number for each of 48 squares and 4 moves, and he wants to know what replaces the table when the situations are too many to list, store or learn one by one. His answer is a formula with a few adjustable numbers, trained toward the same targets as before, so that learning in one situation also moves the estimate in similar ones. The island ran the mildest version: two Q-learning bots were told less about where they stand, and one learned faster than the full table while the other crossed cleanly in only 3 of 10 runs.

**Two windows:** this page, and [Game 6: Callouts](../workshop/games/g06.md), an Overwatch custom game for this lecture (paste `workshop/compiled/game-06.txt` into a custom game's settings and start it). The game opens at stop 1 and waits. Read down this page; at each box marked Alt+Tab, switch to the game, do that stop, and switch back. The game never moves on while you read.

## The lecture in order

### [01:34](https://www.youtube.com/watch?v=UoPei5o4fps&t=94s) Tables stop working when the states cannot be listed
A table needs one entry for every situation the learner can be in, and real problems have more situations than any table can hold. Silver counts them. A situation is called a state. Backgammon has about 10 to the 20 states, Go about 10 to the 170, and a robot moving through continuous space has infinitely many. "You can't just build a table anymore."

He gives two reasons. The table will not fit in memory. And even if it did, every entry would have to be learned separately, which needs too much experience.

What he wants is for learning to carry over between states that are alike, which is called generalisation. Standing here and standing one millimetre to the right should be worth about the same, and should not be learned twice. This lecture's game puts the problem at toy size: what you can say about every place when you can afford to visit only some of them.

> **Alt+Tab · game 6 · stop 1 of 6: Scout six of twelve pads.**
>
> **What he just said:** When there are too many states to visit one by one, a table that keeps a separate number for each state cannot learn them all.
>
> **In the game:** Twelve pads lie in a row, each hiding a danger number. Walk into a ring with WASD and press F (Interact) to read it. You get 6 reads; each costs a small hit and can be off by 1.
>
> **Before you press:** Before you start, choose which 6 pads will tell your team the most about all 12.
>
> <details><summary>Back from the game: what you just saw</summary>Each read lands on its pad and nowhere else, so half the strip is still blank. You just lived Silver's problem at toy size: the budget is smaller than the number of states. In a real game the gap is not 6 against 12 but a handful against more states than atoms. <em>In an agent:</em> An agent meets conversations it has never seen in every session, so it cannot keep one stored answer per conversation.</details>

**On the island:** The game reports Tracer's position as continuous coordinates, and the lab snaps it to one of 48 squares. So even the full-table Q-LEARNING bot uses a hand-made approximation: every point inside a 2 m square counts as the same state.

### [05:45](https://www.youtube.com/watch?v=UoPei5o4fps&t=345s) Replace the table with a formula that has a few adjustable numbers
Instead of storing a score for every situation, you can compute one when you need it. Silver's fix is a formula that takes in a state (a situation) and gives back an estimate of the total reward expected from there onward, which is the state's value. The formula is steered by a short list of adjustable numbers, called weights and written w, and that list is much shorter than the list of states. He calls such a formula a function approximator.

`v̂(s, w) ≈ vπ(s)`. In words: a small set of numbers w should give roughly the true value of following the policy π (the bot's rule for choosing a move) from any state.

The short list saves memory, and it is also what lets learning carry over between similar states, the generalisation Silver asked for: the formula is fitted on states the learner has visited and can then be asked about states it has never seen.

For the score of a move in a state, called the action value, he shows two shapes. Feed in a state and one move and get one number back. Or feed in the state alone and get every move's value at once, as his Atari-playing program did.

**On the island:** Counting from the setup, Q-LEARNING keeps 192 numbers. Q, 16 COARSE STATES keeps 16 groups times 4 moves, which is 64, and Q, ROW ONLY keeps 4 rows times 4 moves, which is 16. Each smaller bot has one number per move per group of squares, and the groups are where generalisation happens.

### [12:44](https://www.youtube.com/watch?v=UoPei5o4fps&t=764s) Train the formula with small nudges that shrink the error
To tune the weights (the formula's adjustable numbers) you have to know which way to turn each one. Silver keeps to formulas where that can be worked out exactly: for each weight, how much the estimate rises when it is nudged up. That list of slopes is called the gradient. A weighted sum of measurements has one, and so does a neural network.

He warns that the data is unlike the data in ordinary machine learning, where a teacher supplies the right answers (supervised learning). Here the right answer moves, because a state's value, its expected total reward, changes each time the policy (the rule for choosing moves) improves. And each sample looks much like the next, because they arrive along one path through the world.

Then he pretends for a moment that a teacher does exist, an oracle that announces each state's true value. With it he derives the training rule: after every sample, change the weights a little in the direction that shrinks the error. This is stochastic gradient descent. `Δw = α (vπ(S) − v̂(S, w)) ∇w v̂(S, w)`. In words: move the weights by the step size α times the error times the direction in which the weights raise the estimate.

**On the island:** The island had an oracle for one question. The lab solved the random policy exactly: the start square is worth -114.4 and the far inland corner -135.5. Those values scored the RANDOM WALK value tables.

### [21:58](https://www.youtube.com/watch?v=UoPei5o4fps&t=1318s) Describe a state by a few measurements and add them up
You can describe where you are by a few measurements instead of an exact address. Silver calls each measurement a feature: one number that says something about the state (the situation the learner is in). His examples are a robot's distance from a landmark, a trend in the stock market, and which pieces are on a chess board.

The simplest formula gives each feature a weight and adds them up. This is the linear value function. `v̂(S, w) = x(S)ᵀw` and `Δw = α (vπ(S) − v̂(S, w)) x(S)`. In words: add up each feature times its weight, and move each weight by step size times error times how strongly its feature was on.

The error of a weighted sum, plotted against its weights, is a bowl, so the downhill nudging of the last part, gradient descent, finds the single best answer. A feature that is off gets no update: with no queen on the board, the "have a queen" weight is not blamed.

Since a weight belongs to a feature, a lesson from one state moves the estimate in every state that shares the feature. The game asks whether that sharing beats a full table when experience is short.

> **Alt+Tab · game 6 · stop 2 of 6: Guess which map wins after six calls.**
>
> **What he just said:** Describe each state by a few features, add them up with weights, and what you learn in one state moves the estimate for every state that shares those features.
>
> **In the game:** Your 6 reads fed three maps: EXACT keeps 12 numbers, THIRDS keeps 3, ONE WORD keeps 1. A question floats in front of you. Answer with left click, right click or melee, then read the truth and each map's numbers under the pads.
>
> **Before you press:** Commit to the map you think sits closest to the truth on all 12 pads after only 6 reads.
>
> <details><summary>Back from the game: what you just saw</summary>EXACT knows the pads you stepped on and writes 0 on the rest, because a table cannot guess where it has not been. THIRDS writes the average of its third on all four pads, so one read reached four places. Learning that spreads to similar states is called generalisation, and THIRDS usually wins here because of it. <em>In an agent:</em> A language model answers a prompt it never saw by its likeness to prompts it did see, which is the same spreading.</details>

**On the island:** Not run on the island. The experiment would give lecture 5's Q-learning a few features per move that are measured amounts (distance from edge, distance to goal) and test whether a weighted sum can express "never step off in row 0".

### [28:50](https://www.youtube.com/watch?v=UoPei5o4fps&t=1730s) A table is the same method with one feature per state
The tables of the earlier lectures were this method all along. Silver does not want the class to think that a table and a weighted sum of features (measurements of the state), which he calls linear function approximation, are two different kinds of algorithm. "Table lookup is a special case of linear function approximation."

To see it, give every state its own feature, one that reads 1 in that state and 0 everywhere else. A list like that, all zeros and a single 1, is called a one-hot vector. Now take the weighted sum. Every term is zero except one, so the sum picks out a single weight, and that weight is the table entry for the state you are in.

So the earlier lectures need no special machinery. A table is a weighted sum with as many features as there are states.

**On the island:** This is the exact description of the reduced bots. Q, 16 COARSE STATES is linear Q-learning with one-hot features over 16 groups (her row and which quarter of the strip, three columns to a quarter). Q, ROW ONLY has 4 groups. Grouping states this way is called state aggregation. It is the mildest approximation there is: the features are fixed, chosen by hand, and never overlap.

### [30:54](https://www.youtube.com/watch?v=UoPei5o4fps&t=1854s) No teacher: use what actually happened, or your own next guess
Nobody hands a learner the right answers, so the pretend teacher of the earlier parts, the oracle, has to go. Silver pastes in a number the learner can get from its own experience, called the target, and keeps the training rule.

The first target is from Monte Carlo, lecture 4's method of waiting to see how a run turns out. It is the actual total reward to the end of the run, or episode, and it is called the return: "the returns become the supervisor." A return is right on average and different every time (unbiased but noisy), so Monte Carlo prediction, the scoring of a fixed way of playing, settles on an answer, or converges, even with a neural network.

The second is from temporal-difference learning, TD, which does not wait. The TD target is `R + γ v̂(S′, w)`. In words: one real reward, then trust your own estimate of the next state. Leaning on its own guess makes it off on average (biased), yet with a weighted sum of features TD prediction still converges close to the best answer (Tsitsiklis and Van Roy).

Lecture 4's eligibility traces, the fading record of what was recently active, now sit on the weights, one per feature. The game takes the first target and asks whether an average of noisy returns ever lands exactly on the truth.

> **Alt+Tab · game 6 · stop 3 of 6: Predict 60 calls, then press F.**
>
> **What he just said:** With no teacher to give the true value, the target is the return actually seen, and averaging those returns is unbiased but noisy.
>
> **In the game:** The team adds 54 calls, every pad read 4 or 5 times. Answer two questions with the mouse buttons or melee, then press F to bring the calls in and read the table on the right.
>
> **Before you press:** Decide which map will be closest after 60 calls, and whether EXACT, which averages each pad's reads, will be exactly right.
>
> <details><summary>Back from the game: what you just saw</summary>With every pad visited, EXACT wins, but its miss is small rather than zero: each pad's number is an average of a few reads that are each off by up to 1. That is lecture 4's Monte Carlo estimate, an average of samples. Look at how little THIRDS and ONE WORD improved between 6 and 60 calls. EXACT is the same method with one group per pad: a table is the special case with one feature per state.</details>

**On the island:** Only tables raced. Typical error against the exact values after 10 episodes: TD step 0.1 at 112.7, TD step 0.5 at 100.5, Monte Carlo 25.9; after 200: 85.6, 46.5, 15.3. All tables started at zero while most true values are below -100.

### [45:57](https://www.youtube.com/watch?v=UoPei5o4fps&t=2757s) Why only the earlier guess gets corrected
When a guess about now disagrees with a guess about one step later, only the earlier guess should move. A student notices that the TD target (one real reward plus the estimate for the next state) depends on the weights too, and asks why the update takes the slope, or gradient, of the earlier estimate alone and treats the target as fixed.

Silver's answer is about the direction of time. The later estimate has seen more real reward, so it is the one to trust, and information should flow from later to earlier. Taking the slope of both is like joining the two estimates with a spring: the later one is pulled back toward the earlier one. He says that gives wrong values even with a table.

Methods that take both slopes are called residual gradient methods. He advises against them unless you know what you are doing.

**On the island:** Not run on the island. Adding the second gradient term to a RANDOM WALK TD table and scoring it against -114.4 would test it.

### [48:58](https://www.youtube.com/watch?v=UoPei5o4fps&t=2938s) Choosing moves: lecture 5's loop, updated after every step
So far the formula has only scored a fixed way of playing, and the learner still has to find a good one. That search is called control, and Silver reuses lecture 5's loop for it. Estimate a score for each state and move together (the action value, Q). Mostly take the best-scoring move, and with a small probability called epsilon take a random one, which is acting epsilon-greedily. Repeat.

The scores now come from the formula in place of a table. He does not wait for the formula to fit well before acting on it: in the most incremental version the weights (its adjustable numbers) are updated after every step, and the next move is chosen from the updated scores.

He gives two warnings. The formula only approximates, and an approximator may be unable to represent the best values at all. And the loop usually does not settle: these methods oscillate near the answer, a little away and then back again. The game takes up the first warning: how wrong a coarse description stays when experience is unlimited.

> **Alt+Tab · game 6 · stop 4 of 6: Find where THIRDS stays wrong.**
>
> **What he just said:** An approximator may be unable to represent the true values at all, however much experience it gets.
>
> **In the game:** Picture scouting forever, every pad read endlessly. Answer two questions with left click, right click or melee, then read the forever column on the right and the numbers under the pads.
>
> **Before you press:** Choose which maps can never get every pad right, and on which pad THIRDS stays most wrong.
>
> <details><summary>Back from the game: what you just saw</summary>With endless reads EXACT reaches 0, THIRDS stops at 1.99 and ONE WORD at 3.39. Most of THIRDS' miss is pad 10, a 9 among 1s and 2s that it calls 3.25, and the same average drags pad 12 up. A coarser description learns faster and has a floor on how right it can get. <em>In an agent:</em> When two prompts look alike to a model but need different answers, it gives both the same confident answer, the way THIRDS treats pad 10 like its neighbours.</details>

**On the island:** Both reduced bots are exactly this loop: Q-learning with epsilon 0.1 on one-hot group features (each group of squares has its own on-off feature). Runs with 10 clean test crossings: full table 11/11, 16 groups 10/10, row only 3/10.

### [56:21](https://www.youtube.com/watch?v=UoPei5o4fps&t=3381s) Mountain car: rocking a weak car out of a valley
A car sits at the bottom of a valley with an engine too weak to drive straight up the slope. It has to roll back, drive forward, roll back again, and build up enough speed to reach the top. This is the mountain car problem. Its state is two continuous numbers, position and velocity.

Silver solves it with Sarsa, lecture 5's method: after each step, shift the score of the move just made toward the reward plus the score of the move actually taken next. Here the scores are a weighted sum of features (measurements of the state), which makes it linear Sarsa. The features are overlapping tiles laid across position and velocity, a scheme called coarse coding. Every tile that contains the current state is on and gets nudged, so nearby states learn too. Over time the scores, drawn as a surface over position and velocity, grow into a spiral.

A student asks whether a better description of the state would give a simpler shape. Silver says good features can make the true value far easier to learn, and that is where knowledge goes in. The game asks how much one well-placed feature is worth.

> **Alt+Tab · game 6 · stop 5 of 6: Give one pad its own number.**
>
> **What he just said:** Good features can make the true value far easier to learn, and choosing them is where the designer's knowledge goes in.
>
> **In the game:** Walk into one pad's ring and press F (Interact). That pad gets its own number on top of THIRDS, a map of 4 numbers. Answer one question with the mouse buttons or melee, then read the YOURS row on the right.
>
> **Before you press:** Once your pad is picked, commit to how far it will pull THIRDS' forever miss down from 1.99.
>
> <details><summary>Back from the game: what you just saw</summary>Only one pad changes much. Splitting off pad 10 drops the floor from 1.99 to 0.55 with 4 numbers; any other pad leaves it between 1.85 and 1.99, because that pad already fit its group. The number of features mattered less than where they were placed. Choosing the description is most of the work.</details>

**On the island:** The 16 coarse states are coarse coding with one tiling (a single layer of tiles) and no overlap. Q, ROW ONLY shows bad features: with no column, forward and back look identical to her, so none of her 16 weights can say "go right".

### [1:04:31](https://www.youtube.com/watch?v=UoPei5o4fps&t=3871s) Learning from your own guesses helps, and it can blow up
Building one guess on another guess, called bootstrapping, is quicker than waiting for the real outcome, and it can go badly wrong. Silver first shows that it pays, across several tasks. He varies one dial, lambda, lecture 4's setting that runs from trusting a guess after one step (0) to waiting for the real outcome (1). At lambda of 1, pure Monte Carlo, results are poor because the returns vary too much. TD(0) does better, and the best lambda lies in between.

Then he shows the danger. In Baird's counterexample the TD updates are swept over all states, not gathered by following the policy (the rule for choosing moves), which makes them off-policy, and the weights go to infinity.

A table of ticks and crosses sums up prediction, the scoring of a fixed policy. When the data comes from following the policy being scored, which is called on-policy, TD converges (settles on an answer) with tables and with weighted sums of features, the linear case, but has no guarantee with non-linear formulas such as neural networks. Off-policy, TD can run away like that, or diverge, even when linear.

Gradient TD is the repair: it follows the true slope, or gradient, of an error measure called the projected Bellman error, with one correction term, and it converges in every column.

**On the island:** Lambda was compared only with tables: SARSA LAMBDA fell 11.8 times per 100 training episodes against SARSA's 16.3, a difference of -4.51 (95% interval -6.21 to -2.78), exploratory. No divergence could appear: the full tables sit in the all-ticks column.

### [1:08:59](https://www.youtube.com/watch?v=UoPei5o4fps&t=4139s) When choosing moves: hovering near the answer, and Q-learning's cross
Choosing moves is shakier than scoring a fixed way of playing. Once a formula replaces the table, Silver says, there is no guarantee that an improvement step really improves the policy (the rule for choosing moves).

His second table of ticks and crosses covers the search for a good policy, which is called control. With a weighted sum of features, the linear case, Monte Carlo control (learning from whole runs) and Sarsa (learning from the move actually taken next) get a bracketed tick. The brackets mean they get close to the best values, step away and come back, without ever shooting off, which Silver calls chattering. Q-learning gets a cross. It is lecture 5's method that learns about the best move while trying others, which makes it off-policy, and a cross means its weights can run off to infinity, or diverge.

A student asks whether the crosses matter in practice. Silver says naive Q-learning or Sarsa with a neural network very often blows up, while linear methods mostly behave.

**On the island:** Q, 16 COARSE STATES is off-policy Q-learning with linear features, a cross cell, and all 10 runs reached the goal. A cross means divergence is possible, not certain, and aggregation (grouping states) is known to be a stable case (not from the lecture). The island logged returns, not weights, so it cannot say whether she chattered.

### [1:12:25](https://www.youtube.com/watch?v=UoPei5o4fps&t=4345s) Keep every experience and learn from it again
Every method so far looks at an experience once, makes one small update, and throws the experience away. Silver says that wastes data. The alternative keeps everything and looks for the weights (the formula's adjustable numbers) that best fit all of it. These are batch methods: "life is one big training set for an agent."

Best fit needs a definition. Take the gap between the estimate and its target (the number it is being pulled toward) at every remembered step, square it, add the squares up, and choose the weights that make the sum smallest. That is the least squares fit.

An easy way to reach it is to store each experience as it happens and then, over and over, draw one at random and repeat the usual small update, the gradient step, toward its target. This is experience replay. The random order does a second job: steps that happened one after another are strongly alike, and drawing them at random breaks that correlation.

**On the island:** Not run on the island. The nearest bot, DYNA-Q, makes 20 extra updates per real step from a remembered table model (lecture 8, not replay itself). Her mean return over the first 40 episodes beat Q-learning's by 25.98 (interval 15.53 to 36.25), exploratory.

### [1:17:27](https://www.youtube.com/watch?v=UoPei5o4fps&t=4647s) The Atari player (DQN): replay plus a frozen target
The program that learned to play Atari games is built from parts already on this page. It is Q-learning, lecture 5's method of learning each move's score from the best next move, with a neural network in place of the table. The network is of a kind that applies the same weights to every region of an image, called convolutional. It reads the last 4 frames and outputs values for 18 joystick positions. It is known as DQN, short for deep Q-network.

Silver has said that naive Q-learning with a neural network very often blows up. Two tricks keep this one stable. The first is replay: it stores about a million of its steps (each a state, the move, the reward and the next state, called a transition) and trains on random handfuls of 64, called minibatches.

The second is a frozen target. The targets, the numbers its scores are pulled toward, come from an older copy of the network, held fixed and swapped every few thousand steps, so the target does not move with every update. "I wouldn't claim this is the most aesthetically satisfying idea," he says, yet both tricks matter: Breakout scores 316.81 with both, 3.17 with neither. One network and one set of settings served 50 games.

**On the island:** Not run on the island. A small network on Tracer's raw position, trained with and without replay and a frozen target, would show both tricks at island scale.

### [1:26:40](https://www.youtube.com/watch?v=UoPei5o4fps&t=5200s) Least squares: jump straight to the answer
With a weighted sum of features (measurements of the state), the best weights can be calculated in one go. Replay can take many passes to reach the weights with the smallest summed squared error, the least squares fit.

At the best fit nothing pushes the weights to change, so over all the stored data the updates average to zero. Silver sets that average update to zero and solves for the weights. `w = (Σ x(sₜ) x(sₜ)ᵀ)⁻¹ Σ x(sₜ) vₜ`. In words: the best weights come from one calculation on a grid of numbers, a matrix inversion, sized by the number of features, not states.

That costs order N cubed for N features, or N squared per step with a shortcut called Sherman-Morrison. With returns (actual totals of reward) as targets the method is least squares Monte Carlo, LSMC. With TD targets (one reward plus a guess) it is least squares temporal difference, LSTD. Both converge whether or not the data came from following the policy being scored, that is, on and off policy.

For choosing moves, least squares policy iteration, LSPI, alternates such fits with a switch to whatever now scores best (greedy improvement). It solved a 50-state chain in seven iterations. The game's last stop asks what this best fit looks like when the features are plain groups.

> **Alt+Tab · game 6 · stop 6 of 6: Read the debrief.**
>
> **What he just said:** With linear features the best weights come straight from one solve over all the experience, sized by the number of features rather than the number of states.
>
> **In the game:** Nothing to press. Read the three lines on the left and your prediction score.
>
> **Before you press:** Before you read, say in one sentence what the three maps had in common and what made them differ.
>
> <details><summary>Back from the game: what you just saw</summary>Every map was the same method: the average of the calls in each group, which is exactly the least-squares answer for features that are on in one group and off elsewhere. Only the grouping differed. This was the mildest form of value function approximation, with fixed hand-made groups and plain averages; a neural network learns its own features, and that is where the guarantees thin out. <em>In an agent:</em> A value head on a language-model agent reads the whole conversation and learns its features rather than being handed them.</details>

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
