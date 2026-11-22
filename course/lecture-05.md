# Lecture 5: Model-Free Control

*David Silver's lecture 5 (UCL, 2015), gone through in his order and re-explained with the Tracer experiments on Workshop Island. The lecture and its slides are his: [video](https://www.youtube.com/watch?v=0g4j2k_Ggc4), [course page](https://davidstarsilver.wordpress.com/teaching/). The words below are a re-explanation. Every island number comes from the logged runs in this repository.*

You are Tracer on high ground beside a drop, and the short way across runs along the edge. Once an enemy Lucio arrives, on one step in ten he boops you one pad in a random direction. This hour asks how a learner who is never told the rules can still find the best way to act, when all she can do is try moves and see what they earn. It arrives at two learners that differ by one line of arithmetic: SARSA learns the value of the walker she really is, stumbles included, and Q-learning learns the value of a perfect walker while stumbling.

**Two windows:** this page, and [Game 5: Slippery Boots](../workshop/games/g05.md), an Overwatch custom game for this lecture (paste `workshop/compiled/game-05.txt` into a custom game's settings and start it). The game opens at stop 1 and waits. Read down this page; at each box marked Alt+Tab, switch to the game, do that stop, and switch back. The game never moves on while you read.

## The lecture in order

### [04:09](https://www.youtube.com/watch?v=0g4j2k_Ggc4&t=249s) Two ways to learn: on the job, or over someone's shoulder
Last lecture's learners only kept score. Each was handed a fixed way of behaving and worked out how much reward it earned, which Silver calls prediction. This hour the learner has to get better: dropped into a world it knows nothing about, it must find the behaviour that earns the most. He calls that problem control.

There are two ways to go about it, and he gives each a nickname. The first is "learning on the job". You follow a rule for choosing moves, called a policy, and what you learn about is that same rule. The name for this is on-policy learning.

The second is "looking over someone's shoulder". The experience comes from one policy and the learning is about another. His example is a robot that watches a human steer an arm and works out, from the human's attempts alone, whether some other way of moving would have done better. This is off-policy learning. The lecture starts with on-policy learning, the simpler of the two.

**On the island:** SARSA, SARSA LAMBDA and MONTE CARLO are on-policy: each learns about her own slightly random walking. Q-LEARNING is off-policy: she walks with random steps but learns about a version of herself that never takes one.

### [05:35](https://www.youtube.com/watch?v=0g4j2k_Ggc4&t=335s) The loop from lecture 3, and why it needs a score for every move
To get better at anything you do two things in turn: you find out how good your current habit is, and then you change the habit toward whatever scored best. Lecture 3 did exactly that with the rules written down. Silver calls the general pattern generalised policy iteration: score the current policy (the rule for choosing a move), improve it, repeat.

Without the rules, two things break. If you always take the move that looks best, you stop visiting the rest of the world, so you never learn what it was worth. And a score for each place is not enough to choose with: to pick a move from it you would need to know where each move lands, and that is the rulebook you do not have [09:53].

His fix for the second problem is to keep a score for each place and move together, written Q and called the action value. Then choosing needs no look-ahead: you read off the top score. `pi'(s) = argmax_a Q(s, a)`. In words: in each state, pick the move with the largest stored score.

> **Alt+Tab · game 5 · stop 1 of 6: Pick a lane with nobody pushing**
>
> **What he just said:** Without the rules of the world you cannot look ahead from a place, so you keep a score for each move from each place, and improving means taking the move with the highest score.
>
> **In the game:** The game asks which lane pays more when nothing pushes you: LEFT CLICK for EDGE, RIGHT CLICK for INLAND, MELEE for THE SAME. Then LEFT CLICK or RIGHT CLICK picks your lane, and you walk it with WASD from the white ring to the green ring.
>
> **Before you press:** Commit to which lane earns more when every step goes where you aim it.
>
> <details><summary>Back from the game: what you just saw</summary>The edge lane pays 39 and the inland lane 37: each pad costs 1, the goal pays 50, and the edge is two pads shorter. With no randomness, reading off the higher score picks the short way. That is greedy improvement on action values, the step Silver builds his whole loop on. <em>In an agent:</em> A plan scored as if every tool call does exactly what was intended looks best when it takes the fewest steps.</details>

**On the island:** PLANNER runs this loop with the rules written down. Every learner instead keeps a table of 48 squares by 4 moves. She never needs to know that "toward the edge" from row 0 is a fall, only that its score is very low.

### [13:27](https://www.youtube.com/watch?v=0g4j2k_Ggc4&t=807s) The two doors, and a little randomness on purpose (epsilon-greedy)
Picture two doors and no idea what is behind either. You open the left one and get 0. You open the right one and get +1, so you open it again and get +3. A chooser that always takes whatever has scored best so far, which Silver calls acting greedily, will now open the right door forever.

The trouble is that the left door was tried once. One try says little about what a door is really worth, and the greedy chooser never goes back to find out, so it never learns the left door's worth.

Silver's fix is the simplest one available, and he says it is surprisingly hard to beat. With a small probability, written epsilon, pick a move at random. The rest of the time, pick the best-scoring move. This is called epsilon-greedy. `pi(a|s) = epsilon/m + 1 - epsilon` for the greedy move, `epsilon/m` for the others. In words: with m moves, the best gets nearly all the probability and every other move keeps a small, never-zero share.

The next thing to work out is what that small share costs when one of the moves is a step off a ledge.

> **Alt+Tab · game 5 · stop 2 of 6: Lucio arrives: one step in ten**
>
> **What he just said:** Silver keeps a learner from locking onto its first good guess by making one move in ten a random one, which he calls epsilon-greedy.
>
> **In the game:** Lucio now stands inland. The game asks the chance that one step off an edge pad ends over the drop: LEFT CLICK, RIGHT CLICK or MELEE for the three answers. Then pick a lane and walk it.
>
> **Before you press:** Commit to how likely a single edge step is to send you over, before you take one.
>
> <details><summary>Back from the game: what you just saw</summary>One step in ten is replaced by a random one of four moves, and one of those four points at the drop, so each edge step falls 1 time in 40. Lucio is the lecture's random move, made for you. Watch the right side: count how many boops you took and where they sent you. <em>In an agent:</em> Sampling with some randomness makes a model try other actions now and then, including the ones that cannot be undone.</details>

**On the island:** epsilon is 0.1 with 4 moves, so in row 0 the edge move has a 0.025 chance every step. Over eleven edge-row steps that is about a 24% chance of a fall (arithmetic, not a measurement), near Q-LEARNING's measured 26.5 per 100 episodes; a rough match, since her route is not always the edge row.

### [17:41](https://www.youtube.com/watch?v=0g4j2k_Ggc4&t=1061s) With a little randomness, each round is still an improvement
Adding random moves sounds as if it should cost something. The worry is that the loop from two parts back, score the habit and then improve it, stops improving once the improved habit is partly random.

Silver spends his one slide of maths showing that it keeps improving. Start with a policy (the rule for choosing a move) that already takes the best-scoring move most of the time and a random one now and then, which is what epsilon-greedy means. Work out the score of every place and move under that policy, its action values Q. Then build a new epsilon-greedy policy from those scores. The new one is never worse than the old.

The reason is that the best move's score is at least as large as any weighted average of the moves' scores, and the old policy's value is one such average. That settles a single step. Carrying it through every later step uses the Bellman equation, lecture 2's rule that ties each value to the values one step later [18:43]. The result is `v_pi'(s) >= v_pi(s)`. In words: from every state, the new policy is worth at least as much as the old one, so softening greed with a little randomness still lets each round help.

A student asks whether the proof says how much to explore. It does not.

**On the island:** Not run on the island. The test: freeze each table every 10 episodes and check that her policy's exact value never drops.

### [25:37](https://www.youtube.com/watch?v=0g4j2k_Ggc4&t=1537s) Explore forever, become greedy in the end (GLIE)
A learner that makes random moves forever cannot be the best, because the best way to act has no random moves in it. One that stops too soon may never find out what it missed. Silver wants both: keep trying everything, and end up taking only the top-scoring move.

He writes this as two conditions. Every state and move must be tried infinitely often. And the policy (the rule for choosing a move) must tend toward the greedy one, which always takes the top score. A schedule that meets both is called greedy in the limit with infinite exploration, or GLIE. One that works: on episode k (the kth run), set epsilon, the share of random moves, to 1/k.

He joins that schedule to Monte Carlo scoring, lecture 4's method of averaging the returns (the total reward that followed), and updates after each episode. `Q(S,A) <- Q(S,A) + (1/N(S,A)) (G - Q(S,A))`. In words: each visited pair's score becomes the running average of the returns that followed it. This is GLIE Monte Carlo control. It converges to the true score of each state and move under the best play, the best action values.

Asked whether the starting scores matter [32:48], he corrects himself mid-answer: a 1/N average erases them on the first visit, but with a constant step size they matter. The algorithm also finds the best blackjack policy [35:20].

> **Alt+Tab · game 5 · stop 3 of 6: Count the falls along the edge**
>
> **What he just said:** Silver asks for exploring that never stops but fades, so every move keeps being tried while the learner turns greedy in the end.
>
> **In the game:** The game asks how often the whole edge lane ends in a fall with boops on: LEFT CLICK, RIGHT CLICK or MELEE. Then pick a lane and walk it again.
>
> **Before you press:** Commit to roughly how many crossings in 100 end over the drop if you always take the edge.
>
> <details><summary>Back from the game: what you just saw</summary>Eleven steps from edge pads at 1 in 40 each gives about 24 falls in 100; counting the walks back after other boops, the game's own arithmetic says about 26. Here the boops never fade, so that cost never shrinks. A schedule that lowers the random share over time, which Silver calls GLIE, is what would let it fall toward zero. <em>In an agent:</em> An agent that keeps a fixed amount of randomness pays the same price for it on every run, however much it has learned.</details>

**On the island:** no bot is strictly GLIE. Most keep epsilon at 0.1. MONTE CARLO uses a constant step of 0.2, and MONTE CARLO + OPTIMISM starts every Q at 40, which Silver's remark says should matter. It did not: late return differed by 0.27 (-0.51 to 1.14), inconclusive.

### [41:01](https://www.youtube.com/watch?v=0g4j2k_Ggc4&t=2461s) SARSA: learn from the very next step, and improve after every one
Waiting for a crossing to end before learning anything from it is slow. Lecture 4 had a quicker way to score: after a single step, move your guess toward the reward you just got plus your guess for where you landed. That is temporal-difference learning, TD for short.

Silver puts TD into the loop in place of Monte Carlo, which averages whole finished runs. Because TD updates after one step, the policy (the rule for choosing a move) can improve at every step too.

The method's name spells the update: the State she is in, the Action she takes, the Reward she gets, the next State, and the next Action she picks there. `Q(S,A) <- Q(S,A) + alpha (R + gamma Q(S',A') - Q(S,A))`. In words: nudge the score of what she just did toward the reward plus the score of the move she has actually chosen next (alpha is the step size, how big each nudge is; gamma is the discount, how much less a later reward counts).

The amount she nudges toward is one sample of the Bellman equation, lecture 2's rule that ties each value to the values one step later, for the policy she is following. So the scores describe that policy, and SARSA is on-policy at its root [48:03]. The question that follows is which route earns more once her own random moves are counted.

> **Alt+Tab · game 5 · stop 4 of 6: Which lane wins in the long run**
>
> **What he just said:** SARSA updates the score of what you just did toward the reward plus the score of the move you will really make next, random moves included.
>
> **In the game:** The game asks which lane earns more on average with boops on: LEFT CLICK for EDGE, RIGHT CLICK for INLAND. The answer and both averages appear, and then you pick a lane for the last crossing and walk it.
>
> **Before you press:** Commit to the lane that earns more over many crossings when Lucio is around.
>
> <details><summary>Back from the game: what you just saw</summary>The edge lane averages 0.41 and the inland lane 30.31: a 26 in 100 chance of losing 100 costs far more than two extra pads. These are the scores of the walker who really gets booped, which is what SARSA learns, so SARSA moves inland. Compare your own four returns on the right with those averages. <em>In an agent:</em> Score a strategy by the runs the agent actually produces, slips and all, and the cautious route often wins.</details>

**On the island:** SARSA uses alpha 0.5, epsilon 0.1. Her next move is sometimes random, so an edge square inherits the cost of her own stumbles there, and she drifts inland.

### [48:12](https://www.youtube.com/watch?v=0g4j2k_Ggc4&t=2892s) When SARSA is guaranteed to work, and the windy gridworld
The learner from the last part is guaranteed to end up with the right scores, on two conditions. The first is the schedule from two parts back: keep trying every move, and become greedy in the end (GLIE). The second concerns the step size, how big each nudge is.

The step sizes must shrink in a particular way. Their sum has to be infinite, so a score can travel as far as it needs to. The sum of their squares has to be finite, so the scores eventually stop jumping around.

Under both conditions SARSA reaches the true score of each state and move under the best play, the best action values. In practice, Silver says, people ignore both and it usually works.

His example ignores them too. In the windy gridworld a walker crosses a grid while wind pushes it upward. Every step earns -1, and the step size and epsilon (the share of random moves) are both fixed. The first episode takes about 2,000 steps. After that the episodes speed up sharply. The plot keeps a "bubbly" look, because epsilon never decays and the odd random move still gets thrown in.

**On the island:** the same shape. SARSA's median first goal came at episode 11, Q-LEARNING's at 13; RANDOM WALK reached it by luck in 1.0% of episodes. Fixed epsilon is why both keep falling.

### [53:36](https://www.youtube.com/watch?v=0g4j2k_Ggc4&t=3216s) Looking more than one step ahead: n-step SARSA and the lambda return
A learner can trust its own guesses after one real step, or trust nothing until the real ending, and there is a whole range in between. SARSA sits at the first end. Monte Carlo, which waits for the run to finish, sits at the other. As in lecture 4, Silver fills in the middle.

Pick a number n. Count n real rewards as they arrive, then lean on the table's own guess for everything after, which is called bootstrapping. `q_t(n) = R_t+1 + gamma R_t+2 + ... + gamma^n Q(S_t+n, A_t+n)`. In words: count n real rewards, then guess the rest. This is the n-step target, and n-step SARSA nudges each score toward it.

Silver would rather not pick a single n, so he averages over all of them. The method is called SARSA(lambda), and it gives the n-step target the weight `(1 - lambda) lambda^(n-1)`. In words: short looks weigh most, each longer one a factor lambda less.

Lambda works as a dial. Set to 1, the method is Monte Carlo. Set to 0, it is plain SARSA.

**On the island:** SARSA LAMBDA uses lambda 0.8; MONTE CARLO is the far end.

### [1:02:01](https://www.youtube.com/watch?v=0g4j2k_Ggc4&t=3721s) Eligibility traces: credit flows back along the path in one episode
When a reward finally arrives, something has to decide which of the earlier moves earned it. The averaging in the last part answers by looking forward from every move, and that cannot be finished until the episode ends. Silver calls it the forward view, and he wants something that can update at every step.

His answer, the backward view, keeps a second table beside the scores. For each state and move it holds one number that marks how recently and how often that pair was used. This is the eligibility trace. `E_t(s,a) = gamma lambda E_t-1(s,a) + 1(S_t = s, A_t = a)`. In words: at every step all the traces fade by a factor of gamma times lambda, and the pair just used goes up by one.

Every pair's score then moves by `alpha delta E(s,a)`. In words: each surprise (delta, the TD error, the gap between what she expected and what happened) is shared out to recent moves in proportion to their trace.

In his gridworld, one-step SARSA learns about one more move per episode, working back from the goal. SARSA(lambda) updates most of the path at once. Lambda, he says, "defeats the tyranny of the time step" [1:10:14].

**On the island:** SARSA LAMBDA fell less than SARSA, 11.8 against 16.3 per 100 (difference -4.51, interval -6.21 to -2.78, exploratory). Her median first goal came at episode 14, later than SARSA's 11.

### [1:19:55](https://www.youtube.com/watch?v=0g4j2k_Ggc4&t=4795s) Why learn off-policy, and why importance sampling mostly fails
So far every learner has studied her own behaviour. Silver now lets a learner study one way of acting while doing another. One policy (a rule for choosing a move) picks the moves in the world, and he calls it the behaviour policy, written mu. A different one is being judged, the target policy, written pi. This is off-policy learning, the looking over someone's shoulder from the start of the hour.

He gives four reasons to want it. A learner could learn from watching humans. It could reuse the experience its own older policies produced, as his Atari work did. It could learn about the best policy while exploring. And it could learn about many policies from one stream of life.

His first tool reweights each sample by how much likelier it is under pi than under mu, which is called importance sampling. `G^(pi/mu) = [pi(A_t|S_t)/mu(A_t|S_t)] ... [pi(A_T|S_T)/mu(A_T|S_T)] G_t`. In words: multiply one ratio per step across the episode.

For Monte Carlo, which uses whole episodes, that is a long chain of ratios, and over that many steps the two policies almost never match. His verdict: "in practice it's just useless" [1:27:09]. TD looks one step ahead, so it needs one ratio. That is far better, but it can still blow up.

**On the island:** Not run on the island. Judging the 11-step greedy route from RANDOM WALK's logs would weight a matching episode by 4^11, about 4.2 million (arithmetic), and every other by zero.

### [1:28:46](https://www.youtube.com/watch?v=0g4j2k_Ggc4&t=5326s) Q-learning: score a move by the best next move, not the one you really make
She can score the move she just made by the best move open to her next, even when her real next move is a random one. That change removes the ratios of the last part.

Silver sets it up in general first. Her real next move comes from the behaviour policy, the rule steering her. She also considers the move that the target policy, the rule she wants to learn about, would have made there. The stored score of that second move stands in for the rest of the run, which is the bootstrapping of lecture 4.

Q-learning is the well-known case where the target policy always takes the top score (it is greedy). That makes the second move's score the largest on offer. `Q(S,A) <- Q(S,A) + alpha (R + gamma max_a' Q(S',a') - Q(S,A))`. In words: nudge the score of what she did toward the reward plus the best score available where she landed, whatever she does next.

That is one sample of the Bellman optimality equation, lecture 2's rule that a move is worth its reward plus the best that can follow. Her behaviour stays partly random (epsilon-greedy), the target is greedy, and her table converges to the scores of the best play, the best action values [1:33:59]. The question to settle next is which learner, this one or SARSA, ends up preferring the edge.

> **Alt+Tab · game 5 · stop 5 of 6: Name the learner that hugs the edge**
>
> **What he just said:** Q-learning updates the score of what you did toward the reward plus the best score available where you landed, whatever you do next.
>
> **In the game:** The game asks which learner ends up preferring the edge: LEFT CLICK for Q-LEARNING, RIGHT CLICK for SARSA. A short reveal follows on the coach line.
>
> **Before you press:** Using lecture 4's rule (move a guess toward the reward plus the next guess), commit to which next guess makes the edge look best.
>
> <details><summary>Back from the game: what you just saw</summary>The best next move is never a boop, so Q-learning scores the edge at 39 and keeps walking it. SARSA counts the boops and scores it 0.41. Q-learning learns about the player you could be while acting as the one you are, which is off-policy; SARSA learns about the one you are, which is on-policy. <em>In an agent:</em> Training on what a flawless version would do, while the real agent still slips, is the Q-learning choice.</details>

**On the island:** Q-LEARNING uses alpha 0.5, epsilon 0.1. An edge square keeps its perfect-walk score because the max ignores her stumbles, so she keeps walking there and pays for them.

### [1:34:04](https://www.youtube.com/watch?v=0g4j2k_Ggc4&t=5644s) The cliff walk: on the slides, not in the talk
The example the island is built on, a walk beside a cliff, is in Silver's slides and nowhere in his talk. He states that Q-learning converges at [1:33:59], calls it a standard idea at [1:34:04], and at [1:34:10] starts to wrap up. The slides with the pseudocode (the method written out step by step), the demo and the cliff pass unmentioned in all three transcriptions of the audio.

So this part reads the slide. Slide 40 shows a grid with -1 per step and -100 for stepping into "The Cliff". It marks two routes, a "safe path" along the far row and an "optimal path" beside the cliff. The slide also has a plot over 500 episodes where SARSA's reward per episode settles near -25 and Q-learning's near -50, both read by eye.

The slide gives no value for epsilon, the share of random moves, and Silver never says what the picture is for. Its unspoken point: SARSA learns the safe route and earns more while learning. Q-learning learns the optimal route and keeps falling.

> **Alt+Tab · game 5 · stop 6 of 6: Read the debrief**
>
> **What he just said:** Silver passes the cliff-walk slide without discussing it; its plot shows the careful learner earning more while it learns and the edge-walking learner falling more.
>
> **In the game:** Nothing to press. Read the three debrief lines and your prediction score in the left block; the right block keeps your four crossings and the long-run averages.
>
> **Before you press:** Before reading, say to yourself which of your four crossings you would repeat.
>
> <details><summary>Back from the game: what you just saw</summary>You crossed beside a drop under random boops, and the arithmetic showed the short lane losing once the boops were counted. One honest limit: here the boop stands in for your own random move. If the boops belonged to the world itself, Q-learning would learn them too and would also move inland. <em>In an agent:</em> Judge a plan by what the agent will really do, mistakes included, not by what a perfect run would score.</details>

**On the island:** the direction matches. SARSA earned more over the last 40 episodes (22.3 against 7.5), fell less (16.3 against 26.5 per 100) and walked 3.88 m from the edge against 2.07 m. The island adds what the slide lacks: with exploring off, Q-LEARNING crossed cleanly in 11 of 11 runs, SARSA in 13 of 16.

### [1:34:10](https://www.youtube.com/watch?v=0g4j2k_Ggc4&t=5650s) The closing table: each planning method has a twin that learns from samples
Silver closes with one table, and its pattern is that every method that needed the rules has a twin that does without them.

The left column holds the planning methods of lecture 3, called dynamic programming (DP). Each updates a score with a full average over everything that could happen next, and that average needs the model, the rules of the world written down. Such an update is called a backup. The right column holds the methods of lecture 4 and of this hour, which build the same update from one real step.

There are three pairs. Iterative policy evaluation, which scores a fixed policy by repeated sweeps, becomes TD learning. Q-policy iteration, which improves a policy through its move scores, becomes SARSA. Q-value iteration, which goes straight for the best scores and comes from the Bellman optimality equation, becomes Q-learning.

The table has its own shorthand: `x <-alpha y` means `x <- x + alpha (y - x)`. In words: where DP takes an expectation (the full average), TD takes one sample and moves a step toward it.

**On the island:** PLANNER is the left column; RANDOM WALK's TD tables, SARSA and Q-LEARNING are the right.

## What the island measured for this lecture

| Bot | Runs | Falls per 100 training episodes (95% interval) | Mean return, last 40 | Distance from edge, last 40 (m) | Runs with 10 clean test crossings |
|---|---|---|---|---|---|
| SARSA | 16 | 16.3 (15.3 to 17.4) | 22.3 | 3.88 | 13/16 |
| Q-LEARNING | 11 | 26.5 (22.4 to 30.4) | 7.5 | 2.07 | 11/11 |
| EXPECTED SARSA | 9 | 13.2 (12.0 to 14.4) | 27.3 | 3.56 | 9/9 |
| SARSA LAMBDA | 14 | 11.8 (10.5 to 13.2) | 22.4 | 5.06 | 13/14 |
| MONTE CARLO | 10 | 98.3 (97.7 to 98.8) | -102.2 | 0.18 | 0/10 |

The one comparison planned before the night was SARSA against Q-LEARNING on falls: -10.14 per 100 (95% interval -14.18 to -5.83, p under 0.001, 16 and 11 runs). The rest are first looks, uncorrected for the number of comparisons: SARSA stood 1.82 m further from the edge (1.38 to 2.23) and earned 14.86 more (5.43 to 23.42); EXPECTED SARSA, a variant not in this lecture, fell 13.30 less than Q-LEARNING (-17.50 to -8.96); MONTE CARLO earned 124.55 less than SARSA (-128.57 to -119.83) and never reached the goal. A beginner never sees the +50, and stepping off at once (-101) beats wandering then falling, so judging moves by whole endings teaches her to step off; TD bots lean on unknown squares valued at zero. What this does not show: one step size and epsilon per method, 150 episodes, one night, no GLIE bot, so nothing tests Silver's convergence theorems; MONTE CARLO's failure concerns constant-step, fixed-epsilon Monte Carlo, not GLIE Monte Carlo control.

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
