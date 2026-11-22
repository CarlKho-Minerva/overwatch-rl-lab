# Lecture 9: Exploration and Exploitation

*David Silver's lecture 9 (UCL, 2015), gone through in his order and re-explained with the Tracer experiments on Workshop Island. The lecture and its slides are his: [video](https://www.youtube.com/watch?v=sGuiWX07sKw), [course page](https://davidstarsilver.wordpress.com/teaching/). The words below are a re-explanation. Every island number comes from the logged runs in this repository.*

Four loot boxes sit in front of you, each with its own hidden chance of paying, and you have 30 opens. Every open is the same choice: go back to the box that has paid best so far, or try one that might be better. Silver's hour asks how much to explore and where, and his answer is to explore where you are uncertain, not at random, and to prefer methods that make fewer mistakes as time goes on. On the island, the bots that were optimistic about what they had not tried fell about a quarter as often as Q-LEARNING, who explores by coin: one move in ten is random, forever, so she keeps falling after her table knows better.

**Two windows:** this page, and [Game 9: Loot Boxes](../workshop/games/g09.md), an Overwatch custom game for this lecture (paste `workshop/compiled/game-09.txt` into a custom game's settings and start it). The game opens at stop 1 and waits. Read down this page; at each box marked Alt+Tab, switch to the game, do that stop, and switch back. The game never moves on while you read.

## The lecture in order

### [02:23](https://www.youtube.com/watch?v=sGuiWX07sKw&t=143s) Every decision made while learning is a choice between using what you know and finding out more
You can eat tonight at the restaurant you already know is good, or try the new one down the street. The new one might be worse, or it might become your favourite, and you only find out by going. Silver's other examples have the same shape: a different advert for a visitor, a new site to drill for oil.

Taking the option you believe is best is called exploitation. Doing something else on purpose, to gather information that may pay off later, is called exploration. The choice comes up because the agent learns while it acts, which Silver calls learning online: its own actions decide which data it ever sees.

He names three families of answer. The first picks a move by chance now and then, and is called random exploration. Lecture 5's rule of taking a random move with small probability epsilon, called epsilon-greedy, is one kind. A rule that picks moves with probability rising with their score, called softmax, is another. The second family prefers the option you know least about, because it might turn out better: optimism in the face of uncertainty. The third treats what the agent knows as part of its situation, and is called the information state space. Silver says it is the most correct and the most expensive.

> **Alt+Tab · game 9 · stop 1 of 8: Open eight loot boxes**
>
> **What he just said:** Every choice an agent makes while it learns is a trade: take the option that has paid best so far, or try another one to find out what it is worth.
>
> **In the game:** Four yellow pads, four boxes, each with its own hidden chance of paying 1. Walk onto a pad and press Interact (F) to open that box. Make eight opens, on any boxes you like; the game waits for each one.
>
> **Before you press:** Before your first open, decide how many opens you will give each box before you settle on one.
>
> <details><summary>Back from the game: what you just saw</summary>Each open paid 1 or 0, and the label over each pad counts your opens and pays. When the round ends, the left side shows regret: for every open, how much less your box pays on average than the best box would, added up. Eight opens across four boxes is about two looks each, which tells you very little. <em>In an agent:</em> An agent that sometimes tries a new tool or prompt instead of its usual one makes this trade on every call.</details>

**On the island:** A bot that never walks the edge row never sees the +50. A bot that never steps toward the drop never learns what it costs.

### [08:18](https://www.youtube.com/watch?v=sGuiWX07sKw&t=498s) You can explore over moves or over whole behaviours
There are two different things you can vary when you try something new: one move in one spot, or your whole way of playing for a while. Silver separates them before going on.

In the first, the agent remembers which moves it has already tried in a particular place (a state), and when it comes back it tries a different one. He calls this state-action exploration.

In the second, the agent changes the numbers that define its rule for choosing moves (its policy), runs the changed policy for a while, and sees how it does. His example is a robot given a slightly different walk. He calls this parameter exploration. Its advantage is consistency: the robot keeps one odd gait long enough to judge it, where lecture 5's occasional random move, epsilon-greedy, rolls again at every step. Its disadvantage is that it ignores which states it has visited, so Silver says it is closer to a blind search for the best settings, global optimisation, than to exploring.

The rest of the lecture covers the first kind.

**On the island:** Every bot explored over moves. Not run on the island: nudge a whole table for an episode, and keep the nudged table if the return improves.

### [11:41](https://www.youtube.com/watch?v=sGuiWX07sKw&t=701s) A row of slot machines called the bandit, and a score called regret
Picture a row of slot machines. Each pays by its own hidden odds, and nobody tells you which one is generous. You pull one arm, you get one reward, and the episode is over. Silver calls this the multi-armed bandit. There is no place to move to, so no state, only a choice of arm.

Each arm has a true worth: the average it would pay over endless pulls. This is the score for a move from lecture 5, the action value, with the state dropped. `Q(a) = E[r | a]`. In words: the value of arm a is the reward you expect from one pull of it. The best you could do is `V* = max Q(a)`. In words: the value of the best arm, which you would collect every pull if you knew which arm it was.

A player is scored by the reward given up by not pulling that best arm, totalled over every pull so far. Silver calls it regret. `L_t = sum over arms E[N_t(a)] * gap(a)`. In words: how often you pulled each arm, times how much worse it is than the best, which is called its gap.

At 19:44 a student spots the catch: the gaps depend on V*, which nobody knows.

> **Alt+Tab · game 9 · stop 2 of 8: Judge a box at three of four**
>
> **What he just said:** A row of slot machines with unknown payouts is called a bandit, and its score, regret, is the reward given up by not pulling the best arm, an arm nobody knows in advance.
>
> **In the game:** A question floats in front of you. Left click for yes, right click for no, too few opens.
>
> **Before you press:** Decide whether a box that paid 3 of its first 4 opens is surely the best of the four.
>
> <details><summary>Back from the game: what you just saw</summary>Four opens prove little. A box that pays 4 times in 10 still pays 3 or 4 of 4 about 18 times in 100, and a box that pays 55 times in 100 does it 39 times in 100. A short lucky streak looks like a great box, which is why nobody knows the best box while playing, and regret can only be counted against odds that are hidden.</details>

**On the island:** The strip is not a bandit. It is an MDP (a Markov decision process, where a move changes where she stands). The two-player build (exploratory, 12 short runs) does have one: the blocker learns her row "as a four-armed bandit".

### [21:39](https://www.youtube.com/watch?v=sGuiWX07sKw&t=1299s) Exploring at a fixed rate forever and never exploring both lose a steady amount every step
Plot the reward you have given up so far against time. If the line keeps climbing at the same slope, the strategy is making the same mistakes at the same rate and will go on making them. Silver puts two familiar strategies on this picture.

The first pulls a random arm with a small fixed probability and otherwise the arm that looks best: lecture 5's epsilon-greedy with epsilon held fixed. The random pulls never stop, so every step adds about the same amount to the reward given up against the best arm, the regret of the last part. The total climbs in a straight line.

The second scores each arm by averaging the payouts seen from it and always takes the highest average. It never explores, and it is called greedy. A few unlucky pulls can make the best arm look bad, and greedy then locks onto a worse arm for good. Its total climbs in a straight line too.

A straight-line climb is what Silver calls linear total regret. The goal is a curve that flattens, which he calls sublinear regret.

> **Alt+Tab · game 9 · stop 3 of 8: Guess which strategy gets stuck**
>
> **What he just said:** Always taking the arm with the best average can lock on to a worse arm for good, and exploring at random a fixed share of the time pays for it forever, so both lose about the same amount every step.
>
> **In the game:** Read the question. GREEDY opens the box with the best average so far; COIN does the same but opens a random box 1 time in 10, like the one random move in ten from lecture 5. Left click for greedy, right click for the coin, melee for neither.
>
> **Before you press:** Pick the strategy that can stay stuck on a bad box forever.
>
> <details><summary>Back from the game: what you just saw</summary>Greedy opens each box once, then always the best average. If the best box loses its first open while another box wins, its average sits at 0 and greedy never opens it again, in at least 23 games in 100. The coin opens every box now and then, so it never stays stuck, but it pays for those random opens forever. Use what you know or find out more: that choice is the exploration and exploitation dilemma. <em>In an agent:</em> An agent that always reuses the tool call that worked first can stay on it long after a better one exists.</details>

**On the island:** Q-LEARNING's last 40 training episodes average 7.5, against a best possible 39. Yet with exploring switched off she made 10 clean test crossings in 11 of 11 runs. Her table was fine. The coin was the cost.

### [26:12](https://www.youtube.com/watch?v=sGuiWX07sKw&t=1572s) Assume the best about every option until proven otherwise (optimistic initialisation)
Suppose you walked up to the machines believing that every one pays the maximum every time. You would not need a rule telling you to try them all. Each would look wonderful until you had played it, and only real payouts could pull its score down.

Silver calls this optimistic initialisation. Start every estimate at the highest value it could have, then always take the arm with the highest estimate, which is called acting greedily. Untried arms still carry their perfect score, so they get tried. He says it is hard to beat.

His version adds a made-up history. Pretend each arm was already pulled 100 times at the maximum payout, then keep averaging real payouts into that record. This equals starting from a belief about a payout rate that is written as counts, called a Beta prior.

Bad luck can still lock out the best arm (27:39): after a few poor results it falls below a worse arm and is never pulled again. So in theory the reward given up against the best arm, the regret, stays linear, a straight-line climb.

**On the island:** Q + OPTIMISM starts every Q (her score for a square and a move together) at 40, one above the best return of 39, and never moves at random. Falls per 100: 7.2 (7.0 to 7.3), against Q-LEARNING's 26.5 (22.4 to 30.4).

### [31:07](https://www.youtube.com/watch?v=sGuiWX07sKw&t=1867s) Exploring less over time can be nearly perfect, if you know how far apart the options are
The obvious repair for a strategy that explores at random forever is to explore less as you go. Lecture 5's rule pulls a random arm with chance epsilon and is called epsilon-greedy. While epsilon stays fixed, the reward it gives up against the best arm, its regret, grows in a straight line. The same is true of the rule that picks arms with probability rising with their score, softmax.

Now let epsilon shrink over time. On the right schedule the regret still grows, but ever more slowly, like the logarithm of time. Silver's schedule is `epsilon_t = min(1, c * |A| / (d^2 * t))`. In words: explore less as time passes, and keep exploring for longer when the best two arms are hard to tell apart. Here t counts the steps so far, c is a constant, the A between bars is the number of arms, and d is the smallest gap, the difference in value between the best arm and the second best.

His comment on the method he had called naive: "maybe it wasn't so naive at all". The catch is d. The schedule needs the gaps, and nobody knows them in advance. A guessed schedule is excellent when it is tuned just right and "a disaster" when it is wrong (55:58).

**On the island:** Q + FADING EXPLORATION uses epsilon = 1 / (1 + episode / 5), with a floor of 0.01, a guessed schedule of that 1-over-time shape. Falls per 100: 27.9 (25.4 to 30.3), against Q-LEARNING's 26.5. The difference is 1.44 (-3.25 to 6.17), which is inconclusive.

### [36:36](https://www.youtube.com/watch?v=sGuiWX07sKw&t=2196s) No method can do better than regret that grows like the logarithm of time
Before the better method, Silver gives one slide of theory about how well any method could ever do. There is a floor, proved by Lai and Robbins. However clever the strategy, the reward it gives up against the best arm, its regret, must keep growing at least as fast as the logarithm of the number of pulls, a curve that rises ever more slowly.

How high the floor sits depends on how hard the bandit (the row of machines) is. An easy one has an obviously good arm and an obviously bad arm, and one pull of each settles it. A hard one has noisy payouts, so a worse arm's results look like the best arm's from pull to pull while their averages differ.

The slide's formula is `lim L_t >= log t * sum over worse arms gap(a) / KL(R_a || R_a*)`. In words: regret grows at least like the logarithm of time, and faster when arms differ in value but look alike. KL stands for a number that is small when two arms' payouts look alike, the Kullback-Leibler divergence.

So the aim from here on is a method whose regret is logarithmic, not linear.

**On the island:** With 0.21 slips per 1,000 steps, one try reveals a move's outcome. Not run on the island: adding random slips, which would make moves look alike.

### [39:32](https://www.youtube.com/watch?v=sGuiWX07sKw&t=2372s) Prefer the option that could still turn out best (optimism in the face of uncertainty)
Silver draws three curves, one for each of three arms. Each curve is the agent's current belief about that arm's true average payout: the peak sits at its best guess, and the width shows how unsure the guess is. Green has been tried often, so its curve is narrow. Blue has barely been tried, so its curve is wide. Red is in between.

Green's best guess is the highest. Silver says to pull blue anyway, because blue has the most potential to be best: the tail of its wide curve reaches furthest. He calls this principle optimism in the face of uncertainty. If blue disappoints, the pull narrows its curve and draws the tail in, and another arm takes its turn.

To turn the principle into a rule, work out for each arm a value that the true average is unlikely to exceed, something like the top of a 95% confidence range. That value is called the upper confidence bound, UCB for short. `a_t = argmax Q(a) + U(a)`. In words: score each arm by its average so far plus a bonus that is large when the arm has rarely been tried and shrinks to zero with use, then pull the top scorer.

> **Alt+Tab · game 9 · stop 4 of 8: Open by the blue beams**
>
> **What he just said:** Optimism in the face of uncertainty picks the option whose best plausible value is highest: its average plus a bonus that is large when it has rarely been tried and shrinks with use, a score called an upper confidence bound.
>
> **In the game:** Blue beams now rise over the boxes. A beam's height is that box's best plausible case from your own opens, and an untried box stands tallest. Make opens 9 to 16 with Interact (F), following the tallest beam or not.
>
> **Before you press:** Before you open, decide whether the box you have opened most can ever have the tallest beam again.
>
> <details><summary>Back from the game: what you just saw</summary>Each open pulls that box's beam toward its average, because the bonus shrinks as you open it. Boxes you leave alone keep tall beams. The three strategies kept playing beside you with the same luck, so compare their totals and regret on the left with yours. Opening the tallest beam is the rule called UCB1.</details>

**On the island:** Q + COUNT BONUS always takes the move with the highest Q + 10 / sqrt(visits + 1), and her epsilon is 0. Falls per 100: 7.1 (6.8 to 7.4), a difference from Q-LEARNING of -19.40 (-23.37 to -15.22).

### [47:22](https://www.youtube.com/watch?v=sGuiWX07sKw&t=2842s) How big the bonus should be: a formula that needs only counts (UCB1)
The bonus needs a size, and Silver takes it from a fact about averages that holds for any rewards between 0 and 1, whatever pattern they follow. Toss a coin a few times and the share of heads can sit far from the coin's true bias. Toss it many times and a big miss becomes unlikely. The fact is called Hoeffding's inequality.

After t samples, the chance that the true average exceeds the average you have seen by more than u is at most `e^(-2 * t * u^2)`. In words: a miss of size u gets rapidly less likely as the samples pile up.

Silver runs it backwards. Choose a small chance p of being wrong, set the bound equal to p, and solve for u. `U = sqrt(-log p / (2 * N(a)))`. In words: the bonus for arm a is large while its pull count N(a) is small, and shrinks as the count grows.

Then let p shrink as time goes on. The result is an algorithm called UCB1. `a_t = argmax Q(a) + sqrt(2 * log t / N(a))`. In words: the bonus falls as an arm is tried and grows slowly with total time, so a neglected arm gets another look. The reward it gives up, its regret, grows only like the logarithm of time. On Silver's 10-armed tests it did well without tuning.

> **Alt+Tab · game 9 · stop 5 of 8: Predict what the optimist reopens**
>
> **What he just said:** From a bound on how far an average can stray from the truth, Silver builds UCB1, whose bonus falls as an arm is tried and creeps up slowly as the total number of tries grows.
>
> **In the game:** Answer the question about the optimist: left click for never again, right click for opens it again later, melee for opens it every time. Then make opens 17 to 24 with Interact (F).
>
> **Before you press:** Decide what the optimist does with a box it opened once that paid nothing.
>
> <details><summary>Back from the game: what you just saw</summary>After 8 opens in all, a box opened once that paid 0 scores 2.04, and a box that paid 4 of 6 scores only 1.50, so the optimist goes back to the loser. The bonus grows with the logarithm of all opens, so any box left alone long enough gets another look. In your round, watch the beams of the boxes you skip: they creep up while you open the others.</details>

> **Alt+Tab · game 9 · stop 6 of 8: Read 300 opens of replays**
>
> **What he just said:** Because its bonus shrinks with use, UCB1's regret grows only like the logarithm of time, while greedy and fixed random exploration add about the same regret every step.
>
> **In the game:** Answer the question: left click for only greedy, right click for greedy and the coin, melee for all three. The right side then shows 20 replays of 300 opens per strategy. Then make opens 25 to 29 with Interact (F).
>
> **Before you press:** Pick whose regret keeps climbing in a straight line when the game runs long.
>
> <details><summary>Back from the game: what you just saw</summary>The right side gives the regret each strategy added in opens 1 to 100, 101 to 200 and 201 to 300. On average the coin's cannot fall below 2.4 per 100, the price of its random opens. The optimist's falls from one hundred to the next: a curve that flattens, against straight lines. At 300 opens the coin is usually still ahead; the optimist passes it only after a few thousand.</details>

**On the island:** The count bonus has no log t term, so a neglected move's bonus never grows back. True UCB1 was not run.

### [57:27](https://www.youtube.com/watch?v=sGuiWX07sKw&t=3447s) Keep a belief about each option, then act on its optimistic end or on a draw from it (Bayesian bandits)
The counting bonus of the last part, UCB1, assumed almost nothing about the machines. The other route starts with an opinion: a belief about how each arm pays before you have pulled anything, which is called a prior. After every pull, the standard recipe for revising a belief in light of evidence, Bayes' rule, turns it into an updated belief called the posterior. These are the three curves again, except that now the agent computes them.

Silver shows two ways to act on them. The first scores each arm by the mean of its posterior plus a few times the curve's width, measured in standard deviations. He uses three in his example, and the method is called Bayesian UCB. The second picks each arm with the probability that it is the best one, which is called probability matching. It is optimistic without any bonus, since an arm with a wide belief has a real chance of being the maximum.

The simple way to do probability matching is to draw one value at random from each arm's posterior and pull the arm with the highest draw. This is Thompson sampling, from the 1930s (1:04:04). For coin-flip bandits, called Bernoulli bandits, it reaches the floor that Lai and Robbins proved, and it has no bonus to tune. Silver's caution is that it is only as good as its prior.

**On the island:** Not run. A Thompson sampling bot would count what each move did and act on a sampled table each episode.

### [1:08:38](https://www.youtube.com/watch?v=sGuiWX07sKw&t=4118s) What the agent knows becomes part of its state (the information state)
Finding something out is only worth the cost if there is time left to use it. Silver's example has two levers. One is known to pay £100, and the other is unknown. With three plays remaining, take the sure £100. With a thousand plays remaining, try the unknown lever.

The reward you would give up to have a piece of information before deciding is what he calls the value of information (1:09:05). It depends on the time left.

Silver says the bonus rule and the draw from your beliefs, UCB and Thompson sampling, are rules of thumb, which he calls heuristics. They break down in problems where a move changes your situation, the full MDPs (Markov decision processes) of earlier lectures (1:11:56).

The principled move (1:12:15) is to make what you know part of your state, the description of where you are. The summary of what you know is called an information state, written `s~ = f(h_t)`. In words: a summary, computed from the history of everything that has happened so far, of all that has been learned, such as how often each lever was pulled. Each pull moves the agent to a new information state, so there is an MDP over information states (1:13:16).

> **Alt+Tab · game 9 · stop 7 of 8: Spend the last open**
>
> **What he just said:** Information is worth what you would give up to have it before deciding, and that depends on the time left: with few plays remaining, take the sure thing.
>
> **In the game:** One open is left. Answer first: left click for the box you know, right click for the barely known box. Then make your last open with Interact (F).
>
> **Before you press:** Decide which box deserves your very last open.
>
> <details><summary>Back from the game: what you just saw</summary>With one open left, nothing you learn can change a later choice, because there is none. The open is worth only its average payout, so the box you know best usually wins. Early in the game the same open of a barely known box was worth more, because what it showed could steer every open after it. This is the value of information.</details>

**On the island:** No bot plans over what she knows. The planned hidden-wall build gives one runner a memory of what she bumped into this episode, which is a tiny information state.

### [1:14:06](https://www.youtube.com/watch?v=sGuiWX07sKw&t=4446s) Plan ahead over what you would learn (Bayes-adaptive bandits)
A drug company has two drugs and a line of patients. Each patient either gets better or does not, so giving a drug is like pulling an arm that pays 1 or 0. The chance of a 1, written mu, is the drug's unknown cure rate. Silver calls this coin-flip bandit a Bernoulli bandit.

The summary of what has been learned, the information state, is each drug's count of successes and failures. Silver gives each drug a starting belief written as such counts, a Beta prior (1:16:28). Drug 1 gets a flat belief and drug 2 a belief near 50/50.

A success shifts a drug's belief one way and a failure the other, so every possible future belief can be laid out as a lookahead tree. Solving the tree gives the best trade-off between exploring and exploiting given the prior. Silver says it is "not a heuristic anymore" (1:18:47).

The cost is size: the decision problem over all those beliefs, the MDP, is infinite (1:19:00), though reinforcement learning methods still apply. Lecture 3's way of solving a problem whose rules are known, dynamic programming, gives an answer called the Gittins index (1:19:37). When the state is a belief updated by data, a posterior, the approach is called Bayes-adaptive reinforcement learning (1:20:07). Planning by simulated playouts from the current belief, lecture 8's Monte Carlo tree search, makes it practical (1:23:36).

**On the island:** Not run. The experiment would be a planner whose state is (square, what she has learned about each move), searched forward.

### [1:24:11](https://www.youtube.com/watch?v=sGuiWX07sKw&t=5051s) The three families side by side, and the objection that optimism is not safe
With the bandit methods covered, Silver lines up the three families. The first flips a coin and never looks at its own uncertainty. This is random exploration: a random move now and then (epsilon-greedy), or moves picked with probability rising with their score (softmax). The second estimates how much it does not know and leans toward what might be good. This is optimism in the face of uncertainty: starting every score high, a bonus for what is rarely tried (UCB), and acting on a draw from your beliefs (Thompson sampling). The third looks ahead over what each choice would teach it and picks the best path. This is information state search.

Then he asks the class what is wrong with optimism. A student answers that with very many actions you never stop exploring, and Silver agrees: there is always more uncertainty to explore.

He adds a second problem. A real robot has to avoid catastrophes, and optimism "doesn't give you safe exploration" (1:26:04). People in industry, he says, sometimes do the opposite: they explore only around what they know is safe.

**On the island:** Optimism and the count bonus each fell about 11 times per 150-episode run. That is roughly once per fatal edge move, and then never again.

### [1:28:45](https://www.youtube.com/watch?v=sGuiWX07sKw&t=5325s) The same three ideas in harder problems: contextual bandits and full MDPs
A website does not show every visitor the same advert. It is told something about the visitor first. Add that one ingredient to the bandit, a state shown before the choice (such as who the visitor is), and it is called a contextual bandit. Silver's example is Yahoo choosing a front-page news story for each reader. He leaves the solution methods to slides that are not examined.

All of it carries over to the full problem where a move also changes the state, the MDP (Markov decision process) of earlier lectures. Optimistic starts become `Q = r_max / (1 - gamma)`. In words: start every score at the largest total reward (return) the problem could pay, the biggest reward on every step with later steps counting for less by the discount gamma.

The bonus for rarely tried moves, UCB, carries over with a warning (1:33:39). In an MDP a score is uncertain in a second way: the rule for choosing moves (the policy) could still improve. The best-known method that plans with optimism is R-max, and E cubed is another variant of the idea (1:34:33). Treat every state you do not understand as heaven, plan, go there, find out, and repeat.

Planning over what you have learned, information state search, carries over too (1:35:51). The state becomes where you are plus what you have learned.

> **Alt+Tab · game 9 · stop 8 of 8: Read the debrief**
>
> **What he just said:** The same three ideas, random exploration, optimism and planning over what you have learned, carry over to problems where the agent first sees a context and to full decision problems with many states.
>
> **In the game:** Nothing to press. The left side shows the hidden odds, how often you opened each box, your total and regret beside greedy, the coin and the optimist, what it is called, and where it shows up in an agent.
>
> **Before you press:** Before reading, guess which of the four players had the lowest regret over 30 opens.
>
> <details><summary>Back from the game: what you just saw</summary>Compare your opens per box with the odds: regret charges each open of a worse box by how much worse it is. Over 30 opens luck moves the totals a lot, so regret, which leaves luck out, is the fairer score. The counts of opens and pays per box were everything anyone used to decide; a summary like that, used as the state, is called an information state. <em>In an agent:</em> Choosing among a few tools or prompts by their pass counts is this bandit, and a router that reads the task first makes it a contextual bandit.</details>

**On the island:** With discount 1 the bound is the best return, 39, so the start of 40 follows the recipe. MONTE CARLO + OPTIMISM got nothing from it: 97.7 falls per 100 (97.1 to 98.3).

## What the island measured for this lecture

| Bot | Runs | Falls per 100 (95% interval) | Return, first 40 | Return, last 40 | Clean tests |
|---|---|---|---|---|---|
| Q-LEARNING (epsilon 0.1) | 11 | 26.5 (22.4 to 30.4) | -57.6 | 7.5 | 11/11 |
| Q + FADING EXPLORATION | 9 | 27.9 (25.4 to 30.3) | -86.3 | 23.6 | 9/9 |
| Q + OPTIMISM | 10 | 7.2 (7.0 to 7.3) | -33.0 | 38.0 | 10/10 |
| Q + COUNT BONUS | 10 | 7.1 (6.8 to 7.4) | -46.3 | 37.0 | 10/10 |
| MONTE CARLO + OPTIMISM | 9 | 97.7 (97.1 to 98.3) | -108.7 | -101.9 | 0/9 |

Against plain Q-learning, falls per 100: optimism -19.28 (-23.28 to -15.11), count bonus -19.40 (-23.37 to -15.22), fading 1.44 (-3.25 to 6.17, inconclusive). MONTE CARLO + OPTIMISM against MONTE CARLO, last-40 return: 0.27 (-0.51 to 1.14), inconclusive. All are exploratory first looks, uncorrected for multiple comparisons; only SARSA against Q-learning was planned. They show the two uncertainty-driven explorers paying a near-fixed bill of falls, then walking the edge row close to the best return of 39, while the coin-flipper kept paying. They do not show regret rates: the strip is a nearly deterministic MDP, not a noisy bandit, and runs were short. Settings were untuned, so fading's poor start (-86.3) belongs to a schedule that began fully random, not to decay in general. The lab's account of Monte Carlo: a beginner never sees the +50, so judging moves by whole endings teaches her to step off, whatever her starting values.

## Guess first

<details><summary>Q + OPTIMISM never takes a random move; Q-LEARNING takes one in ten. Which falls more in training?</summary>
Q-LEARNING, by far: 26.5 falls per 100 against 7.2 (difference -19.28, interval -23.28 to -15.11, exploratory). The optimistic bot tries each fatal edge move about once, because a score of 40 says it might be wonderful, learns it costs -100, and stops.
</details>

<details><summary>Give MONTE CARLO (lecture 5) the same optimistic start of 40. Does she stop stepping off?</summary>
No: 97.7 falls per 100, and her last-40 return differed from plain Monte Carlo by 0.27 (-0.51 to 1.14), inconclusive. Optimism makes her try every move, but Monte Carlo scores a move by the whole episode, and a beginner's episodes all end badly. Optimism decides what she tries, not what she concludes.
</details>

<details><summary>Silver says decaying epsilon can be nearly perfect. Did Q + FADING EXPLORATION beat Q-LEARNING on falls?</summary>
Not measurably: 27.9 against 26.5, difference 1.44 (-3.25 to 6.17), inconclusive. The good schedule needs the gaps, which no agent knows, and a guessed one can be a disaster (55:58). The island's began fully random, so her first 40 episodes averaged -86.3.
</details>

<details><summary>Lecture 3 solved known MDPs by dynamic programming. Can you solve a Bernoulli bandit that way, and what is the state?</summary>
Yes, in principle. The state is the information state: per arm, successes and failures so far. Bayes' rule with a Beta prior gives the transitions exactly, and dynamic programming yields the Gittins index (1:19:37).
</details>

<details><summary>UCB1's bonus is sqrt(2 log t / N(a)). What happens to an arm never pulled?</summary>
With N(a) = 0 the bonus is unbounded, so every arm is pulled once first. Afterwards the bonus shrinks with N(a) but creeps up with log t, so an arm left alone long enough is tried again. The island's count bonus lacks that return visit.
</details>

<details><summary>Lecture 8's planning plus R-max's heaven: would that bot fall more or less than Q + OPTIMISM?</summary>
Not run; a prediction. A planner that treats each untried move as heaven heads straight for it, fatal edge moves included, so it should also pay about one fall per fatal move, but sooner, since planning spreads the news without real steps.
</details>

## Cards

- Q: What is regret? | A: Reward given up by not choosing the best action, summed over time.
- Q: Why does fixed epsilon-greedy have linear regret? | A: It explores randomly forever, adding similar regret each step.
- Q: Why can greedy have linear regret? | A: Unlucky early results can lock it onto a worse action forever.
- Q: What is optimistic initialisation? | A: Start every estimate at its maximum and act greedily, so untried actions get tried.
- Q: What does the Lai and Robbins bound say? | A: Total regret grows at least like log t; similar-looking arms with different means make it larger.
- Q: The UCB1 rule? | A: Pick the arm maximising its mean plus sqrt(2 log t / N(a)).
- Q: Thompson sampling in one line? | A: Draw one value per arm from its posterior and pull the arm with the highest draw.
- Q: What is an information state? | A: A summary of the history (such as success and failure counts) used as the state of an MDP.

## In language-model terms

Exact: choosing among a few prompts, tools or models across many tau-bench tasks, scored by whether each passed, is a Bernoulli bandit. Each option is an arm with an unknown pass rate; UCB1 or Thompson sampling over pass counts applies as written. Let the router read a task description first and it is a contextual bandit.

Analogy: sampling temperature is softmax exploration, spread over every token, including those the model is sure of. Inside one conversation, asking the simulated customer a question is information gathering; the agent's picture of what the customer wants plays the part of an information state, and the question's value depends on turns remaining. Nothing in the model computes that value; it is a lens.

Where it breaks: regret bounds assume fixed arms and independent pulls, while the task set is small and the model changes. Silver's safety objection lands hardest: cancelling a real reservation is a step off the edge, and an optimistic explorer will try it once.

## The thread to partial observability

An information state (1:12:15) is a statistic of the history, `s~ = f(h_t)`, and in the Bayes-adaptive version (1:20:07) it is a posterior, a belief. A POMDP's (partially observable MDP's) belief state is the same object aimed elsewhere: here the hidden thing is a fixed fact (each arm's payout), there it is the current state, which can change. Silver's augmented MDP state (1:35:51), where you are plus what you have learned, has the shape of the hidden-wall build's RUNNER REMEMBERS BUMPS condition (planned and running, no results yet): her memory of this episode's bumps is the smallest information state. Carry forward: when she cannot see something, give her a summary of what she has seen, and value actions partly for what they reveal.

## Experiments the lecture asks for that the island has not run

- True UCB1 per square: would show whether the log t return visit changes falls against the count bonus.
- Thompson sampling over counted move outcomes, against optimism on falls.
- R-max in Dyna-Q's model (untried moves as heaven): should pay its falls sooner than Q + OPTIMISM.
- Optimism at several starts (39, 60, 200): how the bill of falls grows with over-optimism.
- Random slips added to moves, so outcomes look alike and regret bounds bite.
