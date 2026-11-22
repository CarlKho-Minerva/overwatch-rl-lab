# Lecture 4: Model-Free Prediction

*David Silver's lecture 4 (UCL, 2015), gone through in his order and re-explained with the Tracer experiments on Workshop Island. The lecture and its slides are his: [video](https://www.youtube.com/watch?v=PnHCvfgC_ZA), [course page](https://davidstarsilver.wordpress.com/teaching/). The words below are a re-explanation. Every island number comes from the logged runs in this repository.*

Walking back from spawn, you can guess again at every corner how long the walk to the point will take, or you can find out when you get there. On the island, three tables of 48 numbers have the same kind of job: they follow the RANDOM WALK bot, who wanders the strip at random and nearly always falls, and from her steps alone, without the island's rules, each must work out how good each square is for a walker like her. This hour asks how that can be done: wait for the walk to end and average what happened (Monte Carlo), or correct each guess after every step using the next guess (temporal-difference learning). Both reach the true values, one paying in noise and the other in bias from its own guesses, and a single dial, lambda, runs between them.

**Two windows:** this page, and [Game 4: Back From Spawn](../workshop/games/g04.md), an Overwatch custom game for this lecture (paste `workshop/compiled/game-04.txt` into a custom game's settings and start it). The game opens at stop 1 and waits. Read down this page; at each box marked Alt+Tab, switch to the game, do that stop, and switch back. The game never moves on while you read.

## The lecture in order

### [04:29](https://www.youtube.com/watch?v=PnHCvfgC_ZA&t=269s) No one hands you the rules, and first you only measure
Until now the learner was handed the rulebook. Lecture 3's planner was told where every move lands and what it pays, so it could work out the answer before taking a step. Silver opens this hour with a factory whose equations nobody can write down, and asks what you do then.

His answer is to learn from experience alone. The rulebook has a formal name from lecture 2: the Markov decision process, or MDP, the map of states, moves, rewards and odds. Lecture 3 solved a known one. Working without it is called model-free learning, the model being the rulebook.

He splits the work in two, as lecture 3 did, and this hour only measures. You are given a rule for choosing moves, called a policy, and you estimate how much reward to expect in total from each state while following it. That expected total, one number for each state, is the value function, and estimating it for a given policy is called prediction. Finding the best policy is called control, and that is lecture 5.

**On the island:** The policy, her rule for choosing a move, is fixed: RANDOM WALK picks each of four moves with equal chance. Prediction fills in, for each square, the total score she will collect from there. PLANNER did this in lecture 3 by reading the rules; the tables only watch.

### [05:17](https://www.youtube.com/watch?v=PnHCvfgC_ZA&t=317s) Monte Carlo: the value is the average of what happened
The plainest way to learn what a starting position is worth is to play from it many times and average what you got. That is Silver's first method, Monte Carlo learning. He says it is not necessarily the most efficient method, but it is very widely used in practice.

It works on whole episodes, an episode being one run from the start until the game ends. From any moment in an episode you can add up all the reward that came between then and the end, and that total is called the return. If one episode returns 5 and the next returns 7, the start is worth 6 so far.

No rulebook is needed, only the returns that were seen. The one requirement is that episodes end, because there is no total until they do. `v(s) = E[G_t | S_t = s]`. In words: a state's value is the average return after standing in it, and Monte Carlo uses the average of the samples it has in place of that true average.

**On the island:** Episodes always end. Over 2,308 random-walk episodes the mean return was -112.7 (standard error 0.46); the exact start value, which ignores the time limit, is -114.4.

### [09:00](https://www.youtube.com/watch?v=PnHCvfgC_ZA&t=540s) First visit or every visit, and why rare states stay noisy
In one episode you can pass through the same place twice, so someone has to decide which pass counts. Counting only the return (the total reward to the end) after the first time an episode reaches a state is called first-visit Monte Carlo. Counting a return for each visit is called every-visit Monte Carlo.

Both settle on the true value, by the law of large numbers: the average of many independent samples approaches the true average. A student asks whether a very large world needs vastly more episodes, and Silver says no. The error for a state shrinks with the number of visits to that state, whatever the number of states (the size of the state space).

His example is blackjack with 200 states, played by a naive rule that sticks (takes no more cards) only on 20 or 21. After 10,000 hands the states with a usable ace (one that can count as 1 or 11) are still noisy, because they come up less often. It takes about 500,000 hands to settle them. Nobody told the learner the deck or the dealer's rule.

**On the island:** The table is every-visit, and revisits are common because walking into a side wall leaves her in place. Far inland squares are rarely reached before she falls; the error score weights squares by visits, so they count less. First-visit was not run.

### [26:21](https://www.youtube.com/watch?v=PnHCvfgC_ZA&t=1581s) A running average, and forgetting on purpose
You do not need to keep every score you saw to know your average. You can keep one number and nudge it each time a new score arrives, which is called the incremental mean. `mu_k = mu_(k-1) + (1/k)(x_k - mu_(k-1))`. In words: the new average is the old one moved toward the new sample by a fraction of the surprise.

The surprise is the gap between what you predicted and what you saw. Silver says nearly every algorithm in the lecture has this shape: a prediction, corrected a little in the direction of its error.

Then he applies it to a state's value and changes one thing. The fraction 1/k shrinks as samples pile up, so each new sample moves the average less. Put a constant step, written alpha, in its place and old episodes fade. `V(S_t) <- V(S_t) + alpha (G_t - V(S_t))`. In words: move the value a fixed fraction of the way toward the latest return, the real total from that visit to the end.

He prefers the version that forgets. Once the policy starts to improve, the thing being measured keeps changing, and returns from long ago only slow the estimate down.

**On the island:** The MONTE CARLO control bot uses a constant step of 0.2. The Monte Carlo value table that follows RANDOM WALK uses the plain running average: a step of 1/k on the k-th visit to a square, every visit counted.

### [34:11](https://www.youtube.com/watch?v=PnHCvfgC_ZA&t=2051s) Temporal difference: update a guess toward a guess
You do not have to finish a walk to learn that your first guess was off. One step in you know a little more, and can correct the old guess with the new one. This is temporal-difference learning, or TD, and it works from episodes that are not over.

The simplest version, TD(0), takes one real step and its reward, then lets its own current estimate of where it landed stand for everything after. Using one of your own estimates as part of what you learn toward is called bootstrapping. `V(S_t) <- V(S_t) + alpha (R_(t+1) + gamma V(S_(t+1)) - V(S_t))`. In words: nudge the value of where you were toward the reward you just got plus your current guess for where you are now.

The thing it nudges toward, R + gamma V(next), is the TD target, where gamma is the discount that makes later reward count for less. The gap between target and old value is the TD error.

Silver's case is a near crash: a car comes hurtling at you and swerves away at the last second. Monte Carlo, waiting for the real total, sees no crash and never learns how close it came. TD lowers the value of the moment before at once. "You don't need to wait until you die to update your value function."

> **Alt+Tab · game 4 · stop 1 of 8: Walk the mud leg to ring 1**
>
> **What he just said:** Temporal-difference learning fixes a guess after every single step, aiming it at the reward just received plus its own guess for where it landed, so it never has to wait for the end.
>
> **In the game:** The game waits at the spawn ring. Walk with WASD to ring 1; leg 1 of the first walk is always mud, so you move at 30% speed. At ring 1 a question floats in front of you: left click for BLUE, right click for ORANGE, melee for both.
>
> **Before you press:** Before you click, decide which of the two guesses for the spawn ring could have changed already, when you have walked only one leg of five.
>
> <details><summary>Back from the game: what you just saw</summary>ORANGE's spawn guess moved, from 15 seconds toward the leg's time plus ORANGE's own guess for ring 1. BLUE stayed at 15, because its target is the time from spawn all the way to the point, and you have not got there. That is the difference in one leg: temporal-difference learning, TD, updates at each step; Monte Carlo waits for the end. <em>In an agent:</em> A value model that scores a half-finished conversation can update after every turn; a grader that reads only the final pass or fail cannot.</details>

**On the island:** Two TD(0) tables, steps 0.1 and 0.5, discount (gamma) 1. From square A to B, the target is -1 plus the table's number for B; off the edge, it is -101.

### [39:50](https://www.youtube.com/watch?v=PnHCvfgC_ZA&t=2390s) Driving home: two ways to revise a forecast
Anyone who has driven home has done this: you leave with a forecast of how long the trip will take, and the forecast keeps changing on the way. Silver takes the example from Sutton and Barto. You leave expecting 30 minutes. It is raining, so the forecast becomes 40. The highway is clear and it drops to 35. You get stuck behind a truck and it is 40 again. You arrive after 43.

Monte Carlo, the method that needs the real total, waits until you are home. Then it pulls every forecast made along the way toward 43.

TD, the method that corrects each guess with the next one, does not wait. At the rain it moves the 30 toward 40, and after the highway it moves the 40 toward 35. Silver describes this as "updating guess towards a guess", and it goes on until the arrival grounds the last guess in a real outcome.

A student asks what the actions are, and there are none. With the policy fixed, the formal map of the world (the MDP) has no choices left in it. What remains is called a Markov reward process: states and rewards following one another with no decisions in between.

> **Alt+Tab · game 4 · stop 2 of 8: Finish the walk and watch BLUE**
>
> **What he just said:** In the driving-home example, Monte Carlo waits until you arrive and then pulls every forecast you made on the way toward the real arrival time.
>
> **In the game:** Leave ring 1 when you are ready and walk to rings 2, 3 and 4 and the point with WASD. Each leg's line turns green for clear or red for mud as you start it. The clock runs only between rings, so you can stand in a ring and read.
>
> **Before you press:** Before you leave ring 1, guess which of the ten numbers on the right will change at each ring, and which will all change together at the point.
>
> <details><summary>Back from the game: what you just saw</summary>At each ring one ORANGE number moved: the guess for the ring you had just left. At the point all five BLUE numbers moved at once, each halfway to the time the rest of that walk really took from its ring. BLUE is Monte Carlo: it learns from real totals, so it had to wait for them. Nobody told either guess how likely mud was.</details>

> **Alt+Tab · game 4 · stop 3 of 8: Say which guess leans on a guess**
>
> **What he just said:** Temporal-difference learning moves the forecast made at one landmark toward the forecast made at the next, a guess updated toward a guess, until the arrival grounds the last one.
>
> **In the game:** A question floats in front of you. Left click for BLUE, right click for ORANGE.
>
> **Before you press:** Lecture 2's Bellman rule says the time from here is this leg plus the time from the next ring; decide which of the two guesses builds its target that way.
>
> <details><summary>Back from the game: what you just saw</summary>ORANGE does. Its target is the real time of the leg plus its own current guess for the next ring. Using one of your guesses inside the target of another is called bootstrapping. Lecture 2's rule uses the true time from the next ring, averaged over every way the leg can go; ORANGE uses one walked leg and a guess in its place. <em>In an agent:</em> Training a value model toward its own next-turn predictions is the same move, and it can copy its own errors forward the same way.</details>

**On the island:** A random episode lasts 14.9 steps on average. The TD tables change after each step; the Monte Carlo table waits for the end.

### [47:31](https://www.youtube.com/watch?v=PnHCvfgC_ZA&t=2851s) Bias and variance, and who cares about the starting values
A guess can be wrong in two ways: it can jump around from try to try, or lean the same way every time. Silver notes first that TD, the step-by-step method, also learns from sequences cut short and from tasks that never end. The deeper difference is statistical.

The return, the real total to the end, is right on average, which is called unbiased. So is one real reward plus the discounted true value of the next state, by lecture 2's Bellman equation. But TD has only its own estimate V of that state, so its target leans: it is biased.

In exchange its spread, called variance, is far lower. A return carries the luck of every step to the end, the TD target the luck of one. When a student calls TD's estimate noisy, Silver corrects the word: "It's not noisy, it's biased."

So Monte Carlo, which waits for real totals, has zero bias and high variance. It converges even with function approximation (a formula in place of a table, when the states are too many to list) and is not very sensitive to starting values. TD has some bias and low variance and is usually more efficient. In a table it converges, a proof he credits to Peter Dayan, but not always with function approximation, and it is more sensitive to starting values because it feeds off itself.

> **Alt+Tab · game 4 · stop 4 of 8: Walk again and compare the jumps**
>
> **What he just said:** Monte Carlo's target is unbiased but noisy, because it carries the luck of a whole episode, while TD's target is biased by its own estimate but carries the luck of only one step.
>
> **In the game:** Walk the second route from the spawn ring to the point with WASD. The mud is drawn again for every walk, so this one will not match the first.
>
> **Before you press:** Before you leave spawn, decide whose spawn guess will jump further on this walk, BLUE's or ORANGE's.
>
> <details><summary>Back from the game: what you just saw</summary>Look at how far each spawn number moved on this walk. BLUE's moved halfway to this walk's total, mud and all, so a muddy walk drags it a long way. ORANGE's moved toward leg 1 plus its guess for ring 1, and that guess carries news from earlier walks, one ring further back each time. Less noise, but only as right as its own guesses: that is bias.</details>

> **Alt+Tab · game 4 · stop 5 of 8: Bet on which guess swings more**
>
> **What he just said:** Because each target carries a different amount of luck, the Monte Carlo estimate swings more from episode to episode than the TD estimate, which is steadier but leans on its own starting values.
>
> **In the game:** A question floats in front of you: left click for BLUE, right click for ORANGE, melee for about the same. Then walk the third route with WASD.
>
> **Before you press:** Commit to whose spawn guess will have moved more in total by the end of the fifth walk.
>
> <details><summary>Back from the game: what you just saw</summary>The total itself comes at stop 7. On this walk, compare its mud with the walk before: when the amount of mud changes a lot, BLUE's spawn number follows it and ORANGE's barely moves. The spread a guess picks up from luck is called variance, and Monte Carlo has more of it here.</details>

> **Alt+Tab · game 4 · stop 6 of 8: Get cut off at ring 2**
>
> **What he just said:** TD can learn from a sequence that never finishes, because each update needs only the next step, while Monte Carlo needs a complete return from start to end.
>
> **In the game:** A question floats in front of you: left click for BLUE, right click for ORANGE, melee for neither. Then walk the fourth route with WASD; at ring 2 the round ends and the walk stops there.
>
> **Before you press:** Commit to which guesses will learn anything from a walk that never reaches the point.
>
> <details><summary>Back from the game: what you just saw</summary>ORANGE changed its guesses for spawn and ring 1, one for each leg you walked. BLUE changed nothing: with no time to the point there is no total to move toward. The fight ended before you arrived, and only the guess that updates at each corner got anything out of the walk. <em>In an agent:</em> An agent run that times out halfway still trains a TD-style value model, while a pass-or-fail grader gets nothing from it.</details>

**On the island:** A random return can be -101 (off at once), about -110 (wander, then fall), -150 (time out), or in 1.0% of episodes a goal: Monte Carlo's variance. The TD tables start at zero; most true values are below -100.

### [53:35](https://www.youtube.com/watch?v=PnHCvfgC_ZA&t=3215s) The random walk: in Silver's example, TD wins
To compare the two methods, Silver uses one of the simplest worlds you could imagine: five states in a row. From each you step left or right at random. Leaving on the right pays a reward of 1, leaving on the left pays nothing, and the true values run from 1/6 at the left end to 5/6 at the right.

He starts TD(0), the one-step method, with every value at 0.5. After about 100 episodes its estimates look right.

Then he plots the error against the number of episodes for both methods. The error is one number for the typical size of the miss across the states, called the root mean squared error. With a good step size, TD beats Monte Carlo, the method that averages real totals.

With a constant step the estimate never lands exactly; it keeps bouncing near the answer. Exact convergence needs a step that shrinks over time, and the rules for how it must shrink are called the Robbins-Monro conditions.

**On the island:** This is the experiment, and it came out the other way. After 10 episodes the error was 112.7 for TD with step 0.1, 100.5 for TD with step 0.5, and 25.9 for Monte Carlo; after 200 episodes it was 85.6, 46.5 and 15.3. The section after the lecture, on what the island measured, says why.

### [58:05](https://www.youtube.com/watch?v=PnHCvfgC_ZA&t=3485s) Eight episodes replayed forever (the AB example): two right answers
Suppose you have only eight recorded episodes and replay them forever. Silver asks whether the two methods, fed the same eight again and again, end with the same numbers. Learning this way is called batch learning.

His eight episodes use two states, A and B. In one, you start in A, get a reward of 0, move to B and get 0 again. In six, you start in B and get 1. In the last, you start in B and get 0. So the value of B, written V(B), is 0.75: six rewards of 1 in eight visits. On A the room splits about half and half.

Monte Carlo, which averages the returns it saw, says V(A) is 0, because the one return seen from A was 0. TD(0), the one-step method, says V(A) is 0.75. It acts as if it had built the most likely model of what it saw (A always leads to B, with reward 0) and then solved it, which is called certainty equivalence. Silver calls both answers legitimate.

What separates them is the assumption that the current state carries all that matters for the future, called the Markov property. TD exploits it and is usually more efficient where it holds. Monte Carlo ignores it and is often better where it fails.

**On the island:** The game is nearly Markov, with 0.21 slips per 1,000 steps. Batch replay was not run.

### [1:09:11](https://www.youtube.com/watch?v=PnHCvfgC_ZA&t=4151s) Two dials: bootstrapping and sampling
Every method so far makes two choices when it updates a value: whether to stop before the end and trust a guess, and whether to try one outcome or weigh them all.

Stopping early and filling in the rest with your own estimate is bootstrapping, the word from the TD part. TD does it after one real step, and so does dynamic programming, lecture 3's way of planning from the rules. Monte Carlo does not: it uses real returns all the way.

Using the one outcome that came, instead of an average over all that could come, is called sampling. Monte Carlo and TD sample. Dynamic programming does not, because it knows the odds and averages over all outcomes. Exhaustive search, which follows every branch to the end, does neither.

A student asks why the later guess should correct the earlier one and not the reverse. Silver says the reverse gives wrong answers. Between the two guesses lies one step of the real world, with a real reward and a real move, so the later guess is the better informed.

> **Alt+Tab · game 4 · stop 7 of 8: Ask what a planner would need**
>
> **What he just said:** Planning by dynamic programming bootstraps without sampling, because it is handed the rules and averages over every outcome; Monte Carlo samples without bootstrapping, and TD does both.
>
> **In the game:** A question floats in front of you: left click for only the map, right click for each leg's mud odds and speeds, melee for nothing more. Then walk the fifth and last route with WASD.
>
> **Before you press:** Lecture 3's planner filled in values without walking at all; decide what it would need to be told to do that here.
>
> <details><summary>Back from the game: what you just saw</summary>It would need the rules: how likely mud is on each leg and how slow it makes you. Neither BLUE nor ORANGE was told those; both learned from walks alone, which is model-free prediction. At the point, the coach line gives how far each spawn guess moved in total over the five walks. BLUE's total is usually the larger one.</details>

**On the island:** PLANNER bootstraps without sampling, the Monte Carlo table samples without bootstrapping, the TD tables do both. PLANNER's good news "travels back one column per sweep"; TD's news travels the same way, but only along steps she really walks.

### [1:15:56](https://www.youtube.com/watch?v=PnHCvfgC_ZA&t=4556s) Between one step and the whole episode: n-step returns and the lambda return
TD takes one real step, then guesses. Monte Carlo takes every real step and never guesses. You can also take two real steps and then guess, or any number n, which gives the n-step return. `G_t^(n) = R_(t+1) + ... + gamma^(n-1) R_(t+n) + gamma^n V(S_(t+n))`. In words: n steps of real reward plus your guess for the rest. With n = 1 it is TD(0), and with n running to the end it is Monte Carlo.

On a longer random walk, of about 21 states, the best n was around 3 to 5, but it shifted with the size of the walk and the timing of the updates.

So Silver averages over all n at once, with weights that shrink by the same factor each time (geometric weights). This average is the lambda return, and lambda, the shrink factor, is a number between 0 and 1. `G_t^lambda = (1 - lambda) sum over n of lambda^(n-1) G_t^(n)`. In words: the one-step return gets weight 1 minus lambda, each longer one lambda times less, and the leftover weight goes to the full return.

Geometric weights are memoryless (nothing separate is stored for each n), so the method costs no more than TD(0). Updating toward this target is called the forward view, and it needs complete episodes. The best lambda moves far less with walk size than the best n.

> **Alt+Tab · game 4 · stop 8 of 8: Read what the walks showed**
>
> **What he just said:** Between one-step TD and Monte Carlo sit n-step returns, a few real steps and then a guess, and lambda blends them all, so the two guesses you watched are the two ends of one dial.
>
> **In the game:** Nothing to press. Read the three lines on the left and your prediction score; then the game ends.
>
> **Before you press:** Before you read, say in one sentence which guess you would trust after five walks, and which after five hundred.
>
> <details><summary>Back from the game: what you just saw</summary>BLUE, Monte Carlo, used real totals: no bias, more noise, and nothing from the cut walk. ORANGE, TD, used one leg plus its own guess: steadier, bent by its guesses, and it learned before the end. Five walks with a fixed half step are far too few for either to settle, so read the numbers as a demonstration, not a result. <em>In an agent:</em> Judging each turn of an agent by the final score is Monte Carlo; judging it by how a value model's estimate moved across that turn is TD.</details>

**On the island:** No prediction table used n-step returns or lambda. SARSA LAMBDA, a control bot, uses lambda 0.8.

### [1:30:42](https://www.youtube.com/watch?v=PnHCvfgC_ZA&t=5442s) What to blame: eligibility traces, the backward view
When something goes wrong, you have to decide what to blame. Silver's rat hears a bell three times, then a light comes on, then it is shocked. You could blame the bell, because it happened most often, or the light, because it happened most recently.

Silver keeps both rules with a running score for each state, called an eligibility trace. `E_t(s) = gamma lambda E_(t-1)(s) + 1(S_t = s)`. In words: a state's trace jumps by one on each visit and fades on every step.

Each surprise is then shared out by those scores. `V(s) <- V(s) + alpha delta_t E_t(s)`. In words: each one-step TD error (the gap between a guess and its target) is sent back to every state in proportion to its trace. This is called the backward view: it looks only at where you have been, so it can update at every step.

With lambda 0 it is TD(0), the one-step method. With lambda 1 and the updates applied at the end of the episode (offline), the total equals Monte Carlo's, and offline the backward view matches the previous part's forward view for any lambda. Applied as you go (online), the two views differ slightly, unless a 2014 method is used.

**On the island:** SARSA LAMBDA keeps replacing traces (reset to one on a revisit). Against plain SARSA she fell 4.51 fewer times per 100 episodes (95% interval -6.21 to -2.78), an exploratory comparison.

## What the island measured for this lecture

| Typical error against exact values (weighted by visits) | TD(0), step 0.1 | TD(0), step 0.5 | Every-visit Monte Carlo |
|---|---|---|---|
| After 10 episodes | 112.7 | 100.5 | 25.9 |
| After 200 episodes | 85.6 | 46.5 | 15.3 |

All three tables followed the same walker from a start of zero. Monte Carlo was closest at both checkpoints, and the faster TD table beat the slower. the island fact sheet gives no intervals, and this comparison was not planned (the only planned comparison was SARSA against Q-learning on falls), so it is a first look. The likely reason is the start. In Silver's walk the guess of 0.5 is at most a third from the truth; here zero is about 100 points too high for most squares, and TD is the method he calls sensitive to starting values. With discount 1, each square must learn its value from neighbours that also start at zero: the -100 of a fall enters only beside the edge, and each inland square takes only part of a partly learned neighbour per visit, so the bad news crawls inward square by square, as PLANNER's good news moved one column per sweep. A plain Monte Carlo average (the island fact sheet does not give its step) swaps the zero for a real return of about -100 on the first visit. Step 0.5 beating 0.1 fits: the error was mostly starting bias, not noise. This does not show Monte Carlo is better in general, or how they compare once the start is forgotten (the lecture says TD usually wins). The exact values ignore the 100-step limit, so even a perfect table would not score zero.

## Guess first

<details><summary>AB example, replayed forever: does Monte Carlo give V(A) = 0 or 0.75? And TD(0)?</summary>
Monte Carlo gives 0: the one return seen from A was 0. TD(0) gives 0.75: A always went to B with reward 0, and B is worth 0.75. TD answers for the best-fitting model, Monte Carlo for the returns.
</details>

<details><summary>RANDOM WALK's first episode: she steps straight off the edge from the start for -101. What does each table now hold for the start square?</summary>
TD step 0.5: -50.5 (half way from 0 to -101). TD step 0.1: -10.1. A plain Monte Carlo average: -101, its only sample. That is the island result in small: from zero, Monte Carlo jumps to the scale of the truth and TD creeps.
</details>

<details><summary>Lecture 3's PLANNER and the TD(0) table both bootstrap. Which needs her to walk, and what does that mean for the far inland corner?</summary>
TD does. PLANNER averages over all four moves with the known rules, so every square updates every sweep. TD updates only squares she stands on, so a rarely reached corner learns slowly. Bootstrapping is shared; sampling is the difference.
</details>

<details><summary>From lecture 2: is R + gamma times the TRUE next value an unbiased target, and is R + gamma V(next)?</summary>
The first is unbiased: the Bellman expectation equation says the value equals expected reward plus discounted true next value. The second is biased, because V is the current estimate, which could be all zeros.
</details>

<details><summary>True or false: TD(lambda) with lambda 1 is exactly Monte Carlo.</summary>
True only with offline updates, applied at episode end: then the total matches every-visit Monte Carlo. Online, values change mid-episode and the two differ slightly, unless a 2014 variant of the trace is used.
</details>

<details><summary>A bot told only her row cannot tell forward from back. Predicting values with that blurred state, would TD(0) or Monte Carlo cope better?</summary>
Silver says Monte Carlo: it still finds the expected return given what it is told, while TD(0) leans on a Markov property the blurred state breaks. Not run for prediction; Q, ROW ONLY was a control bot, dithering at 47.1 steps per episode.
</details>

## Cards

- Q: What is prediction? | A: Estimating each state's value for a fixed, given policy, without improving it.
- Q: Monte Carlo's target? | A: The actual return from that moment to the end of the episode.
- Q: TD(0)'s target? | A: The reward just received plus the current estimate of the next state's value.
- Q: What is bootstrapping? | A: Updating an estimate toward a target that contains another estimate.
- Q: Which is biased, which is noisy? | A: TD's target is biased, low variance; Monte Carlo's return is unbiased, high variance.
- Q: Batch TD(0) converges to? | A: The values of the most likely model fitted to the data (certainty equivalence).
- Q: Lambda 0 and lambda 1 give? | A: TD(0), and (offline) every-visit Monte Carlo.
- Q: What does an eligibility trace combine? | A: Frequency and recency: it rises on each visit and fades by gamma times lambda per step.

## In language-model terms

A model on a tau-bench task reads the conversation, calls tools against a store's database and talks to a simulated customer; at the end the benchmark checks the database. That is an episode with one reward at the end, like Silver's random walk. Scoring every turn by the final pass or fail is Monte Carlo prediction: unbiased and noisy, since a good tool call in a conversation that failed for another reason gets the failure's score.

The TD version needs a value model that reads a half-finished transcript and predicts the chance of passing; each turn is judged by how that prediction moved across it. The form is exact, and so is the weakness: a badly wrong starting predictor feeds on itself, as the zero tables did. Many policy-gradient setups for language models use a lambda-weighted advantage (not from the lecture), the lambda return under another name.

Where it breaks: Silver's guarantees are for a table and a fixed policy. A conversation is a history, so the value model approximates, where he warns TD may not converge, and the policy is usually training too.

## The thread to partial observability

At [1:04:24] Silver says TD exploits the Markov property, and that when states are aliased (different situations look the same), Monte Carlo can be the better choice. At [1:05:00] he describes the partially observed MDP: a real MDP underneath, of which the agent sees only part, some cards and not others. Monte Carlo still finds the expected return given what it sees, even for "a blind robot"; TD(0) does not work well. So lambda is also a dial for how far to trust the state. The hidden-wall build (planned and running, no results yet) is this case: a blind runner sees one square where there are two situations. Carry forward: bootstrapping assumes the state is complete, and a memory of the episode can turn a blurred observation back into something closer to a state.

## Experiments the lecture asks for that the island has not run

- Start the TD tables at -100: how much of Monte Carlo's lead was the start.
- A shrinking step (1 over visits) for all three: whether TD catches up once the start is forgotten.
- Batch-replay the logged episodes to Monte Carlo and TD(0), against a model built by counting transitions: the AB example at full size.
- n-step and TD(lambda) prediction tables on the same walk: the lecture's large random walk figure.
- Prediction with the row-only view: whether Monte Carlo beats TD(0) on a blurred state ([1:04:24]).
