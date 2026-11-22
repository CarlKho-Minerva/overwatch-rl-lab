# Lecture 2: Markov Decision Processes

*David Silver's lecture 2 (UCL, 2015), gone through in his order and re-explained with the Tracer experiments on Workshop Island. The lecture and its slides are his: [video](https://www.youtube.com/watch?v=lfHX2hHRMVQ), [course page](https://davidstarsilver.wordpress.com/teaching/). The words below are a re-explanation. Every island number comes from the logged runs in this repository.*

Tracer stands on a row of pads with a small health pack three pads behind her and a large one ten pads ahead, and she has to choose which to walk to. Silver's second lecture gives the form for writing a choice like that down, called the Markov decision process, and then puts a question that has an exact answer: how many points each place is worth, under a given way of moving and under the best one. On the island the question was put to a strip of 48 squares beside a drop, where a bot picks one of four moves and is told where she landed and what it cost. A random walker's start square is worth -114.4 on paper and she averaged -112.7 in play; under the best policy (the rule for choosing moves) it is worth 39, which the PLANNER computed in 13 sweeps and then walked without a fall.

**Two windows:** this page, and [Game 2: Mini or Mega](../workshop/games/g02.md), an Overwatch custom game for this lecture (paste `workshop/compiled/game-02.txt` into a custom game's settings and start it). The game opens at stop 1 and waits. Read down this page; at each box marked Alt+Tab, switch to the game, do that stop, and switch back. The game never moves on while you read.

## The lecture in order

### [00:50](https://www.youtube.com/watch?v=lfHX2hHRMVQ&t=50s) A Markov decision process describes the world, not the learner
Before anyone can get good at a game, somebody has to say what the game is: which places exist, which moves are allowed, where each move lands, and what each step pays. Silver opens with the form for writing that down. It is called the Markov decision process, MDP for short. In last week's picture of a learner that picks moves (the agent) facing a world that answers (the environment), the MDP belongs to the environment's side.

He starts with what he calls the "nice case". The agent is told the full situation of the world right now, which is called the state, and nothing is hidden from it. A world like that is called fully observable.

He then claims that almost every problem in the field fits this one form, and names three that might seem not to. Control problems where the moves vary smoothly instead of coming from a short list (continuous control) fit. So do problems where the agent sees only part of the state (partially observable problems), and problems where you pick one move, collect one reward, and the task is over. Those last are called bandits, and a bandit is an MDP with a single state.

**On the island:** Here is the strip in full. The states (places) are 48 squares (4 rows, 12 columns), with two endings, the goal at the right end of row 0 and the drop. The actions (moves) are forward, back, inland and toward the edge. The transitions (where a move lands): one square that way; off the grid on the left, right or inland, she stays put; toward the edge from row 0, she falls. The rewards (what a step pays) are -1 per step, +50 at the goal, -100 for a fall, and -50 if 100 steps pass. The discount is 1, so a late reward counts as much as an early one. Each bot is told her square after every move.

### [03:26](https://www.youtube.com/watch?v=lfHX2hHRMVQ&t=206s) The Markov property: the present is enough
Some snapshots of the present are complete enough that the story of how you got there adds nothing. Silver's sentence for this is "the future is independent of the past given the present." A state (the situation the world is in right now) with that quality is called Markov: once you know it, the rest of the history does not help you predict what comes next. `P[S(t+1) | S(t)] = P[S(t+1) | S(1), ..., S(t)]`. In words: adding the whole past to the present state does not change the odds of the next state.

This has a practical use. If the current state settles the odds of what follows, then one number for each pair of states describes the whole world: the chance of going from the first state to the second, called the transition probability. Put those numbers in a table with one row for each starting state and you have the transition matrix. A row lists every place you could land from one state, so each row sums to 1.

**On the island:** A square and a move together fix the next square. There were 0.21 slips (steps that missed their target) per 1,000 steps, so the table is nearly all zeros and ones. Q, ROW ONLY, the bot told only her row, does not have a Markov state (see Guess first).

### [07:28](https://www.youtube.com/watch?v=lfHX2hHRMVQ&t=448s) The student chain, and a clock folded into the state
The simplest world you can write down this way has nobody choosing and nothing being scored. It only drifts from one situation (state) to the next by chance, so all it needs is the list of states and the table of chances between them (the transition matrix). Silver calls this a Markov process, or a Markov chain. `<S, P>`. In words: a Markov process is just the list of states and the table of moves between them.

His example is a cartoon student, who drifts between three classes, Facebook, the Pub, Pass and Sleep. Facebook leads straight back to Facebook with chance 0.9 (a self-loop). Sleep is where a run stops, which makes it a terminal state, and he draws it as a state that loops on itself forever. One random run from start to finish, such as C1 C2 C3 Pass Sleep, is called a sample, or an episode.

At 11:35 a student asks what to do if Facebook grows less addictive the longer you stay, so that the chances change over time. One of his two answers is to add a counter to the state that records how long you have been there. With the counter inside it, the state again holds everything that matters for what comes next, so it is Markov again.

**On the island:** The 100-step limit is a counter of this kind. Strictly, the square alone is not Markov, because whether a step triggers the -50 depends on how many steps have passed. Every bot was blind to that count.

### [13:08](https://www.youtube.com/watch?v=lfHX2hHRMVQ&t=788s) Rewards, the return, and why later rewards count for less
Now each step pays or costs something, and a payment that comes later counts for less. Silver pays the student a number at each step, a reward: -2 for each class, -1 for each step on Facebook, +1 at the pub and +10 for passing. He adds one more number, between 0 and 1, for how much a reward is worth one step later compared with now: the discount factor, written gamma (γ in the formulas). A chain with rewards and a discount is a Markov reward process, or MRP.

What matters is the total along one run from now on, with each later reward shrunk by gamma once per step of delay. That total is the return, written G. `G(t) = R(t+1) + γ R(t+2) + γ² R(t+3) + ...`. In words: the next reward, plus the one after scaled by gamma, plus the next scaled by gamma twice, and so on. A return belongs to one random run, with no average in it yet.

He gives four reasons to discount. You may not trust your own picture of the future (your model). The maths stays finite even when a run can cycle again and again. Money earns interest. And animals and people prefer a reward sooner. With no discount (gamma 1) the sum is still fine when every run is sure to end. What remains to see is how fast a far reward loses to a near one as gamma falls.

> **Alt+Tab · game 2 · stop 1 of 8: Lock the dial, then call her pack.**
>
> **What he just said:** Silver adds rewards and a discount: the return is every future reward added up, each one shrunk by the discount once for every step it waits.
>
> **In the game:** The game is waiting on the dial at the right of the screen. Press F to turn it to a setting and R to lock it in. Then answer with left click for the mini or right click for the mega.
>
> **Before you press:** Before you lock it, decide which pack a Tracer who discounts that much walks to: 15 three pads away, or 50 ten pads away.
>
> <details><summary>Back from the game: what you just saw</summary>Above each pack you saw what it is worth to her from the start: its worth times the dial once per pad, so 15 x dial^3 against 50 x dial^10. The bot Tracer walked to the bigger number. The dial is the discount factor, gamma: what one step later is worth compared with now. <em>In an agent:</em> An agent's discount decides whether it answers now or keeps calling tools for a better answer later.</details>

> **Alt+Tab · game 2 · stop 2 of 8: Try a second setting.**
>
> **What he just said:** A return is one run's total, and with a discount below 1 a reward far away adds very little to it.
>
> **In the game:** Press F until the dial shows a setting you have not tried, then R to lock it. Answer with left click for the mini or right click for the mega.
>
> **Before you press:** Say whether this setting is more patient or less patient than the last one, and whether that flips her choice.
>
> <details><summary>Back from the game: what you just saw</summary>Both worths moved, and the far mega moved more, because it is shrunk ten times and the mini only three. What she collects, each reward shrunk by gamma once per step of delay and added up, is her return. Her return here holds one reward, so it is that pack's shrunk worth.</details>

**On the island:** Discount 1 is allowed because every episode ends (at the goal, in a fall, or at 100 steps), and the -1 per step does a discount's job. The best return is 39 (eleven steps, then +50); stepping straight off the edge is -101.

### [23:19](https://www.youtube.com/watch?v=lfHX2hHRMVQ&t=1399s) Value is the average return from a state
One run can go well or badly by luck, so one run's discounted total (its return) says little about how good a starting point is. The useful number is the return you would get from there on average, over many runs. Silver calls it the value of the state, written v(s). `v(s) = E[G(t) | S(t) = s]`. In words: a state's value is the return you get from it on average.

You can estimate a value by collecting sample returns and averaging them. From Class 1 with the discount, gamma, set to 1/2, his first sample return is -2.25. Each sample is random, but the number they estimate is fixed: "the value function is not a random quantity."

The discount changes the answer. With gamma 0 only the next reward counts, so Class 2 is worth its immediate -2. With gamma 0.9 the same class rises to 0.9, because the +10 for passing, further ahead, now counts. The worth of a place therefore depends on how patient you are, which raises the question of whether the better choice depends on it too.

> **Alt+Tab · game 2 · stop 3 of 8: Find where her choice flips.**
>
> **What he just said:** A state's value is the return you get from it on average, and his example shows one state worth far more once the discount lets a big reward ahead count.
>
> **In the game:** Turn the dial with F to a third setting and lock it with R. Answer with left click for the mini or right click for the mega.
>
> **Before you press:** Pick her pack, and guess whether the start is worth more or less to her than at your last setting.
>
> <details><summary>Back from the game: what you just saw</summary>Nothing about the row changed, only gamma, and the best pack can change with it. Below a discount of about 0.84 the mini is worth more; above it, the mega. In words: 15 x gamma^3 equals 50 x gamma^10 when gamma^7 is 0.3. The best policy, the rule for choosing, depends on the discount.</details>

> **Alt+Tab · game 2 · stop 4 of 8: Lock the last setting.**
>
> **What he just said:** With a discount near 1 a state's value counts the big reward ahead almost in full; with a discount of 0 it counts only the next reward.
>
> **In the game:** One setting is left. Press R to lock it (F has nothing new to turn to), then answer with left click for the mini or right click for the mega.
>
> **Before you press:** You have three answers already; say what the last one is, and why, before you click.
>
> <details><summary>Back from the game: what you just saw</summary>With all four settings tried, the mini won at 0.5 and 0.8 and the mega at 0.9 and 1. The coach line then gives Silver's reasons to discount: the far future is less certain, sums over endless steps stay finite, and sooner is usually worth more. A discount of 1 is safe here because every walk ends at a pack.</details>

**On the island:** RANDOM WALK's mean return, -112.7 over 2,308 episodes (standard error 0.46), is an estimate of this kind for the start square's value.

### [29:11](https://www.youtube.com/watch?v=lfHX2hHRMVQ&t=1751s) The Bellman equation, and its one-shot solution
You do not have to follow a run to its end to know what a place is worth. One step ahead is enough: a state's average return (its value) equals the next step's reward plus the value of where that step lands, shrunk once by the discount and averaged over the places you might land. Silver calls this the Bellman equation, and his small tree drawing of it a backup diagram.

He checks it on Class 3 with no discounting (gamma 1), where the value is 4.3. The step costs 2; with chance 0.6 the student passes, into a state worth 10, and with chance 0.4 goes to the pub, worth 0.8. So 4.3 = -2 + 0.6 * 10 + 0.4 * 0.8.

Every state has one such equation, and in each the unknown values are only multiplied by fixed numbers and added, which is what linear means. So a small chain with rewards (a Markov reward process) can be solved in one step of matrix algebra, a matrix inverse. `v = R + γPv, so v = (I - γP)^(-1) R`. In words: value here is reward here plus gamma times the average value next; stack every state's equation and invert once. The cost grows with the cube of the number of states, so large problems need methods that improve an estimate over repeated passes (iterative methods), which come in the next lectures.

**On the island:** The random walker's -114.4 was solved from these equations, one per square, using the written-down rules (with the time limit left out).

### [43:15](https://www.youtube.com/watch?v=lfHX2hHRMVQ&t=2595s) Actions turn it into a Markov decision process
Until now the student has had no say: chance decided everything. Silver now hands over the choices. He adds a finite set of moves you may pick, called actions, and with them the chain with rewards becomes a Markov decision process, the MDP that the lecture is named for.

Two things change in the written description. Where you land now depends on the move you picked, so there is one table of chances (one transition matrix) for each action. The reward for a step may depend on the action too. `P(a; s, s') = P[S(t+1) = s' | S(t) = s, A(t) = a]`. In words: where you land now depends on what you chose as well as where you stood.

In the student example the arrows that used to carry chances become choices. Only the pub stays random. Going to the Pub is now an action, and it leads to a point where the world (the environment) rolls its dice to settle which class the student lands back in. Such a point is called a chance node. As he explains later in answer to a question, every other arrow hides one as well, with a single outcome of probability 1.

**On the island:** There are four tables, one per move, and almost every chance node has a single outcome. The -100 belongs to one action in one row: toward the edge from row 0.

### [46:15](https://www.youtube.com/watch?v=lfHX2hHRMVQ&t=2775s) A policy is the rule for choosing
Once there are choices, you need a way to say how someone makes them. Silver's way is a rule that looks at the situation you are in (the state) and gives the chance of each move (action) there. The rule is called a policy and written pi (π in the formulas). In his example, a student in Class 1 goes on to Class 2 with chance 0.9 and opens Facebook with chance 0.1.

A policy reads only the current state. It does not consult the history, and it is the same rule at every time step. That is enough, he says, because a state that makes the past irrelevant, a Markov state, already carries everything that decides the future.

Fixing a policy takes the choices back out of the picture. Once you know the chance of each action, you can average the per-action tables over those chances, and what is left is a chain with rewards again, a Markov reward process (MRP). `P_π(s, s') = Σ_a π(a|s) P(a; s, s')`. In words: under a fixed policy, the chance of each next state is a mix over actions, each weighted by how often the policy picks it. One claim in this part can be tested directly: that the current state is enough to tell what comes next.

> **Alt+Tab · game 2 · stop 5 of 8: Say what her state must hold.**
>
> **What he just said:** A policy looks only at the current state, and that is enough when the state carries everything about the past that matters.
>
> **In the game:** A question floats in front of you. Left click: yes, both. Right click: here yes, match no. Melee: no, not here.
>
> **Before you press:** Decide whether knowing only her pad tells you all you need about what comes next, on this island and in a real match.
>
> <details><summary>Back from the game: what you just saw</summary>Here nothing changes but where she stands, so the pad is a Markov state: once you know it, the past adds nothing. In a real match a taken pack comes back on a timer, so two Tracers on the same pad can face different futures. The fix from lecture 1, which Silver repeats with a counter, is to put the timer into the state. <em>In an agent:</em> An agent that sees only the last message is in the same spot; it has to carry the history, or a summary of it.</details>

**On the island:** RANDOM WALK puts 1/4 on each move everywhere. That flattens the strip into an MRP, which is why her values are linear to solve. SARSA's policy, of the kind called epsilon-greedy, moves at random one time in ten (epsilon 0.1).

### [50:49](https://www.youtube.com/watch?v=lfHX2hHRMVQ&t=3049s) Two values under a policy, tied by the Bellman expectation equation
With the rule for choosing moves (the policy) fixed, the question of how good a place is splits in two. One version scores a state: the average return (a run's discounted total) from following the policy from there. This is the state value, written `v_π(s)`. The other scores a state and a move together: take action a first, then follow the policy. This is the action value, written `q_π(s, a)`, and it is the one you consult to choose a move.

Each comes from the other by one step of look-ahead. A state's value is the average of its action values, weighted by how often the policy picks each. An action's value is the move's reward plus the discounted average value of the states it can lead to, weighted by the chance of landing in each. Joined, the two halves make the Bellman expectation equation. `v_π(s) = Σ_a π(a|s) [ R(s, a) + γ Σ_s' P(a; s, s') v_π(s') ]`. In words: average over your own choices, then over the environment's dice, of reward plus the discounted value of where you land.

His check is Class 3, worth 7.4 under a policy that picks 50-50 at every choice, there studying or the pub. The look-ahead agrees: 7.4 = 0.5 * (1 + 0.2 * -1.3 + 0.4 * 2.7 + 0.4 * 7.4) + 0.5 * 10. The same look-ahead works on any state, so one place's value can be worked out from the values one step ahead.

> **Alt+Tab · game 2 · stop 6 of 8: Fill the pads, then walk them.**
>
> **What he just said:** Under a fixed policy, a state's value is the next step's reward plus the discounted value of where that step leads, averaged over the choices and the dice.
>
> **In the game:** Press F to fill the pads. Each step now costs 1 and the discount is 0.9. Three pads get numbers, then a question asks for the pad marked ?: left click, right click or melee. Then walk the row to the mega with WASD.
>
> **Before you press:** Work out the ? pad from the pad ahead of it before you click.
>
> <details><summary>Back from the game: what you just saw</summary>Each number is that pad's value if she always walks to the mega: minus 1 for the step, plus 0.9 times the pad ahead, starting from 50 at the mega. The line on the right checked it on every pad you stood on, down to 10.92 at the start. That one-step look ahead is the Bellman expectation equation. <em>In an agent:</em> An estimate of whether a task will pass from here obeys the same rule: one more tool call's cost, plus the discounted estimate after it.</details>

**On the island:** At the start square the random walker's equation has four terms: back (blocked, so she pays 1 and stays), forward, inland, and the edge (-101). Solved, the start square is worth -114.4 and the far inland corner -135.5.

### [1:07:57](https://www.youtube.com/watch?v=lfHX2hHRMVQ&t=4077s) Optimal value: the most any policy can get
A place can be worth one amount under one way of choosing and a different amount under another. So there is a ceiling: the most that any way of choosing at all (any policy) could expect from that place. Silver calls it the optimal state value and says it as v star. `v*(s) = max over π of v_π(s)`. In words: the best score any policy at all could expect from this state. There is a matching ceiling for a state and a move together, the optimal action value, written `q*(s, a)` and said q star: the most you can expect after committing to action a.

In the student example with no discounting (gamma 1), the optimal values run 10, 8, 6 counting back from the end. At the last class, studying pays +10 and finishes. One class earlier, studying costs 2 and lands you there, which makes 8, and the class before that makes 6. The other move at the last class is the pub, which pays +1 on the way, but its q star of 8.4 loses to studying's 10.

That comparison is what the second number is for. In his words, "If you have Q star, you're done": in every state, take the action with the biggest q star.

> **Alt+Tab · game 2 · stop 7 of 8: Switch her rule to the mini.**
>
> **What he just said:** The optimal value of a state is the most any policy at all can get from it, and once you know it you take the action that reaches it.
>
> **In the game:** You are back on the start pad. The question asks whether the start pad is worth more or less than 10.92 if she always walks to the mini instead: left click for more, right click for less.
>
> **Before you press:** Decide which way the number moves when only her way of walking changes.
>
> <details><summary>Back from the game: what you just saw</summary>The start pad is worth 8.23 walking to the mini, against 10.92 walking to the mega: the same pad has another value under another policy. The pads then redraw for the mini walk, and one pad behind the start the mini walk wins, 10.25 against 8.83. The best policy takes, pad by pad, whichever walk is worth more.</details>

**On the island:** The PLANNER's start value is 39. From the rules (arithmetic, not a measurement), a square in row r, column c is worth 50 - (11 - c) - r under the best policy, so the inland corner behind the start (row 3, column 0) is worth 36.

### [1:15:42](https://www.youtube.com/watch?v=lfHX2hHRMVQ&t=4542s) A best policy always exists, and one that never flips a coin
It is not obvious that a single best way to play exists. One rule could be better in some states and another better in others, and then neither would be best. Silver first fixes what better means: one rule for choosing moves (one policy) beats another only if it is at least as good in every state. Because some pairs cannot be ranked this way, the comparison is called a partial ordering.

Then comes the theorem. Every world written down in this form (every MDP) has a policy that is at least as good as all the others. It is called an optimal policy. There may be several, and they all reach the same ceilings from the last part, the optimal values: v star for each state and q star for each state and move.

One of them can be read straight off q star: in each state, put probability 1 on the action with the largest optimal action value. A policy like that, which leaves nothing to chance, is called deterministic, so a deterministic optimal policy always exists. `π*(a|s) = 1 if a = argmax_a q*(s, a), else 0`. In words: always take the move with the best optimal action value.

**On the island:** The PLANNER walks greedily on her values, taking the best-valued move each time: 10 runs, 0.0 falls per 100 episodes, 11.0 steps per episode, and all 10 runs with 10 clean test crossings. From inland squares several routes are optimal, since the order of the moves does not change the count.

### [1:21:47](https://www.youtube.com/watch?v=lfHX2hHRMVQ&t=4907s) Bellman optimality: maximise your choices, average the dice
To find the most a place can pay, look one step ahead as before, but take your best move instead of averaging over your moves. Where the environment decides, nothing changes. As Silver says of that step, "There's no max here. We don't get to pick where the wind blows us." So the rule is a maximum over your own moves and an average over the dice, and it is called the Bellman optimality equation. `v*(s) = max_a [ R(s, a) + γ Σ_s' P(a; s, s') v*(s') ]`. In words: a square's best value is the best, over moves, of the step's reward plus the discounted average best value where it leads.

His check is Class 1, worth 6. Studying costs 2 and leads to a class worth 8; Facebook costs 1 and leads to a state worth 6. So Class 1 = 6 = max{-2 + 8, -1 + 6}.

The maximum has a cost. With it the unknown values are no longer only multiplied and added, so the equation is non-linear and the single matrix inverse from before does not work. In general no formula gives the answer in one go (there is no closed form). It is solved instead by applying the equation to an estimate over and over, each pass giving a better one, which is called iteration. He names the methods to come: value iteration and policy iteration in the next lecture, Q-learning and Sarsa later.

> **Alt+Tab · game 2 · stop 8 of 8: Read the debrief.**
>
> **What he just said:** The best values obey the same one-step look ahead with a maximum over your own choices, which is why they are found by repeated sweeps instead of one matrix inverse.
>
> **In the game:** Press F for the debrief. Three lines appear on the left, and your prediction score sits under the title.
>
> **Before you press:** Before you press, count how many of the seven predictions you think you got right.
>
> <details><summary>Back from the game: what you just saw</summary>The lines name what you did: the discount, the return as a discounted sum, value under a policy, and the Bellman equation. The game left out the dice: every step lands where it aims, so the average over next states has one term. In Silver's examples a chance node puts a probability-weighted average there. <em>In an agent:</em> A low discount makes an agent answer from what it already has; a high one lets it spend more tool calls on a better answer.</details>

**On the island:** The PLANNER is value iteration: she sweeps this equation over the squares until the largest change is under 0.001. It took 13 sweeps, with largest changes 101, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 48, 0.00. The check at the start square: forward -1 + 40 = 39, back -1 + 39 = 38, inland -1 + 38 = 37, edge -101; the max is 39.

### [1:40:21](https://www.youtube.com/watch?v=lfHX2hHRMVQ&t=6021s) The extensions stay on the slides
The lecture closes with a list of harder worlds that the same form can be stretched to cover. Silver is out of time, so he spends about a minute on one slide of extensions, says they are not examinable, and names them without detail.

First come worlds with endlessly many states or moves, or a smooth range of them (infinite and continuous MDPs); his picture is an airplane or helicopter, perhaps in continuous time. Then come worlds the agent sees only in part (partially observable MDPs), where the agent gets the robot's camera view and not the full state inside the environment (the Markov state). Last is scoring behaviour by its average reward per step instead of a discounted total (average-reward MDPs).

The slides go further than he does aloud. Unspoken, on the slides only, are the definition of the partially observable MDP (POMDP) with an observation function, histories, belief states and belief trees, the continuous-control cases (LQR, Hamilton-Jacobi-Bellman), and ergodic average reward. These stay as names here. One formula from those slides: `b(h) = ( P[S(t) = s1 | H(t) = h], ..., P[S(t) = sn | H(t) = h] )`. In words: a belief state lists the chance of each true state, given everything seen so far.

**On the island:** Not run yet. The hidden-wall build is planned and running, with no results.

## What the island measured for this lecture

| Bot | Lecture role | Paper value, start square | Measured | Falls per 100 (95% interval) |
|---|---|---|---|---|
| RANDOM WALK | fixed policy, so an MRP | -114.4 (time limit ignored) | mean -112.7 (standard error 0.46), 2,308 episodes, goal by luck in 1.0% | 97.4 (96.9 to 97.9), 11 runs |
| PLANNER | value iteration on the optimality equation | 39 | 39.0 in the first and last 40 episodes; first goal in episode 1 | 0.0 (0.0 to 0.0), 10 runs |

The random walker scored 1.7 points above the paper value, more than three times the standard error, so sampling noise alone is an unlikely cause. The paper value leaves out the 100-step limit, which caps the longest wanderings; that is one candidate, untested. The PLANNER, planning from the rules alone, matched the best return every episode. Neither is one of the night's comparisons; only SARSA against Q-learning (falls) was planned in advance. Not shown: that the format fits a world with real dice, or how fast a bot learns these values.

## Guess first

<details><summary>Under the random walk, which is worse to stand on: the start square beside the drop, or the far inland corner?</summary>
The inland corner, -135.5 against -114.4. Inland she wanders longer, paying 1 a step, and falls anyway. Value belongs to a square and a policy together.
</details>

<details><summary>Lecture 1 split planning (you have the rules) from learning (you only have experience). The PLANNER reached the goal in episode 1; SARSA's median first goal was episode 11. Which side explains the gap?</summary>
Planning. The PLANNER was handed the transition and reward tables, the model in lecture 1's terms, and solved the optimality equation before her first step. SARSA had to discover the same facts by falling.
</details>

<details><summary>Lecture 1 separated the environment's state from the agent's state. Is Q, ROW ONLY's state Markov?</summary>
No. Two squares in the same row have different futures but look identical to her. She dithers: 47.1 steps per episode against 18.6 with the full table.
</details>

<details><summary>Silver warns that undiscounted cycles can give infinite returns. The island uses discount 1 and has back-and-forth cycles. Are its returns finite?</summary>
Yes. Every episode ends at the goal, in a fall, or at 100 steps, and Silver says undiscounted is fine when every sequence terminates.
</details>

<details><summary>From the inland corner behind the start square, does the PLANNER have one best route or several?</summary>
Several. She needs three moves toward the edge and eleven forward, and inland squares are never dangerous, so the order does not change the return. From the start square there is only one: eleven moves forward.
</details>

<details><summary>Can the optimality equation for the island be solved with one matrix inverse, like the random walker's values?</summary>
No. The max over actions makes it non-linear, with no closed form in general. The PLANNER iterated, 13 sweeps.
</details>

## Cards

- Q: The Markov property? | A: Given the present state, the past adds nothing to predicting the future.
- Q: The five parts of an MDP? | A: States, actions, transition probabilities per action, rewards, discount factor gamma.
- Q: Return versus value? | A: The return is one episode's random total; the value is its average from that state.
- Q: When is discount 1 safe? | A: When every episode is sure to end, as on the island.
- Q: Fixing a policy does what to an MDP? | A: Turns it into a Markov reward process.
- Q: v_pi versus q_pi? | A: v_pi scores a state; q_pi scores one action in that state, then following pi.
- Q: Expectation versus optimality equation? | A: One averages over choices, the other maximises; both average over the dice.
- Q: Why no matrix inverse for v*? | A: The max makes the equation non-linear; it needs iteration such as value iteration.

## In language-model terms

Take a model working a tau-bench task (not from the lecture: a model serves a simulated customer and calls database tools, passing if the database ends right). The state is the conversation plus the database; an action is a message or tool call; the customer's and tools' replies are the transitions, the customer being the environment's dice; the reward is pass or fail at the end, and discount 1 fits because episodes end. A state's value is the chance the task passes from here.

The structure is exact in one place: a fixed model at a fixed temperature is a stochastic policy, one run is a random return, and a pass rate over many runs estimates the value. Elsewhere it is only an analogy. The action set is every possible string, nobody writes the transition table down, so there is no PLANNER.

It breaks at full observability. The customer's real goal sits in instructions the model never sees, so from the model's side the task is partially observable, the case this lecture leaves on the slides.

## The thread to partial observability

This lecture assumes the state is fully observed and says so in its first minutes. Three spoken moments point past it. At 02:33 Silver claims "any partially observed problem can be completely converted into an MDP." At 11:35 he shows how: put what you need, a counter, into the state. At 1:33:34 he describes a state that includes the observations seen so far, a belief without the word. The slides finish it: the history is always Markov, and so is a belief. On the island every bot was blind to the step clock, and the planned hidden-wall build makes the gap deliberate, with RUNNER REMEMBERS BUMPS carrying the smallest possible belief. Carry one rule forward: when your state is not Markov, add memory until it is.

## Experiments the lecture asks for that the island has not run

- Exact random-walk value with the step count in the state: whether the 100-step limit explains the 1.7-point gap.
- PLANNER with gamma 0.9: discounting changes the values, and it would show whether the route changes too.
- A noisy strip (random sideways pushes): whether the PLANNER's plan survives real dice.
- Exact values of the final SARSA and Q-LEARNING policies, square by square: Silver's partial ordering, whether either is better everywhere.
