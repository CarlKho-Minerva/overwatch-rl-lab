# Lecture 4: Model-Free Prediction

*David Silver's lecture 4 (UCL, 2015), gone through in his order and re-explained with the Tracer experiments on Workshop Island. The lecture and its slides are his: [video](https://www.youtube.com/watch?v=PnHCvfgC_ZA), [course page](https://davidstarsilver.wordpress.com/teaching/). The words below are a re-explanation. Every island number comes from the logged runs in this repository.*

You died on the point and are walking back from spawn. By the first corner you are already guessing how long until you are back in the fight. Do you fix that guess at every corner, or just walk and find out when you arrive?

That choice is this whole lecture.

On the island, three tables of 48 numbers face it. They follow the RANDOM WALK bot, who wanders the strip at random and nearly always falls, and from her steps alone, without the island's rules, each must work out how good each square is for a walker like her.

Either wait for her walk to end and average what happened (Monte Carlo), or correct each guess after every step using the next guess (temporal-difference learning). Both reach the true values, one paying in noise and the other in bias from its own guesses. A single dial, lambda, runs between them.

**Two windows:** this page, and [Game 4: Back From Spawn](../workshop/games/g04.md), an Overwatch custom game for this lecture (paste `workshop/compiled/game-04.txt` into a custom game's settings and start it). The game opens at stop 1 and waits. Read down this page; at each box marked Alt+Tab, switch to the game, do that stop, and switch back. The game never moves on while you read.

## The lecture in order

### [04:29](https://www.youtube.com/watch?v=PnHCvfgC_ZA&t=269s) Nobody hands you the rulebook, so first you just measure
The first time you play a new map, nobody hands you a chart of every sightline. You walk it, die in a few odd places, and slowly learn which spots are good to stand on.

Lecture 3's planner never had to. It was handed the rulebook, which lecture 2 called the Markov decision process, or MDP: the map of states, moves, rewards and odds. Lecture 3 solved a known one.

Silver opens this hour with a factory whose equations nobody can write down. Now what?

You learn from experience alone. That is model-free learning (the model is just the rulebook; the name sounds grander than the idea).

As in lecture 3, he splits the work in two, and this hour does only the first half. You are handed a rule for choosing moves, a policy, and you estimate the total reward to expect from each state if you follow it. That expected total, one number per state, is the value function. Estimating it is called prediction. Finding the best policy is control, which waits for lecture 5.

Nobody gets better today. We only keep score.

**On the island:** The policy, her rule for choosing a move, is fixed: RANDOM WALK picks each of four moves with equal chance. Prediction fills in, for each square, the total score she will collect from there. PLANNER did this in lecture 3 by reading the rules; the tables only get to watch.

### [05:17](https://www.youtube.com/watch?v=PnHCvfgC_ZA&t=317s) Monte Carlo: play it a lot, then average
How good is it to start a fight from high ground? You could argue about it in voice chat all night. Or you could take that fight many times and average how it went.

That is Silver's first method, Monte Carlo learning, and it is about as plain as learning gets. He admits it is not necessarily the most efficient method, but it is very widely used in practice.

It works on whole episodes, an episode being one run from the start until the game ends. From any moment in an episode, add up all the reward that came between then and the end. That total is called the return. If one episode returns 5 and the next returns 7, the start is worth 6 so far.

Notice what is missing: the rulebook. You only need the returns you actually saw.

The one catch is that episodes have to end, because there is no total until they do. (Give Monte Carlo a match that never ends and it will wait in the lobby forever.)

<details markdown="1"><summary>The formula, when you want it</summary>

`v(s) = E[G_t | S_t = s]`. In words: a state's value is the average return after standing in it, and Monte Carlo uses the average of the samples it has in place of that true average.

</details>

**On the island:** Episodes always end. Over 2,308 random-walk episodes the mean return was -112.7 (standard error 0.46); the exact start value, which ignores the time limit, is -114.4.

### [09:00](https://www.youtube.com/watch?v=PnHCvfgC_ZA&t=540s) First visit or every visit, and why rare spots stay blurry
Say you stand on the same high ground twice in one round: once early, once in the final push. Do both visits count toward what that spot is worth, or only the first?

Silver names both answers. Count only the return (the total reward to the end) after the first time an episode reaches a state, and you have first-visit Monte Carlo. Count a return for every visit, and you have every-visit Monte Carlo.

Both settle on the true value, by the law of large numbers: average enough independent samples and you approach the true average.

A student asks whether a huge world needs vastly more episodes. Silver says no. A state's error shrinks with the visits to that state. How many states the world has, the size of the state space, does not come into it.

His example is blackjack with 200 states, played by a naive rule: stick, meaning take no more cards, only on 20 or 21. After 10,000 hands the states with a usable ace, one that can count as 1 or 11, are still noisy, because they rarely come up. They take about 500,000 hands to settle. Nobody told the learner the deck or the dealer's rule.

The spots you rarely stand on are the spots you know least about.

**On the island:** The table is every-visit, and revisits are common because walking into a side wall leaves her in place. Far inland squares are rarely reached before she falls; the error score weights squares by visits, so they count less. First-visit was not run.

### [26:21](https://www.youtube.com/watch?v=PnHCvfgC_ZA&t=1581s) A running average, and forgetting on purpose
You do not keep a spreadsheet of every game to know how you are playing. You carry one impression, and each game nudges it. The further a game lands from what you expected, the harder it shoves.

That is the incremental mean. Keep one number, and when a new score arrives, move the number toward it by a fraction of the surprise. The surprise is the gap between what you predicted and what you saw.

Silver says nearly every algorithm in the lecture has this shape: a prediction, corrected a little in the direction of its error.

Then he changes one thing. In a true average the fraction is 1/k, which shrinks as samples pile up, so each new sample moves the average less. Put a constant step, written alpha, in its place and old episodes fade.

He prefers the version that forgets. Once the policy starts to improve, the thing being measured keeps changing, and returns from long ago only slow the estimate down. (Same reason your read on a hero should count for less after a patch. Here it is your own policy that changed, not the game, but old data goes stale either way.)

Forgetting, here, is the feature.

<details markdown="1"><summary>The formulas, when you want them</summary>

`mu_k = mu_(k-1) + (1/k)(x_k - mu_(k-1))`. In words: the new average is the old one moved toward the new sample by a fraction of the surprise.

`V(S_t) <- V(S_t) + alpha (G_t - V(S_t))`. In words: move the value a fixed fraction of the way toward the latest return, the real total from that visit to the end.

</details>

**On the island:** The MONTE CARLO control bot uses a constant step of 0.2. The Monte Carlo value table that follows RANDOM WALK uses the plain running average: a step of 1/k on the k-th visit to a square, every visit counted.

### [34:11](https://www.youtube.com/watch?v=PnHCvfgC_ZA&t=2051s) Temporal difference: fix a guess with a guess
You are walking back from spawn, sure you will make the fight. Then you round the last corner and the enemy is already on the point. You do not need to finish the walk to know your guess was off. You fix it right there.

That is temporal-difference learning, or TD. One step in, you know a little more, so you correct the old guess with the new one. It even works on episodes that are not over yet.

The simplest version, TD(0), takes one real step and its reward, then lets its own current guess for where it landed stand in for everything after. Using one of your own estimates as part of what you learn toward is called bootstrapping. (As in pulling yourself up by your own bootstraps, which sounds impossible and mostly works.)

What it nudges toward is called the TD target, and the gap between target and old value is the TD error.

Silver's case is a near crash. A car comes hurtling at you and swerves away at the last second. Monte Carlo, waiting for the real total, sees no crash and never learns how close it came. TD lowers the value of the moment before at once.

"You don't need to wait until you die to update your value function."

<details markdown="1"><summary>The formula, when you want it</summary>

`V(S_t) <- V(S_t) + alpha (R_(t+1) + gamma V(S_(t+1)) - V(S_t))`. In words: nudge the value of where you were toward the reward you just got plus your current guess for where you are now. That target, R + gamma V(next), is the TD target, where gamma is the discount that makes later reward count for less.

</details>

> **Alt+Tab · game 4 · stop 1 of 8: Walk the mud leg to ring 1**
>
> **What he just said:** TD does not wait for the end. After every single step it fixes its guess, aiming at the reward it just got plus its own guess for where it landed. You do not have to reach the point to learn you were slow.
>
> **In the game:** The game waits at the spawn ring. Walk with WASD to ring 1; leg 1 of the first walk is always mud, so you move at 30% speed. At ring 1 a question floats in front of you: left click for BLUE, right click for ORANGE, melee for both.
>
> **Before you press:** Before you click, decide which of the two guesses for the spawn ring could have changed already, when you have walked only one leg of five.
>
> <details><summary>Back from the game: what you just saw</summary>ORANGE's spawn guess already moved, from 15 seconds toward the leg's time plus ORANGE's own guess for ring 1. BLUE is still sitting on 15. Its target is the time from spawn all the way to the point, and you are nowhere near the point yet. One leg in, the split is already there: temporal-difference learning, TD, updates at each step; Monte Carlo waits for the end. <em>In an agent:</em> A value model that scores a half-finished conversation can update after every turn. A grader that reads only the final pass or fail has to wait for the last line.</details>

**On the island:** Two TD(0) tables, steps 0.1 and 0.5, discount (gamma) 1. From square A to B, the target is -1 plus the table's number for B; off the edge, it is -101.

### [39:50](https://www.youtube.com/watch?v=PnHCvfgC_ZA&t=2390s) Driving home, and the forecast that keeps changing its mind
Silver borrows this one from Sutton and Barto. You leave for home expecting the trip to take 30 minutes. It starts raining, so you think 40. The highway is clear: 35. You get stuck behind a truck: 40 again. You arrive after 43.

Monte Carlo, the method that needs the real total, says nothing the whole drive. Once you are home, it pulls every forecast made along the way toward 43.

TD, the method that corrects each guess with the next one, does not wait. At the rain it moves the 30 toward 40. After the highway it moves the 40 toward 35. Silver calls this "updating guess towards a guess", and it goes on until the arrival grounds the last guess in a real outcome.

Same drive, same forecasts. One method grades them at the door, the other at every turn.

A student asks what the actions are. There are none. With the policy fixed, the formal map of the world (the MDP) has no choices left in it. What remains is called a Markov reward process: states and rewards following one another with no decisions in between.

> **Alt+Tab · game 4 · stop 2 of 8: Finish the walk and watch BLUE**
>
> **What he just said:** Driving home, Monte Carlo says nothing the whole trip. Once you arrive, it pulls every forecast you made on the way toward the real arrival time.
>
> **In the game:** Leave ring 1 when you are ready and walk to rings 2, 3 and 4 and the point with WASD. Each leg's line turns green for clear or red for mud as you start it. The clock runs only between rings, so you can stand in a ring and read.
>
> **Before you press:** Before you leave ring 1, guess which of the ten numbers on the right will change at each ring, and which will all change together at the point.
>
> <details><summary>Back from the game: what you just saw</summary>At each ring one ORANGE number moved: the guess for the ring you had just left. Then, at the point, all five BLUE numbers moved at once, each halfway to the time the rest of that walk really took from its ring. BLUE is Monte Carlo. It learns from real totals, so it had to wait for them. And nobody told either guess how likely mud was.</details>

> **Alt+Tab · game 4 · stop 3 of 8: Say which guess leans on a guess**
>
> **What he just said:** TD moves the forecast made at one landmark toward the forecast made at the next. A guess updated toward a guess, all the way until the arrival grounds the last one in something real.
>
> **In the game:** A question floats in front of you. Left click for BLUE, right click for ORANGE.
>
> **Before you press:** Lecture 2's Bellman rule says the time from here is this leg plus the time from the next ring; decide which of the two guesses builds its target that way.
>
> <details><summary>Back from the game: what you just saw</summary>ORANGE. Its target is the real time of the leg plus its own current guess for the next ring. Using one of your guesses inside the target of another is called bootstrapping. Lecture 2's rule uses the true time from the next ring, averaged over every way the leg can go. ORANGE has no such thing, so it plugs in one walked leg and a guess. <em>In an agent:</em> Training a value model toward its own next-turn predictions is the same move. It can also copy its own errors forward the same way, one turn at a time.</details>

**On the island:** A random episode lasts 14.9 steps on average. The TD tables change after each step; the Monte Carlo table waits for the end.

### [47:31](https://www.youtube.com/watch?v=PnHCvfgC_ZA&t=2851s) Leaning or jumping: bias, variance, and the trouble with starting values
Two teammates give you callouts. One is right on average but all over the place. The other is steady and always a bit too far left.

A guess can miss in the same two ways: it jumps around, or it leans. (Silver first notes a practical edge: TD also learns from cut-short sequences and tasks that never end.)

The return, the real total to the end, is right on average: unbiased. So is one real reward plus the discounted true value of the next state, by lecture 2's Bellman equation. But TD only has its own estimate V of that state, so its target leans. Biased.

It buys a far lower spread, called variance. A return carries the luck of every step to the end, the TD target the luck of one. When a student calls TD's estimate noisy, Silver corrects the word: "It's not noisy, it's biased."

1. **Monte Carlo:** zero bias, high variance. Converges even with function approximation, a formula standing in for a table with too many states to list. Barely bothered by starting values.
2. **TD:** some bias, low variance, usually more efficient. Converges in a table, a proof Silver credits to Peter Dayan, but not always with function approximation. More sensitive to starting values, because it feeds off itself.

Remember that last line. The island needs it.

> **Alt+Tab · game 4 · stop 4 of 8: Walk again and compare the jumps**
>
> **What he just said:** Monte Carlo's target is right on average but noisy, because it carries the luck of a whole episode. TD's target leans on its own estimate, so it is biased, but it carries the luck of only one step.
>
> **In the game:** Walk the second route from the spawn ring to the point with WASD. The mud is drawn again for every walk, so this one will not match the first.
>
> **Before you press:** Before you leave spawn, decide whose spawn guess will jump further on this walk, BLUE's or ORANGE's.
>
> <details><summary>Back from the game: what you just saw</summary>Check how far each spawn number moved on this walk. BLUE's went halfway to this walk's total, mud and all, so one muddy walk drags it a long way. ORANGE's moved toward leg 1 plus its guess for ring 1, and that guess holds news from earlier walks, carried one ring further back each time. Less noise, but only as right as its own guesses. That lean is bias.</details>

> **Alt+Tab · game 4 · stop 5 of 8: Bet on which guess swings more**
>
> **What he just said:** Each target carries a different amount of luck. So the Monte Carlo estimate swings more from episode to episode, and the TD estimate stays steadier but leans on wherever it started.
>
> **In the game:** A question floats in front of you: left click for BLUE, right click for ORANGE, melee for about the same. Then walk the third route with WASD.
>
> **Before you press:** Commit to whose spawn guess will have moved more in total by the end of the fifth walk.
>
> <details><summary>Back from the game: what you just saw</summary>The total itself comes at stop 7. For now, compare this walk's mud with the walk before. When the amount of mud changes a lot, BLUE's spawn number chases it and ORANGE's barely twitches. The spread a guess picks up from luck is called variance, and here Monte Carlo has more of it.</details>

> **Alt+Tab · game 4 · stop 6 of 8: Get cut off at ring 2**
>
> **What he just said:** TD can learn from a sequence that never finishes, because each update needs only the next step. Monte Carlo needs a complete return from start to end, or it has nothing to learn from.
>
> **In the game:** A question floats in front of you: left click for BLUE, right click for ORANGE, melee for neither. Then walk the fourth route with WASD; at ring 2 the round ends and the walk stops there.
>
> **Before you press:** Commit to which guesses will learn anything from a walk that never reaches the point.
>
> <details><summary>Back from the game: what you just saw</summary>ORANGE changed its guesses for spawn and ring 1, one for each leg you walked. BLUE changed nothing. No arrival, no total, nothing to move toward. The fight ended before you got there, and only the guess that updates at every corner got anything out of the walk. <em>In an agent:</em> An agent run that times out halfway still trains a TD-style value model. A pass-or-fail grader gets nothing from it at all.</details>

**On the island:** A random return can be -101 (off at once), about -110 (wander, then fall), -150 (time out), or in 1.0% of episodes a goal: Monte Carlo's variance. The TD tables start at zero; most true values are below -100.

### [53:35](https://www.youtube.com/watch?v=PnHCvfgC_ZA&t=3215s) The random walk: in Silver's example TD wins, and on the island it does not
To race the two methods, Silver picks about the simplest world you could build: five states in a row. From each you step left or right at random, like a Tracer whose controller has a mind of its own. Leaving on the right pays a reward of 1, leaving on the left pays nothing, and the true values run from 1/6 at the left end to 5/6 at the right.

He starts TD(0), the one-step method, with every value at 0.5. After about 100 episodes its estimates look right.

Then he plots the error against the number of episodes for both methods. The error is one number for the typical size of the miss across the states, called the root mean squared error. With a good step size, TD beats Monte Carlo, the method that averages real totals.

One catch: with a constant step the estimate never lands exactly. It keeps bouncing near the answer. Exact convergence needs a step that shrinks over time, and the rules for how it must shrink are called the Robbins-Monro conditions.

That is the result you would bet on. Now look at the island.

**On the island:** This is the experiment, and it came out the other way. After 10 episodes the error was 112.7 for TD with step 0.1, 100.5 for TD with step 0.5, and 25.9 for Monte Carlo; after 200 episodes it was 85.6, 46.5 and 15.3. The section after the lecture, on what the island measured, says why.

### [58:05](https://www.youtube.com/watch?v=PnHCvfgC_ZA&t=3485s) Eight replays, studied forever (the AB example): two right answers
Imagine the servers go down for good and all you have left is eight replays, to watch forever.

Silver asks whether the two methods, fed the same eight episodes over and over, end with the same numbers. Learning from a fixed pile like this is called batch learning.

His episodes use two states, A and B. In one, you start in A, get a reward of 0, move to B and get 0 again. In six, you start in B and get 1. In the last, you start in B and get 0. So the value of B, written V(B), is 0.75: six rewards of 1 in eight visits.

And A? The room splits about half and half.

Monte Carlo, which averages the returns it saw, says V(A) is 0, because the one return seen from A was 0. TD(0) says V(A) is 0.75. It acts as if it built the most likely model of what it saw (A always leads to B, with reward 0) and solved that, which is called certainty equivalence. Silver calls both answers legitimate.

What separates them is the Markov property: the idea that the current state carries all that matters for the future. TD exploits it and is usually more efficient where it holds. Monte Carlo ignores it and is often better where it fails.

**On the island:** The game is nearly Markov, with 0.21 slips per 1,000 steps. Batch replay was not run.

### [1:09:11](https://www.youtube.com/watch?v=PnHCvfgC_ZA&t=4151s) Two dials: trust a guess or not, try one outcome or all of them
Picture deciding whether a fight was winnable. Do you play it to the end, or stop partway and trust your read of the rest? And do you go by the fight that happened, or think through every way it could have gone?

Every method so far makes both choices each time it updates a value.

Stopping early and filling in the rest with your own estimate is bootstrapping, the word from the TD part. TD does it after one real step, and so does dynamic programming, lecture 3's way of planning from the rules. Monte Carlo does not: it uses real returns all the way.

Going by the one outcome that came, instead of an average over all that could come, is called sampling. Monte Carlo and TD sample. Dynamic programming knows the odds and averages over every outcome, so it does not. Exhaustive search, which follows every branch to the end, does neither.

A student asks why the later guess should correct the earlier one and not the reverse. Silver says the reverse gives wrong answers. Between the two guesses lies one step of the real world, a real reward and a real move, so the later guess knows more.

> **Alt+Tab · game 4 · stop 7 of 8: Ask what a planner would need**
>
> **What he just said:** Lecture 3's planner, dynamic programming, bootstraps without sampling: it is handed the rules and averages over every outcome. Monte Carlo samples without bootstrapping. TD does both.
>
> **In the game:** A question floats in front of you: left click for only the map, right click for each leg's mud odds and speeds, melee for nothing more. Then walk the fifth and last route with WASD.
>
> **Before you press:** Lecture 3's planner filled in values without walking at all; decide what it would need to be told to do that here.
>
> <details><summary>Back from the game: what you just saw</summary>It would need the rules: how likely mud is on each leg, and how slow it makes you. Neither BLUE nor ORANGE was told any of that. Both learned from walks alone, which is model-free prediction. At the point, the coach line gives how far each spawn guess moved in total over the five walks. BLUE's total is usually the larger one.</details>

**On the island:** PLANNER bootstraps without sampling, the Monte Carlo table samples without bootstrapping, the TD tables do both. PLANNER's good news "travels back one column per sweep"; TD's news travels the same way, but only along steps she really walks.

### [1:15:56](https://www.youtube.com/watch?v=PnHCvfgC_ZA&t=4556s) Why pick one: n-step returns and the lambda return
Back to the walk from spawn. TD looks one corner ahead and guesses the rest. Monte Carlo walks all the way in and never guesses. Nothing stops you from walking two corners and then guessing. Or five.

That is the n-step return: n steps of real reward, then your guess for the rest. With n = 1 it is TD(0), and with n running to the end it is Monte Carlo.

So which n? On a longer random walk, of about 21 states, the best n was around 3 to 5, but it shifted with the size of the walk and the timing of the updates. The right setting kept moving under you.

Silver's way out is to refuse to choose. He averages over all n at once, with weights that shrink by the same factor each time (geometric weights). That average is the lambda return, and lambda, the shrink factor, is a number between 0 and 1.

Geometric weights are memoryless, so nothing separate is stored for each n, and the method costs no more than TD(0). Updating toward this target is called the forward view, and it needs complete episodes.

The payoff: the best lambda moves far less with walk size than the best n.

<details markdown="1"><summary>The formulas, when you want them</summary>

`G_t^(n) = R_(t+1) + ... + gamma^(n-1) R_(t+n) + gamma^n V(S_(t+n))`. In words: n steps of real reward plus your guess for the rest.

`G_t^lambda = (1 - lambda) sum over n of lambda^(n-1) G_t^(n)`. In words: the one-step return gets weight 1 minus lambda, each longer one lambda times less, and the leftover weight goes to the full return.

</details>

> **Alt+Tab · game 4 · stop 8 of 8: Read what the walks showed**
>
> **What he just said:** Between one-step TD and Monte Carlo sit n-step returns: a few real steps, then a guess. Lambda blends them all. The two guesses you just watched are the two ends of one dial.
>
> **In the game:** Nothing to press. Read the three lines on the left and your prediction score; then the game ends.
>
> **Before you press:** Before you read, say in one sentence which guess you would trust after five walks, and which after five hundred.
>
> <details><summary>Back from the game: what you just saw</summary>BLUE, Monte Carlo, used real totals: no bias, more noise, and nothing from the cut walk. ORANGE, TD, used one leg plus its own guess: steadier, bent by its guesses, and learning before the end. One honest warning: five walks with a fixed half step are far too few for either to settle. Treat the numbers as a demonstration, not a result. <em>In an agent:</em> Judge each turn of an agent by the final score and you are doing Monte Carlo. Judge it by how a value model's estimate moved across that turn and you are doing TD.</details>

**On the island:** No prediction table used n-step returns or lambda. SARSA LAMBDA, a control bot, uses lambda 0.8.

### [1:30:42](https://www.youtube.com/watch?v=PnHCvfgC_ZA&t=5442s) Who gets the blame: eligibility traces, the backward view
You lose a teamfight. Was it the flank you kept taking all round, or the one bad peek right before it fell apart? Both have a case.

Silver's version has a rat. It hears a bell three times, then a light comes on, then it is shocked. You could blame the bell, because it happened most often, or the light, because it happened most recently.

Silver keeps both rules. Each state gets a running score that jumps by one on every visit and fades on every step. That score is called an eligibility trace.

Then each surprise is shared out by those scores. Every one-step TD error, the gap between a guess and its target, goes back to every state in proportion to its trace. This is called the backward view: it looks only at where you have been, so it can update at every step.

With lambda 0 it is TD(0), the one-step method. With lambda 1 and the updates applied at the end of the episode (offline), the total equals Monte Carlo's, and offline the backward view matches the previous part's forward view for any lambda. Applied as you go (online), the two views differ slightly, unless a 2014 method is used.

Often and recent both get their share of the blame.

<details markdown="1"><summary>The formulas, when you want them</summary>

`E_t(s) = gamma lambda E_(t-1)(s) + 1(S_t = s)`. In words: a state's trace jumps by one on each visit and fades on every step.

`V(s) <- V(s) + alpha delta_t E_t(s)`. In words: each one-step TD error is sent back to every state in proportion to its trace.

</details>

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

Picture a model on a tau-bench task. It reads the conversation, calls tools against a store's database and talks to a simulated customer. At the end the benchmark checks the database: pass or fail. One episode, one reward at the very end, the same shape as Silver's random walk.

So which turns were good? The Monte Carlo answer scores every turn by the final pass or fail. Unbiased, and noisy: a good tool call in a conversation that failed for another reason gets the failure's score, the way a loss drops your rank even in a game you played well.

The TD answer needs a value model that reads a half-finished transcript and predicts the chance of passing. Each turn is judged by how that prediction moved across it. The form is exact, and so is the weakness: a badly wrong starting predictor feeds on itself, as the zero tables did. Many policy-gradient setups for language models use a lambda-weighted advantage (not from the lecture), the lambda return under another name.

Where it breaks: Silver's guarantees are for a table and a fixed policy. A conversation is a history, so the value model approximates, right where he warns TD may not converge. And the policy is usually training too.

## The thread to partial observability

At [1:04:24] Silver says TD exploits the Markov property, and that when states are aliased (different situations look the same), Monte Carlo can be the better choice. At [1:05:00] he describes the partially observed MDP: a real MDP underneath, of which the agent sees only part, some cards and not others. Monte Carlo still finds the expected return given what it sees, even for "a blind robot"; TD(0) does not work well. So lambda is also a dial for how far to trust the state. The hidden-wall build (planned and running, no results yet) is this case: a blind runner sees one square where there are two situations. Carry forward: bootstrapping assumes the state is complete, and a memory of the episode can turn a blurred observation back into something closer to a state.

## Experiments the lecture asks for that the island has not run

- Start the TD tables at -100: how much of Monte Carlo's lead was the start.
- A shrinking step (1 over visits) for all three: whether TD catches up once the start is forgotten.
- Batch-replay the logged episodes to Monte Carlo and TD(0), against a model built by counting transitions: the AB example at full size.
- n-step and TD(lambda) prediction tables on the same walk: the lecture's large random walk figure.
- Prediction with the row-only view: whether Monte Carlo beats TD(0) on a blurred state ([1:04:24]).
