# Lecture 6: Value Function Approximation

*David Silver's lecture 6 (UCL, 2015), gone through in his order and re-explained with the Tracer experiments on Workshop Island. The lecture and its slides are his: [video](https://www.youtube.com/watch?v=UoPei5o4fps), [course page](https://davidstarsilver.wordpress.com/teaching/). The words below are a re-explanation. Every island number comes from the logged runs in this repository.*

Nobody calls out "Tracer, two steps left of the health pack, facing slightly up." They say "Tracer mid", and one word covers a whole area. This lecture is about that shortcut. In its game you are the scout: twelve pads lie in a row, each hiding a danger number, and you get six reads to tell your team about all twelve. Silver asks the same thing at full size. Every bot on the island so far kept a table, one number for each of 48 squares and 4 moves, and he wants to know what replaces it when the situations are too many to list, store or learn one at a time. His answer is a formula with a few adjustable numbers, trained toward the same targets as before, so that learning in one place also moves the estimate in places like it. The island ran the mildest version: two Q-learning bots were told less about where they stand. One learned faster than the full table. The other crossed cleanly in only 3 of 10 runs.

**Two windows:** this page, and [Game 6: Callouts](../workshop/games/g06.md), an Overwatch custom game for this lecture (paste `workshop/compiled/game-06.txt` into a custom game's settings and start it). The game opens at stop 1 and waits. Read down this page; at each box marked Alt+Tab, switch to the game, do that stop, and switch back. The game never moves on while you read.

## The lecture in order

### [01:34](https://www.youtube.com/watch?v=UoPei5o4fps&t=94s) A notebook with one line for every millimetre
Imagine learning King's Row with a notebook that has one line for every spot you could stand on.

Not every room. Every spot. A millimetre to the right is a fresh, empty line.

That is how every bot so far has learned. Silver calls each situation a state, and the notebook is a table with one entry per state. Then he counts the states in real problems. Backgammon has about 10 to the 20. Go has about 10 to the 170, more than there are atoms in the universe. A robot moving through continuous space has infinitely many. "You can't just build a table anymore."

Two reasons. The table will not fit in memory. And even if it did, you would have to learn every entry separately, which takes far more experience than you will ever get.

What he wants is for learning to carry over between states that are alike. Standing here and a millimetre to the right should be worth about the same, and you should not have to learn it twice. He calls that generalisation.

The game shrinks this to twelve pads: what can you say about all of them when you can visit only some?

> **Alt+Tab · game 6 · stop 1 of 6: Scout six of twelve pads.**
>
> **What he just said:** A table keeps one number per state and learns each one on its own. Fine for the island's 48 squares. Hopeless when there are more states than you could ever visit, which is Silver's whole problem in this lecture.
>
> **In the game:** Twelve pads lie in a row, each hiding a danger number. Walk into a ring with WASD and press F (Interact) to read it. You get 6 reads; each costs a small hit and can be off by 1.
>
> **Before you press:** Before you start, choose which 6 pads will tell your team the most about all 12.
>
> <details><summary>Back from the game: what you just saw</summary>Each read landed on its own pad and nowhere else, so half the strip is still blank. That is Silver's problem at toy size: your budget is smaller than the number of states. In a real game the gap is not 6 against 12. It is a handful against more states than there are atoms. <em>In an agent:</em> An agent meets a conversation it has never seen in every session. A notebook with one stored answer per conversation would be blank on every page that matters.</details>

**On the island:** The game reports Tracer's position as continuous coordinates, and the lab snaps it to one of 48 squares. So even the full-table Q-LEARNING bot is already using a hand-made approximation: every point inside a 2 m square counts as the same state.

### [05:45](https://www.youtube.com/watch?v=UoPei5o4fps&t=345s) Swap the notebook for a formula with a few knobs
Your mouse sensitivity is one number, and it shapes every flick you will ever make. You do not set a separate one for each angle.

One knob, everywhere.

Silver's fix for the notebook works the same way. Instead of storing a score for every state, you compute one when you need it. A formula takes in a state and gives back an estimate of its value, the total reward you can expect from there onward. It is steered by a short list of adjustable numbers, called weights and written w, much shorter than the list of states. He calls such a formula a function approximator.

<details markdown="1"><summary>The formula, when you want it</summary>

`v̂(s, w) ≈ vπ(s)`. In words: a small set of numbers w should give roughly the true value of following the policy π (the bot's rule for choosing a move) from any state.

</details>

The short list saves memory. It also buys the generalisation Silver asked for: fit the formula on states you have visited, then ask it about states you have never seen. (The sensitivity picture breaks in one place: sensitivity is one knob you set by feel, and a formula has many, set by learning.)

For the score of a move in a state, called the action value, he shows two shapes. Feed in a state and one move and get one number back. Or feed in the state alone and get every move's value at once, as his Atari-playing program did.

**On the island:** Counting from the setup, Q-LEARNING keeps 192 numbers. Q, 16 COARSE STATES keeps 16 groups times 4 moves, which is 64, and Q, ROW ONLY keeps 4 rows times 4 moves, which is 16. Each smaller bot has one number per move per group of squares, and the groups are where generalisation happens.

### [12:44](https://www.youtube.com/watch?v=UoPei5o4fps&t=764s) Nudge each knob the way that makes you less wrong
When your shots keep landing a little left, you do not reinstall the game. You move your aim a little right and see whether it helps.

Training the formula is that, done carefully. You need to know which way to turn each weight, so Silver sticks to formulas where that can be worked out exactly: for each weight, how much the estimate rises when you nudge it up. That list of slopes is called the gradient. A weighted sum of measurements has one, and so does a neural network.

He warns that this data is nastier than in ordinary machine learning, where a teacher supplies the right answers (supervised learning). Here the right answer moves, because a state's value, its expected total reward, changes every time the policy (the rule for choosing moves) improves. And each sample looks a lot like the next, because they all arrive along one path through the world.

So he cheats, on purpose. He pretends a teacher exists, an oracle that announces each state's true value. With it the training rule falls out: after every sample, change the weights a little in the direction that shrinks the error. This is stochastic gradient descent.

<details markdown="1"><summary>The formula, when you want it</summary>

`Δw = α (vπ(S) − v̂(S, w)) ∇w v̂(S, w)`. In words: move the weights by the step size α times the error times the direction in which the weights raise the estimate.

</details>

There is no oracle, of course. He takes it away at (30:54).

**On the island:** The island had an oracle for one question. The lab solved the random policy exactly: the start square is worth -114.4 and the far inland corner -135.5. Those values scored the RANDOM WALK value tables.

### [21:58](https://www.youtube.com/watch?v=UoPei5o4fps&t=1318s) Describe where you are with a few numbers, then add them up
Before a fight you do not replay every past fight in your head. You check a few things: how many of them are up, how many of you, who has ult. A handful of readings, and you have a decent guess.

Silver calls each reading a feature: one number that says something about the state. His examples are a robot's distance from a landmark, a trend in the stock market, and which pieces are on a chess board.

The simplest formula gives each feature a weight and adds them up. This is the linear value function, and it comes with two gifts.

1. **One bottom.** The error of a weighted sum, plotted against its weights, is a bowl, so the downhill nudging from the last part, gradient descent, finds the single best answer.
2. **No blame for what was absent.** A feature that is off gets no update. With no queen on the board, the "have a queen" weight is left alone.

<details markdown="1"><summary>The formula, when you want it</summary>

`v̂(S, w) = x(S)ᵀw` and `Δw = α (vπ(S) − v̂(S, w)) x(S)`. In words: add up each feature times its weight, and move each weight by step size times error times how strongly its feature was on.

</details>

Since a weight belongs to a feature, one lesson moves the estimate in every state that shares it. That is a callout: one "mid is hot" changes what the whole team thinks about a whole area.

The game asks whether that sharing beats a full table when experience is short.

> **Alt+Tab · game 6 · stop 2 of 6: Guess which map wins after six calls.**
>
> **What he just said:** The callout idea. Describe each state by a few features, give each a weight, add them up. Now one lesson moves the estimate for every state that shares those features, the way one "mid is hot" warns the team about a whole area.
>
> **In the game:** Your 6 reads fed three maps: EXACT keeps 12 numbers, THIRDS keeps 3, ONE WORD keeps 1. A question floats in front of you. Answer with left click, right click or melee, then read the truth and each map's numbers under the pads.
>
> **Before you press:** Commit to the map you think sits closest to the truth on all 12 pads after only 6 reads.
>
> <details><summary>Back from the game: what you just saw</summary>EXACT knows the pads you stepped on and writes 0 on the rest. A table cannot guess where it has not been. THIRDS writes its third's average on all four pads, so one read reached four places. That spreading is called generalisation, and it is usually why THIRDS wins this early. <em>In an agent:</em> A language model answers a prompt it never saw by how much it looks like prompts it did see. Same spreading, much bigger map.</details>

**On the island:** Not run on the island. The experiment would give lecture 5's Q-learning a few features per move that are measured amounts (distance from edge, distance to goal) and test whether a weighted sum can express "never step off in row 0".

### [28:50](https://www.youtube.com/watch?v=UoPei5o4fps&t=1730s) Plot twist: the table was a formula all along
Picture the worst callout system ever made. Every square metre of the map gets its own name, and each callout covers exactly one of them. Nothing you say about one spot tells anyone anything about the next.

It works. It is also just the notebook again.

Silver makes this point on purpose. He does not want you to think a table and a weighted sum of features, which he calls linear function approximation, are two different kinds of algorithm. "Table lookup is a special case of linear function approximation."

To see it, give every state its own feature, one that reads 1 in that state and 0 everywhere else. A list like that, all zeros and a single 1, is called a one-hot vector. Now take the weighted sum. Every term is zero except one, so the sum picks out a single weight, and that weight is the table entry for the state you are in.

So the earlier lectures need no special machinery. A table is a weighted sum with as many features as there are states.

**On the island:** This is the exact description of the reduced bots. Q, 16 COARSE STATES is linear Q-learning with one-hot features over 16 groups (her row and which quarter of the strip, three columns to a quarter). Q, ROW ONLY has 4 groups. Grouping states this way is called state aggregation. It is the mildest approximation there is: the features are fixed, chosen by hand, and never overlap.

### [30:54](https://www.youtube.com/watch?v=UoPei5o4fps&t=1854s) Fire the oracle: learn from what happened, or from your next guess
A Mercy who resurrects a teammate never gets told what the res was worth. She can wait and see whether the fight is won. Or she can judge from how it looks a second later.

Once the oracle goes, those are Silver's two options. He keeps the training rule and swaps in a number the learner can get from its own experience, the target.

1. **Wait and see.** Monte Carlo, lecture 4's method. The target is the actual total reward to the end of the run, or episode, called the return: "the returns become the supervisor." It is right on average and different every time (unbiased but noisy), so Monte Carlo prediction, scoring a fixed way of playing, converges, or settles on an answer, even with a neural network.

2. **Trust your next guess.** Temporal-difference learning, TD, which does not wait: one real reward, then your own estimate of the next state. Leaning on its own guess makes it off on average (biased), yet with a weighted sum of features TD prediction still converges close to the best answer (Tsitsiklis and Van Roy).

<details markdown="1"><summary>The formula, when you want it</summary>

The TD target is `R + γ v̂(S′, w)`. In words: one real reward, then trust your own estimate of the next state.

</details>

Lecture 4's eligibility traces, the fading record of what was recently active, now sit on the weights, one per feature.

The game takes the first target: do noisy returns ever average out to exactly the truth?

> **Alt+Tab · game 6 · stop 3 of 6: Predict 60 calls, then press F.**
>
> **What he just said:** Fire the oracle. Nobody tells you a state's true value, so you use the return you actually saw. Each return is right on average and noisy every time, so you average them.
>
> **In the game:** The team adds 54 calls, every pad read 4 or 5 times. Answer two questions with the mouse buttons or melee, then press F to bring the calls in and read the table on the right.
>
> **Before you press:** Decide which map will be closest after 60 calls, and whether EXACT, which averages each pad's reads, will be exactly right.
>
> <details><summary>Back from the game: what you just saw</summary>With every pad visited, EXACT wins. Its miss is small, not zero: each pad's number is an average of a few reads, each off by up to 1. That is lecture 4's Monte Carlo estimate. Notice how little THIRDS and ONE WORD moved from 6 calls to 60. And EXACT is the same method with one group per pad: a table is the special case with one feature per state.</details>

**On the island:** Only tables raced. Typical error against the exact values after 10 episodes: TD step 0.1 at 112.7, TD step 0.5 at 100.5, Monte Carlo 25.9; after 200: 85.6, 46.5, 15.3. All tables started at zero while most true values are below -100.

### [45:57](https://www.youtube.com/watch?v=UoPei5o4fps&t=2757s) When two guesses disagree, the later one wins
Early in a fight you think you are winning. Two seconds later their Zarya has ult, and you think you are losing. The second guess has seen more of what actually happened, so that is the one you trust. You fix the first.

A student asks Silver about exactly this. The TD target (one real reward plus the estimate for the next state) depends on the weights too. So why does the update take the slope, or gradient, of the earlier estimate alone and treat the target as fixed?

Silver's answer is about the direction of time. The later estimate has seen more real reward, so information should flow from later to earlier. Take the slope of both and it is like joining the two estimates with a spring: the later one gets pulled back toward the earlier one. He says that gives wrong values even with a table.

Your better guess, dragged toward your worse one.

Methods that take both slopes are called residual gradient methods. He advises against them unless you know what you are doing.

**On the island:** Not run on the island. Adding the second gradient term to a RANDOM WALK TD table and scoring it against -114.4 would test it.

### [48:58](https://www.youtube.com/watch?v=UoPei5o4fps&t=2938s) Choosing moves: lecture 5's loop, with the formula steering
You do not wait until you have mastered a hero before you queue with them. You play, adjust a little after each fight, and keep going.

So far the formula has only scored a fixed way of playing. You still have to find a good one, which Silver calls control, and he reuses lecture 5's loop. Estimate a score for each state and move together (the action value, Q). Mostly take the best-scoring move, and with a small probability called epsilon take a random one, which is acting epsilon-greedily. Repeat.

The scores now come from the formula instead of a table, and he does not wait for it to fit well before acting on it. In the most incremental version the weights are updated after every step, and the next move is chosen from the updated scores.

He attaches two warnings.

1. **It may have no way to say the right answer.** An approximator may be unable to represent the best values at all.
2. **It usually does not settle.** These methods oscillate near the answer, a little away and then back again.

The game takes up the first warning: how wrong does a coarse map stay when experience never runs out?

> **Alt+Tab · game 6 · stop 4 of 6: Find where THIRDS stays wrong.**
>
> **What he just said:** Silver's warning: an approximator may be unable to represent the true values at all, however much experience it gets. More scouting cannot fix a map that has no word for what you found.
>
> **In the game:** Picture scouting forever, every pad read endlessly. Answer two questions with left click, right click or melee, then read the forever column on the right and the numbers under the pads.
>
> **Before you press:** Choose which maps can never get every pad right, and on which pad THIRDS stays most wrong.
>
> <details><summary>Back from the game: what you just saw</summary>With endless reads EXACT reaches 0. THIRDS stops at 1.99 and ONE WORD at 3.39. Most of THIRDS' miss is pad 10, a 9 among 1s and 2s that it calls 3.25, and the same average drags pad 12 up. A coarse map learns fast and has a floor. Scouting forever does not get you under it. <em>In an agent:</em> When two prompts look alike to a model but need different answers, it gives both the same confident answer. That is THIRDS calling pad 10 a 3.25 because its neighbours are calm.</details>

**On the island:** Both reduced bots are exactly this loop: Q-learning with epsilon 0.1 on one-hot group features (each group of squares has its own on-off feature). Runs with 10 clean test crossings: full table 11/11, 16 groups 10/10, row only 3/10.

### [56:21](https://www.youtube.com/watch?v=UoPei5o4fps&t=3381s) Mountain car: when you cannot drive up, rock
A kid on a swing cannot jump straight to the top. They pump: back, forward, back, a little higher each time.

Silver's car sits in a valley with an engine too weak to drive straight out, so it does the same: roll back, drive forward, roll back, until it has the speed to reach the top. This is the mountain car problem. Its state is two continuous numbers, position and velocity.

He solves it with Sarsa, lecture 5's method: after each step, shift the score of the move you just made toward the reward plus the score of the move you actually take next. With a weighted sum of features as the scores, it is linear Sarsa.

The features are overlapping tiles laid across position and velocity. Every tile containing the current state is on and gets nudged, so nearby states learn too. This is coarse coding. (Like overlapping callouts: one sighting can update both "mid" and "near the bridge".) Over time the scores, drawn as a surface over position and velocity, grow into a spiral.

A student asks whether a better description of the state would give a simpler shape. Silver says good features make the true value far easier to learn, and that is where your knowledge goes in.

The game asks what one well-placed feature is worth.

> **Alt+Tab · game 6 · stop 5 of 6: Give one pad its own number.**
>
> **What he just said:** Good features can make the true value far easier to learn. Choosing them is where your knowledge goes in, and Silver says so plainly.
>
> **In the game:** Walk into one pad's ring and press F (Interact). That pad gets its own number on top of THIRDS, a map of 4 numbers. Answer one question with the mouse buttons or melee, then read the YOURS row on the right.
>
> **Before you press:** Once your pad is picked, commit to how far it will pull THIRDS' forever miss down from 1.99.
>
> <details><summary>Back from the game: what you just saw</summary>One pad matters far more than the rest. Split off pad 10 and the floor drops from 1.99 to 0.55, with just 4 numbers. Pick any other pad and it stays between 1.85 and 1.99, because that pad already fit its group. Where you put the feature mattered more than how many you had. Choosing the description is most of the work.</details>

**On the island:** The 16 coarse states are coarse coding with one tiling (a single layer of tiles) and no overlap. Q, ROW ONLY shows bad features: with no column, forward and back look identical to her, so none of her 16 weights can say "go right".

### [1:04:31](https://www.youtube.com/watch?v=UoPei5o4fps&t=3871s) Guesses built on guesses: faster, and occasionally explosive
Judge a fight by how the next moment looks and you know sooner than the scoreboard tells you. You also let one bad read feed the next.

Building one guess on another is called bootstrapping, and Silver shows both sides. The good side: across several tasks he turns one dial, lambda, lecture 4's setting that runs from trusting a guess after one step (0) to waiting for the real outcome (1). At lambda of 1, pure Monte Carlo, results are poor because the returns vary too much. TD(0) does better, and the best lambda lies in between.

The bad side is Baird's counterexample. Its TD updates are swept over all states instead of gathered by following the policy, so they are off-policy. The weights go to infinity.

Infinity is not a useful estimate.

His table of ticks and crosses for prediction, scoring a fixed policy:

- **On-policy** (data from following the policy being scored): TD converges, or settles, with tables and with weighted sums of features, the linear case. With non-linear formulas such as neural networks, no guarantee.
- **Off-policy:** TD can run away like Baird's, or diverge, even when linear.

Gradient TD is the repair: it follows the true slope of an error measure called the projected Bellman error, with one correction term, and converges in every column.

**On the island:** Lambda was compared only with tables: SARSA LAMBDA fell 11.8 times per 100 training episodes against SARSA's 16.3, a difference of -4.51 (95% interval -6.21 to -2.78), exploratory. No divergence could appear: the full tables sit in the all-ticks column.

### [1:08:59](https://www.youtube.com/watch?v=UoPei5o4fps&t=4139s) Choosing moves: some methods wobble, Q-learning can fly off
Your crosshair on a moving Pharah never sits perfectly still. It drifts a hair off, comes back, drifts again, and the shot still lands.

A crosshair that drifts off the screen is a different problem.

Choosing moves is shakier than scoring a fixed way of playing. Once a formula replaces the table, Silver says, there is no guarantee that an improvement step really improves the policy. His second table of ticks and crosses covers this search for a good policy, called control. With a weighted sum of features, the linear case:

- **Monte Carlo control** (learning from whole runs) and **Sarsa** (learning from the move actually taken next) get a tick in brackets. They get close to the best values, step away and come back, without ever shooting off. Silver calls this chattering. It is the wobbling crosshair.

- **Q-learning** gets a cross. It is lecture 5's method that learns about the best move while trying others, which makes it off-policy, and a cross means its weights can run off to infinity, or diverge.

A student asks whether the crosses matter in practice. Silver says naive Q-learning or Sarsa with a neural network very often blows up, while linear methods mostly behave.

**On the island:** Q, 16 COARSE STATES is off-policy Q-learning with linear features, a cross cell, and all 10 runs reached the goal. A cross means divergence is possible, not certain, and aggregation (grouping states) is known to be a stable case (not from the lecture). The island logged returns, not weights, so it cannot say whether she chattered.

### [1:12:25](https://www.youtube.com/watch?v=UoPei5o4fps&t=4345s) Stop throwing your replays away
Imagine you could watch each of your games once, live, and then the footage got deleted. No replay. No second look at that fight in overtime.

That is how every method so far treats experience.

Each one looks once, makes one small update, and throws the experience away. Silver says that wastes data. The alternative keeps everything and looks for the weights that best fit all of it. These are batch methods: "life is one big training set for an agent."

Best fit needs a definition. Take the gap between the estimate and its target (the number it is being pulled toward) at every remembered step, square it, add the squares up, and choose the weights that make the sum smallest. That is the least squares fit.

An easy way to reach it: store each experience as it happens, then over and over draw one at random and repeat the usual small update, the gradient step, toward its target. This is experience replay.

The shuffle does a second job. Steps that happened one after another are strongly alike, and drawing them at random breaks that correlation.

**On the island:** Not run on the island. The nearest bot, DYNA-Q, makes 20 extra updates per real step from a remembered table model (lecture 8, not replay itself). Her mean return over the first 40 episodes beat Q-learning's by 25.98 (interval 15.53 to 36.25), exploratory.

### [1:17:27](https://www.youtube.com/watch?v=UoPei5o4fps&t=4647s) The Atari player (DQN): replay, and a target that holds still
Picture aiming at a target that jumps every time you fire, because your own shot knocked it. You would never settle on an aim.

The program that learned Atari games is built from parts already on this page. It is Q-learning, lecture 5's method of learning each move's score from the best next move, with a neural network in place of the table. The network is convolutional: it applies the same weights to every region of an image. It reads the last 4 frames and outputs values for 18 joystick positions. It is called DQN, short for deep Q-network.

Silver has already said that naive Q-learning with a neural network very often blows up. Two tricks keep this one stable.

1. **Replay.** It stores about a million of its steps (each a state, the move, the reward and the next state, called a transition) and trains on random handfuls of 64, called minibatches.

2. **A frozen target.** Its targets would otherwise come from the network being trained: the jumping target. So they come from an older copy, held fixed and swapped every few thousand steps.

"I wouldn't claim this is the most aesthetically satisfying idea," he says. It works anyway, and one network with one set of settings served 50 games.

Breakout scores 316.81 with both tricks and 3.17 with neither.

**On the island:** Not run on the island. A small network on Tracer's raw position, trained with and without replay and a frozen target, would show both tricks at island scale.

### [1:26:40](https://www.youtube.com/watch?v=UoPei5o4fps&t=5200s) Least squares: skip the nudging, solve for the answer
To know your average damage over a season, you do not nudge a guess up and down after every game.

You add it all up and divide once.

With a weighted sum of features, the best weights can be found the same way, in one go. Replay can take many passes to reach the least squares fit, the weights with the smallest summed squared error. This gets there in one.

At the best fit nothing pushes the weights to change, so over all the stored data the updates average to zero. Silver sets that average to zero and solves for the weights.

<details markdown="1"><summary>The formula, when you want it</summary>

`w = (Σ x(sₜ) x(sₜ)ᵀ)⁻¹ Σ x(sₜ) vₜ`. In words: the best weights come from one calculation on a grid of numbers, a matrix inversion, sized by the number of features, not states.

</details>

That costs order N cubed for N features, or N squared per step with a shortcut called Sherman-Morrison. With returns (actual totals of reward) as targets it is least squares Monte Carlo, LSMC. With TD targets (one reward plus a guess) it is least squares temporal difference, LSTD. Both converge on and off policy, whether or not the data came from following the policy being scored.

For choosing moves, least squares policy iteration, LSPI, alternates such fits with a switch to whatever now scores best (greedy improvement). It solved a 50-state chain in seven iterations.

The game's last stop asks what this best fit looks like when the features are plain groups.

> **Alt+Tab · game 6 · stop 6 of 6: Read the debrief.**
>
> **What he just said:** With linear features you can skip the nudging. Solve once over all your experience and the best weights fall out. The size of that calculation depends on the number of features, not the number of states.
>
> **In the game:** Nothing to press. Read the three lines on the left and your prediction score.
>
> **Before you press:** Before you read, say in one sentence what the three maps had in common and what made them differ.
>
> <details><summary>Back from the game: what you just saw</summary>All three maps were the same method: average the calls in each group. For features that are on in one group and off everywhere else, that average is exactly the least-squares answer. Only the grouping differed. This was value function approximation at its mildest, fixed hand-made groups and plain averages. A neural network learns its own features, and that is where the guarantees thin out. <em>In an agent:</em> A value head on a language-model agent reads the whole conversation and learns its own callouts instead of being handed them.</details>

**On the island:** Not run on the island. LSTD on RANDOM WALK's logged steps would give a value table in one solve, against TD's error of 85.6 after 200 episodes.

## What the island measured for this lecture

Put money on it before you look: the player with the best information wins. Three Q-learning bots with the same settings (alpha 0.5, epsilon 0.1) walk the same strip. One is told her exact square, one her row and which quarter of the strip she is in, one only her row. More information should mean better play.

Half of that bet pays.

| | Q-LEARNING (48 squares) | Q, 16 COARSE STATES | Q, ROW ONLY |
|---|---|---|---|
| Runs | 11 | 10 | 10 |
| Falls per 100 training episodes (95% interval) | 26.5 (22.4 to 30.4) | 16.3 (12.1 to 21.0) | 42.5 (39.0 to 45.7) |
| Mean return, first 40 / last 40 episodes | -57.6 / 7.5 | -13.2 / 14.3 | -114.3 / -76.0 |
| Episode of first goal (median) | 13 | 5 | 24 |
| Runs with 10 clean test crossings | 11/11 | 10/10 | 3/10 |
| Steps per training episode | 18.6 | 17.6 | 47.1 |

The bot who knew least did play worst. Against the full table, the row-only bot fell more, a difference of 15.97 per 100 (10.62 to 21.32), and her late return was lower by 83.48 (interval -107.47 to -60.97 for the difference). Tested with exploring switched off, only 3 of her 10 runs crossed cleanly ten times out of ten.

The bot who knew most did not play best. The 16-group bot fell less than the full table, -10.15 per 100 (interval -15.99 to -4.13, p 0.0074), and found the goal for the first time at a median of episode 5 instead of 13.

The only thing that differed was the lumping. Grouping helped where the grouped squares behave alike: the edge is just as deadly one square along, so one fall teaches three squares. It hurt where it erased what she needed. The row-only bot cannot tell which way the goal is, so a step forward and a step back look identical to her.

What it does not show:

1. **Not a planned test.** All of these are exploratory first looks, uncorrected for the number of comparisons (only SARSA against Q-learning was planned).
2. **Not a win on return, yet.** The 16-group bot's late-return edge over the full table has no interval, so it is not a result.
3. **Not the hard cases.** Learned or overlapping features, a network, replay, least squares and divergence were not tested.

## Guess first

<details><summary>Q, ROW ONLY always knows how close the edge is and never knows how close the goal is. Next to the bot who knows her exact square, does she fall more often or less?</summary>
More: 42.5 falls per 100 episodes against 26.5. She learns "not toward the edge in row 0" fast, since it holds in every column. But a step forward and a step back look identical to her, so she paces the edge row for 47.1 steps an episode, and each random exploratory move there is another chance to fall (that link is an inference, not a separate measurement). Grouping squares like this is state aggregation, and here it grouped away the one thing she needed.
</details>

<details><summary>The full-table bot first reaches the goal at a median of episode 13. Q, 16 COARSE STATES sees each row in blocks of three squares. Does she get there sooner or later?</summary>
Sooner: a median of episode 5. Each update moves a weight shared by three squares, so one experience teaches three places. The sharing is right here, because neighbouring columns really are alike: the edge is just as deadly one square along. Silver calls this generalisation.
</details>

<details><summary>Swap the table for a neural network and ask it to score one fixed way of playing. One learner waits for the end of each run; the other trusts its own next guess. Which one is still guaranteed to settle?</summary>
The one that waits, Monte Carlo. The return is an unbiased sample, so the update is true stochastic gradient descent and reaches a local optimum. The one that trusts its guess, lecture 4's TD, has a target that leans on the network's own estimate, and it can diverge with non-linear approximators. Building a guess on a guess, bootstrapping, still usually learns faster, which is why Silver goes looking for safe TD variants.
</details>

<details><summary>Put lecture 5's SARSA and Q-learning on a weighted sum of features and let both choose moves. One of them can send its weights off to infinity. Which one?</summary>
Q-learning. It learns about the best move while trying others, which makes it off-policy, and Silver's table of ticks and crosses gives it a cross. Linear SARSA only chatters: near the answer, a little away, back again. The 16-group bot is off-policy Q-learning on linear features and stayed stable, which fits: a cross means divergence is possible, not certain, and one-hot grouping is a well-behaved case.
</details>

<details><summary>Give Q, ROW ONLY experience replay: she keeps every step and trains on each one many times over. Does she stop pacing the edge?</summary>
No. Replay converges to the least squares fit for her features, and her features cannot separate forward from back. More passes squeeze out everything the features can express, and never anything more. Only a better description of where she stands fixes her. That is Silver's point at the mountain car: good features are where your knowledge goes in.
</details>

<details><summary>Lecture 3's PLANNER solved the strip in 13 sweeps. Hand her a Go board instead. How far does she get?</summary>
Nowhere. Each sweep visits every state, and Go has about 10 to the 170: the table would not fit and the sweeps would not finish. She also needs the rules written down. Approximation answers the first problem. Learning from experience instead of from written rules, called model-free, answers the second.
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

Picture an agent in tau-bench. It reads a conversation with a simulated customer, calls tools on a database, and gets one score at the end: is the database right? Its state is the conversation so far. No table could list those, so any value estimate for it has to be a function approximator.

Here the mapping is exact. A value head that reads the conversation and predicts the score is this lecture's non-linear v-hat. The one difference is that it learns its own features instead of being handed them, the "discovery problem" that Silver sets aside (23:12).

Generalisation cuts both ways, as it did on the island. Two conversations that share features but need different actions get the same confident estimate. That is the row-only bot's trouble, and THIRDS calling pad 10 a 3.25 in the game (an analogy, not a measurement of any model).

The mapping breaks at the action. DQN maximises over 18 joystick positions. An agent's action is a whole message or tool call, and Silver notes (1:03:07) that the max is hard when actions are not a short list.

The tables still have a warning for you. Learning from logs of older agent versions is off-policy, and off-policy bootstrapping through a network has crosses in every cell.

## The thread to partial observability

Both smaller bots on this page play with part of the map blacked out, and the designer did it to them on purpose.

That is all state aggregation is: partial observability chosen by hand. Whether a step forward reaches the goal or just costs Q, ROW ONLY a step depends on her column, and nobody tells her the column. So from her side the world is no longer Markov. What she is shown is not enough to predict what happens next.

The lecture quietly assumes the opposite: its features summarise a state the agent can fully see. DQN is where the seam shows. Its input stacks the last 4 frames, a short history where one frame would not show motion (that reason is not stated in the lecture).

Lesson 11 pulls on that seam. One square on the strip is shut, a different one each episode, and the runner is not told which. With no way round, the blind runner reached the goal in 52% of her test crossings. Give her one slot of memory, the row of the square that stopped her, and it was 90%: 38 points higher (95% interval 10 to 66 points), a real difference by the rule set in advance. Told the wall's row outright, she reached 94%, and the gap between seeing and remembering is not yet conclusive. Where a way round existed, none of the gaps was established.

Practice does not rescue her either. In the lesson's simulation by the rules alone, on the strip with no way round, the blind runner reached the goal 47% of the time after 200 training episodes and 48% after 1,000. What she lacks is not practice.

The same lesson tries it on a local language model, where "more weights" can be taken literally. Shown only the latest message, gemma4:12b got 6 of 24 cases right, and gemma4:31b, the bigger model, 12 of 24. The smaller one with a short note to itself got 23 of 24. (One small scripted world, one run per case, nothing wider.)

An approximator can only be as good as what its inputs tell apart.

The fix for a missing fact is memory, not more weights.

## Experiments the lecture asks for that the island has not run

- Offset tilings over Tracer's real position with linear Sarsa: generalisation without aliasing.
- Q-learning on real-valued features (distance from edge, distance to goal): chattering or growing weights.
- LSTD on RANDOM WALK's logged steps: one solve against TD's slow tables.
- A small network on raw position, with and without replay and a frozen target: DQN's ablation in miniature.
- Off-policy linear TD on random-walk logs evaluating the greedy policy: Baird-style weight growth.
