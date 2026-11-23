# Lecture 2: Markov Decision Processes

*David Silver's lecture 2 (UCL, 2015), gone through in his order and re-explained with the Tracer experiments on Workshop Island. The lecture and its slides are his: [video](https://www.youtube.com/watch?v=lfHX2hHRMVQ), [course page](https://davidstarsilver.wordpress.com/teaching/). The words below are a re-explanation. Every island number comes from the logged runs in this repository.*

Tracer is low on health. A small pack sits three pads behind her, a big one ten pads ahead, and you have to pick one now. Silver's second lecture writes a choice like that down so carefully that it gets an exact answer: how many points each place is worth, under a given way of moving and under the best one. The written-down form is called a Markov decision process. On the island it was a strip of 48 squares beside a drop, where a bot picks one of four moves and is told where she landed and what it cost. A bot walking at random has a start square worth -114.4 on paper; in play she averaged -112.7. Under the best policy (the rule for choosing moves) the same square is worth 39. The PLANNER worked that out in 13 sweeps, then walked it without a single fall.

**Two windows:** this page, and [Game 2: Mini or Mega](../workshop/games/g02.md), an Overwatch custom game for this lecture (paste `workshop/compiled/game-02.txt` into a custom game's settings and start it). The game opens at stop 1 and waits. Read down this page; at each box marked Alt+Tab, switch to the game, do that stop, and switch back. The game never moves on while you read.

## The lecture in order

### [00:50](https://www.youtube.com/watch?v=lfHX2hHRMVQ&t=50s) Somebody has to write the game down first
Overwatch runs on a rulebook you will never read: the game's code. It says where Blink puts you, how much a health pack heals, and what happens when you step off a ledge.

Your aim is not in it. Neither is your rank.

Silver opens with the form for writing a rulebook like that down: which places exist, which moves are allowed, where each move lands, and what each step pays. He calls it a Markov decision process, MDP for short. Last week split the picture into a learner that picks moves (the agent) and a world that answers (the environment). The MDP lives entirely on the world's side.

He starts with the "nice case": you see the full situation right now, called the state, with nothing hidden. Spectator view, every outline on. A world like that is called fully observable.

Then he claims almost every problem fits this one form, even three that look as if they would not. Moves that vary smoothly, like your crosshair (continuous control). Worlds where you see only part of the state, which is every real match (partially observable). And one move, one reward, task over, like a single pull on a slot machine. That last kind is a bandit, and a bandit is an MDP with a single state.

**On the island:** Here is the whole rulebook for the strip. The states (places) are 48 squares (4 rows, 12 columns), with two endings: the goal at the right end of row 0, and the drop. The actions (moves) are forward, back, inland and toward the edge. The transitions (where a move lands): one square that way; off the grid on the left, right or inland, she stays put; toward the edge from row 0, she falls. The rewards (what a step pays) are -1 per step, +50 at the goal, -100 for a fall, and -50 if 100 steps pass. The discount is 1, so a late reward counts as much as an early one. Each bot is told her square after every move.

### [03:26](https://www.youtube.com/watch?v=lfHX2hHRMVQ&t=206s) The present is enough, if it is the right present
You join a Quick Play game already in progress. The payload is nearly at the end, the clock is almost out, and most of the enemy team is dead.

You do not need the replay.

Some snapshots of the present are complete like that: how you got there adds nothing. Silver's sentence for it is "the future is independent of the past given the present." A state (the situation the world is in right now) with that quality is called Markov. Once you know it, the rest of the history does not help you predict what comes next.

(A real match is not quite this tidy. The screen hides the enemy's ult charge, and the last few fights would help you guess it.)

<details markdown="1"><summary>The formula, when you want it</summary>

`P[S(t+1) | S(t)] = P[S(t+1) | S(1), ..., S(t)]`. In words: adding the whole past to the present state does not change the odds of the next state.

</details>

That saves a lot of bookkeeping. If the present settles the odds, one number per pair of states describes the whole world: the chance of going from the first to the second, called the transition probability. Put those in a table, one row per starting state, and you have the transition matrix. A row lists every place you could land from one state, so each row sums to 1.

**On the island:** A square and a move together fix the next square. There were 0.21 slips (steps that missed their target) per 1,000 steps, so the table is nearly all zeros and ones. Q, ROW ONLY, the bot told only her row, does not have a Markov state (see Guess first).

### [07:28](https://www.youtube.com/watch?v=lfHX2hHRMVQ&t=448s) One more game, and a clock hidden inside the state
You queue for one game. It ends. You queue again. Nobody really decided that; it just tends to happen.

Silver's simplest world works the same way. Nobody chooses and nothing is scored. It drifts from one state to the next by chance, so all it needs is the list of states and the table of chances between them (the transition matrix). He calls this a Markov process, or a Markov chain.

<details markdown="1"><summary>The formula, when you want it</summary>

`<S, P>`. In words: a Markov process is just the list of states and the table of moves between them.

</details>

His example is a cartoon student who drifts between three classes, Facebook, the Pub, Pass and Sleep. Facebook leads straight back to Facebook with chance 0.9 (a self-loop). You know that loop. Sleep is where a run stops, a terminal state, and he draws it as a state that loops on itself forever. One random run from start to finish, such as C1 C2 C3 Pass Sleep, is called a sample, or an episode. In Overwatch terms: one match.

A student asks (11:35) what happens if Facebook grows less addictive the longer you stay, so the chances change over time. One of Silver's two answers: add a counter to the state that records how long you have been there. With the counter inside, the state again holds everything that matters for what comes next, so it is Markov again.

Not Markov? Put the clock in the state.

**On the island:** The 100-step limit is a counter of this kind. Strictly, the square alone is not Markov, because whether a step triggers the -50 depends on how many steps have passed. Every bot was blind to that count.

### [13:08](https://www.youtube.com/watch?v=lfHX2hHRMVQ&t=788s) Points, and why points later are worth less
You are holding Nano Boost. This fight is probably winnable. A better one might come in thirty seconds, if you are still alive in thirty seconds.

An ult later is worth less than an ult now.

Silver turns that feeling into numbers. He pays the student at each step, a reward: -2 for each class, -1 for each step on Facebook, +1 at the pub and +10 for passing. Then he adds one number between 0 and 1: what a reward one step later is worth compared with now. That is the discount factor, gamma (γ). A chain with rewards and a discount is a Markov reward process, or MRP.

Add up everything one run collects, each reward shrunk by gamma once per step it waited, and you have the return, G. One random run, no averaging yet.

<details markdown="1"><summary>The formula, when you want it</summary>

`G(t) = R(t+1) + γ R(t+2) + γ² R(t+3) + ...`. In words: the next reward, plus the one after scaled by gamma, plus the next scaled by gamma twice, and so on.

</details>

He gives four reasons to discount:

1. **Your picture of the future might be wrong.** Silver calls that picture your model.
2. **The maths stays finite,** even when a run loops again and again.
3. **Money earns interest.**
4. **Animals and people prefer a reward sooner.**

With no discount (gamma 1) the sum is still fine, as long as every run is sure to end. How fast a far reward loses to a near one as gamma falls is what the game's dial is for.

> **Alt+Tab · game 2 · stop 1 of 8: Lock the dial, then call her pack.**
>
> **What he just said:** Silver starts paying for each step, then adds a discount: a reward that waits counts for less. Add up everything one run collects, each reward shrunk once for every step it waited, and you have the return.
>
> **In the game:** The game is waiting on the dial at the right of the screen. Press F to turn it to a setting and R to lock it in. Then answer with left click for the mini or right click for the mega.
>
> **Before you press:** Before you lock it, decide which pack a Tracer who discounts that much walks to: 15 three pads away, or 50 ten pads away.
>
> <details><summary>Back from the game: what you just saw</summary>Each pack showed what it is worth from where she stands: its size, shrunk by the dial once per pad. So 15 x dial^3 against 50 x dial^10. The bot walked to the bigger number, no feelings involved. That dial is the discount factor, gamma: how much one step later is worth compared with now. <em>In an agent:</em> A language-model agent turns the same dial: answer now with what it has, or keep calling tools for a better answer later.</details>

> **Alt+Tab · game 2 · stop 2 of 8: Try a second setting.**
>
> **What he just said:** A return is one run's total. With a discount below 1, a reward far down the road barely adds to it, because it gets shrunk again at every step on the way.
>
> **In the game:** Press F until the dial shows a setting you have not tried, then R to lock it. Answer with left click for the mini or right click for the mega.
>
> **Before you press:** Say whether this setting is more patient or less patient than the last one, and whether that flips her choice.
>
> <details><summary>Back from the game: what you just saw</summary>Both numbers moved, and the mega moved more. It gets shrunk ten times on the way, the mini only three. Her return is everything she collects, each reward shrunk by gamma once per step of delay. Here that is a single pack, so her return is just that pack's shrunk worth.</details>

**On the island:** Discount 1 is allowed because every episode ends (at the goal, in a fall, or at 100 steps), and the -1 per step does a discount's job. The best return is 39 (eleven steps, then +50); stepping straight off the edge is -101.

### [23:19](https://www.youtube.com/watch?v=lfHX2hHRMVQ&t=1399s) Why one good game proves nothing
You win one game on a hero you have never played. Are you good at her now? Maybe. One game cannot tell skill from luck.

Neither can one run's discounted total (its return). The number worth having is the return you get from a place on average, over many runs. Silver calls it the value of the state, written v(s).

<details markdown="1"><summary>The formula, when you want it</summary>

`v(s) = E[G(t) | S(t) = s]`. In words: a state's value is the return you get from it on average.

</details>

One game is a return. Your win rate is a value.

(Strictly, a win rate is the value of the moment a match starts, if a win pays 1 and a loss pays 0.)

You estimate a value the obvious way: collect sample returns and average them. From Class 1 with gamma set to 1/2, his first sample return is -2.25. Each sample is random, but what they estimate is fixed: "the value function is not a random quantity."

The discount changes the answer. With gamma 0 only the next reward counts, so Class 2 is worth its immediate -2. With gamma 0.9 the same class rises to 0.9, because the +10 for passing, further ahead, now counts. How much a place is worth depends on how patient you are. Whether the best choice depends on it too, the game's dial will show you.

> **Alt+Tab · game 2 · stop 3 of 8: Find where her choice flips.**
>
> **What he just said:** A state's value is the return you get from it on average. In his example one class is worth far more once the discount lets the big reward ahead count. Patience changes the price.
>
> **In the game:** Turn the dial with F to a third setting and lock it with R. Answer with left click for the mini or right click for the mega.
>
> **Before you press:** Pick her pack, and guess whether the start is worth more or less to her than at your last setting.
>
> <details><summary>Back from the game: what you just saw</summary>The row did not change. The packs did not change. Only gamma did, and that alone can flip her choice. Below a discount of about 0.84 the mini is worth more; above it, the mega (15 x gamma^3 equals 50 x gamma^10 when gamma^7 is 0.3). So the best policy, the rule for choosing, depends on how patient you are.</details>

> **Alt+Tab · game 2 · stop 4 of 8: Lock the last setting.**
>
> **What he just said:** Turn the discount to 0 and a state is worth only its next reward. Turn it near 1 and the big reward far ahead counts almost in full. Same world, very different price tags.
>
> **In the game:** One setting is left. Press R to lock it (F has nothing new to turn to), then answer with left click for the mini or right click for the mega.
>
> **Before you press:** You have three answers already; say what the last one is, and why, before you click.
>
> <details><summary>Back from the game: what you just saw</summary>Four settings, one clean split: the mini won at 0.5 and 0.8, the mega at 0.9 and 1. The coach line then gave Silver's reasons to discount: the far future is less certain, sums over endless steps stay finite, and sooner is usually worth more. A discount of 1 is safe here because every walk ends at a pack.</details>

**On the island:** RANDOM WALK's mean return, -112.7 over 2,308 episodes (standard error 0.46), is an estimate of this kind for the start square's value.

### [29:11](https://www.youtube.com/watch?v=lfHX2hHRMVQ&t=1751s) You can read a fight one step early
Your Mercy goes down mid-fight. Nobody waits for the wipe to know the fight just got worse.

Silver's version: you never have to play a run to its end to know what a place is worth. A state's value equals the next step's reward plus the value of where that step lands, shrunk once by the discount and averaged over the places you might land. He calls this the Bellman equation, and his small tree drawing of it a backup diagram.

One step ahead is enough.

He checks it on Class 3 with no discounting (gamma 1), where the value is 4.3. The step costs 2. With chance 0.6 the student passes, into a state worth 10; with chance 0.4 it is the pub, worth 0.8. Add it up and you land back on 4.3.

<details markdown="1"><summary>The formula, when you want it</summary>

`4.3 = -2 + 0.6 * 10 + 0.4 * 0.8`. In words: pay for the step, then average the two places the student might land.

`v = R + γPv, so v = (I - γP)^(-1) R`. In words: value here is reward here plus gamma times the average value next; stack every state's equation and invert once.

</details>

Every state has one such equation, and in each the unknown values are only multiplied by fixed numbers and added, which is what linear means. So a small chain with rewards (an MRP) is solved in one shot, with a matrix inverse.

The catch: the cost grows with the cube of the number of states. Double the states and the work goes up eightfold. Big problems need methods that improve a guess pass after pass (iterative methods), coming in the next lectures.

**On the island:** The random walker's -114.4 was solved from these equations, one per square, using the written-down rules (with the time limit left out).

### [43:15](https://www.youtube.com/watch?v=lfHX2hHRMVQ&t=2595s) Finally, you get the controller
Until now you have been watching a replay. Things happen, the score ticks, and you cannot press a single button. Chance decides everything.

Silver now hands over the choices. He adds a finite set of moves you may pick, called actions, and with them the chain with rewards becomes a Markov decision process, the MDP the lecture is named for.

Two things change in the written description. Where you land now depends on the move you picked, so there is one table of chances (one transition matrix) for each action. And the reward for a step may depend on the action too.

<details markdown="1"><summary>The formula, when you want it</summary>

`P(a; s, s') = P[S(t+1) = s' | S(t) = s, A(t) = a]`. In words: where you land now depends on what you chose as well as where you stood.

</details>

In the student example the arrows that used to carry chances become choices. Only the pub stays random. Going to the Pub is now an action, and it leads to a point where the world (the environment) rolls its dice to settle which class the student lands back in. Silver calls that point a chance node. As he explains later in answer to a question, every other arrow hides one as well, with a single outcome of probability 1.

You pick the door. The world picks what is behind it.

**On the island:** There are four tables, one per move, and almost every chance node has a single outcome. The -100 belongs to one action in one row: toward the edge from row 0.

### [46:15](https://www.youtube.com/watch?v=lfHX2hHRMVQ&t=2775s) Your playstyle, written as odds
Every player has a rule, even if they never wrote it down. Low health: go to the pack. Widow on the high ground: take the other route. Most of the time, anyway.

Silver writes a rule like that as odds. It looks at the situation you are in (the state) and gives the chance of each move (action) there. He calls it a policy, written pi (π). His student in Class 1 goes on to Class 2 with chance 0.9 and opens Facebook with chance 0.1.

A policy reads only the current state. It ignores the history, and it is the same rule at every time step. That is enough, he says, because a Markov state already carries everything that decides the future. You get to test that claim directly in the game.

Now a neat trick. Fix the policy, and the choices drop back out of the picture. Once you know the chance of each action, you can average the per-action tables over those chances, and what is left is a chain with rewards again, a Markov reward process (MRP).

<details markdown="1"><summary>The formula, when you want it</summary>

`P_π(s, s') = Σ_a π(a|s) P(a; s, s')`. In words: under a fixed policy, the chance of each next state is a mix over actions, each weighted by how often the policy picks it.

</details>

Pick a playstyle, and from the outside your choices are just more dice.

> **Alt+Tab · game 2 · stop 5 of 8: Say what her state must hold.**
>
> **What he just said:** A policy, the rule for choosing, looks only at the current state. Silver says that is enough, as long as the state carries everything about the past that matters.
>
> **In the game:** A question floats in front of you. Left click: yes, both. Right click: here yes, match no. Melee: no, not here.
>
> **Before you press:** Decide whether knowing only her pad tells you all you need about what comes next, on this island and in a real match.
>
> <details><summary>Back from the game: what you just saw</summary>On this row nothing changes but where she stands, so her pad is a Markov state: know it, and the past adds nothing. A real match is less polite. A taken pack comes back on a timer, so two Tracers on the same pad can face different futures. The fix from lecture 1, which Silver repeats with his counter, is to put the timer into the state. <em>In an agent:</em> An agent that sees only the last message is Tracer without the timer. It needs the history in its state, or a summary of it.</details>

**On the island:** RANDOM WALK puts 1/4 on each move everywhere. That flattens the strip into an MRP, which is why her values are linear to solve. SARSA's policy, of the kind called epsilon-greedy, moves at random one time in ten (epsilon 0.1).

### [50:49](https://www.youtube.com/watch?v=lfHX2hHRMVQ&t=3049s) Two questions about any spot on the map
You are Tracer on the high ground, and there are two questions you can ask. How good is it to be here? And how good is it to be here and press Blink right now?

Silver gives each its own number, both under a fixed policy. The first scores a state: the average return from following the policy from there. That is the state value, `v_π(s)`. The second scores a state and a move together: take action a first, then follow the policy. That is the action value, `q_π(s, a)`.

The second one is the one you choose with.

Each comes from the other by one step of look-ahead. A state's value is the average of its action values, weighted by how often the policy picks each. An action's value is its reward plus the discounted average value of the states it can lead to, weighted by the chance of landing in each. Join the two halves and you have the Bellman expectation equation.

<details markdown="1"><summary>The formula, when you want it</summary>

`v_π(s) = Σ_a π(a|s) [ R(s, a) + γ Σ_s' P(a; s, s') v_π(s') ]`. In words: average over your own choices, then over the environment's dice, of reward plus the discounted value of where you land.

`7.4 = 0.5 * (1 + 0.2 * -1.3 + 0.4 * 2.7 + 0.4 * 7.4) + 0.5 * 10`. In words: half the time the pub and then the dice, half the time study, collect 10 and finish.

</details>

His check is Class 3, worth 7.4 under a policy that picks 50-50 at every choice, there studying or the pub. The look-ahead agrees, and it works on any state: one place's value can be worked out from the values one step ahead.

> **Alt+Tab · game 2 · stop 6 of 8: Fill the pads, then walk them.**
>
> **What he just said:** Pick a policy and keep it. Then a state's value is the next step's reward plus the discounted value of wherever that step leads, averaged over your choices and the world's dice.
>
> **In the game:** Press F to fill the pads. Each step now costs 1 and the discount is 0.9. Three pads get numbers, then a question asks for the pad marked ?: left click, right click or melee. Then walk the row to the mega with WASD.
>
> **Before you press:** Work out the ? pad from the pad ahead of it before you click.
>
> <details><summary>Back from the game: what you just saw</summary>Each number is what that pad is worth if she always walks to the mega. Start from 50 at the mega and walk backwards: minus 1 for the step, plus 0.9 times the pad ahead. The line on the right checked it on every pad you stood on, down to 10.92 at the start. You just did the Bellman expectation equation with your feet. <em>In an agent:</em> Your guess at whether an agent's task will pass from here follows the same rule: the cost of one more tool call, plus the discounted guess after it.</details>

**On the island:** At the start square the random walker's equation has four terms: back (blocked, so she pays 1 and stays), forward, inland, and the edge (-101). Solved, the start square is worth -114.4 and the far inland corner -135.5.

### [1:07:57](https://www.youtube.com/watch?v=lfHX2hHRMVQ&t=4077s) The ceiling: the best Tracer who could ever exist
The same spot is worth more to one Tracer than to another, because they would do different things from there. So ask the ambitious question: what is it worth to the best Tracer who could ever exist?

Silver calls that ceiling the optimal state value, said v star: the most that any way of choosing at all (any policy) could expect from that place. The matching ceiling for a state and a move together is the optimal action value, written `q*(s, a)` and said q star: the most you can expect after committing to action a.

<details markdown="1"><summary>The formula, when you want it</summary>

`v*(s) = max over π of v_π(s)`. In words: the best score any policy at all could expect from this state.

</details>

In the student example with no discounting (gamma 1), the optimal values run 10, 8, 6 counting back from the end. At the last class, studying pays +10 and finishes. One class earlier, studying costs 2 and lands you there, which makes 8, and the class before that makes 6. The other move at the last class is the pub, which pays +1 on the way, but its q star of 8.4 loses to studying's 10.

That comparison is what q star is for.

In his words, "If you have Q star, you're done": in every state, take the action with the biggest q star.

> **Alt+Tab · game 2 · stop 7 of 8: Switch her rule to the mini.**
>
> **What he just said:** Every state has a ceiling: the most any policy at all could get from there, which Silver calls its optimal value. Once you know it, playing well is easy: take the action that reaches it.
>
> **In the game:** You are back on the start pad. The question asks whether the start pad is worth more or less than 10.92 if she always walks to the mini instead: left click for more, right click for less.
>
> **Before you press:** Decide which way the number moves when only her way of walking changes.
>
> <details><summary>Back from the game: what you just saw</summary>Same pad, new rule, new number: 8.23 walking to the mini, against 10.92 walking to the mega. Then the pads redrew for the mini walk, and one pad behind the start the mini walk won, 10.25 against 8.83. So the best policy is not one walk. It takes, pad by pad, whichever walk is worth more from there.</details>

**On the island:** The PLANNER's start value is 39. From the rules (arithmetic, not a measurement), a square in row r, column c is worth 50 - (11 - c) - r under the best policy, so the inland corner behind the start (row 3, column 0) is worth 36.

### [1:15:42](https://www.youtube.com/watch?v=lfHX2hHRMVQ&t=4542s) A best way to play always exists, and it never flips a coin
Who is better: the player who wins every attack, or the one who wins every defence? You cannot say. Each beats the other somewhere.

Silver hits the same snag. One rule for choosing moves (one policy) could be better in some states and another in others, and then neither is best. So he pins down what better means: one policy beats another only if it is at least as good in every state. Some pairs cannot be ranked this way, so the comparison is called a partial ordering.

Then the theorem, and it is a relief. Every MDP has a policy at least as good as all the others, called an optimal policy. There may be several, and they all reach the same ceilings from the last part: v star for each state and q star for each state and move.

One of them can be read straight off q star: in each state, put probability 1 on the action with the largest optimal action value. A policy that leaves nothing to chance is called deterministic, so a deterministic optimal policy always exists.

<details markdown="1"><summary>The formula, when you want it</summary>

`π*(a|s) = 1 if a = argmax_a q*(s, a), else 0`. In words: always take the move with the best optimal action value.

</details>

The best possible player never needs to flip a coin.

(That holds in a world that sits still. An opponent who learns your habits is a different problem.)

**On the island:** The PLANNER walks greedily on her values, taking the best-valued move each time: 10 runs, 0.0 falls per 100 episodes, 11.0 steps per episode, and all 10 runs with 10 clean test crossings. From inland squares several routes are optimal, since the order of the moves does not change the count.

### [1:21:47](https://www.youtube.com/watch?v=lfHX2hHRMVQ&t=4907s) Pick your moves, average the boops
When you plan a dive, you choose your route and your cooldowns, and you choose the best ones you can. You do not choose where the enemy Lúcio boops you.

Silver builds that split into one equation. To find the most a place can pay, look one step ahead as before, but take your best move instead of averaging over your moves. Where the environment decides, nothing changes. As he says of that step, "There's no max here. We don't get to pick where the wind blows us." Maximise over your choices, average over the dice: that is the Bellman optimality equation.

<details markdown="1"><summary>The formula, when you want it</summary>

`v*(s) = max_a [ R(s, a) + γ Σ_s' P(a; s, s') v*(s') ]`. In words: a square's best value is the best, over moves, of the step's reward plus the discounted average best value where it leads.

`Class 1 = 6 = max{-2 + 8, -1 + 6}`. In words: studying beats Facebook, 6 to 5.

</details>

His check is Class 1, worth 6. Studying costs 2 and leads to a class worth 8; Facebook costs 1 and leads to a state worth 6. Studying wins, at 6.

The max has a price.

The unknown values are no longer only multiplied and added, so the equation is non-linear and the one-shot matrix inverse stops working. In general no formula gives the answer in one go (there is no closed form). Instead you apply the equation to an estimate over and over, each pass a little better, which is called iteration. He names what is coming: value iteration and policy iteration in the next lecture, Q-learning and Sarsa later.

> **Alt+Tab · game 2 · stop 8 of 8: Read the debrief.**
>
> **What he just said:** The best values obey the same one-step look ahead with one change: take the best of your own moves instead of averaging them. That max is why they need repeated sweeps instead of one matrix inverse.
>
> **In the game:** Press F for the debrief. Three lines appear on the left, and your prediction score sits under the title.
>
> **Before you press:** Before you press, count how many of the seven predictions you think you got right.
>
> <details><summary>Back from the game: what you just saw</summary>The lines name what you did: the discount, the return as a discounted sum, value under a policy, and the Bellman equation. One thing the game quietly skipped is the dice. Every step lands where it aims, so the average over next states has one term. In Silver's examples a chance node puts a probability-weighted average there. <em>In an agent:</em> Turn an agent's discount down and it answers from what it already has. Turn it up and it will happily spend more tool calls chasing a better answer.</details>

**On the island:** The PLANNER is value iteration: she sweeps this equation over the squares until the largest change is under 0.001. It took 13 sweeps, with largest changes 101, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 48, 0.00. The check at the start square: forward -1 + 40 = 39, back -1 + 39 = 38, inland -1 + 38 = 37, edge -101; the max is 39.

### [1:40:21](https://www.youtube.com/watch?v=lfHX2hHRMVQ&t=6021s) Overtime: the extensions stay on the slides
The clock has run out and somebody is still touching the point. That is where this lecture ends. Silver is out of time, so he gives one slide of extensions about a minute, says they are not examinable, and names them without detail:

1. **Endless or smooth worlds.** Endlessly many states or moves, or a smooth range of them (infinite and continuous MDPs). His picture is an airplane or helicopter, perhaps in continuous time.
2. **Worlds you see only in part** (partially observable MDPs). You get the robot's camera view, not the full state inside the environment (the Markov state). That is every Overwatch match ever played.
3. **Average reward.** Behaviour is scored by its average reward per step instead of a discounted total (average-reward MDPs).

The slides go further than he does aloud. Unspoken, on the slides only, are the definition of the partially observable MDP (POMDP) with an observation function, histories, belief states and belief trees; the continuous-control cases (LQR, Hamilton-Jacobi-Bellman); and ergodic average reward. They stay as names here, with one formula kept from those slides.

<details markdown="1"><summary>The formula, when you want it</summary>

`b(h) = ( P[S(t) = s1 | H(t) = h], ..., P[S(t) = sn | H(t) = h] )`. In words: a belief state lists the chance of each true state, given everything seen so far.

</details>

Of the three, the camera view is the one that looks most like your game.

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

Take a model working a tau-bench task. (This is not from the lecture. In tau-bench a model serves a simulated customer and calls database tools, and it passes if the database ends up right.) Now read it as an MDP. The state is the conversation plus the database. An action is a message or a tool call. The customer's and the tools' replies are the transitions, with the customer as the environment's dice. The reward is pass or fail at the end, and a discount of 1 fits because episodes end. A state's value is the chance the task passes from here.

In one place the fit is exact, not a metaphor. A fixed model at a fixed temperature is a stochastic policy: a rule that gives odds over moves. One run is one random return. A pass rate over many runs estimates the value, the same way your win rate does.

Everywhere else it is only an analogy. The action set is every possible string, and nobody writes the transition table down, so there is no PLANNER to hand the rules to.

And it breaks at full observability. The customer's real goal sits in instructions the model never sees, so from the model's side the task is partially observable. That is the case this lecture leaves on the slides.

## The thread to partial observability

This lecture assumes the state is fully observed and says so in its first minutes. Three spoken moments point past it. At 02:33 Silver claims "any partially observed problem can be completely converted into an MDP." At 11:35 he shows how: put what you need, a counter, into the state. At 1:33:34 he describes a state that includes the observations seen so far, a belief without the word. The slides finish it: the history is always Markov, and so is a belief. On the island every bot was blind to the step clock, and the planned hidden-wall build makes the gap deliberate, with RUNNER REMEMBERS BUMPS carrying the smallest possible belief. Carry one rule forward: when your state is not Markov, add memory until it is.

## Experiments the lecture asks for that the island has not run

- Exact random-walk value with the step count in the state: whether the 100-step limit explains the 1.7-point gap.
- PLANNER with gamma 0.9: discounting changes the values, and it would show whether the route changes too.
- A noisy strip (random sideways pushes): whether the PLANNER's plan survives real dice.
- Exact values of the final SARSA and Q-LEARNING policies, square by square: Silver's partial ordering, whether either is better everywhere.
