# Lecture 8: Integrating Learning and Planning

*David Silver's lecture 8 (UCL, 2015), gone through in his order and re-explained with the Tracer experiments on Workshop Island. The lecture and its slides are his: [video](https://www.youtube.com/watch?v=ItMutbeOHtc), [course page](https://davidstarsilver.wordpress.com/teaching/). The words below are a re-explanation. Every island number comes from the logged runs in this repository.*

Overwatch will not run faster than real time, so every real step costs Tracer about a quarter of a second, and no setting buys you more of them. The bot called Q-LEARNING learns only from the steps she really takes. DYNA-Q also keeps a table of what each move did, and after every real step she stands still and replays 20 imagined moves from it. Silver's eighth lecture asks how much more you can squeeze out of one real step if you build your own copy of the world and practise inside it. His answer: learn the copy from real experience (he calls it a model), then plan, which here just means running your usual learning method on steps drawn from the model for as long as you have time to think.

**Two windows:** this page, and [Game 8: Recall](../workshop/games/g08.md), an Overwatch custom game for this lecture (paste `workshop/compiled/game-08.txt` into a custom game's settings and start it). The game opens at stop 1 and waits. Read down this page; at each box marked Alt+Tab, switch to the game, do that stop, and switch back. The game never moves on while you read.

## The lecture in order

### [02:40](https://www.youtube.com/watch?v=ItMutbeOHtc&t=160s) You can play the map in your head. Now so can the agent.
After enough games you can play a map with your eyes shut. From spawn, you know the left door opens onto a long sightline and the stairs lead to high ground, without walking there to find out.

That knowledge, what a move does and what it pays, is what Silver calls a model. The word means many things to many people, he admits. Here it means one thing: the agent's own picture of how one situation (a state) leads to the next, and of the reward each move brings.

Until now the agent learned one of two things straight from experience: a rule for choosing moves (the policy) or a guess at the reward still to come (the value function). Now it learns the model, which lets it take imagined steps in what Silver draws as a cartoon copy of the world. Where would this move land? What would it pay?

He draws the method as a loop. Real experience builds the model. Planning, which means looking ahead inside the model, gives values. The values choose the next real move.

Your feet feed the map, and the map tells your feet where to go.

**On the island:** the model is a table. For each square and each move it holds the square she lands on and the reward. DYNA-Q builds her table as she walks; PLANNER was handed the true rules.

### [11:43](https://www.youtube.com/watch?v=ItMutbeOHtc&t=703s) Easy to say what charge does, hard to say whether to charge
Ask anyone what Reinhardt's charge does and you get one sentence: he runs forward and pins the first enemy he hits. Ask whether you should charge right now and you get an argument that outlasts the match.

Silver uses chess. Where a pawn stands after you push it is trivial. Who is winning afterwards is very hard, because moving one piece by one square can turn a won position into a lost one. So a score for every position, the value function of earlier lectures, is hard to learn head on.

The rules are easy. The values are hard.

That gap is his main reason for building a model: learn the rules, which are simple, and work the values out by looking ahead with them.

He gives two more reasons. Learning a model is supervised learning, the kind where every example comes with the right answer attached, and every real step is one: it shows you where that move led. And a model lets you reason about what you do not know, so you can go where your picture is weakest.

The bill arrives as error. The model is approximate, and the values computed from it are approximate in their own right. One source of error has become two.

**On the island:** the rules fit in one line. The values took PLANNER 13 sweeps (passes over every square) to settle, with good news travelling back one column per sweep.

### [15:54](https://www.youtube.com/watch?v=ItMutbeOHtc&t=954s) Two guesses per move: where you land, and what it pays
Every frag you throw as Junkrat comes with two silent guesses. Where will it end up? And how much will it do when it gets there?

A model makes those same two guesses for every move. Silver writes the world down as a list: the situations (states), the moves (actions), the chances of passing from one state to the next, and the rewards. The course has called such a list a Markov decision process, or MDP, since lecture 2. The model is the agent's own version of it, with adjustable numbers inside, called parameters and written eta.

He assumes the agent already knows which states and moves exist. That leaves only the two guesses.

<details markdown="1"><summary>The formula, when you want it</summary>

`S' ~ P_eta(S' | S, A)` and `R = R_eta(R | S, A)`. In words: given where you are and what you did, predict where you land and what you are paid.

</details>

They are different kinds of problem. What a move pays is one number to fit, which is called regression. Where it lands you is a spread of possible outcomes to fit, which is called density estimation. His example is a helicopter that the wind pushes left 30% of the time and right 70%.

One guess is a number. The other is a smear.

The game now asks which steps are worth writing down: only the ones that got somewhere, or the bumps into the wall as well.

> **Alt+Tab · game 8 · stop 1 of 6: Walk the maze once yourself**
>
> **What he just said:** Silver's model is two guesses per move: where you land and what it pays. The good news is that the answer key comes free. Every real step you take is one worked example: from here, with this move, you landed there and were paid this.
>
> **In the game:** The game waits on the blue pad. Walk with W, A, S and D onto a pad next to yours, one pad at a time, until you reach the green pad. A red ball is wall and bounces you back. There is no clock.
>
> **Before you press:** Before you set off, decide whether a bump into the wall is worth remembering, or only the steps that got somewhere.
>
> <details><summary>Back from the game: what you just saw</summary>Look right: your steps and your bumps, counted. Every one is now a line in the replaying bot's memory: from this pad, with this move, you landed there and were paid this much. That memory is its model. You reached the goal, so it already holds the only reward in the maze. The bumps count too. Each is a line saying that move goes nowhere. <em>In an agent:</em> Every logged conversation is a stack of the same lines: what the agent said, and what the user said back. Nobody had to label them. The user did, by answering.</details>

**On the island:** each real step is one example: the square and the move go in, the reward and the next square come out. A step misses its square only 0.21 times per 1,000 steps, so the smear is nearly a single point.

### [27:54](https://www.youtube.com/watch?v=ItMutbeOHtc&t=1674s) The simplest model is a tally, and Silver tallies the AB example
Over the last five fights the enemy Genji came through the left door four times. You did not build a theory of Genji. You counted, and now you face left.

Four out of five is already a model.

It is the simplest kind there is. Silver calls it a table lookup model: a table with one entry for every situation (state) and move (action), filled in by counting what happened. The reward estimate is the average reward seen.

<details markdown="1"><summary>The formula, when you want it</summary>

`P_hat(s' | s, a) = N(s, a, s') / N(s, a)`. In words: the chance of landing in s' is the share of past tries from s with a that landed there.

</details>

You can hold the same model by remembering instead of counting. Keep every step as a record of four things (state, action, reward, next state), which he calls a tuple, and when you need a prediction, pull out a matching one at random. He says the two ways give the same information.

Then he tallies the AB example from lecture 4: eight short runs from start to finish (episodes).

- In one, A paid 0 and led to B, which paid 0.
- In six, B paid 1.
- In one, B paid 0.

Count them up and the model says A always leads to B with reward 0, and B pays 1 six times in eight. (Nothing clever happened. It is the Genji tally with letters.)

> **Alt+Tab · game 8 · stop 2 of 6: Pick replays, then watch race 1**
>
> **What he just said:** The simplest model is a tally. Or skip the counting: keep every step you have seen, and when you want to know what a move does, pull out one of those stored steps at random. Silver says that tells you the same thing as asking the model.
>
> **In the game:** Press F (Interact) to change the replays per real step between 0, 5 and 20, and R (Reload) to start. Answer two questions with left click, right click or melee. Then watch both bots run 10 trips; the game pauses when the plain bot first reaches the goal.
>
> **Before you press:** Commit to how many pads the plain bot will know the way from after its first arrival, and to which bot first makes a trip of 10 steps or fewer.
>
> <details><summary>Back from the game: what you just saw</summary>At the pause, orange light marks the pads the plain bot knows, blue balls the replaying bot's. Q-learning from lecture 5 carries good news back one pad per visit, so a first arrival teaches the plain bot one pad. The replaying bot reruns stored steps between real ones, your walk among them, so the news spreads further while it stands still. On 0 replays they are one learner with the same dice, tied trip for trip. <em>In an agent:</em> Replaying stored steps is an agent rereading its own old conversations between new ones, and learning from each one a second time.</details>

**On the island:** DYNA-Q's model is a table over 48 squares and 4 moves. the island fact sheet does not say whether it keeps counts or tuples. With slips (steps that miss their square) this rare, the two agree.

### [33:17](https://www.youtube.com/watch?v=ItMutbeOHtc&t=1997s) Practise in your head as if it were the game
You are dead and replaying the fight. What if you had taken high ground? The game will not let you try. Your head will, as often as the respawn timer allows.

Planning, Silver says, means solving the world your model describes. One way is to sweep over every situation (state) with the rules until the scores settle, the lecture 3 method called value iteration.

He prefers the respawn-timer way. Use the model only to make up steps, one random draw at a time, as if they were real. Then learn from them with any method from lectures 4 and 5 that needs no rulebook, the model-free ones: Monte Carlo, Sarsa, Q-learning. He calls this sample-based planning.

Random draws land mostly on likely outcomes, so that is where the effort goes. That breaks the explosion of work that comes as the number of states grows, known as the curse of dimensionality.

On the AB example, eight runs (episodes) drawn from the counted model make A worth 1 and B worth 0.75, written V(A) = 1 and V(B) = 0.75.

Asked how to split time between acting and thinking, he says to act at the rate the world demands, and:

"You plan at whatever rate you can think at."

> **Alt+Tab · game 8 · stop 3 of 6: Change the replays, run race 2**
>
> **What he just said:** Planning, for Silver, is practice in your head: draw made-up steps from the model and learn from them as if they were real. The world sets how fast you act. In your head you get as many steps as you have time to think.
>
> **In the game:** Pick a different number with F (Interact) and start with R (Reload). Answer one question with left click, right click or melee, then watch race 2.
>
> **Before you press:** Decide whether the replaying bot's real steps over 10 trips will be far fewer, about the same, or far more than in race 1.
>
> <details><summary>Back from the game: what you just saw</summary>The plain bot rolls the same dice every race, so its row did not budge. It is the yardstick. Going from 0 replays to some cuts the replaying bot's real steps many times over. Going from 5 to 20 changes little. The shortest trip is 8 steps, and once the way has spread through memory, no amount of thinking turns 8 into 7. This is sample-based planning, and its returns shrink. <em>In an agent:</em> Practice against a simulator has a ceiling. Once the agent already does everything the simulator can teach it, another thousand runs teach it nothing new.</details>

**On the island:** this is the answer in principle to the speed question. The clock cannot be sped up, so DYNA-Q gets more learning from each real step: 20 imagined updates for every real one.

### [44:23](https://www.youtube.com/watch?v=ItMutbeOHtc&t=2663s) A perfect plan for the wrong world
Your team plans the perfect dive on the enemy Ana, and everyone goes in together. It lands on the spot where she stood thirty seconds ago.

Nothing was wrong with the planning. The picture it planned on was wrong.

That is Silver's warning. Make the planning flawless and it still finds only the best rule for choosing moves (the best policy) for the world the model describes. If the real world differs, the plan is wrong, and confidently so. In his words, "model-based RL is only as good as the model that we've learned."

That is no reason to drop models, he says. With too little data every method is approximate, and learning a model first is one more way to be approximate, sometimes better and sometimes worse.

He names two remedies. When you cannot trust the model, fall back on learning straight from real experience, the model-free way. Or reason explicitly about how unsure the model is, which is called model uncertainty. That is the Bayesian approach, and he leaves it to bonus slides.

The game now asks which is hurt more when the world changes: a learner with an out-of-date model, or a learner with only out-of-date values.

> **Alt+Tab · game 8 · stop 4 of 6: Move the gap, predict who struggles**
>
> **What he just said:** A plan is only as good as the model behind it. Plan perfectly on a model that has gone wrong and you get a wrong plan with full confidence, like a perfect dive on the spot where the enemy Ana stood thirty seconds ago.
>
> **In the game:** Press R (Reload) to move the gap to the far side of the wall. Both bots keep what they learned. Answer with left click, right click or melee which bot will need more real steps over the next 10 trips.
>
> **Before you press:** Decide whether the replaying bot's out-of-date memory or the plain bot's out-of-date values will cost more real steps.
>
> <details><summary>Back from the game: what you just saw</summary>The red balls moved. The old gap is shut and a new one opened on the far row. Now both bots are out of date. The replaying bot's memory still says the old gap leads through. The plain bot's values say the same thing in another form, as numbers on each pad. Which mistake costs more shows in race 3 at the next stop, in the two totals on the right. <em>In an agent:</em> When the users change and the simulator does not, the agent keeps rehearsing for users who are gone.</details>

**On the island:** the model is nearly exact, so this failure is hard to provoke. The hidden-wall build being run now shuts a square at random each episode, which makes a world that a table knowing only her square cannot model. There are no results yet.

### [51:18](https://www.youtube.com/watch?v=ItMutbeOHtc&t=3078s) Dyna-Q: Recall, but for her memory
Picture a Tracer whose Recall rewinds her memory instead of her body, with no cooldown. After every real step she jumps back to a moment she has already lived, replays it in her head, and learns from it again.

That is Dyna, an old design by Rich Sutton that Silver presents next. The model is learned from real experience. The values are learned from real and imagined (simulated) experience together.

The simplest version is Dyna-Q (54:01). After every real step it does three things:

1. **Learn from the real step.** Correct the score of the move just made (Q, a score for a situation and a move together) with the lecture 5 rule called Q-learning.
2. **Update the model** with what that step showed.
3. **Recall, n times.** Pick a situation and move it has tried before, ask the model what happened, and make the same correction.

<details markdown="1"><summary>The formula, when you want it</summary>

`Q(S, A) <- Q(S, A) + alpha (R + gamma max_a' Q(S', a') - Q(S, A))`. In words: nudge a move's value toward its reward plus the best value where it leads, once for real and n times in imagination.

</details>

In Sutton's maze, n = 0 (plain Q-learning) needs about 30 attempts, or episodes. With n = 5 the agent is near the best path of about 14 steps after a couple.

There is a catch, and Silver points it out (1:00:59). Before the first arrival at the goal there is little signal to replay, so the first episode barely differs.

You cannot rehearse a win you have never had.

**On the island:** DYNA-Q uses n = 20. Her mean return (average total reward per episode) over the first 40 episodes was -31.7 against Q-LEARNING's -57.6. Yet both had a median first goal at episode 13: a model cannot replay a +50 it has never seen.

### [1:01:09](https://www.youtube.com/watch?v=ItMutbeOHtc&t=3669s) The door you always use is a wall now
Overnight, the doorway you always flank through has been bricked up, and a new one has opened further along. Everything you remember about getting through that wall is now wrong. Nothing you remember points at the new door.

Silver does this to an agent on purpose: partway through a run, he moves the gap in a maze wall.

The agent's model, its record of what each move does, still says the old way works. Planning trusts the model and keeps sending the agent there, so performance flatlines until the agent, by trying moves that do not look best (exploring), finds the new gap.

Thinking harder about an old map does not draw the new door on it.

One fix is a bonus for any move, from any place in the maze, that has gone untried for a long time. The variant with that bonus, Dyna-Q+, recovers sooner.

He also shows the opposite change: a shortcut opens while the old path still works. Plain Dyna-Q, the learner from the last part, never notices, because it keeps using the path it knows. Dyna-Q+ revisits stale places and finds the shortcut.

Which takes longer after a change, fixing the record of the old gap or finding the new one? The game asks you next.

> **Alt+Tab · game 8 · stop 5 of 6: Predict the fix, watch race 3**
>
> **What he just said:** When the maze changes, the model keeps recommending the old route until real experience corrects it. Planning works from what you remember, and nothing you remember points at the new gap. So planning cannot stand in for exploring.
>
> **In the game:** Answer one question with left click, right click or melee, then watch race 3 with 20 replays per real step.
>
> **Before you press:** Decide which comes later for the replaying bot: fixing its memory of the old gap, or finding the new one.
>
> <details><summary>Back from the game: what you just saw</summary>A trip that stops at the 200-step limit means a bot's values still point at the shut gap, and only real steps lower them. The replaying bot bumps the old gap within a few steps, which rewrites that line, and its replays spread the fix. The new gap takes far longer. No memory points there, so only a random step can find it. The last line counts replays of memories the move made untrue. <em>In an agent:</em> Rehearsing old logs cannot teach an agent about a tool or a user behaviour it has never met. For that, it has to go and try.</details>

> **Alt+Tab · game 8 · stop 6 of 6: Read the summary**
>
> **What he just said:** Silver's fix is Dyna-Q+: a small reward for any move that has gone untried for a long time. It is the teammate who checks the other flank now and then, just in case, and so it notices a changed maze sooner.
>
> **In the game:** Press R (Reload) to show the summary: three lines on what you did, what it is called, and where it shows up in a language-model agent, under your prediction score.
>
> **Before you press:** Before you press, name in a few words what the replaying bot had that the plain bot lacked.
>
> <details><summary>Back from the game: what you just saw</summary>You walked the maze once. The replaying bot turned your steps and its own into a model and rehearsed it between real steps, a Recall for its memory. That is Dyna-Q: learn a model from experience, then plan by replaying it. Two things were left out: Dyna-Q+, which would have found the new gap sooner, and search from the current position, which the rest of the lecture covers. <em>In an agent:</em> An agent trained against a simulated user learns that simulation. Where the simulation differs from real users, it learns the wrong lessons, and it learns them fast.</details>

**On the island:** Not run on the island. The experiment would shut a square in the edge row partway through a run and compare DYNA-Q with a DYNA-Q+ bot.

### [1:04:33](https://www.youtube.com/watch?v=ItMutbeOHtc&t=3873s) Forward search: think about the fight you are in
Overtime, two seconds on the clock. Nobody on your team is thinking about the next map. Everyone is thinking about the next two seconds.

Silver makes the same point with a climber: halfway up a rock face, you need the next handhold, not a plan for tomorrow's lunch. Dyna replayed steps from anywhere the agent had been. His next approach cares about one situation (state) above the rest, the one the agent is in right now. He calls it forward search.

You look ahead from now: each move available, then what might follow each one. That draws a branching tree with the present at its root, and you solve only the small problem that starts here, not the full description of the task, which the course calls the MDP.

"Solving the whole MDP is a big waste of resource," he says.

One way to look ahead is to imagine whole runs from now to the end (episodes), drawn from the model, which he calls simulation-based search. The simplest form fixes one rule for choosing moves in imagination, the simulation policy. For each move available now you play out a number of imagined episodes, written K, and pick the move whose imagined games went best on average. That is simple Monte Carlo search.

<details markdown="1"><summary>The formula, when you want it</summary>

`Q(s_t, a) = (1/K) * sum of the K returns`. In words: try each first move many times in imagination and pick the one whose imagined games went best on average.

</details>

**On the island:** Not run on the island. PLANNER solved the whole grid before she moved, the opposite approach.

### [1:13:49](https://www.youtube.com/watch?v=ItMutbeOHtc&t=4429s) Monte Carlo tree search: the imagined games get smarter
The first week a new map is out, you know the first fight cold and wing the rest. A week later you know two fights.

The part you know grows into the part you were guessing.

Simple Monte Carlo search imagines with a fixed rule, so its imagined games never get smarter. Monte Carlo tree search, or MCTS, keeps notes on its imagined games and uses them to imagine better ones.

For every situation (state) and move its imagined games pass through, MCTS stores their mean return, the average total reward that followed. These form a tree growing out from the current state. Each imagined game has two phases:

1. **Inside the tree,** a rule called the tree policy picks the move with the best average, with some exploration (an occasional other move), and it improves as the averages do.
2. **Beyond the tree,** where nothing is stored yet, a fixed rule called the default policy, often random, plays to the end.

Silver points out that this is lecture 5's Monte Carlo control, improving choices from the averages of whole runs, applied to imagined runs from now. That is why, run long enough, it settles on the best search tree. Asked whether one random imagined game is a poor guide, he says the tree grows over it, and "uniform random isn't as dumb as you might think."

**On the island:** Not run on the island. Under the random policy the start square is worth -114.4, which is worse than the -101 of stepping off. That is the trap that sent MONTE CARLO over the edge.

### [1:18:52](https://www.youtube.com/watch?v=ItMutbeOHtc&t=4732s) Go: too messy to judge, so play it out and count
Some team fights are too messy to call by looking. So you run the setup back in scrims a few times and count how often you take the fight.

Go is where that kind of search won. The approach that had worked for chess, looking at every continuation the program could reach (brute-force search), got nowhere in Go.

Silver sets Go up as a reward problem. The reward is 0 on every move until the end, then 1 if Black wins.

<details markdown="1"><summary>The formula, when you want it</summary>

`v(s) = P[Black wins | S = s]`. In words: a position's value is the chance Black wins from it.

</details>

The simplest estimate needs no tree. Imagine four random games from a position.

Black wins two. The position is worth 0.5.

Tree search builds on those imagined games. Each one adds a position to the tree and updates the win counts along its path, so the root reads 1 of 1, then 1 of 2, then 2 of 3. The branches that keep winning get searched deeper.

Go programs jumped in strength once two of them, MoGo and CrazyStone, brought in search by imagined games (Monte Carlo search), and by his account they have reached about six dan. Why it works, he says: it follows the most promising line first (best-first), it needs only a model it can draw samples from (a black-box model), and you can stop it at any time.

**On the island:** Not run on the island. The two-player build for lecture 10 has a blocker, but its runner is Q-learning, not a search.

### [1:30:57](https://www.youtube.com/watch?v=ItMutbeOHtc&t=5457s) TD search: learn mid-game, even in your head
You do not wait for the end of the match to learn that diving in alone was a bad idea. You learn it seconds later, when your name hits the kill feed and your team is fighting four against five. You know roughly how that goes.

Monte Carlo tree search (MCTS), as described so far, does wait: each imagined game has to end before its result is averaged in. Silver says that is not required. The two ideas doing the work are searching forward from now, and sampling.

So he swaps in the lecture 4 way of learning, which corrects each guess from the next guess and is called temporal-difference or TD learning. TD search runs the same imagined games from the situation the agent is really in, but after every imagined step it applies Sarsa, the lecture 5 form of that correction for moves.

<details markdown="1"><summary>The formula, when you want it</summary>

`delta Q(S, A) = alpha (R + gamma Q(S', A') - Q(S, A))`. In words: move a move's value toward its reward plus the value of the next move chosen, without waiting for the imagined game to end.

</details>

Learning a guess from another guess is called bootstrapping. As in earlier lectures, the estimates jump around less (lower variance) but carry a steady error inherited from the guesses they lean on (higher bias). It is usually more efficient, most of all where many paths reach the same situation (state).

What one path learned about that state is already there when the next path arrives.

**On the island:** Not run on the island. The strip has many paths to each square. The experiment would set TD search against MCTS from the start square.

### [1:35:08](https://www.youtube.com/watch?v=ItMutbeOHtc&t=5708s) Dyna-2: what you always know, plus what you know this match
How to play Tracer comes with you into every match. That this match's Widowmaker keeps going back to the same perch is worth a lot for ten minutes and nothing tomorrow. You carry both and add them up without thinking.

Silver's last design, Dyna-2, gives an agent both: the Dyna idea of mixing real and imagined experience, applied to forward search. Dyna-2 keeps two sets of adjustable numbers that its scores are computed from, called weights:

1. **Long-term weights** are learned from real experience by correcting each guess from the next one, which is TD learning. They hold general knowledge.
2. **Short-term weights** are learned by TD search, the same correction made inside imagined games from the situation the agent is in now. They hold what is true of this situation only. His example is the loose rock under this particular handhold.

The value the agent uses is the two added together.

He ends on Go, with the share of games won against a standard benchmark program called GnuGo. TD learning on real Go games won about 5%. The same updates applied to imagined games from the current position beat MCTS, the tree search from earlier, after about a thousand steps of computation.

Dyna-2 did best.

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

Take tau-bench. An agent chats with a customer who is really another language model playing a user, calls tools on a database, and is scored once, at the end, on whether the database came out right.

Careful with one word here. From the agent's side, that simulated customer is not a model in Silver's sense. The customer and the tools are the environment, handed over: his case where someone tells you the rules (1:10:08). Model-based RL in his exact sense would be fitting your own predictor of customer replies from logged conversations and practising against it. Then the agent gets as good as the best policy for that customer model.

No better.

Dyna maps onto training on real conversations mixed with generated ones. It breaks at the state. A conversation is not one of 48 squares, so the model has to generalise, and its errors compound with the policy's.

Forward search maps, loosely, onto sampling several continuations from the current turn and keeping the best. But tau-bench pays once at the end, like Go, so this needs a value estimate or a simulator run all the way to the end.

One point holds exactly. A real tool call with side effects cannot be undone, so the risky moves belong in imagination.

## The thread to partial observability

Silver assumes the states and actions are known (16:53), and the model predicts the next state from the current one, which works only if the state holds everything that matters for what comes next. Asked about learning your own features (25:47), he agrees raw inputs may be a poor state. Three things carry forward. A model indexed by the wrong state is wrong in a way more data will not fix: in the hidden-wall build, a square-only table would see column 6 sometimes block and sometimes not (no results yet). Reasoning about model uncertainty, the Bayesian route he skipped, is already a belief: a probability over which world you are in. And Dyna-2's short-term memory has the shape of the RUNNER REMEMBERS BUMPS condition: a small memory of this episode standing in for what cannot be seen.

## Experiments the lecture asks for that the island has not run

- DYNA-Q with 0, 5, 20 and 50 imagined updates: Silver's maze curve, and where extra thinking stops paying.
- Shut an edge-row square at episode 75: DYNA-Q against DYNA-Q+, the flatline and the recovery.
- Simple Monte Carlo search and MCTS with random rollouts on a learned table: do rollouts pick the jump.
- PLANNER's value iteration on a learned table: planning with a learned model, without Dyna's mixing.
- A Dyna-2 style bot on the hidden-wall strip, its short-term table reset each episode.
