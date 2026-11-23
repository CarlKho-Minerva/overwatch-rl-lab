# Lecture 5: Model-Free Control

*David Silver's lecture 5 (UCL, 2015), gone through in his order and re-explained with the Tracer experiments on Workshop Island. The lecture and its slides are his: [video](https://www.youtube.com/watch?v=0g4j2k_Ggc4), [course page](https://davidstarsilver.wordpress.com/teaching/). The words below are a re-explanation. Every island number comes from the logged runs in this repository.*

You are Tracer on high ground beside a drop, and the short way across runs right along the edge. Then an enemy Lucio arrives, and on one step in ten he boops you one pad in a random direction. Suddenly the short way has a price nobody wrote down. This hour asks how a learner who is never told the rules can still find the best way to act, when all she can do is try moves and see what they earn. It ends with two learners that differ by one line of arithmetic. SARSA learns the value of the walker she really is, stumbles included. Q-learning learns the value of a perfect walker, while stumbling.

**Two windows:** this page, and [Game 5: Slippery Boots](../workshop/games/g05.md), an Overwatch custom game for this lecture (paste `workshop/compiled/game-05.txt` into a custom game's settings and start it). The game opens at stop 1 and waits. Read down this page; at each box marked Alt+Tab, switch to the game, do that stop, and switch back. The game never moves on while you read.

## The lecture in order

### [04:09](https://www.youtube.com/watch?v=0g4j2k_Ggc4&t=249s) Grind your own games, or study someone else's replay
There are two ways to get better at Tracer. Play your own games and learn from what keeps happening to you, or watch someone else's replay and ask whether a different play would have worked.

Both are about getting better, not just keeping score, and that is this hour's change. Last lecture's learners were scorekeepers: each was handed a fixed way of behaving and worked out how much reward it earned, which Silver calls prediction. Now the learner is dropped into a world it knows nothing about and must find the behaviour that earns the most. He calls that control.

Silver has a nickname for each way of getting there.

"Learning on the job" is the first. You follow a rule for choosing moves, called a policy, and you learn about that same rule. That is on-policy learning.

"Looking over someone's shoulder" is the second. The experience comes from one policy and the learning is about another. His example: a robot watches a human steer an arm and works out, from the human's attempts alone, whether some other way of moving would have done better. That is off-policy learning.

The lecture starts on the job, the simpler of the two.

**On the island:** SARSA, SARSA LAMBDA and MONTE CARLO are on-policy: each learns about her own slightly random walking. Q-LEARNING is off-policy: she walks with random steps but learns about a version of herself that never takes one.

### [05:35](https://www.youtube.com/watch?v=0g4j2k_Ggc4&t=335s) Score, adjust, repeat, and why the score has to sit on the move
Think about how anyone gets decent at a hero. You play, you notice what worked, you do more of that. Score the habit, shift it toward whatever scored best, go again.

Lecture 3 ran exactly this loop with the rules written down. Silver calls the general pattern generalised policy iteration: score the current policy (the rule for choosing a move), improve it, repeat.

Take the rules away and two things break.

1. **You stop looking.** If you always take the move that looks best, you stop visiting the rest of the world, so you never learn what it was worth.
2. **A score per square cannot pick a key.** Picture the island shaded in, every square coloured by how good it is to stand there. Lovely. Now which key do you press? To choose, you would need to know where each move lands, and that is the rulebook you do not have (09:53).

His fix for the second is to put the score on the move instead of the square: one number for each place and move together. He writes it Q and calls it the action value. Now choosing needs no look-ahead.

You just read off the top score.

<details markdown="1"><summary>The formula, when you want it</summary>

`pi'(s) = argmax_a Q(s, a)`. In words: in each state, pick the move with the largest stored score.

</details>

> **Alt+Tab · game 5 · stop 1 of 6: Pick a lane while nobody is pushing you**
>
> **What he just said:** Without the rules you cannot look ahead from a spot to see where each key takes you. So you keep a score on every move from every spot, and getting better just means pressing whichever move scores highest.
>
> **In the game:** The game asks which lane pays more when nothing pushes you: LEFT CLICK for EDGE, RIGHT CLICK for INLAND, MELEE for THE SAME. Then LEFT CLICK or RIGHT CLICK picks your lane, and you walk it with WASD from the white ring to the green ring.
>
> **Before you press:** Commit to which lane earns more when every step goes where you aim it.
>
> <details><summary>Back from the game: what you just saw</summary>Edge 39, inland 37. Each pad costs 1, the goal pays 50, and the edge is two pads shorter. With nothing pushing you, reading off the higher score picks the short way, and the short way is right. Silver builds his whole loop on this one step: greedy improvement on action values. <em>In an agent:</em> Score a plan as if every tool call does exactly what you meant, and the one with the fewest steps always looks best. Hold that thought until Lucio shows up.</details>

**On the island:** PLANNER runs this loop with the rules written down. Every learner instead keeps a table of 48 squares by 4 moves. She never needs to know that "toward the edge" from row 0 is a fall, only that its score is very low.

### [13:27](https://www.youtube.com/watch?v=0g4j2k_Ggc4&t=807s) Two doors, and the teammate who only knows one flank
Everyone has played with this person. In their first week they took the left flank, got two picks, and have taken the left flank ever since. Is it the best route? They have no idea. They have never tried the other one.

Silver tells the same story with doors. Open the left door and you get 0. Open the right and you get +1, so you open it again and get +3. A chooser that always takes whatever has scored best so far will now open the right door until the heat death of the universe.

It is not being stupid. It is doing exactly what the scores say. Silver calls that acting greedily.

The trouble is that the left door got one try. One try tells you almost nothing, and the greedy chooser never goes back to check.

His fix is almost embarrassingly simple, and he says it is surprisingly hard to beat: every so often, do something random. With a small probability, written epsilon, pick any move at all. The rest of the time take the best-scoring one. This is called epsilon-greedy.

<details markdown="1"><summary>The formula, when you want it</summary>

`pi(a|s) = epsilon/m + 1 - epsilon` for the greedy move, `epsilon/m` for the others. In words: with m moves, the best gets nearly all the probability and every other move keeps a small, never-zero share.

</details>

Which is fine when a random move costs you a few seconds.

It is less fine when one of the moves is a step off a ledge.

> **Alt+Tab · game 5 · stop 2 of 6: Lucio arrives: one step in ten**
>
> **What he just said:** To stop a learner locking onto its first good guess, Silver makes one move in ten a random one. He calls it epsilon-greedy. It is the cheap cure for the teammate who only ever takes one flank.
>
> **In the game:** Lucio now stands inland. The game asks the chance that one step off an edge pad ends over the drop: LEFT CLICK, RIGHT CLICK or MELEE for the three answers. Then pick a lane and walk it.
>
> **Before you press:** Commit to how likely a single edge step is to send you over, before you take one.
>
> <details><summary>Back from the game: what you just saw</summary>One step in ten is swapped for a random one of four moves, and one of those four points at the drop. So each edge step goes over 1 time in 40. Lucio is the lecture's random move, made for you. Check the right side: how many boops you took, and where they sent you. <em>In an agent:</em> Sampling with some randomness makes a model try other actions now and then, and other actions include the ones that cannot be undone.</details>

**On the island:** epsilon is 0.1 with 4 moves, so in row 0 the edge move has a 0.025 chance every step. Over eleven edge-row steps that is about a 24% chance of a fall (arithmetic, not a measurement), near Q-LEARNING's measured 26.5 per 100 episodes; a rough match, since her route is not always the edge row.

### [17:41](https://www.youtube.com/watch?v=0g4j2k_Ggc4&t=1061s) Rolling dice on purpose does not make you worse
Say you decide to throw a random play into a fight now and then, on purpose, so you keep learning. Sensible. But now your improved habit has dice in it. Does the loop from two parts back, score the habit and then improve it, still improve anything, or does it quietly stall?

Silver spends his one slide of maths on this worry. It keeps improving.

The setup: start with a policy that takes the best-scoring move most of the time and a random one now and then, which is what epsilon-greedy means. Work out its score for every place and move, its action values Q. Then build a new epsilon-greedy policy from those scores. The new one is never worse than the old.

The reason fits in two sentences. The best move's score is at least as large as any weighted average of the moves' scores, and the old policy's value is one such average. (Your best option is never worse than your average option. That is the whole trick.)

That settles a single step. Carrying it through every later step uses the Bellman equation, lecture 2's rule that ties each value to the values one step later (18:43).

<details markdown="1"><summary>The formula, when you want it</summary>

`v_pi'(s) >= v_pi(s)`. In words: from every state, the new policy is worth at least as much as the old one, so softening greed with a little randomness still lets each round help.

</details>

A student asks whether the proof says how much to explore.

It does not.

**On the island:** Not run on the island. The test: freeze each table every 10 episodes and check that her policy's exact value never drops.

### [25:37](https://www.youtube.com/watch?v=0g4j2k_Ggc4&t=1537s) Explore forever, lock in eventually (GLIE)
Think of a fresh season. In week one you try everything, even the obviously bad build. By the end you mostly play one way, and check the odd idea less and less often, but never quite never.

That is what Silver is after. A learner that makes random moves forever cannot be the best, because the best way to act has no random moves in it. One that stops too soon may never find out what it missed. So he asks for two things:

1. **Try everything forever.** Every state and move gets tried infinitely often.
2. **Lock in eventually.** The policy tends toward the greedy one, which always takes the top score.

A schedule that meets both is called greedy in the limit with infinite exploration, or GLIE. One that works: on episode k (the kth run), set epsilon, the share of random moves, to 1/k.

Join that to Monte Carlo scoring, lecture 4's averaging of the returns (the total reward that followed), updated after each episode, and you have GLIE Monte Carlo control. It converges to the best action values, the true score of each state and move under the best play. It also finds the best blackjack policy (35:20).

<details markdown="1"><summary>The formula, when you want it</summary>

`Q(S,A) <- Q(S,A) + (1/N(S,A)) (G - Q(S,A))`. In words: each visited pair's score becomes the running average of the returns that followed it.

</details>

Asked whether the starting scores matter (32:48), he corrects himself mid-answer. A 1/N average erases them on the first visit.

With a constant step size, they matter.

> **Alt+Tab · game 5 · stop 3 of 6: Count the falls along the edge**
>
> **What he just said:** Silver wants exploring that never stops but fades: every move keeps getting tried, and the learner still locks in on the best one in the end.
>
> **In the game:** The game asks how often the whole edge lane ends in a fall with boops on: LEFT CLICK, RIGHT CLICK or MELEE. Then pick a lane and walk it again.
>
> **Before you press:** Commit to roughly how many crossings in 100 end over the drop if you always take the edge.
>
> <details><summary>Back from the game: what you just saw</summary>Eleven edge steps at 1 in 40 each comes to about 24 falls in 100. Count the walks back after other boops and the game's own arithmetic says about 26. Here the boops never fade, so that tax never shrinks. A schedule that lowers the random share over time, which Silver calls GLIE, is what would let it fall toward zero. <em>In an agent:</em> An agent with a fixed amount of randomness pays the same tax for it on every run, however much it has learned.</details>

**On the island:** no bot is strictly GLIE. Most keep epsilon at 0.1. MONTE CARLO uses a constant step of 0.2, and MONTE CARLO + OPTIMISM starts every Q at 40, which Silver's remark says should matter. It did not: late return differed by 0.27 (-0.51 to 1.14), inconclusive.

### [41:01](https://www.youtube.com/watch?v=0g4j2k_Ggc4&t=2461s) SARSA: you know the dive failed before the match ends
You do not need the end-of-match screen to know a dive went badly. You know the moment you land in their backline and the whole enemy team turns around. Your guess about the fight changed one step in, because of where you landed.

That is lecture 4's quicker way to score. After a single step, move your guess toward the reward you just got plus your guess for where you landed. It is called temporal-difference learning, TD for short.

Silver puts TD into the loop in place of Monte Carlo, which waits for whole finished runs. Because TD updates after one step, the policy can improve at every step too.

The name spells the update: S for the state she is in, A for the action she takes, R for the reward she gets, S for the next state, and A for the next action she picks there.

<details markdown="1"><summary>The formula, when you want it</summary>

`Q(S,A) <- Q(S,A) + alpha (R + gamma Q(S',A') - Q(S,A))`. In words: nudge the score of what she just did toward the reward plus the score of the move she has actually chosen next (alpha is the step size, how big each nudge is; gamma is the discount, how much less a later reward counts).

</details>

What she nudges toward is one sample of the Bellman equation (lecture 2's rule tying each value to the values one step later) for the policy she is actually following. So her scores describe that policy, stumbles and all.

SARSA is on-policy at its root (48:03).

That leaves the island's question: which route earns more once her own random moves are counted.

> **Alt+Tab · game 5 · stop 4 of 6: Which lane wins in the long run**
>
> **What he just said:** SARSA nudges the score of what you just did toward the reward plus the score of the move you will really make next, random moves included. It is honest about how you actually play.
>
> **In the game:** The game asks which lane earns more on average with boops on: LEFT CLICK for EDGE, RIGHT CLICK for INLAND. The answer and both averages appear, and then you pick a lane for the last crossing and walk it.
>
> **Before you press:** Commit to the lane that earns more over many crossings when Lucio is around.
>
> <details><summary>Back from the game: what you just saw</summary>Edge 0.41, inland 30.31. A 26 in 100 chance of losing 100 costs far more than two extra pads. These are the scores of the walker who really gets booped, which is what SARSA learns, so SARSA walks inland. Hold your own four returns on the right up against those averages. <em>In an agent:</em> Score a strategy by the runs the agent actually produces, slips and all, and the cautious route often wins.</details>

**On the island:** SARSA uses alpha 0.5, epsilon 0.1. Her next move is sometimes random, so an edge square inherits the cost of her own stumbles there, and she drifts inland.

### [48:12](https://www.youtube.com/watch?v=0g4j2k_Ggc4&t=2892s) The warranty, the fine print, and the windy gridworld
SARSA comes with a warranty. It is guaranteed to end up with the right scores, the best action values, as long as two conditions hold:

1. **Keep exploring, then lock in.** That is GLIE, the schedule from two parts back.
2. **Shrink the step size the right way.** The step size is how big each nudge is. Add up all the steps and the total must be infinite, so a score can travel as far as it needs to. Add up their squares and the total must be finite, so the scores eventually stop jumping around.

Like most fine print, it mostly goes unread.

In practice, Silver says, people ignore both conditions, and it usually works.

His own example ignores them too. In the windy gridworld you cross a grid while a wind keeps pushing you upward. Every step earns -1, and the step size and epsilon (the share of random moves) are both fixed. The first episode takes about 2,000 steps. After that, the episodes speed up sharply.

The plot keeps a "bubbly" look, because epsilon never decays and the odd random move still gets thrown in.

**On the island:** the same shape. SARSA's median first goal came at episode 11, Q-LEARNING's at 13; RANDOM WALK reached it by luck in 1.0% of episodes. Fixed epsilon is why both keep falling.

### [53:36](https://www.youtube.com/watch?v=0g4j2k_Ggc4&t=3216s) How far ahead to look before trusting your own guess (n-step SARSA and the lambda return)
You can judge a play the second after you make it, or wait until the match ends, or anywhere in between. Judge early and you are mostly trusting your own guess about how it will go. Judge late and you trust only the real result, at the price of waiting for it.

SARSA judges after one real step. Monte Carlo waits for the run to finish. As in lecture 4, Silver fills in the middle.

Pick a number n. Count n real rewards as they arrive, then lean on the table's own guess for everything after. Leaning on your own guess like that is called bootstrapping. What you get is the n-step target, and n-step SARSA nudges each score toward it.

Silver would rather not pick one n, so he averages over all of them, with short looks weighted most. That is SARSA(lambda).

<details markdown="1"><summary>The formulas, when you want them</summary>

`q_t(n) = R_t+1 + gamma R_t+2 + ... + gamma^n Q(S_t+n, A_t+n)`. In words: count n real rewards, then guess the rest.

SARSA(lambda) gives the n-step target the weight `(1 - lambda) lambda^(n-1)`. In words: short looks weigh most, each longer one a factor lambda less.

</details>

Lambda is a dial.

Set it to 1 and the method is Monte Carlo. Set it to 0 and it is plain SARSA.

**On the island:** SARSA LAMBDA uses lambda 0.8; MONTE CARLO is the far end.

### [1:02:01](https://www.youtube.com/watch?v=0g4j2k_Ggc4&t=3721s) Eligibility traces: handing out assists
Your team wins a fight. Who earned it? The kill feed has a rough answer: anyone who had a hand in it in the last few seconds gets an assist.

A learner has the same problem. When a reward finally arrives, something has to decide which earlier moves earned it. The averaging in the last part answers by looking forward from every move, and that cannot be finished until the episode ends. Silver calls it the forward view, and he wants something that can update at every step.

His answer, the backward view, keeps a second table beside the scores. For each state and move it holds one number that marks how recently and how often you used that pair. This is the eligibility trace. (Unlike the kill feed there is no hard cutoff. The trace just fades, and a move used twice counts for more.)

So when a surprise arrives, the moves with the biggest traces get most of the credit.

<details markdown="1"><summary>The formulas, when you want them</summary>

`E_t(s,a) = gamma lambda E_t-1(s,a) + 1(S_t = s, A_t = a)`. In words: at every step all the traces fade by a factor of gamma times lambda, and the pair just used goes up by one.

Every pair's score then moves by `alpha delta E(s,a)`. In words: each surprise (delta, the TD error, the gap between what she expected and what happened) is shared out to recent moves in proportion to their trace.

</details>

In his gridworld, one-step SARSA learns about one more move per episode, working back from the goal. SARSA(lambda) updates most of the path at once. Lambda, he says, "defeats the tyranny of the time step" (1:10:14).

**On the island:** SARSA LAMBDA fell less than SARSA, 11.8 against 16.3 per 100 (difference -4.51, interval -6.21 to -2.78, exploratory). Her median first goal came at episode 14, later than SARSA's 11.

### [1:19:55](https://www.youtube.com/watch?v=0g4j2k_Ggc4&t=4795s) Learning from someone else's replay, and why the obvious maths mostly fails
Back to the replay from the start of the hour. Every learner so far has studied her own play. Now one policy picks the moves in the world, and Silver calls it the behaviour policy, written mu. A different one gets judged: the target policy, written pi. This is off-policy learning, looking over someone's shoulder.

He gives four reasons you would want it:

1. **Watch people.** Learn from watching humans.
2. **Reuse old games.** Reuse the experience its own older policies produced, as his Atari work did.
3. **Explore, but learn the best.** Learn about the best policy while exploring.
4. **Many lessons, one life.** Learn about many policies from one stream of life.

His first tool is the obvious one: reweight each sample by how much likelier it is under pi than under mu. This is called importance sampling.

<details markdown="1"><summary>The formula, when you want it</summary>

`G^(pi/mu) = [pi(A_t|S_t)/mu(A_t|S_t)] ... [pi(A_T|S_T)/mu(A_T|S_T)] G_t`. In words: multiply one ratio per step across the episode.

</details>

For Monte Carlo, which uses whole episodes, that is a long chain of ratios, and over that many steps the two policies almost never match. (Picture rating replays using only the matches where the player did what you would have done at every single moment.) His verdict: "in practice it's just useless" (1:27:09).

TD looks one step ahead, so it needs one ratio. That is far better.

It can still blow up.

**On the island:** Not run on the island. Judging the 11-step greedy route from RANDOM WALK's logs would weight a matching episode by 4^11, about 4.2 million (arithmetic), and every other by zero.

### [1:28:46](https://www.youtube.com/watch?v=0g4j2k_Ggc4&t=5326s) Q-learning: rate every spot as if your next move will be perfect
After a lost fight you replay it in your head and decide that from that corner, with the next shot hit, you win. You are scoring the spot by the best play available from it, not by what you actually did next.

Q-learning does that on purpose. She scores the move she just made by the best move open to her next, even when her real next move is random. That one change removes the ratios from the last part.

Silver builds it up in general first. Her real next move comes from the behaviour policy, the rule steering her. She also considers the move the target policy, the rule she wants to learn about, would have made there, and lets its stored score stand in for the rest of the run (lecture 4's bootstrapping).

Q-learning is the well-known case where the target policy is greedy, so the stand-in is the largest score on offer.

<details markdown="1"><summary>The formula, when you want it</summary>

`Q(S,A) <- Q(S,A) + alpha (R + gamma max_a' Q(S',a') - Q(S,A))`. In words: nudge the score of what she did toward the reward plus the best score available where she landed, whatever she does next.

</details>

That is one sample of the Bellman optimality equation, lecture 2's rule that a move is worth its reward plus the best that can follow. Her behaviour stays partly random (epsilon-greedy), her target is greedy, and her table converges to the best action values (1:33:59).

So which learner ends up hugging the edge, this one or SARSA?

> **Alt+Tab · game 5 · stop 5 of 6: Name the learner that hugs the edge**
>
> **What he just said:** Q-learning nudges the score of what you did toward the reward plus the best score available where you landed, whatever you actually do next. It rates every spot as if your next move will be perfect.
>
> **In the game:** The game asks which learner ends up preferring the edge: LEFT CLICK for Q-LEARNING, RIGHT CLICK for SARSA. A short reveal follows on the coach line.
>
> **Before you press:** Using lecture 4's rule (move a guess toward the reward plus the next guess), commit to which next guess makes the edge look best.
>
> <details><summary>Back from the game: what you just saw</summary>The best next move is never a boop, so Q-learning scores the edge at 39 and keeps walking it. SARSA counts the boops and scores it 0.41. Q-learning learns about the player you could be while playing as the one you are: off-policy. SARSA learns about the one you are: on-policy. <em>In an agent:</em> Training on what a flawless version would do, while the real agent still slips, is the Q-learning choice. A good map, carried by a walker who trips.</details>

**On the island:** Q-LEARNING uses alpha 0.5, epsilon 0.1. An edge square keeps its perfect-walk score because the max ignores her stumbles, so she keeps walking there and pays for them.

### [1:34:04](https://www.youtube.com/watch?v=0g4j2k_Ggc4&t=5644s) The cliff walk: the slide he talks straight past
Here is an awkward fact for a page built around a cliff. The cliff walk, the example this whole island is built on, is in Silver's slides and nowhere in his talk.

If you only listened, you would never know it was there.

He states that Q-learning converges (1:33:59), calls it a standard idea (1:34:04), and at (1:34:10) starts to wrap up. The slides with the pseudocode (the method written out step by step), the demo and the cliff go by unmentioned in all three transcriptions of the audio.

So this part reads the slide. Slide 40 shows a grid with -1 per step and -100 for stepping into "The Cliff". It marks two routes, a "safe path" along the far row and an "optimal path" right beside the cliff. A plot over 500 episodes has SARSA's reward per episode settling near -25 and Q-learning's near -50, both read by eye.

The slide gives no value for epsilon, the share of random moves, and Silver never says what the picture is for. Its unspoken point: SARSA learns the safe route and earns more while learning. Q-learning learns the optimal route and keeps falling.

> **Alt+Tab · game 5 · stop 6 of 6: Read the debrief**
>
> **What he just said:** Silver goes straight past the cliff-walk slide without a word. Its plot says it for him: the careful learner earns more while it learns, and the edge-hugging learner falls more.
>
> **In the game:** Nothing to press. Read the three debrief lines and your prediction score in the left block; the right block keeps your four crossings and the long-run averages.
>
> **Before you press:** Before reading, say to yourself which of your four crossings you would repeat.
>
> <details><summary>Back from the game: what you just saw</summary>You crossed beside a drop while getting booped, and the arithmetic showed the short lane losing once the boops were counted. One honest limit: here the boop stands in for your own random move. If the boops belonged to the world itself, Q-learning would learn them too and would also move inland. <em>In an agent:</em> Judge a plan by what your agent will really do, mistakes included, not by what a perfect run would score.</details>

**On the island:** the direction matches. SARSA earned more over the last 40 episodes (22.3 against 7.5), fell less (16.3 against 26.5 per 100) and walked 3.88 m from the edge against 2.07 m. The island adds what the slide lacks: with exploring off, Q-LEARNING crossed cleanly in 11 of 11 runs, SARSA in 13 of 16.

### [1:34:10](https://www.youtube.com/watch?v=0g4j2k_Ggc4&t=5650s) The closing table: every planner has a twin that just plays
There are two ways to learn a matchup. You can read the full spreadsheet, every damage number and cooldown, and work out on paper how every fight could go. Or you can play it, one real fight at a time, and nudge your opinion after each.

Silver closes on one table that says these are twins.

The left column holds lecture 3's planning methods, called dynamic programming (DP). Each updates a score with a full average over everything that could happen next, and that average needs the model, the rules of the world written down. Such an update is called a backup. The right column holds the methods of lecture 4 and of this hour, which build the same update from one real step.

1. **Iterative policy evaluation**, which scores a fixed policy by repeated sweeps, becomes **TD learning**.
2. **Q-policy iteration**, which improves a policy through its move scores, becomes **SARSA**.
3. **Q-value iteration**, which goes straight for the best scores and comes from the Bellman optimality equation, becomes **Q-learning**.

<details markdown="1"><summary>The table's shorthand, when you want it</summary>

`x <-alpha y` means `x <- x + alpha (y - x)`. In words: where DP takes an expectation (the full average), TD takes one sample and moves a step toward it.

</details>

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

Take a tool-using agent in tau-bench, where a model talks to a simulated customer and calls tools such as order lookup or cancellation. Each conversation is one episode, scored at the end on whether the database ends up right. Training one maps neatly onto generalised policy iteration: score conversations, shift the model toward what scored well, repeat. (Sampling temperature is epsilon only by analogy.)

The cliff is the part to carry with you. A plan that is best when every step goes right can be poor for an agent that sometimes slips, and some tool calls (cancel, refund) cannot be undone. Those are the edge. Judge a strategy with the slips included and you are asking the SARSA question. Judge it by flawless execution and you are asking the Q-learning one.

The off-policy part is close to exact. Training on transcripts from an older model, or from people, is off-policy learning. A long transcript's probability ratio under two models is a product over hundreds of tokens, and it explodes just as Silver says.

Where the mapping breaks: the state is the whole conversation, and there is no Q table.

## The thread to partial observability

Every table here is indexed by the true state, and every convergence result assumes the agent sees it. Exploration is information gathering: in the two-doors example the agent's beliefs can be wrong, and only trying the doors fixes them [15:28]. The eligibility trace is a memory of recent history, used for credit, never for choosing a move. On the island, Q, ROW ONLY sees only her row, so different squares look identical to her; she fell 42.5 times per 100 against 26.5 for full Q-LEARNING and dithered along the edge. The hidden-wall build being run now asks whether a small memory of bumps can stand in for a state she is not told. Carry forward: these guarantees hold only when the table's index is the full state.

## Experiments the lecture asks for that the island has not run

- SARSA and Q-LEARNING with epsilon = 1/k and no floor, run long: GLIE should pull SARSA back to the edge row.
- Monte Carlo control as on the slide (1/N averages, epsilon = 1/k): is the jumping caused by constant steps and fixed epsilon, or by the method.
- n-step SARSA for n = 1, 2, 4, 8, 16: where on the spectrum learning to jump begins.
- PLANNER's route judged from RANDOM WALK's logs, full-episode against one-step importance sampling: the variance gap.
- Silver's windy-gridworld plot for the island: episodes completed against real steps.
