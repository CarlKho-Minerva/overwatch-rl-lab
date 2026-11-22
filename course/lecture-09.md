# Lecture 9: Exploration and Exploitation

*David Silver's lecture 9 (UCL, 2015), gone through in his order and re-explained with the Tracer experiments on Workshop Island. The lecture and its slides are his: [video](https://www.youtube.com/watch?v=sGuiWX07sKw), [course page](https://davidstarsilver.wordpress.com/teaching/). The words below are a re-explanation. Every island number comes from the logged runs in this repository.*

Every bot on the island chooses between the move that looks best so far and a move that might teach her something. Q-LEARNING settles it with a coin: one move in ten is random, forever, so she keeps falling after her table knows better. Silver asks how much to explore and where. His answer: explore where you are uncertain, not at random, and prefer methods that make fewer mistakes as time goes on. On the island, bots optimistic about what they had not tried fell about a quarter as often as the bot that explored by coin.

## The lecture in order

### [02:23](https://www.youtube.com/watch?v=sGuiWX07sKw&t=143s) Every online decision is a choice between using what you know and finding out more
Exploitation takes the action you believe is best. Exploration does something else on purpose, to gather information that may pay off later: a new restaurant, a different advert, a new oil site. It arises because the agent learns online: its actions decide which data it sees. Silver names three families: random exploration (epsilon-greedy; softmax, which picks moves with probability rising with their score), optimism in the face of uncertainty, and the information state space, the most correct and the most expensive.
**On the island:** a bot that never walks the edge row never sees the +50; one that never steps toward the drop never learns its cost.

### [08:18](https://www.youtube.com/watch?v=sGuiWX07sKw&t=498s) You can explore over moves or over whole behaviours
State-action exploration tries a different move in a particular state and remembers what was tried where. Parameter exploration runs a whole different policy (the rule for choosing moves, here a robot's gait) for a while and sees how it does. That is consistent, where epsilon-greedy re-rolls every step, but it ignores which states it has visited, so it is closer to global optimisation. The lecture covers the first kind.
**On the island:** every bot explored over moves. Not run on the island: perturb a whole table for an episode, keep it if the return improves.

### [11:41](https://www.youtube.com/watch?v=sGuiWX07sKw&t=701s) The bandit: one state, one step, and a score called regret
A multi-armed bandit is a row of slot machines, each paying from its own unknown distribution. Pull one arm, get one reward, episode over. An arm's true value is its mean payout, `Q(a) = E[r | a]`; the best is `V* = max Q(a)`. Regret totals the reward given up: `L_t = sum over arms E[N_t(a)] * gap(a)`. In words: how often you pulled each arm, times how much worse it is than the best. A student spots the catch at 19:44: the gaps depend on V*, which nobody knows.
**On the island:** the strip is not a bandit but an MDP (a Markov decision process, where a move changes where she stands). The two-player build (exploratory, 12 short runs) has a bandit: the blocker learns her row "as a four-armed bandit".

### [21:39](https://www.youtube.com/watch?v=sGuiWX07sKw&t=1299s) Too much exploring and too little both cost the same every step
Fixed epsilon-greedy keeps picking random arms, each adding similar regret, so total regret climbs in a straight line. Greedy, which averages each arm's payouts and takes the highest, climbs straight too: a few unlucky pulls can lock it onto a worse arm for good. Both have linear total regret. The goal is sublinear regret, a curve that flattens.
**On the island:** Q-LEARNING's last 40 training episodes average 7.5 against a best possible 39, yet with exploring off she made 10 clean test crossings in 11 of 11 runs. The table was fine; the coin was the cost.

### [26:12](https://www.youtube.com/watch?v=sGuiWX07sKw&t=1572s) Optimistic initialisation: assume the best until proven otherwise
Start every estimate at the highest value it could have, then act greedily. Untried arms look wonderful, so they get tried, and only real payouts pull them down. Silver calls it hard to beat. His version: pretend each arm was already pulled 100 times at the maximum payout and keep averaging, which equals a Beta prior (a belief about a payout rate, written as counts). Bad luck can still lock out the best arm (27:39), so in theory regret stays linear.
**On the island:** Q + OPTIMISM starts every Q at 40, one above the best return of 39, and never moves at random. Falls per 100: 7.2 (7.0 to 7.3) against Q-LEARNING's 26.5 (22.4 to 30.4).

### [31:07](https://www.youtube.com/watch?v=sGuiWX07sKw&t=1867s) Shrinking epsilon can be nearly perfect, if you know the gaps
Plain epsilon-greedy and softmax have linear regret. Decay epsilon on the right schedule and regret becomes logarithmic: `epsilon_t = min(1, c * |A| / (d^2 * t))`, where d is the smallest gap. In words: explore less as time passes, and more slowly when the best two arms are hard to tell apart. Silver: "maybe it wasn't so naive at all". But the schedule needs the gaps, and a guessed one is excellent or "a disaster" (55:58).
**On the island:** Q + FADING EXPLORATION uses epsilon = 1 / (1 + episode / 5), floor 0.01, a guessed schedule of that 1-over-time shape. Falls 27.9 (25.4 to 30.3) against 26.5: difference 1.44 (-3.25 to 6.17), inconclusive.

### [36:36](https://www.youtube.com/watch?v=sGuiWX07sKw&t=2196s) No method can beat logarithmic regret
Lai and Robbins proved a floor. A bandit is hard when a worse arm's payouts look like the best arm's but have a different mean: `lim L_t >= log t * sum over worse arms gap(a) / KL(R_a || R_a*)`. In words: regret grows at least like the logarithm of time, and faster when arms differ in value but look alike (KL, the Kullback-Leibler divergence, measures how alike two distributions look).
**On the island:** with 0.21 slips per 1,000 steps, one try reveals a move's outcome. Not run on the island: added random slips would make moves look alike.

### [39:32](https://www.youtube.com/watch?v=sGuiWX07sKw&t=2372s) Optimism in the face of uncertainty, and the upper confidence bound
Three belief curves: green tried often (narrow), blue barely tried (wide), red between. Green has the highest mean, but the principle picks the arm with the most potential to be best, blue, whose tail reaches furthest. UCB (upper confidence bound) makes this a rule: `a_t = argmax Q(a) + U(a)`. In words: score each arm by its mean plus a bonus that is large when rarely tried and shrinks to zero with use.
**On the island:** Q + COUNT BONUS acts greedily on Q + 10 / sqrt(visits + 1), epsilon 0. Falls 7.1 (6.8 to 7.4), a difference from Q-LEARNING of -19.40 (-23.37 to -15.22).

### [47:22](https://www.youtube.com/watch?v=sGuiWX07sKw&t=2842s) Hoeffding's inequality turns counts into a bonus: UCB1
For rewards in [0, 1], whatever their distribution, the chance that the true mean exceeds the sample mean by more than u is at most `e^(-2 * t * u^2)`. Set that chance to p and solve: `U = sqrt(-log p / (2 * N(a)))`. Shrink p over time and you get UCB1: `a_t = argmax Q(a) + sqrt(2 * log t / N(a))`. In words: the bonus falls as an arm is tried and grows slowly with total time, so a neglected arm gets another look. Its regret is logarithmic; on 10-armed tests it did well untuned.
**On the island:** the count bonus has no log t term, so a neglected move's bonus never grows back. True UCB1 was not run.

### [57:27](https://www.youtube.com/watch?v=sGuiWX07sKw&t=3447s) Bayesian bandits: keep a belief, then act on its tail or on a draw from it
Bayes' rule turns a prior (a belief before any data) into a posterior after every pull. Bayesian UCB takes the posterior mean plus a few standard deviations (three, in his example). Probability matching picks each arm with the probability it is best, which is optimistic by itself, since a wide belief has a real chance of being the max. Thompson sampling, from the 1930s (1:04:04), does this by sampling: draw one value per arm from its posterior, pull the highest. It reaches the Lai and Robbins floor for coin-flip (Bernoulli) bandits, with no bonus to tune, but is only as good as its prior.
**On the island:** not run. Thompson sampling would count what each move did and act on a sampled table each episode.

### [1:08:38](https://www.youtube.com/watch?v=sGuiWX07sKw&t=4118s) The information state: what the agent knows becomes part of its state
The value of information (1:09:05) is the reward you would give up to have it before deciding, and it depends on time left: with three plays remaining, take the sure £100; with a thousand, try the unknown lever. UCB and Thompson are heuristics that break down in full MDPs (1:11:56). The principled move (1:12:15): an information state `s~ = f(h_t)`, a statistic of the history summing up everything learned, such as how often each lever was pulled. Each pull moves the agent to a new information state, so there is an MDP over information states (1:13:16).
**On the island:** no bot plans over what she knows. The planned hidden-wall build gives one runner a memory of what she bumped into this episode, a tiny information state.

### [1:14:06](https://www.youtube.com/watch?v=sGuiWX07sKw&t=4446s) Bayes-adaptive bandits: plan over what you would learn
A Bernoulli bandit pays 1 or 0, like a drug that cures with probability mu. The information state is each arm's successes and failures. Start each drug with a Beta prior (1:16:28: drug 1 flat, drug 2 near 50/50). A success shifts the belief one way, a failure the other, giving a lookahead tree of every possible future belief. Solving it gives the best trade-off given the prior, "not a heuristic anymore" (1:18:47). The MDP is infinite (1:19:00), but RL methods apply, and dynamic programming gives the Gittins index (1:19:37). A posterior as the state is Bayes-adaptive RL (1:20:07); Monte Carlo tree search (planning by simulated playouts) from the current belief makes it tractable (1:23:36).
**On the island:** not run. The experiment: a planner whose state is (square, what she has learned about each move), searched forward.

### [1:24:11](https://www.youtube.com/watch?v=sGuiWX07sKw&t=5051s) The map, and the objection: optimism is not safe exploration
Silver lines up the three families, then asks what is wrong with optimism. A student: with very many actions you never stop exploring. Silver adds that a real robot must avoid catastrophes, and optimism "doesn't give you safe exploration" (1:26:04); industry often explores only near what it knows is safe.
**On the island:** optimism and the count bonus each fell about 11 times per 150-episode run, roughly once per fatal edge move, then never again.

### [1:28:45](https://www.youtube.com/watch?v=sGuiWX07sKw&t=5325s) Contextual bandits and full MDPs: the same three ideas, harder
A contextual bandit shows a state first, such as who the visitor is (Yahoo's front-page news); its solution is left to non-examinable slides. All of it carries over to MDPs. Optimistic starts: `Q = r_max / (1 - gamma)`. In words: the largest return the problem could pay. UCB in MDPs faces a second uncertainty, how much the policy could still improve (1:33:39). R-max and its variant E cubed (1:34:33): treat every state you do not understand as heaven, plan, go there, find out, repeat. Information state search becomes where you are plus what you have learned (1:35:51).
**On the island:** with discount 1 the bound is the best return, 39, so the start of 40 follows the recipe. MONTE CARLO + OPTIMISM got nothing from it: 97.7 falls per 100 (97.1 to 98.3).

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
