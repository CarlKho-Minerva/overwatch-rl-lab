# Lecture 9: Exploration and Exploitation

*David Silver's lecture 9 (UCL, 2015), gone through in his order and re-explained with the Tracer experiments on Workshop Island. The lecture and its slides are his: [video](https://www.youtube.com/watch?v=sGuiWX07sKw), [course page](https://davidstarsilver.wordpress.com/teaching/). The words below are a re-explanation. Every island number comes from the logged runs in this repository.*

Four loot boxes, each with its own hidden chance of paying, and 30 opens to spend. Every open asks the same question: go back to the box that has been kind to you, or try one that might be kinder? Silver spends the hour on how much to explore, and where. His answer: explore where you are unsure, not at random, and prefer methods whose mistakes thin out as time goes on. On the island, the bots that were optimistic about what they had not tried fell about a quarter as often as Q-LEARNING. She explores by coin, one move in ten at random, forever, so she keeps falling long after her table knows better.

**Two windows:** this page, and [Game 9: Loot Boxes](../workshop/games/g09.md), an Overwatch custom game for this lecture (paste `workshop/compiled/game-09.txt` into a custom game's settings and start it). The game opens at stop 1 and waits. Read down this page; at each box marked Alt+Tab, switch to the game, do that stop, and switch back. The game never moves on while you read.

## The lecture in order

### [02:23](https://www.youtube.com/watch?v=sGuiWX07sKw&t=143s) Your main, or the hero you have never played
Hero select, ranked. You can lock in your main, the hero you know wins fights, or the one you keep meaning to learn. The new one might be worse. It might also be your best hero.

There is one way to find out, and it might cost you a game.

Silver tells it with restaurants: the place you know is good, or the new one down the street. His other examples have the same shape: showing a visitor a different advert, drilling for oil at a new site.

Taking what you believe is best is exploitation. Doing something else on purpose, to learn what may pay later, is exploration. The choice never goes away, because the agent learns while it acts. Silver calls that learning online: your own moves decide what data you ever see.

He sorts the answers into three families:

1. **Roll dice now and then.** Random exploration, such as lecture 5's epsilon-greedy (a random move with small probability epsilon) or softmax (moves picked with probability rising with their score).
2. **Lean toward what you know least**, since it might be better. Optimism in the face of uncertainty.
3. **Make what you know part of your situation.** The information state space: the most correct, Silver says, and the most expensive.

> **Alt+Tab · game 9 · stop 1 of 8: Open eight loot boxes**
>
> **What he just said:** Every open is the hero-select question: your main, or the one you have not learned yet. Taking what has paid best so far is exploitation; trying something else to find out what it is worth is exploration. An agent that learns while it acts makes this trade on every choice.
>
> **In the game:** Four yellow pads, four boxes, each with its own hidden chance of paying 1. Walk onto a pad and press Interact (F) to open that box. Make eight opens, on any boxes you like; the game waits for each one.
>
> **Before you press:** Before your first open, decide how many opens you will give each box before you settle on one.
>
> <details><summary>Back from the game: what you just saw</summary>Each open paid 1 or 0, and the label over each pad counts your opens and pays. When the round ends, the left side shows your regret: for every open, how much less your box pays on average than the best box would, added up. Eight opens across four boxes is about two looks each. Two looks is a rumour, not evidence. <em>In an agent:</em> An agent that sometimes tries a new tool or prompt instead of its usual one is making this exact trade, on every call.</details>

**On the island:** A bot that never walks the edge row never sees the +50. A bot that never steps toward the drop never learns what it costs.

### [08:18](https://www.youtube.com/watch?v=sGuiWX07sKw&t=498s) Try one new move, or play a whole game differently
Two ways to experiment on Tracer. Change one thing in one spot: at the corner where you always blink right, blink left. Or change your whole style for a game, every fight from high ground, and check the scoreboard at the end.

Silver separates the two before going on.

The first is state-action exploration: the agent remembers which moves it has tried in a particular place (a state), and next time it is there, it tries a different one.

The second is parameter exploration: the agent nudges the numbers behind its rule for choosing moves (its policy), plays that for a while, and sees how it went. His example is a robot given a slightly different walk.

The upside is consistency. The robot keeps one odd gait long enough to judge it, where lecture 5's epsilon-greedy rolls the dice again at every step. The downside: it ignores which states it has visited, so Silver says it is closer to a blind search for the best settings, global optimisation, than to exploring.

The rest of the lecture is the first kind.

**On the island:** Every bot explored over moves. Not run on the island: nudge a whole table for an episode, and keep the nudged table if the return improves.

### [11:41](https://www.youtube.com/watch?v=sGuiWX07sKw&t=701s) A row of slot machines, and a score for what you left on the table
Picture a row of slot machines. Each pays by its own hidden odds, and nobody tells you which one is generous. Pull an arm, get one reward, episode over. Nowhere to walk, so no state. Only which arm.

Silver calls this the multi-armed bandit. (A slot machine's old nickname is the one-armed bandit. Line up several and the name writes itself.)

Each arm has a true worth, what it would pay on average over endless pulls: lecture 5's action value, with the state dropped. Every pull of a worse arm gives up, on average, its gap, how much worse it is than the best. Silver calls the running total regret.

<details markdown="1"><summary>The formulas, when you want them</summary>

`Q(a) = E[r | a]`. In words: the value of arm a is the reward you expect from one pull of it.

`V* = max Q(a)`. In words: the value of the best arm, which you would collect every pull if you knew which arm it was.

`L_t = sum over arms E[N_t(a)] * gap(a)`. In words: how often you pulled each arm, times how much worse it is than the best, which is called its gap.

</details>

A student spots the catch (19:44): the gaps depend on V*, the best arm's worth, which nobody knows.

Regret is a fine score for a referee who can see the odds. Mid-game, you cannot.

> **Alt+Tab · game 9 · stop 2 of 8: Judge a box at three of four**
>
> **What he just said:** A row of slot machines with hidden payouts is called a bandit. Its score, regret, is the reward you gave up by not pulling the best arm. The annoying part: nobody knows in advance which arm that is.
>
> **In the game:** A question floats in front of you. Left click for yes, right click for no, too few opens.
>
> **Before you press:** Decide whether a box that paid 3 of its first 4 opens is surely the best of the four.
>
> <details><summary>Back from the game: what you just saw</summary>Four opens prove very little. A box that pays 4 times in 10 still pays 3 or 4 of its first 4 about 18 times in 100, and a box that pays 55 times in 100 does it 39 times in 100. A short lucky streak looks exactly like a great box. That is why nobody knows the best box while playing, and why regret can only be counted against odds that stay hidden.</details>

**On the island:** The strip is not a bandit. It is an MDP (a Markov decision process, where a move changes where she stands). The two-player build (exploratory, 12 short runs) does have one: the blocker learns her row "as a four-armed bandit".

### [21:39](https://www.youtube.com/watch?v=sGuiWX07sKw&t=1299s) The stubborn flanker and the random wanderer both leak a little every step, forever
Everyone has played with these two. One found a flank in their first week that got two picks, and has taken it every round since. The other plays sensibly, except that one fight in ten they wander off and do something random, for science.

Both can cost you fights at a steady rate, forever.

Silver draws it as a graph: the reward given up so far (the regret from the last part) against time. A constant slope means the same mistakes at the same rate, with no end in sight.

The wanderer is lecture 5's epsilon-greedy with epsilon held fixed: a random arm with small probability, otherwise the best-looking one. The random pulls never stop, so each step adds about the same regret. Straight line.

The flanker is greedy: it always takes the arm with the highest average payout so far, never exploring. A few unlucky pulls can make the best arm look bad, and greedy then locks onto a worse one for good. Straight line too.

Silver calls a straight-line climb linear total regret. The goal is a curve that bends flat, which he calls sublinear regret.

> **Alt+Tab · game 9 · stop 3 of 8: Guess which strategy gets stuck**
>
> **What he just said:** Two ways to lose a little every step, forever. Always take the best average, and a few unlucky pulls can lock you on to a worse arm for good. Explore at random a fixed share of the time, and you pay for those random pulls forever.
>
> **In the game:** Read the question. GREEDY opens the box with the best average so far; COIN does the same but opens a random box 1 time in 10, like the one random move in ten from lecture 5. Left click for greedy, right click for the coin, melee for neither.
>
> **Before you press:** Pick the strategy that can stay stuck on a bad box forever.
>
> <details><summary>Back from the game: what you just saw</summary>Greedy opens each box once, then always the best average. If the best box loses its first open while another box wins, its average sits at 0 and greedy never opens it again: at least 23 games in 100. The coin opens every box now and then, so it never stays stuck, but pays for those random opens forever. Use what you know or find out more: that is the exploration and exploitation dilemma. <em>In an agent:</em> An agent that always reuses the tool call that worked first is the teammate on the same flank every round: it can stay there long after a better option exists.</details>

**On the island:** Q-LEARNING's last 40 training episodes average 7.5, against a best possible 39. Yet with exploring switched off she made 10 clean test crossings in 11 of 11 runs. Her table was fine. The coin was the cost.

### [26:12](https://www.youtube.com/watch?v=sGuiWX07sKw&t=1572s) Every untried box is a jackpot until it proves otherwise (optimistic initialisation)
Think of a new hero the week before you play them. On paper they are incredible, because nothing has gone wrong yet. Only real games can drag that opinion down.

Walk up to the slot machines like that, sure every one pays the maximum every time, and you need no rule telling you to try them all. Each looks wonderful until real payouts pull it down.

Silver calls this optimistic initialisation: start every estimate at the highest value it could have, then always take the highest one (acting greedily). Untried arms keep their perfect score, so they get tried. He says it is hard to beat.

His version invents a past: pretend each arm was already pulled 100 times at the maximum payout, then average real payouts into that record. (That equals starting from a belief about a payout rate written as counts, called a Beta prior.)

It can still go wrong (27:39). The best arm has a few poor results, falls below a worse arm, and is never pulled again. So in theory its regret stays linear.

Hype gets every arm tried. It does not protect the best one from a bad start.

**On the island:** Q + OPTIMISM starts every Q (her score for a square and a move together) at 40, one above the best return of 39, and never moves at random. Falls per 100: 7.2 (7.0 to 7.3), against Q-LEARNING's 26.5 (22.4 to 30.4).

### [31:07](https://www.youtube.com/watch?v=sGuiWX07sKw&t=1867s) Explore less as you go: nearly perfect, with one catch
Think of a player's first week of Overwatch: every hero gets a go. A thousand hours later, it is a pool of three. Nobody told them to explore less. It just made sense once they knew more.

That is the obvious repair for the wanderer, lecture 5's epsilon-greedy, whose regret climbs in a straight line while epsilon stays fixed. Softmax, the rule that picks arms with probability rising with their score, draws the same straight line. Let epsilon shrink, and on the right schedule regret still grows, but ever more slowly, like the logarithm of time.

<details markdown="1"><summary>The formula, when you want it</summary>

`epsilon_t = min(1, c * |A| / (d^2 * t))`. In words: explore less as time passes, and keep exploring for longer when the best two arms are hard to tell apart. Here t counts the steps so far, c is a constant, the A between bars is the number of arms, and d is the smallest gap, the difference in value between the best arm and the second best.

</details>

Silver, on the method he had called naive: "maybe it wasn't so naive at all".

Then the catch.

The schedule needs d, the gap between the best arm and the second best, and nobody knows the gaps in advance. (A recipe that lists part of the answer among its ingredients.) So you guess, and a guessed schedule is excellent when it is tuned just right and "a disaster" when it is wrong (55:58).

**On the island:** Q + FADING EXPLORATION uses epsilon = 1 / (1 + episode / 5), with a floor of 0.01, a guessed schedule of that 1-over-time shape. Falls per 100: 27.9 (25.4 to 30.3), against Q-LEARNING's 26.5. The difference is 1.44 (-3.25 to 6.17), which is inconclusive.

### [36:36](https://www.youtube.com/watch?v=sGuiWX07sKw&t=2196s) A floor nobody gets under: regret that grows like the logarithm of time
Some matchups explain themselves: walk into a hard counter and you know by the first teamfight. Others never settle. Two heroes, one wins slightly more often, and on any given night either can look better.

Silver spends one slide on how well any method could ever do. Lai and Robbins proved a floor: however clever your strategy, its regret keeps growing at least as fast as the logarithm of the number of pulls. Ever more slowly, but forever.

The floor sits higher when the bandit is hard. An easy one has an obviously good arm and an obviously bad arm, and one pull of each settles it. A hard one has noisy payouts, so a worse arm's results look like the best arm's from pull to pull while their averages differ. Your two similar heroes are a hard bandit.

<details markdown="1"><summary>The formula, when you want it</summary>

`lim L_t >= log t * sum over worse arms gap(a) / KL(R_a || R_a*)`. In words: regret grows at least like the logarithm of time, and faster when arms differ in value but look alike. KL stands for a number that is small when two arms' payouts look alike, the Kullback-Leibler divergence.

</details>

So the aim from here on is logarithmic regret, not linear.

Nobody gets under the floor. The job is to get off the straight line.

**On the island:** With 0.21 slips per 1,000 steps, one try reveals a move's outcome. Not run on the island: adding random slips, which would make moves look alike.

### [39:32](https://www.youtube.com/watch?v=sGuiWX07sKw&t=2372s) Pick the one that could still surprise you (optimism in the face of uncertainty)
Say you know exactly how good you are on Soldier: fine. You have played two games of Echo. She might be awful in your hands or the best hero in your pool, and two games cannot rule out either.

Silver draws three curves, one per arm, each the agent's belief about that arm's true average payout: the peak is its best guess, the width is how unsure it is. Green has been tried often, so its curve is narrow. Blue has barely been tried, so its curve is wide. Red is in between.

Green has the highest best guess. Silver says pull blue anyway: the tail of its wide curve reaches furthest, so it has the most room to turn out best. This is optimism in the face of uncertainty. If blue disappoints, its curve narrows and another arm gets its turn.

The optimism lasts exactly as long as the ignorance does.

As a rule: give each arm a value its true average is unlikely to exceed, something like the top of a 95% confidence range, called the upper confidence bound (UCB). Then pull the arm whose bound is highest.

<details markdown="1"><summary>The formula, when you want it</summary>

`a_t = argmax Q(a) + U(a)`. In words: score each arm by its average so far plus a bonus that is large when the arm has rarely been tried and shrinks to zero with use, then pull the top scorer.

</details>

> **Alt+Tab · game 9 · stop 4 of 8: Open by the blue beams**
>
> **What he just said:** When unsure, be optimistic. Score each option by its best plausible value: its average plus a bonus that is big when it has rarely been tried and shrinks with use. That score is an upper confidence bound, and the principle is optimism in the face of uncertainty.
>
> **In the game:** Blue beams now rise over the boxes. A beam's height is that box's best plausible case from your own opens, and an untried box stands tallest. Make opens 9 to 16 with Interact (F), following the tallest beam or not.
>
> **Before you press:** Before you open, decide whether the box you have opened most can ever have the tallest beam again.
>
> <details><summary>Back from the game: what you just saw</summary>Each open drags that box's beam toward its average, because the bonus shrinks with use. The boxes you leave alone keep their tall beams. Meanwhile the three strategies kept playing beside you with the same luck, so compare their totals and regret on the left with yours. Always opening the tallest beam is the rule called UCB1.</details>

**On the island:** Q + COUNT BONUS always takes the move with the highest Q + 10 / sqrt(visits + 1), and her epsilon is 0. Falls per 100: 7.1 (6.8 to 7.4), a difference from Q-LEARNING of -19.40 (-23.37 to -15.22).

### [47:22](https://www.youtube.com/watch?v=sGuiWX07sKw&t=2842s) How big a bonus? Count your pulls and you have it (UCB1)
Win your first two games on a new hero and your win rate on them is perfect. Nobody believes it, including you. After a hundred games, the same number means something.

That difference sizes the bonus. Silver uses a fact about averages that holds for any rewards between 0 and 1, whatever pattern they follow: toss a coin a few times and the share of heads can sit far from its true bias; toss it many times and a big miss becomes unlikely. It is called Hoeffding's inequality.

He runs it backwards, picking a small chance p of being wrong and solving for the miss to allow, then lets p shrink over time. Out comes UCB1. Its bonus falls each time you pull an arm and creeps up slowly with total time, so a neglected arm gets another look. Its regret grows only like the logarithm of time, and on Silver's 10-armed tests it did well without tuning.

All it needs is counts.

<details markdown="1"><summary>The formulas, when you want them</summary>

After t samples, the chance that the true average exceeds the average you have seen by more than u is at most `e^(-2 * t * u^2)`. In words: a miss of size u gets rapidly less likely as the samples pile up.

`U = sqrt(-log p / (2 * N(a)))`. In words: the bonus for arm a is large while its pull count N(a) is small, and shrinks as the count grows.

`a_t = argmax Q(a) + sqrt(2 * log t / N(a))`. In words: the bonus falls as an arm is tried and grows slowly with total time, so a neglected arm gets another look.

</details>

> **Alt+Tab · game 9 · stop 5 of 8: Predict what the optimist reopens**
>
> **What he just said:** From a bound on how far an average can stray from the truth, Silver builds UCB1. Its bonus falls each time an arm is tried and creeps up slowly as the total number of tries grows, so nothing stays ignored forever.
>
> **In the game:** Answer the question about the optimist: left click for never again, right click for opens it again later, melee for opens it every time. Then make opens 17 to 24 with Interact (F).
>
> **Before you press:** Decide what the optimist does with a box it opened once that paid nothing.
>
> <details><summary>Back from the game: what you just saw</summary>After 8 opens in all, a box opened once that paid 0 scores 2.04, and a box that paid 4 of 6 scores only 1.50. So the optimist goes back to the loser. The bonus grows with the logarithm of all opens, so any box left alone long enough gets another look. In your round, watch the beams of the boxes you skip: they creep up while you are busy with the others.</details>

> **Alt+Tab · game 9 · stop 6 of 8: Read 300 opens of replays**
>
> **What he just said:** Because its bonus shrinks with use, UCB1's regret grows only like the logarithm of time. Greedy and fixed random exploration keep adding about the same regret every step, like a tap nobody turns off.
>
> **In the game:** Answer the question: left click for only greedy, right click for greedy and the coin, melee for all three. The right side then shows 20 replays of 300 opens per strategy. Then make opens 25 to 29 with Interact (F).
>
> **Before you press:** Pick whose regret keeps climbing in a straight line when the game runs long.
>
> <details><summary>Back from the game: what you just saw</summary>The right side gives the regret each strategy added in opens 1 to 100, 101 to 200 and 201 to 300. On average the coin's can never fall below 2.4 per 100: the price of its random opens, paid forever. The optimist's shrinks from one hundred to the next, a curve that flattens against straight lines. The twist: at 300 opens the coin is usually still ahead. The optimist passes it only after a few thousand.</details>

**On the island:** The count bonus has no log t term, so a neglected move's bonus never grows back. True UCB1 was not run.

### [57:27](https://www.youtube.com/watch?v=sGuiWX07sKw&t=3447s) Start with an opinion, then act on its bright side or roll it (Bayesian bandits)
Patch day. Before you have played a single game, you already have opinions: buffed hero, probably stronger; nerfed hero, probably not. Every game after that nudges them.

UCB1 assumed almost nothing about the machines. This route starts with an opinion about how each arm pays, before any pulls, called a prior. After each pull, Bayes' rule (the standard recipe for revising a belief on evidence) turns it into an updated belief, the posterior. These are the three curves again, except that now the agent computes them.

Silver shows two ways to act on them:

1. **The bright side.** Score each arm by its posterior's mean plus a few standard deviations (he uses three). This is Bayesian UCB.
2. **Weighted dice.** Pick each arm with the probability that it is the best one. This is probability matching, and it is optimistic with no bonus at all, since a wide belief has a real chance of being the maximum.

The simple way to do the second: draw one value at random from each arm's posterior and pull the highest. That is Thompson sampling, from the 1930s (1:04:04). On coin-flip bandits, called Bernoulli bandits, it reaches the Lai and Robbins floor with no bonus to tune.

Silver's caution: it is only as good as its prior.

**On the island:** Not run. A Thompson sampling bot would count what each move did and act on a sampled table each episode.

### [1:08:38](https://www.youtube.com/watch?v=sGuiWX07sKw&t=4118s) Why nobody experiments in overtime (the information state)
Overtime, last point, the payload inching forward. Nobody sensible picks this moment to try a hero they have never played. In the first minute, the same experiment might be worth it: there is time left to use what you learn.

Silver puts it in money. One lever is known to pay £100; the other is unknown. With three plays left, take the sure £100. With a thousand plays left, try the unknown lever.

What you would give up to know something before deciding, he calls the value of information (1:09:05).

It depends on the clock.

UCB and Thompson sampling, Silver says, are rules of thumb (heuristics). They break down in full MDPs, the Markov decision processes of earlier lectures, where a move changes your situation (1:11:56).

The principled move (1:12:15): make what you know part of your state, the description of where you are. The summary of what you have learned, such as how often each lever was pulled, is the information state. Each pull moves you to a new one, so there is an MDP over information states (1:13:16).

<details markdown="1"><summary>The formula, when you want it</summary>

`s~ = f(h_t)`. In words: a summary, computed from the history of everything that has happened so far, of all that has been learned, such as how often each lever was pulled.

</details>

> **Alt+Tab · game 9 · stop 7 of 8: Spend the last open**
>
> **What he just said:** Information is worth what you would give up to have it before deciding, and that depends on the clock. With three plays left, take the sure £100. With a thousand left, try the unknown lever.
>
> **In the game:** One open is left. Answer first: left click for the box you know, right click for the barely known box. Then make your last open with Interact (F).
>
> **Before you press:** Decide which box deserves your very last open.
>
> <details><summary>Back from the game: what you just saw</summary>With one open left, nothing you learn can change a later choice, because there is no later choice. The open is worth only its average payout, so the box you know best usually wins. Early in the game the same open of a barely known box was worth more, because what it showed could steer every open after it. This is the value of information, and why nobody tries a new hero in overtime.</details>

**On the island:** No bot plans over what she knows. The planned hidden-wall build gives one runner a memory of what she bumped into this episode, which is a tiny information state.

### [1:14:06](https://www.youtube.com/watch?v=sGuiWX07sKw&t=4446s) Plan over everything you might learn (Bayes-adaptive bandits)
Imagine planning hero practice like a chess engine. Win the first game, and here is what you would then believe and play; lose it, and here is the other branch. Nobody does this. The tree explodes.

Silver does it anyway. A drug company has two drugs and a line of patients. Each patient gets better or does not, so a drug is an arm that pays 1 or 0, and the chance of a 1, written mu, is its unknown cure rate. That is a Bernoulli bandit.

The information state is each drug's count of successes and failures. Each drug starts from a belief written as counts, a Beta prior (1:16:28): drug 1 flat, drug 2 near 50/50.

Each result shifts a belief, so every possible future belief fits in a lookahead tree. Solve it and you get the best trade-off between exploring and exploiting, given the prior. Silver says it is "not a heuristic anymore" (1:18:47).

The catch is size. That MDP over beliefs is infinite (1:19:00).

Reinforcement learning still applies. Lecture 3's dynamic programming (solving a problem whose rules you know) gives the Gittins index (1:19:37). With a posterior, a belief updated by data, as the state, it is called Bayes-adaptive reinforcement learning (1:20:07). Lecture 8's Monte Carlo tree search, planning by simulated playouts from your current belief, makes it practical (1:23:36).

**On the island:** Not run. The experiment would be a planner whose state is (square, what she has learned about each move), searched forward.

### [1:24:11](https://www.youtube.com/watch?v=sGuiWX07sKw&t=5051s) Three families on one slide, and why optimism is a bad idea near a ledge
Every map with a drop teaches the same lesson: to an optimist, the ledge you have never stepped off might be wonderful. Silver gets there at the end. He starts by lining up the three families:

1. **Dice.** Ignore your own uncertainty and act at random now and then (epsilon-greedy), or by probabilities rising with each move's score (softmax). Random exploration.
2. **Optimism.** Lean toward what might be good, given what you do not know: high starting scores, a bonus for the rarely tried (UCB), or a draw from your beliefs (Thompson sampling). Optimism in the face of uncertainty.
3. **Lookahead.** Look ahead over what each choice would teach you and pick the best path. Information state search.

Then he asks the class what is wrong with optimism. A student says that with very many actions you never stop exploring, and Silver agrees: there is always more uncertainty to explore.

His own second problem is the ledge.

A real robot has to avoid catastrophes, and optimism "doesn't give you safe exploration" (1:26:04). People in industry, he says, sometimes do the opposite: they explore only around what they know is safe.

**On the island:** Optimism and the count bonus each fell about 11 times per 150-episode run. That is roughly once per fatal edge move, and then never again.

### [1:28:45](https://www.youtube.com/watch?v=sGuiWX07sKw&t=5325s) Same three ideas, harder maps: contextual bandits and full MDPs
You do not pick the same hero on every map against every team. You read the situation first.

Give the bandit that one extra ingredient, a state shown before the choice (such as who is visiting a website), and it is a contextual bandit. Silver's example is Yahoo choosing a front-page news story for each reader. He leaves the solution methods to slides that are not examined.

Then all of it carries over to the full MDP (Markov decision process), where a move also changes the state.

Optimistic starts carry over: begin every score at the most the problem could ever pay.

<details markdown="1"><summary>The formula, when you want it</summary>

`Q = r_max / (1 - gamma)`. In words: start every score at the largest total reward (return) the problem could pay, the biggest reward on every step with later steps counting for less by the discount gamma.

</details>

The bonus for rarely tried moves, UCB, carries over with a warning (1:33:39): in an MDP a score is also uncertain because the policy, the rule for choosing moves, could still improve. The best-known method that plans with optimism is R-max, and E cubed is another variant (1:34:33). Its recipe fits in a line: treat every state you do not understand as heaven, plan a route there, go, find out, repeat.

Planning over what you have learned, information state search, carries over too (1:35:51). The state becomes where you are plus what you have learned.

> **Alt+Tab · game 9 · stop 8 of 8: Read the debrief**
>
> **What he just said:** The same three ideas, random exploration, optimism and planning over what you have learned, carry over to problems where the agent sees a context before it chooses, and to full decision problems with many states.
>
> **In the game:** Nothing to press. The left side shows the hidden odds, how often you opened each box, your total and regret beside greedy, the coin and the optimist, what it is called, and where it shows up in an agent.
>
> **Before you press:** Before reading, guess which of the four players had the lowest regret over 30 opens.
>
> <details><summary>Back from the game: what you just saw</summary>Compare your opens per box with the odds: regret charges each open of a worse box by how much worse it is. Over 30 opens luck moves the totals a lot, so regret, which leaves luck out, is the fairer score. Notice what everyone decided with: the counts of opens and pays per box, nothing else. A summary like that, used as the state, is called an information state. <em>In an agent:</em> Choosing among a few tools or prompts by their pass counts is this bandit, exactly. Let a router read the task first and it becomes a contextual bandit.</details>

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

Exact: say you have a few prompts, tools or models and a pile of tau-bench tasks, and each run either passes or fails. That is a Bernoulli bandit, no metaphor needed. Each option is an arm with an unknown pass rate, and UCB1 or Thompson sampling over the pass counts applies as written. Let the router read the task description before it chooses and it becomes a contextual bandit.

Analogy: sampling temperature is softmax exploration, spread over every token, including the ones the model is sure of. Inside one conversation, asking the simulated customer a question is information gathering. The agent's picture of what the customer wants plays the part of an information state, and the question is worth more when more turns remain, just as the unknown lever was worth more with a thousand plays left. Nothing in the model computes that value. It is a lens, not a mechanism.

Where it breaks: regret bounds assume the arms stay fixed and the pulls are independent. Here the task set is small and the model changes. Silver's safety objection lands hardest: cancelling a real reservation is a step off the edge, and an optimistic explorer will try it once.

Once is plenty.

## The thread to partial observability

An information state (1:12:15) is a statistic of the history, `s~ = f(h_t)`, and in the Bayes-adaptive version (1:20:07) it is a posterior, a belief. A POMDP's (partially observable MDP's) belief state is the same object aimed elsewhere: here the hidden thing is a fixed fact (each arm's payout), there it is the current state, which can change. Silver's augmented MDP state (1:35:51), where you are plus what you have learned, has the shape of the hidden-wall build's RUNNER REMEMBERS BUMPS condition (planned and running, no results yet): her memory of this episode's bumps is the smallest information state. Carry forward: when she cannot see something, give her a summary of what she has seen, and value actions partly for what they reveal.

## Experiments the lecture asks for that the island has not run

- True UCB1 per square: would show whether the log t return visit changes falls against the count bonus.
- Thompson sampling over counted move outcomes, against optimism on falls.
- R-max in Dyna-Q's model (untried moves as heaven): should pay its falls sooner than Q + OPTIMISM.
- Optimism at several starts (39, 60, 200): how the bill of falls grows with over-optimism.
- Random slips added to moves, so outcomes look alike and regret bounds bite.
