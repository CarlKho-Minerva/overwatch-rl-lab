# Lecture 3: Planning by Dynamic Programming

*David Silver's lecture 3 (UCL, 2015), gone through in his order and re-explained with the Tracer experiments on Workshop Island. The lecture and its slides are his: [video](https://www.youtube.com/watch?v=Nd1-UUMVfz4), [course page](https://davidstarsilver.wordpress.com/teaching/). The words below are a re-explanation. Every island number comes from the logged runs in this repository.*

In this lecture's game you stand over a board of 25 pads before the round begins, with the rules already written beside it: each step costs 1, the goal pays 10, and falling into a pit costs 10 and ends the run. On the island, where almost every Tracer found the cliff by walking off it, PLANNER was handed the rules of her strip in the same way (where each move leads, what it pays), stood still while she did the arithmetic, then walked the eleven-step edge route in all 10 of her runs without a fall. The question for this hour is what that arithmetic is. The answer: given the full rules of a world, you can compute exactly how good any way of behaving is, and the best one, by repeating the Bellman equation from lecture 2 (a place is worth one step's reward plus the worth of where you land) as an update until the numbers stop moving.

**Two windows:** this page, and [Game 3: The Whiteboard](../workshop/games/g03.md), an Overwatch custom game for this lecture (paste `workshop/compiled/game-03.txt` into a custom game's settings and start it). The game opens at stop 1 and waits. Read down this page; at each box marked Alt+Tab, switch to the game, do that stop, and switch back. The game never moves on while you read.

## The lecture in order

### [02:26](https://www.youtube.com/watch?v=Nd1-UUMVfz4&t=146s) Dynamic programming optimises a step-by-step plan by reusing answers to smaller problems
Suppose you already know the shortest way from the middle of a room to the far wall. Every longer walk through the middle can reuse that answer. This hour is built on that kind of reuse.

Silver starts with the name. "Dynamic" means the problem unfolds in steps. "Programming" is meant in the mathematical sense, as in linear programming: optimising a plan. For us the plan is the rule for choosing an action in each state (each situation you can be in), called a policy.

The method needs two properties. The first is that the best whole is built from best pieces, which he calls optimal substructure: the shortest path to the wall is the shortest path to a midpoint plus the shortest path on from there. The second is that the pieces recur, which he calls overlapping subproblems, so you solve each once and store it.

Lecture 2's model of a world (states, actions, chances, rewards, discount), called a Markov decision process or MDP, has both. The Bellman equation splits the problem into one step and the rest. The value function, the table of total reward to expect from each state, stores the answers, "like a cache of all the good information".

**On the island:** the best way to the goal from a given square is a subproblem that every route through that square reuses. PLANNER stores one answer per square and never searches whole routes.

### [08:08](https://www.youtube.com/watch?v=Nd1-UUMVfz4&t=488s) Planning: the rules are given, and you want to score one policy or find the best one
Planning is what you can do when someone hands you the rules of a world before you take a step in it: where each action leads and what it pays. Silver stresses that this is not full reinforcement learning. It is like being handed an Atari game's source code instead of its screen. The written rules are the MDP itself (lecture 2's model: states, actions, chances, rewards, discount).

With the rules in hand there are two questions. The first takes the rules and one fixed way of choosing actions, a policy, and asks how much total reward to expect from each state under it. That table of expected totals is the policy's value function, and the question is called prediction.

The second takes only the rules. It asks for the most reward any policy can earn from each state, the optimal values, and for a policy that earns it, an optimal policy. This question is called control.

What a single look ahead at the rules can tell one square is the first thing to try in the game.

> **Alt+Tab · game 3 · stop 1 of 7: Read the rules, call the first number**
>
> **What he just said:** Planning means someone hands you the rules of the world, where each move leads and what it pays, so the only job left is to work out what to do.
>
> **In the game:** The board is 25 pads on the floor, all showing 0, with the rules in the orange row on the left. Answer the question floating in front of you with LEFT CLICK, RIGHT CLICK or MELEE, then press F to run sweep 1.
>
> **Before you press:** After one sweep, what number will the pad right next to the goal show?
>
> <details><summary>Back from the game: what you just saw</summary>The three pads beside the goal jumped to 9 and every other pad to -1. In one sweep each pad looks one step ahead: the step costs 1, and only a pad next to the goal can see its 10. That one-step look ahead is lecture 2's Bellman rule, used here as an update because the rules are known in advance. <em>In an agent:</em> An agent that knows exactly what a tool returns can score a call before making it, the way a pad scores a move before taking it.</details>

**On the island:** both were answered from the written rules. Prediction: the policy that picks every move with equal chance (the uniform random policy) is worth exactly -114.4 from the start square. Control: PLANNER's table and her greedy walk, which takes the best-looking move at each square, gave a return (total reward) of 39, the best possible.

### [13:07](https://www.youtube.com/watch?v=Nd1-UUMVfz4&t=787s) Policy evaluation: score a fixed policy by repeating one look-ahead over every state
To find out how good a fixed way of behaving is, start every state at a guess of zero and keep correcting the guesses, one look ahead at a time. Silver calls this policy evaluation, and it answers the prediction question from the last part.

Pass over all the states and replace each one's value with a one-step look-ahead: the average, over the actions the policy (the rule being scored) might take and over where the world might send you, of the reward plus your current guess for the next state. One pass over every state is called a sweep. Repeat the sweeps, and the numbers settle on the policy's true values, which Silver asks you to take on trust for now.

The look-ahead is lecture 2's Bellman expectation equation (a state's value is the average of reward plus next value), used as an update. Each new table is computed whole from the old one, which is called a synchronous sweep.

`v_{k+1}(s) = sum_a pi(a|s) * ( R(s,a) + gamma * sum_s' P(s'|s,a) * v_k(s') )`
In words: the new value is the policy's average of reward now plus the discounted old value of the next state (gamma is the discount, which shrinks later reward, and P is the chance of each next state).

**On the island:** the random policy's exact values come from this update. Each square averages, over four moves taken a quarter of the time each, -1 plus the next square's value, with -100 for a fall. The discount is 1.

### [19:28](https://www.youtube.com/watch?v=Nd1-UUMVfz4&t=1168s) The small gridworld: a random walk's values, and a better policy for free
Silver's first worked example is a walker who moves at random on a small board. The useful surprise is that scoring her aimless walk also shows how to walk well.

The board is a 4 by 4 grid. Two of its corners are squares where the run ends, called terminal squares. Every step earns -1, and the walker picks one of four directions at random.

Every value starts at zero. One pass of look-aheads over every square (one sweep) gives -1 everywhere but the corners. The second sweep gives -2 in the middle and -1.75 beside a corner. Once the values have converged, meaning more sweeps no longer change them, they read as expected steps to finish, up to 22 on the slide.

The slide has a second column. At each stage it picks, on every square, the move that looks best under the current numbers, which is called acting greedily. After three sweeps that greedy policy (rule for choosing moves) is already optimal, long before the values converge.

The game shows next how fast news of a goal reaches a distant square.

> **Alt+Tab · game 3 · stop 2 of 7: Watch the good news spread**
>
> **What he just said:** In his small gridworld the value of a square (the total reward you can expect from it) is found by sweeping over every square again and again, and the numbers fill in a little more each time.
>
> **In the game:** Answer the question, then press F for sweep 2 and watch which pads turn yellow.
>
> **Before you press:** On which sweep will your own start pad, the blue ring, first turn positive?
>
> <details><summary>Back from the game: what you just saw</summary>Yellow marks the pads that just heard about the goal: a new ring of them each sweep, one pad further out. Each pad reads only its neighbours' numbers from the sweep before, so news travels one step per sweep. Your start pad is 5 steps from the goal, so it turns positive on sweep 5, which you will see in stop 4.</details>

**On the island:** the strip is this grid with a cliff. The exact values under the random policy are -114.4 at the start and -135.5 at the far inland corner, which is worse because she wanders longer and then falls anyway. RANDOM WALK actually averaged -112.7 (standard error 0.46) over 2,308 episodes of 14.9 steps, and reached the goal by luck in 1.0% of them.

### [29:41](https://www.youtube.com/watch?v=Nd1-UUMVfz4&t=1781s) Policy iteration: score the policy, switch to the best-looking moves, repeat until nothing changes
Once you can score a way of behaving, you can improve it: switch to the moves the scores favour, score the new behaviour, and go round again. Silver makes that loop the lecture's first complete method for control, the question of which policy (rule for choosing an action in each state) is best.

Each round has two steps. First evaluate the current policy: work out its value in every state, as in the last two parts. Then improve it by taking, in every state, the action with the best look-ahead under those values, which is acting greedily. Repeat until nothing changes. The loop is called policy iteration, and Silver says it reaches the optimal policy from any start.

His example is Jack's Car Rental (a problem from Sutton and Barto's textbook; that attribution is not from the lecture). Jack has two lots of up to 20 cars each. Rentals and returns arrive at random, in numbers described by a standard formula called the Poisson distribution. Up to five cars can be moved between the lots overnight, and each rental earns $10. Starting from a policy of moving nothing, the policy stops changing after about four rounds.

**On the island:** policy iteration was not run on the island. PLANNER used value iteration, which comes later in this lecture. The experiment would evaluate the random policy exactly, act greedily, and count the rounds until the arrows stop changing.

### [46:02](https://www.youtube.com/watch?v=Nd1-UUMVfz4&t=2762s) Why acting greedily can never make things worse
Switching, in every state, to the move that looks best under your current scores can never leave you worse off. The loop in the last part depends on that, so Silver stops to show why.

His score covers a state and an action together: the value of taking that action now, then following the old policy (the old rule for choosing actions), written pi. This score is written q and called the action value. The new policy picks in each state the action with the highest q, and it is called the greedy policy, written pi'. The highest q cannot be lower than the q of pi's own action, so one greedy step followed by pi is at least as good as pi alone.

`q_pi(s, pi'(s)) = max_a q_pi(s, a) >= q_pi(s, pi(s)) = v_pi(s)`
In words: the best-looking action, then the old policy, is worth at least the old policy, in every state.

Unroll the same argument step by step, and pi' is at least as good as pi everywhere. If improvement stops, the values satisfy lecture 2's Bellman optimality equation (a state is worth its best action's look-ahead), so the policy is optimal.

Greedy is not short-sighted. It "doesn't mean that we only look at one step of immediate reward", because the next state's value sums the whole future.

**On the island:** the +50 is eleven steps from the start, yet one-step greedy choices get PLANNER there, because her values already carry the news of the goal.

### [58:40](https://www.youtube.com/watch?v=Nd1-UUMVfz4&t=3520s) You need not finish evaluating before you improve
Rough scores can point to the same moves as exact ones, so you need not finish scoring a policy before you act on the scores. Silver returns to the small gridworld. There, everything after the third pass over the squares (the third sweep) changed nothing about the greedy policy, the one that takes the best-looking move on each square. He describes "iterations 4 to infinity of our inner loop as being wasted work".

Stopping the evaluation early is called modified policy iteration. You can stop once the values change by less than a small tolerance, written epsilon, or after a fixed number of sweeps, written k. Either way the method still converges, which means it still settles on the best policy.

The extreme case is k equal to 1: one sweep of evaluation, then improve at once. That is value iteration, which Silver calls probably the most popular dynamic programming method.

**On the island:** PLANNER uses the tolerance rule. She sweeps until the largest change in a sweep is under 0.001.

### [1:01:50](https://www.youtube.com/watch?v=Nd1-UUMVfz4&t=3710s) The principle of optimality: a best plan is a best first move, then a best plan from wherever you land
A best plan is a best first move followed by a best plan from wherever that move lands you. That is what lets a large problem be cut into one step and the rest. Silver calls it the principle of optimality, and he returns to it here because the next method is built on it.

In the lecture's terms the plan is a policy (a rule for choosing an action in each state): an optimal policy is an optimal first action followed by an optimal policy from wherever you land.

The theorem makes this exact. A policy is optimal from a state if and only if it is optimal from every state that can be reached from it. States that cannot be reached have zero probability, so they drop out of the calculation.

**On the island:** the edge route is optimal from the start because it is optimal from every edge square it passes. The row-only bot, told only her row, cannot tell forward from back: 47.1 steps per episode against 18.6 for the full table.

### [1:03:45](https://www.youtube.com/watch?v=Nd1-UUMVfz4&t=3825s) Value iteration: work backwards from the end, without knowing where the end is
If you already knew what every neighbouring square was worth under best play (its optimal value), one look ahead would give your own square's worth: the best move's reward plus the value of where it leads. Value iteration applies that look-ahead with a max to every state, repeatedly, from any starting numbers.

`v_{k+1}(s) = max_a ( R(s,a) + gamma * sum_s' P(s'|s,a) * v_k(s') )`
In words: new value equals the best action's reward plus the discounted old value of where it leads.

In his shortest-path grid the right values spread one step outward with each pass over the squares (each sweep), until the far corner reads -6 at the seventh table. It looks like working backwards from the goal, yet the method never needs to know where the goal is, so it handles loops, randomness and no goal at all.

It keeps no explicit policy (no stored rule for choosing actions), and a midway table "might not be the value for any real policy". The game tests that claim, and then asks how you know when to stop.

> **Alt+Tab · game 3 · stop 3 of 7: Judge a half-finished board**
>
> **What he just said:** Value iteration (sweep, keep the best move's number, sweep again) ends at the best values, but a table halfway through need not be the score of any real plan.
>
> **In the game:** The board now shows sweep 2. Answer the question, then press F for sweep 3.
>
> **Before you press:** Is there one plan, one fixed choice of step on every pad, whose scores are exactly the numbers on the board right now?
>
> <details><summary>Back from the game: what you just saw</summary>No plan scores these numbers. A pad showing -2 whose neighbours all show -2 would score -3 under any plan, because every step costs 1 and lands on a -2. The midway numbers are unfinished sums: two steps of cost counted, the goal not yet seen. Only the settled table is the value of a plan.</details>

> **Alt+Tab · game 3 · stop 4 of 7: Sweep until nothing moves**
>
> **What he just said:** In his shortest-path grid the far corner needed one sweep for every step of distance before its number was right, and the method stops once a whole sweep changes nothing.
>
> **In the game:** Answer the question, then keep pressing F, one sweep per press, until the panel on the right says 0 pads changed. Green lines then appear on the pads.
>
> **Before you press:** Which sweep will be the first that changes nothing at all?
>
> <details><summary>Back from the game: what you just saw</summary>The farthest pad got its final number on sweep 7, and sweep 8 changed nothing, which is the only way to know you are done. The green lines are the plan: on each pad, the step toward the best number next door. Choosing that way is called acting greedily, or policy improvement. Eight sweeps of 22 pads and 4 moves came to 704 look-aheads.</details>

**On the island:** PLANNER settled in 13 sweeps. The largest change in each sweep was 101, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 48, 0.00. The 101 is a fall plus one step (stepping off is worth -101). After that, good news travels back one column per sweep, so the biggest change stays nearly level. The last sweep changes nothing and ends the loop.

### [1:24:03](https://www.youtube.com/watch?v=Nd1-UUMVfz4&t=5043s) The summary slide, and what a sweep costs
The whole lecture so far fits on one slide: two questions, and the equation each method repeats to answer them. Silver says "if you get this slide, you're doing well".

Prediction asks how good a given policy (a fixed rule for choosing actions) is. Its equation is the Bellman expectation equation, the averaging look-ahead, and repeating it gives iterative policy evaluation.

Control asks for the best policy, and there are two routes. Policy iteration alternates that same expectation equation with greedy improvement, the switch to the best-looking action in every state. Value iteration repeats the Bellman optimality equation, the look-ahead with a max. Modified policy iteration, which cuts the evaluation short, lies between them.

Then the cost. With n states and m actions, a sweep (one pass over every state) costs on the order of m times n squared.

`cost per sweep = O(m * n^2)`
In words: every state checks every action against every possible next state.

Run on action values (a score for each state and action together), a sweep costs m squared times n squared. The game now checks prediction directly: whether a walk along the finished plan earns the number on its first square.

> **Alt+Tab · game 3 · stop 5 of 7: Walk the plan yourself**
>
> **What he just said:** His summary splits planning in two: prediction finds how good a given plan is, control finds the best plan, and every sweep costs each state times each move.
>
> **In the game:** Answer the question, then walk with WASD along the green lines from the blue ring to the green goal ring. Each pad you enter costs 1 and the goal pays 10.
>
> **Before you press:** Your start pad shows 5. If you follow the lines, what will you score?
>
> <details><summary>Back from the game: what you just saw</summary>Following the lines scores 5: five pads at -1 each, plus 10 at the goal. That is the start pad's number exactly, because a pad's number is what the plan earns from there. Checking what a plan earns is called policy evaluation. If you wandered off the lines, the score on the left came out lower than the pad said. <em>In an agent:</em> A score for a half-finished conversation, such as a reward model's, plays the same part as the pad's number, though nothing makes it this exact.</details>

**On the island:** the strip has 47 non-goal squares, 4 moves, and one next square per move. A sweep is instant, which is why PLANNER could be exact.

### [1:29:03](https://www.youtube.com/watch?v=Nd1-UUMVfz4&t=5343s) Asynchronous dynamic programming: update single states, in a good order
You do not have to update every state on every pass. States can be updated one at a time, in any order, and the values still converge (settle on the right answer) as long as every state keeps being picked. Silver calls this asynchronous dynamic programming, and he gives three versions of it.

The first keeps one table and always uses the newest values in it. This is in-place dynamic programming, and with it the order matters. A corridor swept from the goal back to the start is solved in one pass over its squares (one sweep), because each square reads a neighbour that has just been corrected. Swept the other way, it gains nothing: "the ordering really matters".

The second chooses the order on purpose. It first updates the state whose value would change the most. The size of that change is called the Bellman error, and the method is called prioritised sweeping.

The third updates only the states the agent actually visits, and is called real-time dynamic programming. How much of a finished plan changes when one piece of the rules moves is what the game tests here.

> **Alt+Tab · game 3 · stop 6 of 7: Move a pit, then plan again**
>
> **What he just said:** You need not sweep every state every time: updating single states, in a good order or first where the numbers would change most, still reaches the same answer.
>
> **In the game:** Walk to any pad and press R: the pit marked THIS PIT MOVES jumps there. Answer the question, then press F; the board is wiped and the sweeps run by themselves.
>
> **Before you press:** How many of the old green lines are no longer the best step once the pit has moved?
>
> <details><summary>Back from the game: what you just saw</summary>Only pads whose best route ran past the new pit change their minds, and their lines turn yellow. A pit on the pad just ahead of the start flips 5 lines; a pit where no best route passes flips none. The game wiped the board and swept all of it again, yet most settled numbers came back the same. Updating first the pads that would move most is what Silver calls prioritised sweeping.</details>

**On the island:** PLANNER updates in place. Her one column per sweep fits an order that does not run goal-first. the island fact sheet does not record her order, so a reversed sweep is untested.

### [1:36:30](https://www.youtube.com/watch?v=Nd1-UUMVfz4&t=5790s) An update that checks every branch needs the full rules; an update from one real step does not
Every update in this lecture looked at everything that could happen next: every action, every next state, each with its known probability. Silver calls an update a backup: value is passed back from the next states to this one. A backup that covers every branch is a full-width backup.

That is costly, and it needs the model (the written rules). The cost has a name, the curse of dimensionality: the number of states multiplies with each variable that describes the world. At 10 to the 170 states not even one backup fits.

Later lectures learn from single real steps instead: take one action, observe one transition, make one update. These are called sample backups. Their cost does not depend on the number of states, and they need no model.

Silver leaves to the slides the proof that all of this settles on one answer. Measured by the largest gap in any state, each backup brings two value tables at least a factor of gamma (the discount) closer, so they converge to one unique fixed point, the table a backup leaves unchanged.

`||T(u) - T(v)||_inf <= gamma * ||u - v||_inf`
In words: a Bellman backup T shrinks the worst-state gap between any two guesses by at least gamma.

> **Alt+Tab · game 3 · stop 7 of 7: Read the debrief**
>
> **What he just said:** Every update here used the full rules and every branch, which is costly and needs a model of the world, and later lectures learn from single real steps instead.
>
> **In the game:** Nothing to press. Read the three lines on the left: what you did, what it is called, and where it shows up in a language-model agent.
>
> **Before you press:** Could this planner have found the plan if nobody had told it where the pits were?
>
> <details><summary>Back from the game: what you just saw</summary>It could not. Every sweep read the rules: where each move lands and what it pays. Without them a player has to walk and fall to find out, which is what the learning methods from lecture 4 on do. The board was also tiny at 25 pads, where a real match has far too many states for even one sweep. <em>In an agent:</em> A language-model agent can think a tool call through only when it has a model of what the tool will do; without one it has to make the call and learn from the result.</details>

**On the island:** SARSA, Q-LEARNING and the rest do sample backups from real runs, and pay in falls: Q-learning fell 26.5 times per 100 training episodes. With discount 1 the contraction slide does not apply as written; convergence rests on every episode ending (not from the lecture).

## What the island measured for this lecture

| Bot | Runs | Falls per 100 training episodes (95% interval) | Mean return, first 40 / last 40 | Clean test runs | Steps per episode |
|---|---|---|---|---|---|
| PLANNER | 10 | 0.0 (0.0 to 0.0) | 39.0 / 39.0 | 10/10 | 11.0 |
| RANDOM WALK | 11 | 97.4 (96.9 to 97.9) | -111.3 / -113.3 | n/a | 14.9 |

Neither bot was in a planned comparison (the only planned one was SARSA against Q-learning on falls), so this is description. PLANNER took 13 sweeps, reached the goal in her first episode every run, and scored the maximum. Her 0.0 to 0.0 interval shows she is deterministic, not that planning is robust: her rules had no slips, while the game slipped 0.21 times per 1,000 steps, so a wrong model was never tested. For prediction, DP says the start is worth -114.4 under the random policy; RANDOM WALK averaged -112.7 (standard error 0.46). The gap of 1.7 is several standard errors (my arithmetic), so probably not luck; the island fact sheet does not explain it, and one candidate is that the exact sum ignores the 100-step limit. The exact values also became lecture 4's yardstick (Monte Carlo table error 15.3 after 200 episodes, TD step 0.1 at 85.6).

## Guess first

<details><summary>PLANNER's biggest change per sweep was 101, then 49 ten times, 48, then 0.00. Why 13 sweeps and not 1?</summary>
A sweep lets each square see only as far as its neighbours' current values. The +50 reached the squares beside the goal in sweep one and moved back one column per sweep, so the start, eleven columns away, waited. The last sweep only confirms nothing changed.
</details>

<details><summary>Under the random policy, which is worse: the start, beside the cliff, or the far inland corner?</summary>
The inland corner: -135.5 against -114.4. Distance from the edge does not save a random walker. She just pays -1 a step for longer, then falls.
</details>

<details><summary>(With lecture 2) To get RANDOM WALK's exact values, which Bellman equation do you iterate?</summary>
The expectation equation, which averages over the random policy's moves. Iterating the optimality equation (the max) gives the best policy's values, 39 from the start, which describe PLANNER, not a bot moving at random.
</details>

<details><summary>(With lecture 1) PLANNER and Q-LEARNING both end up crossing. Which solved the reinforcement learning problem as lecture 1 defined it?</summary>
Q-LEARNING. Lecture 1 split planning (model given) from reinforcement learning (environment unknown, learn by interacting). PLANNER was handed the model, so her result says nothing about a world whose rules nobody wrote down.
</details>

<details><summary>In the gridworld, greedy after three sweeps was already optimal. Would PLANNER's table after 6 sweeps give a clean walk from the start?</summary>
Probably not; not run. With news moving one column per sweep, squares near the start have not seen the goal after 6 sweeps, so their choices rest on step costs alone.
</details>

<details><summary>(With lecture 2) If PLANNER's rules said one step in ten slips sideways at random, would her best route still hug the edge?</summary>
Not run. Value iteration handles randomness as is (the sum over next states gains terms). With -100 waiting, each edge step would risk a fall, so the route would likely move inland.
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

Take a model that reads a conversation, calls tools and is scored on tau-bench, where a simulated customer makes a request and a database answers. Planning would need the full transition table: for every conversation and reply, the chance of each next customer message and database state. The customer is itself a language model, so full-width DP fails for Silver's reason at 1:36:30: not one backup is affordable.

What carries over is the shape of policy iteration. Teams run a fixed agent (prompt, model, tools) many times, change it toward what scored best, and evaluate again. But evaluation is by samples (lecture 4), and the improvement theorem does not transfer: it needs exact evaluation and a greedy change in every state, and a prompt edit is neither.

A learned scorer of partial conversations (a reward model or verifier) is a fair analogy for the value function as a cache: it stores how a conversation usually ends from here. Only an analogy: nothing makes it a Bellman fixed point. The mapping breaks hardest on the state: DP assumes you can name it, and in tau-bench what matters most, what the customer actually wants, is not yet in the transcript.

## The thread to partial observability

This lecture assumes the agent knows its state and the whole model. The principle of optimality depends on it: behaving optimally from the next state only makes sense if that state summarises everything that matters. The row-only bot shows the cost of a state that does not (47.1 steps per episode, unable to tell forward from back). In the hidden-wall build, running now, a square at column 6 is shut at random each episode, so the next square depends on something the runner is not told. A planner there would plan over beliefs (her guess about which square is shut, updated by bumps), the standard extension of value iteration (not from the lecture). Carry forward: a value function is a cache keyed by state, and is only as good as that state.

## Experiments the lecture asks for that the island has not run

- Sweep goal-first, in place, and count sweeps against the measured 13.
- Run synchronous value iteration (two tables) beside in-place and compare sweep counts.
- Policy iteration from the random policy, checking whether one greedy round already gives the edge route, as in the gridworld.
- Give PLANNER a slip model (one step in ten random) and see whether her route moves inland, then walk it.
- Real-time DP: back up only squares a walking bot visits, and count backups to a clean crossing.
