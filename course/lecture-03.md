# Lecture 3: Planning by Dynamic Programming

*David Silver's lecture 3 (UCL, 2015), gone through in his order and re-explained with the Tracer experiments on Workshop Island. The lecture and its slides are his: [video](https://www.youtube.com/watch?v=Nd1-UUMVfz4), [course page](https://davidstarsilver.wordpress.com/teaching/). The words below are a re-explanation. Every island number comes from the logged runs in this repository.*

Before a round, someone draws the map on a whiteboard. Here is the choke, here is the drop, and if we go this way they have to come through there. Nobody has died yet. All the dying happens in marker.

In this lecture's game you get the whiteboard. You stand over a board of 25 pads before the round begins, with the rules already written beside it: each step costs 1, the goal pays 10, and falling into a pit costs 10 and ends the run. On the island, almost every Tracer found the cliff by walking off it. PLANNER was handed the rules of her strip instead (where each move leads, what it pays). She stood still while she did the arithmetic, then walked the eleven-step edge route in all 10 of her runs without a fall.

This hour is about that arithmetic. Given the full rules of a world, you can compute exactly how good any way of behaving is, and which way is best. You do it by repeating the Bellman equation from lecture 2 (a place is worth one step's reward plus the worth of where you land) as an update, until the numbers stop moving.

**Two windows:** this page, and [Game 3: The Whiteboard](../workshop/games/g03.md), an Overwatch custom game for this lecture (paste `workshop/compiled/game-03.txt` into a custom game's settings and start it). The game opens at stop 1 and waits. Read down this page; at each box marked Alt+Tab, switch to the game, do that stop, and switch back. The game never moves on while you read.

## The lecture in order

### [02:26](https://www.youtube.com/watch?v=Nd1-UUMVfz4&t=146s) Dynamic programming: never work out the same route twice

You have walked from spawn to the first choke so often your hands do it alone. When you want the shortest route to the point beyond, you do not replan the whole walk. You reuse the part you know.

This whole hour is built on that kind of reuse.

Silver starts with the name, which has aged badly. "Dynamic" means the problem unfolds in steps. "Programming" means optimising a plan, as in linear programming, and has nothing to do with code. Here the plan is a policy: a rule for choosing an action in each state (each situation you can be in).

The reuse needs two things:

1. **Best wholes are made of best pieces.** If the shortest route to the point runs through the choke, it is the shortest route to the choke plus the shortest on from there. Silver calls this optimal substructure.
2. **The pieces come back.** Many routes pass the same choke, so you solve it once and store it. This is overlapping subproblems.

Lecture 2's model of a world, the MDP (states, actions, chances, rewards, discount), has both. The Bellman equation splits the problem into one step and the rest, and the value function (the total reward to expect from each state) stores the answers, "like a cache of all the good information".

**On the island:** the best way to the goal from a given square is a subproblem that every route through that square reuses. So PLANNER stores one answer per square and never searches whole routes.

### [08:08](https://www.youtube.com/watch?v=Nd1-UUMVfz4&t=488s) Planning: someone hands you the rules before the match

Imagine getting the game's source code before your first match: every cooldown, every damage number, where each button leads and what it pays. You would not need to walk off a cliff to learn that cliffs kill you. You could read it.

That is planning.

Silver's own picture: being handed an Atari game's source code instead of its screen. The written rules are the MDP itself (lecture 2's model: states, actions, chances, rewards, discount). He stresses that this is not full reinforcement learning, which has to play without the source.

With the rules in hand you can ask two questions:

1. **How good is the way I play?** Fix one policy and ask how much total reward to expect from each state under it. That table is the policy's value function, and the question is called prediction.
2. **What is the best way to play?** Ask for the most reward any policy can earn from each state (the optimal values) and a policy that earns it (an optimal policy). This is called control.

First thing to try in the game: what one look ahead at the rules tells one square.

> **Alt+Tab · game 3 · stop 1 of 7: Read the rules, call the first number**
>
> **What he just said:** Planning is the lucky case. Someone hands you the rules before you take a step (where each move leads, what it pays), so the only job left is working out what to do.
>
> **In the game:** The board is 25 pads on the floor, all showing 0, with the rules in the orange row on the left. Answer the question floating in front of you with LEFT CLICK, RIGHT CLICK or MELEE, then press F to run sweep 1.
>
> **Before you press:** After one sweep, what number will the pad right next to the goal show?
>
> <details><summary>Back from the game: what you just saw</summary>The three pads beside the goal jumped to 9. Every other pad went to -1. In one sweep a pad sees exactly one step ahead: the step costs 1, and only a pad next to the goal can see its 10. The rest have no idea the goal exists yet. That one-step look is lecture 2's Bellman rule, used as an update because you were handed the rules in advance. <em>In an agent:</em> An agent that knows exactly what a tool returns can score a call before making it, the way each pad scored its move without taking it.</details>

**On the island:** both questions were answered from the written rules. Prediction: the policy that picks every move with equal chance (the uniform random policy) is worth exactly -114.4 from the start square. Control: PLANNER's table and her greedy walk, which takes the best-looking move at each square, gave a return (total reward) of 39, the best possible.

### [13:07](https://www.youtube.com/watch?v=Nd1-UUMVfz4&t=787s) Policy evaluation: score a plan without anyone counting

Here is how a queue can learn how far each person is from the front, without anyone counting. Everyone starts by saying 0. Each round, every person says one more than the person ahead said last round, and the person at the front always says 0. A few rounds later, every number is right.

Nobody ever looked at the whole queue.

Silver scores a policy the same way and calls it policy evaluation, the answer to the prediction question. Start every state at zero. Pass over all the states, replacing each guess with a one-step look ahead: the average, over the moves the policy might make and wherever the world might send you, of the reward plus your current guess for the next state. (A random policy has several possible squares ahead, and averages what they said.)

One pass over every state is a sweep. Repeat, and the numbers settle on the policy's true values, which Silver asks you to take on trust for now.

The look ahead is lecture 2's Bellman expectation equation (a state's value is the average of reward plus next value), used as an update. As in the queue, each new table is computed whole from the old one: a synchronous sweep.

<details markdown="1"><summary>The formula, when you want it</summary>

`v_{k+1}(s) = sum_a pi(a|s) * ( R(s,a) + gamma * sum_s' P(s'|s,a) * v_k(s') )`. In words: the new value is the policy's average of reward now plus the discounted old value of the next state (gamma is the discount, which shrinks later reward, and P is the chance of each next state).

</details>

**On the island:** the random policy's exact values come from this update. Each square averages, over four moves taken a quarter of the time each, -1 plus the next square's value, with -100 for a fall. The discount is 1.

### [19:28](https://www.youtube.com/watch?v=Nd1-UUMVfz4&t=1168s) The small gridworld: score an aimless walk, get a good one thrown in

Picture a Tracer bot with no plan. Every step, she blinks in a random direction. She does reach an exit eventually, though nobody, least of all her, could tell you why.

Silver's first worked example is her, on a 4 by 4 grid. Two corners end the run (terminal squares), every step earns -1, and each step goes one of four ways at random.

You score her walk with sweeps, starting every value at 0. After one sweep, every square but the corners reads -1. After two, the middle reads -2 and the squares beside a corner -1.75. Once more sweeps change nothing (the values have converged), each number reads as the steps she can expect before finishing, up to 22 on the slide.

Then the surprise, in the slide's second column. On every square it marks the move that looks best under the current numbers, which is called acting greedily. After three sweeps those greedy moves are already the optimal policy, long before the numbers converge.

You scored an aimless walk and got the best one thrown in.

Next, the game shows how fast news of a goal reaches a distant square.

> **Alt+Tab · game 3 · stop 2 of 7: Watch the good news spread**
>
> **What he just said:** In his small gridworld, a square's value (the total reward you can expect from it) is found by sweeping the whole board again and again. Each sweep, the numbers fill in a little further.
>
> **In the game:** Answer the question, then press F for sweep 2 and watch which pads turn yellow.
>
> **Before you press:** On which sweep will your own start pad, the blue ring, first turn positive?
>
> <details><summary>Back from the game: what you just saw</summary>Yellow marks the pads that just heard about the goal, a new ring each sweep, one pad further out. Like a callout passed back down the team, each pad only hears its neighbours' numbers from the sweep before, so news travels one step per sweep. Your start pad is 5 steps from the goal, so it turns positive on sweep 5. You will watch that happen in stop 4.</details>

**On the island:** the strip is this grid with a cliff. The exact values under the random policy are -114.4 at the start and -135.5 at the far inland corner, which is worse because she wanders longer and then falls anyway. RANDOM WALK actually averaged -112.7 (standard error 0.46) over 2,308 episodes of 14.9 steps, and reached the goal by luck in 1.0% of them.

### [29:41](https://www.youtube.com/watch?v=Nd1-UUMVfz4&t=1781s) Policy iteration: watch the VOD, fix the play, watch again

After a bad night you watch the VOD, see which fights went wrong, change how you take them, and play again.

Score it, fix it, score it again.

Silver makes that loop the lecture's first complete method for control, the question of which policy (rule for choosing an action in each state) is best. Each round has two steps:

1. **Evaluate.** Work out the current policy's value in every state, as in the last two parts.
2. **Improve.** In every state, switch to the action with the best look ahead under those values. That is acting greedily.

Repeat until nothing changes. This is policy iteration, and Silver says it reaches the optimal policy from any start. A VOD only scores the fights you happened to have; his evaluation is exact, in every state.

His example is Jack's Car Rental, a problem from Sutton and Barto's textbook (that attribution is not from the lecture). Jack has two lots of up to 20 cars each. Rentals and returns arrive at random, in numbers given by a standard formula called the Poisson distribution. Overnight he can move up to five cars between lots, and each rental earns $10.

Start him moving nothing, and after about four rounds the policy stops changing.

**On the island:** policy iteration was not run on the island. PLANNER used value iteration, which comes later in this lecture. The experiment would evaluate the random policy exactly, act greedily, and count the rounds until the arrows stop changing.

### [46:02](https://www.youtube.com/watch?v=Nd1-UUMVfz4&t=2762s) Why the greedy switch can never make you worse

Take the way you usually play and change one decision: in the first fight you dive instead of holding, then play exactly as before. If diving then playing as usual beats holding then playing as usual, you are better off diving.

Obvious, for one decision.

The surprise is that it stays true when you switch in every state at once, though each switch was judged as if the rest stayed the same. The loop in the last part depends on that, so Silver stops to show why.

Taking an action now, then following the old policy (written pi), has a score called the action value, written q. The greedy policy, written pi', picks in each state the action with the highest q. The highest q cannot be lower than the q of pi's own action, so one greedy step followed by pi is at least as good as pi alone.

<details markdown="1"><summary>The formula, when you want it</summary>

`q_pi(s, pi'(s)) = max_a q_pi(s, a) >= q_pi(s, pi(s)) = v_pi(s)`. In words: the best-looking action, then the old policy, is worth at least the old policy, in every state.

</details>

Unroll that step by step, and pi' is at least as good as pi everywhere. If improvement ever stops, the values satisfy lecture 2's Bellman optimality equation (a state is worth its best action's look ahead), so the policy is optimal.

Greedy is not short-sighted, either. It "doesn't mean that we only look at one step of immediate reward", because the next state's value already sums the whole future.

**On the island:** the +50 is eleven steps from the start, yet one-step greedy choices get PLANNER there, because her values already carry the news of the goal.

### [58:40](https://www.youtube.com/watch?v=Nd1-UUMVfz4&t=3520s) You can act on rough scores

You do not need a Widowmaker's exact hit rate to know you should stop crossing her sightline. Knowing it is high is enough.

Silver makes the same point with the small gridworld. There, every sweep (pass over the squares) after the third changed nothing about the greedy policy, the one taking the best-looking move on each square. He describes "iterations 4 to infinity of our inner loop as being wasted work".

Infinity is a lot of wasted work.

So stop early. That is called modified policy iteration. You can stop once the values change by less than a small tolerance, written epsilon, or after a fixed number of sweeps, written k. Either way the method still converges, which means it still settles on the best policy.

The extreme case is k equal to 1: one sweep of evaluation, then improve at once. That is value iteration, which Silver calls probably the most popular dynamic programming method.

**On the island:** PLANNER uses the tolerance rule. She sweeps until the largest change in a sweep is under 0.001.

### [1:01:50](https://www.youtube.com/watch?v=Nd1-UUMVfz4&t=3710s) The principle of optimality: a best rotation is best from every stop on it

Take the best rotation from spawn to the high ground. If any later leg could be done better, you could swap in the better leg and improve the whole rotation. Then it was not the best after all.

A best plan is a best first move, then a best plan from wherever you land.

That is what lets a large problem be cut into one step and the rest. Silver calls it the principle of optimality, and returns to it because the next method is built on it. In policy terms (a policy is a rule for choosing an action in each state): an optimal first action, then an optimal policy from wherever you land.

The theorem makes this exact: a policy is optimal from a state if and only if it is optimal from every state reachable from it. (What you would do on a square you can never reach does not matter. It has zero probability, so it drops out.)

**On the island:** the edge route is optimal from the start because it is optimal from every edge square it passes. The row-only bot, told only her row, cannot tell forward from back: 47.1 steps per episode against 18.6 for the full table.

### [1:03:45](https://www.youtube.com/watch?v=Nd1-UUMVfz4&t=3825s) Value iteration: good news travels back one square at a time

Someone on the objective calls that it is free. The player next to them repeats it, the player behind repeats that, and a few calls later it reaches spawn.

Nobody at spawn heard the first call, or needs to.

Value iteration spreads value the same way. If you knew what each neighbouring square was worth under best play (its optimal value), one look ahead would give your own: the best move's reward plus the value of where it leads. Value iteration applies that look ahead, with a max, to every state, over and over, from any starting numbers.

<details markdown="1"><summary>The formula, when you want it</summary>

`v_{k+1}(s) = max_a ( R(s,a) + gamma * sum_s' P(s'|s,a) * v_k(s') )`. In words: new value equals the best action's reward plus the discounted old value of where it leads.

</details>

In his shortest-path grid the right values spread one step further each sweep, until the far corner reads -6 at the seventh table. It looks like working backwards from the goal, yet the method never needs to know where the goal is, so it copes with loops, randomness and no goal at all. (Where the callout picture breaks: here every square speaks every sweep, news or not.)

It keeps no explicit policy, and a midway table "might not be the value for any real policy". The game tests that, then asks how you know when to stop.

> **Alt+Tab · game 3 · stop 3 of 7: Judge a half-finished board**
>
> **What he just said:** Value iteration (sweep, keep the best move's number, sweep again) ends at the best values. Halfway through, though, the board need not be the score of any real plan.
>
> **In the game:** The board now shows sweep 2. Answer the question, then press F for sweep 3.
>
> **Before you press:** Is there one plan, one fixed choice of step on every pad, whose scores are exactly the numbers on the board right now?
>
> <details><summary>Back from the game: what you just saw</summary>No plan scores these numbers. Take a pad showing -2 whose neighbours all show -2: under any plan it would score -3, because every step costs 1 and lands on a -2. The midway board is a sum someone stopped adding halfway, with two steps of cost counted and the goal not yet seen. Only the settled table is the value of a plan.</details>

> **Alt+Tab · game 3 · stop 4 of 7: Sweep until nothing moves**
>
> **What he just said:** In his shortest-path grid the far corner needed one sweep per step of distance before its number was right. And the method stops the first time a whole sweep changes nothing.
>
> **In the game:** Answer the question, then keep pressing F, one sweep per press, until the panel on the right says 0 pads changed. Green lines then appear on the pads.
>
> **Before you press:** Which sweep will be the first that changes nothing at all?
>
> <details><summary>Back from the game: what you just saw</summary>The farthest pad got its final number on sweep 7. Sweep 8 changed nothing, and that dull sweep is the only way to know you are done. The green lines are the plan: on each pad, the step toward the best number next door. Choosing that way is called acting greedily, or policy improvement. The bill: 8 sweeps of 22 pads and 4 moves, 704 look-aheads.</details>

**On the island:** PLANNER settled in 13 sweeps. The largest change in each sweep was 101, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 48, 0.00. The 101 is a fall plus one step (stepping off is worth -101). After that, good news travels back one column per sweep, so the biggest change stays nearly level. The last sweep changes nothing and ends the loop.

### [1:24:03](https://www.youtube.com/watch?v=Nd1-UUMVfz4&t=5043s) Slide of the game, and the bill for a sweep

At the end of a match the game picks one clip and calls it Play of the Game. Silver does the same for this lecture, with a slide: "if you get this slide, you're doing well". It holds two questions and the equation each method repeats to answer them:

1. **Prediction.** How good is this policy (this fixed rule for choosing actions)? Repeat the Bellman expectation equation, the averaging look ahead. That is iterative policy evaluation.
2. **Control.** What is the best policy? Two routes. Policy iteration alternates that same expectation equation with greedy improvement, the switch to the best-looking action in every state. Value iteration repeats the Bellman optimality equation, the look ahead with a max. Modified policy iteration, which cuts the evaluation short, lies between them.

Then the bill. With n states and m actions, a sweep (one pass over every state) costs on the order of m times n squared.

<details markdown="1"><summary>The formula, when you want it</summary>

`cost per sweep = O(m * n^2)`. In words: every state checks every action against every possible next state.

</details>

Double the states and every sweep costs four times as much.

Run on action values (a score for each state and action together), a sweep costs m squared times n squared. The game now checks prediction directly: whether a walk along the finished plan earns the number on its first square.

> **Alt+Tab · game 3 · stop 5 of 7: Walk the plan yourself**
>
> **What he just said:** His summary slide splits planning in two. Prediction asks how good a given plan is; control asks for the best plan. And every sweep costs each state times each move.
>
> **In the game:** Answer the question, then walk with WASD along the green lines from the blue ring to the green goal ring. Each pad you enter costs 1 and the goal pays 10.
>
> **Before you press:** Your start pad shows 5. If you follow the lines, what will you score?
>
> <details><summary>Back from the game: what you just saw</summary>Follow the lines and you score 5: five pads at -1 each, plus 10 at the goal. That is the start pad's number exactly, because a pad's number is what the plan earns from there. The pad made a promise and the walk kept it. Checking what a plan earns is called policy evaluation. If you wandered off the lines, the score on the left came in under what the pad said. <em>In an agent:</em> A reward model's score for a half-finished conversation plays the pad's part: a promise about how this one ends. Nothing makes it keep that promise this exactly.</details>

**On the island:** the strip has 47 non-goal squares, 4 moves, and one next square per move. A sweep is instant, which is why PLANNER could be exact.

### [1:29:03](https://www.youtube.com/watch?v=Nd1-UUMVfz4&t=5343s) Asynchronous dynamic programming: update one square at a time, in a good order

Back to the queue from policy evaluation, where everyone answered from last round's numbers. Now let each person answer the moment the person ahead has spoken. Go front to back and the whole queue is right in one pass. Go back to front, and each person repeats a number about to go stale.

Same number of answers, very different speed.

You need not update every state on every pass. Update them one at a time, in any order, and the values still converge (settle on the right answer) as long as every state keeps being picked. Silver calls this asynchronous dynamic programming, in three versions:

1. **In-place dynamic programming.** One table, always the newest values. A corridor swept from the goal back to the start is solved in one sweep, because each square reads a neighbour just corrected. Swept the other way, it gains nothing: "the ordering really matters".
2. **Prioritised sweeping.** Update first the state whose value would change most. The size of that change is called the Bellman error.
3. **Real-time dynamic programming.** Update only the states the agent actually visits.

The game tests how much of a finished plan changes when one piece of the rules moves.

> **Alt+Tab · game 3 · stop 6 of 7: Move a pit, then plan again**
>
> **What he just said:** You need not sweep every state every time. Update single states, in a good order or first where the numbers would change most, and you still reach the same answer.
>
> **In the game:** Walk to any pad and press R: the pit marked THIS PIT MOVES jumps there. Answer the question, then press F; the board is wiped and the sweeps run by themselves.
>
> **Before you press:** How many of the old green lines are no longer the best step once the pit has moved?
>
> <details><summary>Back from the game: what you just saw</summary>Only pads whose best route ran past the new pit change their minds; their lines turn yellow. A pit on the pad just ahead of the start flips 5 lines, and a pit where no best route passes flips none. The game wiped the board and redid every sum, and most came back exactly as before. Doing first the pads that would move most is what Silver calls prioritised sweeping.</details>

**On the island:** PLANNER updates in place. Her one column per sweep fits an order that does not run goal-first. the island fact sheet does not record her order, so a reversed sweep is untested.

### [1:36:30](https://www.youtube.com/watch?v=Nd1-UUMVfz4&t=5790s) Thinking through every branch needs the rules; one real peek does not

Before you peek a corner, you could in principle think through everything behind it: every hero, every position, every cooldown, each with its chance.

Nobody does. You peek, see one thing, and learn from that.

Every update in this lecture did the thinking-through version: every action, every next state, each with its known probability, passing value back from the next states to this one. Silver calls an update a backup, and one that covers every branch a full-width backup.

That is costly, and it needs the model (the written rules). The cost has a name, the curse of dimensionality: the number of states multiplies with each variable that describes the world. At 10 to the 170 states, a 1 followed by 170 zeros, not even one backup fits.

Later lectures peek instead: take one action, observe one transition, make one update. These are sample backups. Their cost does not depend on the number of states, and they need no model.

Silver leaves to the slides why all this settles on one answer. Take any two guesses at the value table. Each backup shrinks their worst disagreement, in any state, by at least a factor of gamma (the discount). So they end up agreeing on one unique fixed point: the table a backup leaves unchanged.

<details markdown="1"><summary>The formula, when you want it</summary>

`||T(u) - T(v)||_inf <= gamma * ||u - v||_inf`. In words: a Bellman backup T shrinks the worst-state gap between any two guesses by at least gamma.

</details>

> **Alt+Tab · game 3 · stop 7 of 7: Read the debrief**
>
> **What he just said:** Every update here read the full rules and checked every branch. That is costly and needs a model of the world. Later lectures learn from single real steps instead.
>
> **In the game:** Nothing to press. Read the three lines on the left: what you did, what it is called, and where it shows up in a language-model agent.
>
> **Before you press:** Could this planner have found the plan if nobody had told it where the pits were?
>
> <details><summary>Back from the game: what you just saw</summary>It could not. Every sweep read the rules: where each move lands and what it pays. Without them you find the pits the way the island's Tracers found the cliff, by falling in, which is what the learning methods from lecture 4 on do. And 25 pads is tiny. A real match has far too many states for even one sweep. <em>In an agent:</em> A language-model agent can think a tool call through only when it has a model of what the tool will do. Without one, it has to make the call and find out.</details>

**On the island:** SARSA, Q-LEARNING and the rest do sample backups from real runs, and pay in falls: Q-learning fell 26.5 times per 100 training episodes. With discount 1 the contraction slide does not apply as written; convergence rests on every episode ending (not from the lecture).

## What the island measured for this lecture

Hand one bot the rulebook and leave the other to wander, and you know who wins before anyone moves. You might also expect the winner's perfect record to prove something grander: that planning is tough, and holds up when things go wrong.

The first part came true. PLANNER stood still for 13 sweeps, then reached the goal in her first episode of every run and scored the maximum, 39. RANDOM WALK fell in 97.4 of every 100 episodes. (Neither bot was in a planned comparison. The only planned one was SARSA against Q-learning on falls, so this table is description, not a test.)

| Bot | Runs | Falls per 100 training episodes (95% interval) | Mean return, first 40 / last 40 | Clean test runs | Steps per episode |
|---|---|---|---|---|---|
| PLANNER | 10 | 0.0 (0.0 to 0.0) | 39.0 / 39.0 | 10/10 | 11.0 |
| RANDOM WALK | 11 | 97.4 (96.9 to 97.9) | -111.3 / -113.3 | n/a | 14.9 |

The second part is the one to be careful with. Her interval of 0.0 to 0.0 says she is deterministic: she does the same thing every time. It does not say planning is robust. Her rules had no slips in them, while the game slipped 0.21 times per 1,000 steps, so she was never once handed a wrong rulebook and made to cope.

She was never tested. She was just right.

The quieter result sits in the wanderer's row. The same arithmetic, run on the random policy instead of the best one, says the start square is worth -114.4. RANDOM WALK, who never saw that sum, averaged -112.7 (standard error 0.46). Sums done on a whiteboard predicted a bot that blinks at random, to within 1.7.

That 1.7 is still several standard errors (my arithmetic), so it is probably not luck. the island fact sheet does not explain it. One candidate is that the exact sum ignores the 100-step limit, which the real strip enforces.

Those exact values had one more job. They became lecture 4's answer key, the yardstick for bots that have to learn the same numbers from experience. After 200 episodes the Monte Carlo table's typical error was 15.3, and the TD table's, with step 0.1, was 85.6.

## Guess first

<details><summary>PLANNER has every rule written down before she moves, and the best route is eleven steps. Does one sweep over the board finish her sums, or does she need more than ten?</summary>
More than ten: 13. Her biggest change per sweep was 101, then 49 ten times, 48, then 0.00. A sweep lets each square see only as far as its neighbours' current values. The +50 reached the squares beside the goal in sweep one and moved back one column per sweep, so the start, eleven columns away, waited its turn. The last sweep changes nothing, which is how she knows to stop. That is value iteration's news travelling backwards.
</details>

<details><summary>A Tracer blinks in a random direction every step. Would you rather she start beside the cliff, or in the far inland corner, in the back row, as far from the drop as the strip goes?</summary>
Beside the cliff. Under the random policy the inland corner is worth -135.5, against -114.4 at the start. Distance from the edge does not save a random walker. She just pays -1 a step for longer, then falls anyway. Those numbers are each square's exact value under her policy, worked out from the rules alone.
</details>

<details><summary>(With lecture 2) You want RANDOM WALK's exact values. On each square, do you take the best move's look ahead, or the average over all four of her moves?</summary>
The average. That is the Bellman expectation equation, which weighs each move by how often she makes it, a quarter of the time each. Take the best move instead (the optimality equation, the one with the max) and you get 39 from the start. That is PLANNER's number. It describes a bot who plays perfectly, not one moving at random.
</details>

<details><summary>(With lecture 1) PLANNER read the rulebook first. Q-LEARNING learned by falling off. Both end up crossing. Which one solved the reinforcement learning problem as lecture 1 defined it?</summary>
Q-LEARNING. Lecture 1 split planning, where the model is given, from reinforcement learning, where the world is unknown and you learn by interacting with it. PLANNER was handed the model, so her clean record says nothing about a world whose rules nobody wrote down. Q-LEARNING paid for what she knows in falls, 26.5 per 100 training episodes.
</details>

<details><summary>In Silver's small gridworld, the greedy moves were already the best ones after three sweeps. Stop PLANNER after 6 of her 13 sweeps and make her walk. Does she cross cleanly from the start?</summary>
Probably not, though nobody ran it. News of the goal moves back one column per sweep, so after 6 sweeps the squares near the start have not heard of it yet, and their choices rest on step costs alone. The start is eleven columns out. (The gridworld got off lightly: no square there is more than three steps from a finishing corner.) That is the risk of acting greedily on a half-finished table.
</details>

<details><summary>(With lecture 2) Rewrite PLANNER's rulebook so that one step in ten slips sideways at random. The best route was eleven steps along the drop. Does she still take it?</summary>
Probably not, though this was not run either. Value iteration copes with chance as it is: the sum over next states just gains terms. But with -100 waiting below, every edge step now carries some risk of a fall, and she takes eleven of them. The route would likely move inland. A slippery world is still an MDP, lecture 2's model; its chances are just no longer all 0 or 1.
</details>

## Cards

- Q: "Programming" in dynamic programming means? | A: Optimising a plan (a policy), as in linear programming, not writing code.
- Q: The two properties DP needs? | A: Optimal substructure and overlapping subproblems.
- Q: Planning versus reinforcement learning? | A: Planning is given the MDP's rules; RL must learn from interaction.
- Q: Iterative policy evaluation? | A: Repeatedly replace each value by the policy-weighted look-ahead until values settle.
- Q: Policy iteration in one line? | A: Evaluate, act greedily, repeat; it converges to an optimal policy.
- Q: Value iteration versus modified policy iteration? | A: Value iteration is modified policy iteration with one evaluation sweep (k = 1).
- Q: PLANNER's sweeps, and why so many? | A: 13; the goal's news moved back one column per sweep.
- Q: Full-width versus sample backup? | A: Full width uses the model and every branch; a sample backup uses one real transition.

## In language-model terms

Picture a model that reads a conversation, calls tools, and is scored on tau-bench, where a simulated customer makes a request and a database answers. To plan in Silver's sense, you would need the full transition table: for every conversation and every reply, the chance of each next customer message and database state.

You will not get that table. The customer is itself a language model, so full-width DP fails for Silver's reason (1:36:30): not one backup is affordable.

What does carry over is the shape of policy iteration, the VOD loop. Teams run a fixed agent (prompt, model, tools) many times, change it toward what scored best, and evaluate again. But the evaluation is by samples (lecture 4), and the improvement theorem does not come along: it needs exact evaluation and a greedy change in every state, and a prompt edit is neither.

A learned scorer of partial conversations (a reward model or verifier) is a fair analogy for the value function as a cache: it stores how a conversation usually ends from here. Only an analogy, though. Nothing makes it a Bellman fixed point.

The mapping breaks hardest on the state. DP assumes you can name it. In tau-bench, the thing that matters most, what the customer actually wants, is not in the transcript yet.

## The thread to partial observability

Every sum in this lecture starts from the same sentence: you are on this square. Not roughly here, not probably here. Here, with the whole rulebook for here written down.

That is a bigger assumption than it looks. The principle of optimality says a best plan is a best first move, then a best plan from wherever you land. "From wherever you land" only works if the square you land on summarises everything that matters about what comes next. If two different situations look like the same square, a plan that reads only the square must do the same thing in both, even when they need different moves.

The row-only bot already paid for this. Told only her row, she could not tell forward from back, and dithered along the edge for 47.1 steps an episode against 18.6 for the full table.

Lesson 11 breaks it on purpose. Before each episode one square on the runner's way is shut, and nobody tells her which (on the usual strip, a square at column 6, in the edge row or the second row). Now her next square depends on something she may not be told, and three Q-learning runners differ only in how much of it they get.

On the short strip, with no way round, BLIND reached the goal in 52% of her test crossings, REMEMBERS BUMPS in 90%, SEES THE WALL in 94%. One remembered bump was a real difference by the rule set in advance: 38 points, with a 95% interval of 10 to 66. Seeing on top of remembering is not yet conclusive, and on the long strip, where she can go round, no gap was established. In a simulation by the rules alone, going from 200 training episodes to 1,000 did nothing for the blind runner on the short strip: 47%, then 48%.

She did not lack practice. She lacked a state.

More sweeps would not have saved her either. A value function is a cache keyed by state, and it is only as good as that state. The standard fix, which this lecture does not cover, is to plan over beliefs instead: her guess about which square is shut, updated by bumps. Lesson 11's game, Sombra's Room, runs value iteration over beliefs for two rooms, and its best plan is to ping while you are between 6% and 94% sure and walk in outside that.

## Experiments the lecture asks for that the island has not run

- Sweep goal-first, in place, and count sweeps against the measured 13.
- Run synchronous value iteration (two tables) beside in-place and compare sweep counts.
- Policy iteration from the random policy, checking whether one greedy round already gives the edge route, as in the gridworld.
- Give PLANNER a slip model (one step in ten random) and see whether her route moves inland, then walk it.
- Real-time DP: back up only squares a walking bot visits, and count backups to a clean crossing.
