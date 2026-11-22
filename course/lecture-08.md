# Lecture 8: Integrating Learning and Planning

*David Silver's lecture 8 (UCL, 2015), gone through in his order and re-explained with the Tracer experiments on Workshop Island. The lecture and its slides are his: [video](https://www.youtube.com/watch?v=ItMutbeOHtc), [course page](https://davidstarsilver.wordpress.com/teaching/). The words below are a re-explanation. Every island number comes from the logged runs in this repository.*

Overwatch cannot run faster than real time, so every real step costs Tracer about a quarter of a second. The bot called Q-LEARNING learns only from the steps she really takes, while DYNA-Q also keeps a table of what each move did and replays 20 imagined moves from it after every real one. Silver's eighth lecture asks how much more an agent can learn from each real step if it builds its own copy of the world and practises inside it. His answer is to learn that copy, which he calls a model, from real experience, and then to plan, which here means running your usual learning method on steps drawn from the model for as long as there is time to think.

**Two windows:** this page, and [Game 8: Recall](../workshop/games/g08.md), an Overwatch custom game for this lecture (paste `workshop/compiled/game-08.txt` into a custom game's settings and start it). The game opens at stop 1 and waits. Read down this page; at each box marked Alt+Tab, switch to the game, do that stop, and switch back. The game never moves on while you read.

## The lecture in order

### [02:40](https://www.youtube.com/watch?v=ItMutbeOHtc&t=160s) This time the agent learns a model of the world
Once you have opened a door and seen the room behind it, you can think about walking through that door again without getting up. That knowledge of what a move does and what it brings is what Silver calls a model. The word means many things to many people, he says, and here it means one thing: the agent's own understanding of how one situation, or state, leads to the next, and of the reward each move pays.

Until now the agent learned one of two things straight from experience: a rule for choosing a move, called a policy, or an estimate of the reward still to come, called a value function. This time it learns a model from experience instead. With a model it can take imagined steps in what Silver draws as a cartoon copy of the world, and ask the copy where a move would land and what it would pay.

He draws the method as a loop. Real experience builds the model. The agent plans with the model, which means looking ahead inside it. Planning gives values, and the values choose the next real action.

**On the island:** the model is a table. For each square and each move it holds the square she lands on and the reward. DYNA-Q builds her table as she walks; PLANNER was handed the true rules.

### [11:43](https://www.youtube.com/watch?v=ItMutbeOHtc&t=703s) Why build one: sometimes the rules are simpler than the values
In chess it is easy to say where a pawn stands after you push it, and very hard to say who is winning afterwards. That gap is Silver's main reason for building a model. Moving one piece by one square can turn a won position into a lost one, so a score for every position, the value function of earlier lectures, is hard to learn directly. The model is just the rules of the game, which are simple, and by looking ahead with the rules the agent can work the values out.

He gives two more advantages. A model can be learned from examples that come with the right answer attached, which is called supervised learning. Every real step is such an example, because it shows where that move led. A model also lets the agent reason about what it does not know, so it can choose to go where its understanding is weakest.

The cost is a second place for mistakes to enter. The model is approximate, and the values computed from it are approximate in their own right, so there are two sources of error where there used to be one.

**On the island:** the rules fit in one line. The values took PLANNER 13 sweeps (passes over every square) to settle, with good news travelling back one column per sweep.

### [15:54](https://www.youtube.com/watch?v=ItMutbeOHtc&t=954s) A model predicts where you land and what you are paid
A model has to predict two things about any move: where it lands you and what it pays. Silver writes the world down as a list of situations (states), moves (actions), the chances of passing from one state to the next, and the rewards. The course has called such a list a Markov decision process, or MDP, since lecture 2. The model is the agent's own version of it, with adjustable numbers inside, called parameters and written eta.

He assumes the agent already knows which states and actions exist. That leaves two things to estimate: `S' ~ P_eta(S' | S, A)` and `R = R_eta(R | S, A)`. In words: given where you are and what you did, predict where you land and what you are paid.

The two are different kinds of problem. The reward is one number to fit, which is called regression. The next state is a spread of possible outcomes to fit, which is called density estimation, and his example is a helicopter that the wind pushes left 30% of the time and right 70%.

Which steps are worth recording, only the ones that got somewhere or the bumps into a wall as well, is what the game asks next.

> **Alt+Tab · game 8 · stop 1 of 6: Walk the maze once yourself**
>
> **What he just said:** A model is the agent's own guess of where a move lands and what it pays, and every real step is one worked example to learn that guess from.
>
> **In the game:** The game waits on the blue pad. Walk with W, A, S and D onto a pad next to yours, one pad at a time, until you reach the green pad. A red ball is wall and bounces you back. There is no clock.
>
> **Before you press:** Before you set off, decide whether a bump into the wall is worth remembering, or only the steps that got somewhere.
>
> <details><summary>Back from the game: what you just saw</summary>The right side counted your steps and your bumps. Each one became a line in the replaying bot's memory: from this pad, with this move, you landed there and were paid this much. That memory is its model. Because you reached the goal, the model already holds the one reward in the maze, and each bump is a line too, saying that move goes nowhere. <em>In an agent:</em> An agent that keeps logs of real conversations is collecting the same kind of lines: what it said, and what the user said back.</details>

**On the island:** each real step is one example: the square and the move go in, the reward and the next square come out. A step misses its square only 0.21 times per 1,000 steps, so the spread is nearly a single point.

### [27:54](https://www.youtube.com/watch?v=ItMutbeOHtc&t=1674s) The simplest model is a tally, shown on the AB example
The simplest way to predict what a move will do is to keep a tally of what it did before. Silver calls this a table lookup model: a table with one entry for every situation (state) and move (action), filled in by counting.

Written out, the tally is `P_hat(s' | s, a) = N(s, a, s') / N(s, a)`. In words: the chance of landing in s' is the share of past tries from s with a that landed there. The reward estimate is the average reward seen.

The same model can be held by remembering instead of counting. Keep every step as a record of four things (state, action, reward, next state), which he calls a tuple, and draw a matching one at random when you need a prediction. He says the two ways give the same information.

He then counts on the AB example from lecture 4, eight short runs from start to finish (episodes). In one, A paid 0 and led to B, which paid 0. In six, B paid 1. In one, B paid 0. Counting gives a model in which A always leads to B with reward 0, and B pays 1 six times in eight.

> **Alt+Tab · game 8 · stop 2 of 6: Pick replays, then watch race 1**
>
> **What he just said:** The simplest model stores every step it has seen, and drawing one of those stored steps at random is the same as asking the model what happens next.
>
> **In the game:** Press F (Interact) to change the replays per real step between 0, 5 and 20, and R (Reload) to start. Answer two questions with left click, right click or melee. Then watch both bots run 10 trips; the game pauses when the plain bot first reaches the goal.
>
> **Before you press:** Commit to how many pads the plain bot will know the way from after its first arrival, and to which bot first makes a trip of 10 steps or fewer.
>
> <details><summary>Back from the game: what you just saw</summary>At the pause, orange light stood on the pads the plain bot knows and blue balls on the replaying bot's. Q-learning from lecture 5 moves good news back one pad per visit, so a first arrival teaches the plain bot one pad. The replaying bot reruns stored steps, your walk among them, between real steps, so the news spreads further. With 0 replays the two are one learner with the same dice and tie trip for trip. <em>In an agent:</em> Replaying stored steps is like an agent rereading its own logged conversations between new ones.</details>

**On the island:** DYNA-Q's model is a table over 48 squares and 4 moves. the island fact sheet does not say whether it keeps counts or tuples. With slips (steps that miss their square) this rare, the two agree.

### [33:17](https://www.youtube.com/watch?v=ItMutbeOHtc&t=1997s) Planning by sampling: treat the model as if it were the world
Once you have a copy of the world in your head, the simplest way to use it is to practise inside it as you would practise outside. Planning, Silver says, means solving the world the model describes. One way is to sweep over every situation (state) with the rules until the scores settle, the lecture 3 method called value iteration.

He prefers a second way. Use the model only to produce imagined steps, one random draw at a time, as if it were the real world. Then learn from them with any method from lectures 4 and 5 that needs no rulebook, the model-free methods: Monte Carlo, Sarsa, Q-learning. He calls this sample-based planning. Random draws land mostly on likely outcomes, so the effort goes there. That breaks the explosion of work that comes as the number of states grows, known as the curse of dimensionality.

On the AB example, eight runs (episodes) sampled from the counted model give a value of 1 for A and 0.75 for B, written V(A) = 1 and V(B) = 0.75. Asked how to divide time between acting and thinking, he says to act at the rate the world demands, and "You plan at whatever rate you can think at."

> **Alt+Tab · game 8 · stop 3 of 6: Change the replays, run race 2**
>
> **What he just said:** Planning means drawing imagined steps from the model and learning from them as if they were real, as many as there is time to think.
>
> **In the game:** Pick a different number with F (Interact) and start with R (Reload). Answer one question with left click, right click or melee, then watch race 2.
>
> **Before you press:** Decide whether the replaying bot's real steps over 10 trips will be far fewer, about the same, or far more than in race 1.
>
> <details><summary>Back from the game: what you just saw</summary>The plain bot rolls the same dice every race, so its row did not move: it is the yardstick. Going from 0 replays to some cuts the replaying bot's real steps many times over; going from 5 to 20 changes little. The shortest trip is 8 steps, and once the way has spread through memory, more thinking cannot make it shorter. This is sample-based planning, and its returns shrink. <em>In an agent:</em> More practice runs against a simulator stop helping once the agent already does everything that simulator can teach it.</details>

**On the island:** this is the answer in principle to the speed question. The clock cannot be sped up, so DYNA-Q gets more learning from each real step: 20 imagined updates for every real one.

### [44:23](https://www.youtube.com/watch?v=ItMutbeOHtc&t=2663s) A wrong model gives a confident wrong answer
If your map is wrong, the best route on the map may be the wrong way to go. That is Silver's warning about planning. Suppose the planning itself is flawless. It still finds only the best rule for choosing moves, the best policy, for the world the model describes, and the real world may differ. In his words, "model-based RL is only as good as the model that we've learned."

He does not treat this as a reason to drop models. With too little data every method is approximate, and learning a model first is one more way to be approximate, sometimes better and sometimes worse.

He names two remedies. One is to fall back on learning straight from real experience, the model-free way, when the model cannot be trusted. The other is to reason explicitly about how unsure the model is, which is called model uncertainty. That is the Bayesian approach, and he leaves it to bonus slides.

The game now asks which is hurt more when the world changes: a learner with an out-of-date model, or a learner with only out-of-date values.

> **Alt+Tab · game 8 · stop 4 of 6: Move the gap, predict who struggles**
>
> **What he just said:** A plan is only as good as the model behind it, so a model that has gone wrong produces a wrong plan with full confidence.
>
> **In the game:** Press R (Reload) to move the gap to the far side of the wall. Both bots keep what they learned. Answer with left click, right click or melee which bot will need more real steps over the next 10 trips.
>
> **Before you press:** Decide whether the replaying bot's out-of-date memory or the plain bot's out-of-date values will cost more real steps.
>
> <details><summary>Back from the game: what you just saw</summary>The red balls moved: the old gap is shut, and a new one opened on the far row. The replaying bot's memory still says the old gap leads through, and the plain bot's values say the same thing in another form, as numbers on each pad. The answer shows in race 3 at the next stop, in the two totals on the right. <em>In an agent:</em> When the users change and the simulator does not, everything the agent rehearsed describes users who are gone.</details>

**On the island:** the model is nearly exact, so this failure is hard to provoke. The hidden-wall build being run now shuts a square at random each episode, which makes a world that a table knowing only her square cannot model. There are no results yet.

### [51:18](https://www.youtube.com/watch?v=ItMutbeOHtc&t=3078s) Dyna and Dyna-Q: learn from real and imagined steps together
An agent can learn from what really happened and from what it imagines at the same time. Silver presents an old design by Rich Sutton that does this, called Dyna. The model is learned from real experience, and the values from real and imagined (simulated) experience together.

The simplest version is Dyna-Q (54:01). After every real step it does three things. It corrects the score of the move just made (a score for a situation and a move together, written Q) by the lecture 5 rule called Q-learning. It updates the model with what the step showed. Then, a set number of times written n, it picks a situation and move it has tried before, asks the model what happened, and makes the same correction.

The correction is `Q(S, A) <- Q(S, A) + alpha (R + gamma max_a' Q(S', a') - Q(S, A))`. In words: nudge a move's value toward its reward plus the best value where it leads, once for real and n times in imagination.

In Sutton's maze, n = 0 (plain Q-learning) needs about 30 attempts, or episodes. With n = 5 the agent is near the best path of about 14 steps after a couple. Before the first arrival at the goal there is little signal, Silver adds, so the first episode barely differs (1:00:59).

**On the island:** DYNA-Q uses n = 20. Her mean return (average total reward per episode) over the first 40 episodes was -31.7 against Q-LEARNING's -57.6. Yet both had a median first goal at episode 13: a model cannot replay a +50 it has never seen.

### [1:01:09](https://www.youtube.com/watch?v=ItMutbeOHtc&t=3669s) When the maze changes, planning does not replace exploring
Suppose the one gap in a wall is bricked up overnight and a new gap is opened further along. Everything you remember about getting through that wall is now wrong, and nothing you remember points at the new gap. Silver puts an agent in that position: partway through a run, he moves the gap in a maze wall.

The agent's model, its record of what each move does, still says the old way works. Planning trusts the model and keeps sending the agent there, so performance flatlines until the agent, by trying moves that do not look best (exploring), finds the new gap.

One fix is a bonus for any move, from any place in the maze, that has gone untried for a long time. The variant with that bonus is called Dyna-Q+, and it recovers sooner.

He also shows the opposite change, where a shortcut opens while the old path still works. Plain Dyna-Q, the learner from the last part, never notices, because it keeps using the path it knows. Dyna-Q+ revisits stale places and finds the shortcut. Which takes longer after a change, correcting the record of the old gap or finding the new one, is what the game asks next.

> **Alt+Tab · game 8 · stop 5 of 6: Predict the fix, watch race 3**
>
> **What he just said:** When the maze changes, the model keeps recommending the old route until real experience corrects it, so planning cannot stand in for exploring.
>
> **In the game:** Answer one question with left click, right click or melee, then watch race 3 with 20 replays per real step.
>
> **Before you press:** Decide which comes later for the replaying bot: fixing its memory of the old gap, or finding the new one.
>
> <details><summary>Back from the game: what you just saw</summary>Trips that stop at the 200-step limit mean a bot's values still point at the shut gap; only real steps lower them. The replaying bot bumps the old gap within a few steps, which rewrites that line, and its replays spread the fix. Finding the new gap takes far longer: no memory points there, and only a random step can find it. The last line counts replays of memories the move made untrue. <em>In an agent:</em> No amount of rehearsal on old logs tells an agent about a tool or a user behaviour it has never met; it has to try.</details>

> **Alt+Tab · game 8 · stop 6 of 6: Read the summary**
>
> **What he just said:** A version called Dyna-Q+ adds a small reward for moves untried for a long time, so it goes back to check and notices a changed maze sooner.
>
> **In the game:** Press R (Reload) to show the summary: three lines on what you did, what it is called, and where it shows up in a language-model agent, under your prediction score.
>
> **Before you press:** Before you press, name in a few words what the replaying bot had that the plain bot lacked.
>
> <details><summary>Back from the game: what you just saw</summary>You walked once, and the replaying bot turned your steps and its own into a model it could rehearse between real steps. That is Dyna-Q: learn a model from experience, then plan by replaying it. The game left out Dyna-Q+, which would have found the new gap sooner, and it left out search from the current position. <em>In an agent:</em> An agent trained against a simulated user learns that simulation, and where the simulation differs from real users it learns the wrong lessons quickly.</details>

**On the island:** Not run on the island. The experiment would shut a square in the edge row partway through a run and compare DYNA-Q with a DYNA-Q+ bot.

### [1:04:33](https://www.youtube.com/watch?v=ItMutbeOHtc&t=3873s) Forward search: only the situation you are in now matters
A climber halfway up a rock face needs the next handhold, not a plan for tomorrow's lunch. Silver uses the picture to say where thinking should be spent. Dyna replayed steps from anywhere the agent had been. His next approach cares about one situation above the rest, the state the agent is in right now. He calls it forward search.

It looks ahead from the current state: each move available now, then what might follow. The result is a branching tree with the present at its root. The agent solves only the small problem that starts from now, not the full description of the task, which the course calls the MDP. In his words, "Solving the whole MDP is a big waste of resource."

One way to look ahead is to imagine whole runs from now to the end (episodes), drawn from the model. He calls this simulation-based search. The simplest form fixes a rule for choosing moves in imagination, called the simulation policy. For each move available now the agent plays out a number of imagined episodes, written K, and scores the move by `Q(s_t, a) = (1/K) * sum of the K returns`. In words: try each first move many times in imagination and pick the one whose imagined games went best on average. He calls this simple Monte Carlo search.

**On the island:** Not run on the island. PLANNER solved the whole grid before she moved, the opposite approach.

### [1:13:49](https://www.youtube.com/watch?v=ItMutbeOHtc&t=4429s) Monte Carlo tree search improves its own simulations
The search in the last part imagines with a fixed rule, so its imagined games never get smarter. The next method keeps notes on its imagined games and uses them to imagine better ones. It is called Monte Carlo tree search, or MCTS.

For every situation (state) and move its imagined games pass through, MCTS stores the average total reward those games went on to collect, their mean return. The stored states and moves form a tree growing out from the current state.

Each imagined game has two phases. Inside the tree, a rule called the tree policy picks the move with the best average, with some exploration (an occasional other move), and it improves as the averages improve. Beyond the tree, where nothing is stored yet, a fixed rule called the default policy, often random, plays on to the end.

Silver points out that this is the lecture 5 method of improving choices from the averages of whole runs, called Monte Carlo control, applied to imagined runs that start from now. That is why, run for long enough, it settles on the best search tree. Asked whether one random imagined game is a poor guide, he says the tree grows over it, and "uniform random isn't as dumb as you might think."

**On the island:** Not run on the island. Under the random policy the start square is worth -114.4, which is worse than the -101 of stepping off. That is the trap that sent MONTE CARLO over the edge.

### [1:18:52](https://www.youtube.com/watch?v=ItMutbeOHtc&t=4732s) Go: where search by simulation won
Go is the board game where search by imagined games won, after the approach that had worked for chess failed. Chess programs looked at every continuation they could reach, which is called brute-force search. In Go that got nowhere.

Silver sets the game up as a reward problem. The reward is 0 on every move until the end, then 1 if Black wins, so `v(s) = P[Black wins | S = s]`. In words: a position's value is the chance Black wins from it. The simplest estimate needs no tree: four random games imagined from a position, two of them won by Black, give 0.5.

Tree search builds on those imagined games. Each one adds a position to the tree and updates the win counts along its path, so the root reads 1 of 1, then 1 of 2, then 2 of 3. The branches that keep winning are searched deeper.

Go programs jumped in strength once two of them, MoGo and CrazyStone, brought in search by imagined games (Monte Carlo search), and by his account they have reached a rank of about six dan. He lists why the method works: it follows the most promising line first (best-first), it needs only a model it can draw samples from (a black-box model), and it can be stopped at any time.

**On the island:** Not run on the island. The two-player build for lecture 10 has a blocker, but its runner is Q-learning, not a search.

### [1:30:57](https://www.youtube.com/watch?v=ItMutbeOHtc&t=5457s) TD search: learn after every imagined step
An imagined game does not have to be finished before you learn from it. Monte Carlo tree search (MCTS), as described so far, waits for each imagined game to end and then averages the results. Silver says that recipe is not required: the two ideas doing the work are searching forward from now and sampling.

So he swaps in the lecture 4 way of learning, which corrects each guess from the next guess and is called temporal-difference or TD learning. TD search runs the same imagined games from the situation the agent is really in, but after every imagined step it applies the lecture 5 form of that correction for moves, called Sarsa: `delta Q(S, A) = alpha (R + gamma Q(S', A') - Q(S, A))`. In words: move a move's value toward its reward plus the value of the next move chosen, without waiting for the imagined game to end.

Learning a guess from another guess is called bootstrapping. Here, as in the earlier lectures, it makes the estimates jump around less (lower variance) and gives them a steady error inherited from the guesses they lean on (higher bias). It is usually more efficient, most of all where many paths reach the same situation (state), because what one path learned about it is already there when another arrives.

**On the island:** Not run on the island. The strip has many paths to each square. The experiment would set TD search against MCTS from the start square.

### [1:35:08](https://www.youtube.com/watch?v=ItMutbeOHtc&t=5708s) Dyna-2: long-term and short-term memory
A climber brings two kinds of knowledge to the rock: how to climb in general, and what she has just worked out about this particular hold. Silver's last design, Dyna-2, gives an agent both. It is the Dyna idea of combining real and imagined experience, applied to forward search.

Dyna-2 keeps two sets of adjustable numbers from which its scores are computed, called weights. The long-term set is learned from real experience by correcting each guess from the next one, which is TD learning, and it holds general knowledge. The short-term set is learned by TD search, the same correction made inside imagined games from the situation the agent is in now, and it holds what is true of this situation only. His example is the loose rock under this handhold. The value the agent uses is the sum of the two.

He ends on one result from Go, the share of games won against a standard benchmark program called GnuGo. TD learning on real Go games won about 5%. The same updates applied to imagined games from the current position beat the tree search above, MCTS, after about a thousand steps of computation. Dyna-2 did best.

**On the island:** Not run on the island. Every bot's Q table, its scores for each square and move, is long-term memory only.

## What the island measured for this lecture

| All finished runs | DYNA-Q | Q-LEARNING |
|---|---|---|
| Runs | 9 | 11 |
| Mean return, first 40 episodes | -31.7 | -57.6 |
| Mean return, last 40 episodes | 15.1 | 7.5 |
| Falls per 100 training episodes (95% interval) | 24.4 (18.6 to 29.5) | 26.5 (22.4 to 30.4) |
| Episode of first goal (median) | 13 | 13 |
| Steps per training episode | 12.9 | 18.6 |
| Runs with 10 clean test crossings | 9/9 | 11/11 |

Over the first 40 episodes DYNA-Q's mean return was 25.98 higher (95% interval 15.53 to 36.25, p 0.0007), and she used 851.48 fewer real steps per run (1,942.33 against 2,793.82; interval -1,019.15 to -673.20). By the last 40 the gap of 7.59 is inconclusive (interval -3.19 to 18.58), as is the fall difference of -2.11 (interval -9.06 to 4.49): falls come from the random step, which planning cannot stop. All Dyna comparisons are exploratory, uncorrected for multiple comparisons; only SARSA against Q-learning on falls was planned. One planning budget (20) was tried, and a nearly exact model says nothing about Silver's wrong-model case. On speed: 25.6 real steps a second against about 2.2 for the earlier single-bot build came from double running speed and ten bots at once; imagined updates add learning per step, not steps.

## Guess first

<details><summary>DYNA-Q and Q-LEARNING both take a random step one time in ten. Will the bot that thinks between steps fall clearly less?</summary>
No clear difference: 24.4 against 26.5 falls per 100, and the interval for the difference (-9.06 to 4.49) includes zero, so inconclusive. Late falls come from the random step itself. Silver treats exploration as separate from planning (50:03).
</details>

<details><summary>Will DYNA-Q reach the goal for the first time in fewer episodes than Q-LEARNING?</summary>
No: the median first goal was episode 13 for both. Her model replays only moves she has made, and before the first arrival none carried the +50. The gain comes after, when the news spreads backward in her head.
</details>

<details><summary>Lecture 4: on the AB data, batch Monte Carlo gave V(A) = 0 and batch TD gave 0.75. Which does planning with the counted table model agree with in the long run?</summary>
TD. Lecture 4's slides say TD converges to the maximum likelihood Markov model, which is exactly this lecture's counted model. Silver's eight samples gave V(A) = 1 by chance; with many samples it settles at 0.75. He says TD built this model implicitly (31:19).
</details>

<details><summary>Lecture 5: MONTE CARLO control learned to step off the edge. Would simple Monte Carlo search with uniform random rollouts from the start square step off too?</summary>
Probably. The start square is worth -114.4 under the random policy, worse than -101 for stepping off, so random rollouts after a forward move would likely score below the jump (not run). Full MCTS escapes in the limit as its tree policy replaces random play (1:27:28).
</details>

<details><summary>Halfway through a run an edge-row square becomes a wall. Which recovers faster: DYNA-Q, or DYNA-Q+ with a bonus for moves untried in a while?</summary>
DYNA-Q+. Plain DYNA-Q's model still says the old route works, so her imagined updates keep recommending it until real bumps fix the model. The bonus sends DYNA-Q+ to neglected moves sooner. This is Silver's blocking maze (1:01:09), not run here.
</details>

<details><summary>Lectures 4 and 5 showed bootstrapping often beats waiting for the full return. On the strip, should TD search beat Monte Carlo search?</summary>
Likely. Many paths reach the same square, which Silver says is where TD search helps most: a value learned along one path is reused by another (1:33:45). He notes exceptions, and the island has run no search. On the island the TD bots learned where Monte Carlo control did not, which points the same way.
</details>

## Cards

- Q: What is a model here? | A: The agent's learned estimate of where a move leads and what it pays, one step ahead.
- Q: Why is model learning supervised? | A: Every real step gives an input (state, action) and the right output (reward, next state).
- Q: How does a table lookup model estimate a transition? | A: The share of past tries from that state and action that landed in each next state.
- Q: What is sample-based planning? | A: Generate imagined experience from the model, then apply a model-free method such as Q-learning to it.
- Q: What limits model-based RL? | A: It finds the best policy for the model; a wrong model gives a wrong plan.
- Q: What does Dyna-Q do after each real step? | A: A Q-learning update, a model update, then n Q-learning updates on transitions sampled from the model.
- Q: What are MCTS's two policies? | A: An improving tree policy inside the tree and a fixed default policy, often random, beyond it.
- Q: What are Dyna-2's two memories? | A: Long-term weights from real experience by TD, short-term weights from simulations by TD search; the value is their sum.

## In language-model terms

In tau-bench an agent talks to a simulated customer (another language model playing a user), calls tools on a database, and is scored at the end on whether the database came out right. For the agent, the simulated customer and tools are the environment, handed over: Silver's case where someone tells you the rules (1:10:08). Model-based RL in his exact sense would be fitting your own predictor of customer replies from logged conversations and practising against it; then the agent gets as good as the best policy for that customer model, no better.

Dyna maps onto training on real conversations mixed with generated ones. It breaks at the state: a conversation is not one of 48 squares, so the model must generalise, and its errors compound with the policy's.

Forward search maps loosely onto sampling several continuations from the current turn and keeping the best; tau-bench pays once at the end, like Go, so this needs a value estimate or a simulator run to the end. One point holds exactly: real tool calls with side effects cannot be undone, so risky moves belong in imagination.

## The thread to partial observability

Silver assumes the states and actions are known (16:53), and the model predicts the next state from the current one, which works only if the state holds everything that matters for what comes next. Asked about learning your own features (25:47), he agrees raw inputs may be a poor state. Three things carry forward. A model indexed by the wrong state is wrong in a way more data will not fix: in the hidden-wall build, a square-only table would see column 6 sometimes block and sometimes not (no results yet). Reasoning about model uncertainty, the Bayesian route he skipped, is already a belief: a probability over which world you are in. And Dyna-2's short-term memory has the shape of the RUNNER REMEMBERS BUMPS condition: a small memory of this episode standing in for what cannot be seen.

## Experiments the lecture asks for that the island has not run

- DYNA-Q with 0, 5, 20 and 50 imagined updates: Silver's maze curve, and where extra thinking stops paying.
- Shut an edge-row square at episode 75: DYNA-Q against DYNA-Q+, the flatline and the recovery.
- Simple Monte Carlo search and MCTS with random rollouts on a learned table: do rollouts pick the jump.
- PLANNER's value iteration on a learned table: planning with a learned model, without Dyna's mixing.
- A Dyna-2 style bot on the hidden-wall strip, its short-term table reset each episode.
