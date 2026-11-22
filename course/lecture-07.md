# Lecture 7: Policy Gradient

*David Silver's lecture 7 (UCL, 2015), gone through in his order and re-explained with the Tracer experiments on Workshop Island. The lecture and its slides are his: [video](https://www.youtube.com/watch?v=KHZVXao4qXs), [course page](https://davidstarsilver.wordpress.com/teaching/). The words below are a re-explanation. Every island number comes from the logged runs in this repository.*

In this lecture's game a bot locks in a hero each round before you pick yours, and its whole brain is three bars: its odds of choosing Tracer, Widowmaker or Pharah. It keeps no score for any hero; it raises the odds of whatever won. This hour asks how a learner can adjust its odds directly like that, which Silver calls policy gradient, and what it should judge each move by: the ending of the whole episode, or the step-by-step guess of a second learner called a critic. On the island that choice parted two Tracers with the same kind of brain, a habit table saying how strongly she leans toward each move on each square: POLICY GRADIENT learned to step off the edge almost at once and never reached the goal in 14 of 15 runs, and ACTOR-CRITIC crossed cleanly in all 17 runs.

**Two windows:** this page, and [Game 7: Counter-Pick](../workshop/games/g07.md), an Overwatch custom game for this lecture (paste `workshop/compiled/game-07.txt` into a custom game's settings and start it). The game opens at stop 1 and waits. Read down this page; at each box marked Alt+Tab, switch to the game, do that stop, and switch back. The game never moves on while you read.

## The lecture in order

### [05:03](https://www.youtube.com/watch?v=KHZVXao4qXs&t=303s) Give the policy its own adjustable numbers
Every bot so far has chosen its moves by looking something up. It kept a score for each move, an estimate of the reward still to come that Silver calls a value, and it took the top-scoring move, with a random one now and then (lecture 5's epsilon-greedy rule). The rule for choosing was never stored. It fell out of the scores.

Silver now stores the rule itself. The rule for choosing a move is called the policy, and he gives it adjustable numbers of its own, which he calls u (the slides write θ). They set how likely each move is in each situation, and they can be held in a table, a simple formula (a linear rule) or a neural network. `π_θ(s, a) = P[a | s, θ]`. In words: the policy is the chance of taking move a (an action) in situation s (a state), and θ sets those chances.

Learning now means changing those numbers so that more reward comes in, from experience alone and with no rulebook of the world. The game first asks what a learner made only of odds does when one move keeps winning.

> **Alt+Tab · game 7 · stop 1 of 8: Predict the bars against a habit**
>
> **What he just said:** Silver stops scoring moves and gives the policy, the rule for choosing a move, its own adjustable numbers, which set how likely each move is.
>
> **In the game:** The question floats in front of you. Answer with LEFT CLICK, RIGHT CLICK or MELEE, as the line under it says.
>
> **Before you press:** Commit to what the bot's three bars will do if you pick the same hero six rounds in a row.
>
> <details><summary>Back from the game: what you just saw</summary>The bot raises the odds of whatever won. Against one hero only that hero's counter keeps winning, so its bar is the one that can climb. The three bars are the bot's whole brain: three preferences turned into three odds by a softmax, a rule that makes the odds add up to 100%. <em>In an agent:</em> A language model is this bot with one bar per word: a preference for every word, turned into odds by a softmax.</details>

> **Alt+Tab · game 7 · stop 2 of 8: Play one hero six times**
>
> **What he just said:** Those numbers can sit in a table, a simple formula or a neural network, and learning means changing them, not filling in a table of move scores.
>
> **In the game:** Pick a hero with LEFT CLICK (Tracer), RIGHT CLICK (Widowmaker) or MELEE (Pharah), then pick the same one five more times. The bot locks in its own pick before you press, from its odds alone.
>
> **Before you press:** Before each press, guess whether the bar of the hero that beats yours will go up, go down or stay put this round.
>
> <details><summary>Back from the game: what you just saw</summary>Your counter's bar climbed round by round. The coach line shows each push: nudge size 0.6 times (reward minus its usual reward) times (1 minus the odds it gave that pick). A pick it thought unlikely moves more. The bot learned its odds directly, with no score for any move: Silver calls the odds a policy, and this way of learning them a policy gradient. <em>In an agent:</em> Training a model on outputs that scored well is this same push, applied to every word of the output.</details>

**On the island:** POLICY GRADIENT and ACTOR-CRITIC each hold a "tabular softmax policy": a table of four preferences, one for each move, for each of 48 squares. The value-based bots (SARSA, Q-LEARNING, MONTE CARLO and the rest) hold move scores instead.

### [10:26](https://www.youtube.com/watch?v=KHZVXao4qXs&t=626s) Why bother: smoother learning, huge action sets, randomness on purpose
The scores were working, so Silver owes a reason for setting them aside. He gives three, and one cost.

The first is steadier learning. Methods built on scores can swing sharply in what they do, and earlier lectures showed some of them oscillating or even diverging. A policy changed in small steps moves smoothly. If each step follows the direction in which changing the numbers raises reward fastest, called the gradient, the policy is sure to reach at least a peak, though maybe not the highest one (a local optimum). Learning a policy this way is called policy gradient.

The second he calls the main reason. A bot that works from scores must find the best of all its moves at every step (the max). That is hopeless with a trillion moves, or with a robot whose moves are continuous turning forces (torques). A policy never runs that search. It shifts its odds a little at a time.

The third is that a policy can be random on purpose, which Silver calls stochastic. The cost is that plain policy gradient is slower and noisier than learning scores. Epsilon-greedy, the top move plus an occasional random one, is random some of the time too, and the game asks next where its randomness goes.

> **Alt+Tab · game 7 · stop 3 of 8: Find where random picks go**
>
> **What he just said:** Silver lists why a policy is worth learning directly, and the third reason is that it can be random on purpose, which a rule that always takes the best-scored move cannot be.
>
> **In the game:** Answer the question with LEFT CLICK, RIGHT CLICK or MELEE.
>
> **Before you press:** Decide where a bot that takes its best hero, plus a random hero one time in ten, spends its randomness.
>
> <details><summary>Back from the game: what you just saw</summary>The lecture 5 rule, epsilon-greedy, sprays its randomness evenly: its best hero 93% of the time and each other hero 3%, whatever they earned. This bot aims its randomness instead. Each hero's odds come from what that hero did, so a softmax policy is random in the amounts that worked. <em>In an agent:</em> Sampling temperature spreads the model's own learned odds, which is aimed randomness, not a flat chance of a random word.</details>

**On the island:** With only four moves the max is trivial, and PLANNER's fixed route earns 39 every time.

### [14:29](https://www.youtube.com/watch?v=KHZVXao4qXs&t=869s) Rock-paper-scissors: the best policy can be random
A player who always does the same thing can be read, and a player who has been read loses. Silver's example is rock-paper-scissors: scissors beats paper, rock beats scissors, paper beats rock.

Any fixed way of playing is easy to exploit. If he always plays rock, he says, you will soon work out that you should play paper, and he will lose every time. A lean is enough: play one option more often than the others and an opponent will learn to exploit it.

So the best play is random. The only policy (rule for choosing) that cannot be exploited plays each option a third of the time. It is the one point where neither player gains by changing alone, which game theory calls a Nash equilibrium. This is the first of his two cases where a policy has to be random to be the best one.

> **Alt+Tab · game 7 · stop 4 of 8: Beat a bot with a rule**
>
> **What he just said:** In rock-paper-scissors any fixed choice gets exploited: a player who always throws rock loses to anyone who notices and throws paper.
>
> **In the game:** Answer the question with LEFT CLICK, RIGHT CLICK or MELEE, then read the line that follows about two squares that look alike.
>
> **Before you press:** Decide what beats a bot that must pick by a fixed rule, such as always Pharah, or the three heroes in turn.
>
> <details><summary>Back from the game: what you just saw</summary>Anyone who spots the rule beats it, every round, however clever the rule is. Only odds that are random on purpose cannot be read. Silver's aliased gridworld, two squares that look the same, makes the same point: one fixed move fails in one of them, and a coin flip gets out. <em>In an agent:</em> A support agent sees the conversation, not the customer's real wishes, so two different customers can look the same to it, like the grey squares.</details>

> **Alt+Tab · game 7 · stop 5 of 8: Name the mix nobody can beat**
>
> **What he just said:** The only stable answer in rock-paper-scissors is to play each option a third of the time, the point where neither player gains by changing alone.
>
> **In the game:** Answer the question with LEFT CLICK, RIGHT CLICK or MELEE.
>
> **Before you press:** Commit to the mix of your own picks that no counter-picker can beat on average.
>
> <details><summary>Back from the game: what you just saw</summary>A third each. Against it every counter wins exactly as often as it loses, so a perfect counter-picker nets zero. Silver calls this the Nash equilibrium, the mix neither player can improve on alone. It is a policy that has to be random to be best.</details>

**On the island:** In the exploratory lecture 10 build, a learning blocker faced a runner who could see which row the blocker stood in, and the blocker spread herself over all four rows (0.36, 0.28, 0.14, 0.21). Four short runs cannot tell a mixed strategy from unfinished learning.

### [15:26](https://www.youtube.com/watch?v=KHZVXao4qXs&t=926s) The aliased gridworld: two squares that look the same
The second case for randomness is being unable to tell two places apart. Silver's slide shows five squares in a corridor along the top, with money below the middle one and skulls below the two ends. Squares two and four are grey.

At [15:30] he says when this arises: when what you see no longer tells you everything that matters, which is the Markov property failing. The world is only partly observed or, equivalently, your features (the facts you describe a situation by) hide something. At [16:20] he fixes the features: each pairs a wall with a move, such as an outside wall to the north while moving east.

At [17:49] a student names the problem: each grey square has walls north and south only, so moving west looks the same from both. Such squares are called aliased. At [18:15] Silver draws the consequence. A policy with one fixed move per situation (deterministic) must choose the same move in both. A value function (the scores a value-based bot learns) must give them equal values, so a greedy bot, which always takes its top score, goes always west or always east.

Take always west. From the right grey square, west reaches the middle and the walker drops onto the money. From the left one, west reaches the corner, the corner sends her east, back to grey, west again. Greedy bounces forever; epsilon-greedy, with its occasional random move, for a long time.

At [19:15] the fix is a policy that is random on purpose (stochastic): in a grey square, go east or west with probability 0.5, which reaches the money in a few steps. `π_θ(wall to N and S, move E) = 0.5`. In words: when she cannot tell which grey square she is in, a coin flip beats every fixed choice. At [19:54]: "whenever state aliasing occurs, a stochastic policy can do better than a deterministic policy." At [20:02] he squares this with lecture 2's theorem that every MDP (Markov decision process, the formal model of a problem) has a deterministic optimal policy: the theorem assumes a perfect description of the state.

**On the island:** Q, ROW ONLY is told only which row she is in. Her case is milder. Forward is the right move in every edge-row square, but forward and back both seem to lead "to the place she is already in", so she dithers (47.1 steps per episode against 18.6 for full Q-learning; 3 of 10 runs clean at test). The planned hidden-wall build is the island's version of the grey squares: RUNNER BLIND meets two situations that look identical. It has no results yet.

### [20:42](https://www.youtube.com/watch?v=KHZVXao4qXs&t=1242s) What "better" means: three objectives
Before a policy can be improved, someone has to say what better means. Silver offers three ways to give a whole policy one number to push up, which he calls the objective.

If every episode begins in the same place, as a game of Atari does, use the total reward the policy expects to collect from that start, called the start value. `J_1(θ) = V^πθ(s_1)`. In words: a policy's score is the reward it collects on average from the start.

Some tasks never end and have no start. For those he gives two measures. One is the average value over the states the policy visits, where a state's value is the reward expected from there on: if it might be in a state worth 10 or in one worth 20, the objective might be 15. The other is the average reward per step.

He does not have to choose. All three give essentially the same gradient direction (the direction in which to change the numbers), so the methods that follow serve any of them.

**On the island:** The objective is the expected return of a crossing. The best is 39; the exact start value under RANDOM WALK is -114.4.

### [26:37](https://www.youtube.com/watch?v=KHZVXao4qXs&t=1597s) The blunt way: nudge each number and measure
Picture the policy's numbers as dials and the objective, its overall score, as a meter. The plainest way to learn which way to turn a dial is to turn it slightly and watch the meter.

Silver first notes that a policy can be improved with no slope at all, by search methods such as hill climbing or genetic algorithms. Those work. But a method that knows the uphill direction, called the gradient, is usually more efficient.

The crudest way to get a gradient is to nudge one number, measure the objective again, and repeat for every number. This is called finite differences. `∂J/∂θ_k ≈ (J(θ + ε u_k) − J(θ)) / ε`. In words: the slope along one dial is how much the score changes when you turn it slightly. It works even when nobody knows how to take the policy's slope by calculus (a non-differentiable policy). But a policy with a million numbers needs a million evaluations, each one noisy.

At [30:19] he shows where it worked: RoboCup's AIBO robot dogs, whose way of walking (gait) is set by 12 numbers. The dog ran up the field a dozen times for each gradient step, and it ended with a much faster walk.

**On the island:** Not run on the island. Each step would need many crossings for each of 192 nudged preferences.

### [33:46](https://www.youtube.com/watch?v=KHZVXao4qXs&t=2026s) The score function: how to make a move more likely
Suppose the bot has just made a move and you want it to make that move a little more often. There is an exact recipe for which way to turn each of the policy's numbers.

Silver reaches it by a step of calculus called the likelihood-ratio trick: multiply and divide the policy's gradient by the policy, and you get the policy times the gradient of the log of the policy. That gradient of the log is called the score function. It is the direction that learning from a teacher's examples (maximum-likelihood learning) follows to make an action more likely, and it turns the gradient into an average over the bot's own moves, which the bot can sample by playing.

He works it out twice. A policy that gives each move a preference, and a probability proportional to e raised to that preference, is called softmax [36:41]. Its score is the chosen action's features (the facts that describe it) minus the average features. `∇θ log π_θ(s,a) = φ(s,a) − E_πθ[φ(s,·)]`. In words: the push is "this was the move I made" minus "how likely I was to make it".

For continuous actions [39:25] he uses a policy that aims at a mean action and adds noise around it, called Gaussian. Its score is the action minus the mean, times the features, over the variance (the spread of the noise). Both say "how much more than usual am I doing something" [41:14].

**On the island:** With a table of preferences the score is simple. The chosen move gets 1 minus its probability, and each other move gets minus its probability.

### [41:45](https://www.youtube.com/watch?v=KHZVXao4qXs&t=2505s) The policy gradient theorem: push each move by how good it was
The score says how to make a move more likely. Still missing is how hard to push, and whether to push toward the move or away from it.

Silver works it out first for the smallest problem there is: see a situation, make one move, collect one reward, and the episode ends. This is a one-step problem, also called a contextual bandit. There the gradient of the expected reward is the average of the score times the reward. A large positive reward pushes hard toward the move just made, and a large negative one pushes away from it. No model (no rulebook of the world) is needed: the bot knows its own score and uses the reward it actually received.

At [46:32] he moves to problems with many steps. One change is enough: swap the single reward for the long-run value of the action, the total reward expected after making that move in that place, written Q. The result is the policy gradient theorem. `∇θ J(θ) = E_πθ[∇θ log π_θ(s,a) Q^πθ(s,a)]`. In words: make good moves more likely in proportion to how good they are.

He sets this beside learning from a teacher (supervised learning), which pushes toward whatever action the teacher names. Here there is no teacher. Each action the bot takes is pushed by how good it was.

**On the island:** Q for stepping off from row 0 is about -101. Q for stepping forward is the number the two bots estimate differently.

### [48:26](https://www.youtube.com/watch?v=KHZVXao4qXs&t=2906s) REINFORCE: the real return stands in for Q
The theorem needs to know how good each move was, and nobody hands the bot that number. The simplest answer is to play the episode out and count.

The total reward from one step to the end of the episode is called the return, and learning from whole episodes is lecture 4's Monte Carlo way. Silver uses the return that actually followed a move as a stand-in for Q, the long-run value of that move. On average the two are equal, so the direction is still right. The method is Monte Carlo policy gradient, roughly the same as an old algorithm named REINFORCE. The bot plays an episode to the end, then goes back over it and nudges its numbers once for each step. `Δθ_t = α ∇θ log π_θ(s_t, a_t) v_t`. In words: after the episode, push each move by its score times the reward that followed, times a step size α.

His example at [50:56] is a puck sliding with very little friction toward a target that moves now and then, steered by a small force each step. It learns smoothly, where value-based learning tends to be jagged, but it takes around 100 million iterations. Each update rests on one complete return, and returns differ a great deal between episodes, so the method is slow and high variance [52:28]. The rest of the hour attacks that noise.

> **Alt+Tab · game 7 · stop 6 of 8: Free play against a fresh bot**
>
> **What he just said:** REINFORCE, the simplest policy gradient, waits for the end of an episode and pushes each move it made by the reward that followed, times a step size.
>
> **In the game:** A fresh bot starts at a third each. Play five rounds with LEFT CLICK, RIGHT CLICK or MELEE, and try to leave it no pattern.
>
> **Before you press:** Guess how close to zero you can bring the number that says what a perfect counter-picker would win against your mix.
>
> <details><summary>Back from the game: what you just saw</summary>The left block shows your mix and what a perfect counter-picker would net against it, in wins minus losses per 100 rounds. Five picks cannot split into thirds, so the best possible is 20. The bars wander instead of climbing, because no hero keeps winning. Each round here is a whole episode, so its reward is the return that REINFORCE pushes by. <em>In an agent:</em> Training on whole conversations scored at the end works this way: one reward, pushed back onto every token the agent chose.</details>

**On the island:** POLICY GRADIENT is this method with a per-state baseline (explained two parts below) and step 0.02. A beginner rarely sees the +50. Of the endings she does see, stepping off at once (-101) beats wandering then falling (about -110) or timing out (-150). She fell in 96.5 of every 100 training episodes, and her last-40 return was -101.6.

### [52:54](https://www.youtube.com/watch?v=KHZVXao4qXs&t=3174s) Actor-critic: a learned judge replaces the raw return
One ending is a poor judge of one move, because so much chance sits between a move and the final score. Silver stops waiting for the ending and trains a second learner to do the judging.

The actor holds the policy and makes the moves. The critic decides nothing: it watches and estimates how good the actor's moves are, by any evaluation method from earlier lectures. The actor then shifts its policy the way the critic points. `Δθ = α ∇θ log π_θ(s,a) Q_w(s,a)`. In words: push each move by the critic's opinion of it, not by one noisy ending.

In his worked version, the Q actor-critic [57:14], the critic is a weighted sum of features (linear) trained by TD(0), the rule that corrects each guess after one step. Nothing waits for the ending, so both update at every step. His Venn diagram [1:01:37] puts actor-critic methods where the two families overlap: they hold both a value and a policy.

He then answers two students. In some of these algorithms the step size sets how greedy the learner is: an infinite step [1:04:47] would push one move's probability to one and the others to zero, and small steps keep learning smooth. At [1:05:27], on getting stuck at a lower peak (a local optimum): a softmax policy kept as a table and following the gradient is known to reach the global optimum, the highest peak. With neural networks neither family is guaranteed to.

> **Alt+Tab · game 7 · stop 7 of 8: Quadruple the nudge and watch**
>
> **What he just said:** Silver treats the step size as a dial between smooth learning and greedy jumps, and warns that big steps drive the other odds toward zero.
>
> **In the game:** Answer the question, then play four more rounds with LEFT CLICK, RIGHT CLICK or MELEE. The nudge size is now 2.5 instead of 0.6.
>
> **Before you press:** Commit to what the bars will do once each push is about four times bigger.
>
> <details><summary>Back from the game: what you just saw</summary>One lucky round can now throw a bar most of the way to the top. A single win from even odds lifts a pick to 48% at nudge 0.6 and to 86% at nudge 2.5. Near the top, 1 minus its odds is close to zero, so later rounds barely move it back. That is the step size Silver warns about. <em>In an agent:</em> A training run with too large a step can lock a model onto one answer that later updates barely move.</details>

**On the island:** ACTOR-CRITIC is the one-step kind, with a TD(0) critic (actor step 0.1, critic 0.2).

### [1:07:03](https://www.youtube.com/watch?v=KHZVXao4qXs&t=4023s) Baselines and the advantage: compare each move with the usual result
Suppose one move earns a reward of a million and the next earns 999,000. Both numbers are huge, so both moves get pushed up hard, and the only thing that matters, the gap between them, is buried. That is Silver's case for measuring each reward against what is normal.

The number you compare against is called a baseline. He shows that any baseline may be subtracted from the value in the policy gradient, provided it depends only on the state and not on the move chosen. The proof is short: in any one state the probabilities of the moves sum to 1, a constant, and the gradient of a constant is 0. So the subtracted term has zero effect on average. The noise falls and the direction holds.

The baseline he picks is how good it is to be in a state in general, the state value V. Subtracting it from Q, the value of one move there, leaves Q minus V. This is called the advantage (Silver calls it D, the slides write A): how much better than usual this action is here. `∇θ J(θ) = E_πθ[∇θ log π_θ(s,a) A^πθ(s,a)]`. In words: push up moves that beat your usual result from that square.

> **Alt+Tab · game 7 · stop 8 of 8: Read the debrief**
>
> **What he just said:** Silver subtracts a baseline, the usual result from that situation, from each reward: the push keeps its direction on average and gets much less noisy.
>
> **In the game:** Nothing to press. Read the three debrief lines on the left and your prediction score.
>
> **Before you press:** Before reading, name the one number the bot compared every reward against.
>
> <details><summary>Back from the game: what you just saw</summary>The bot compared each reward with its usual reward, a running average that moved a quarter of the way toward each new reward. A win it expected barely moved its odds; a draw when it usually won counted against the pick. That usual reward is the baseline, and reward minus baseline is what Silver calls the advantage. <em>In an agent:</em> A language model draws each word from a softmax, temperature sets how spread the odds are, and training pushes up answers that beat the average of several tries.</details>

**On the island:** POLICY GRADIENT had this baseline. Stepping off really was better than her usual ending, so it still got pushed up.

### [1:13:06](https://www.youtube.com/watch?v=KHZVXao4qXs&t=4386s) The TD error is a sample of the advantage: one step's surprise judges the move
You think you are winning, you make a move, and now you think you are losing. That move was probably bad, and you did not need the end of the game to find out. This is Silver's picture for the part.

The size of that change of mind is the TD error from lecture 4: the reward just received, plus the guess for where you landed (shrunk a little by the discount γ), minus the guess for where you stood. `δ = r + γ V_v(s') − V_v(s)`. In words: the surprise after one step is the verdict on the move just made.

He then shows why it is the right verdict. If the guesses were the true state values V, the average TD error after a given move in a given state would be exactly Q minus V, the advantage from the last part. At [1:14:47]: "the TD error is an unbiased sample of the advantage function." Unbiased means right on average, though any one sample can be off.

So the critic has less to learn. It needs only V, the value of each state, and no separate score for every move. Silver calls this probably the most commonly used form of actor-critic. In practice the critic's V is itself an estimate, so the update is a good approximation to the true gradient and no longer exact.

**On the island:** This is ACTOR-CRITIC. Her critic's guess for a square she has not visited starts at zero, far above -101, so forward kept looking better than the edge: 7.1 falls per 100.

### [1:17:14](https://www.youtube.com/watch?v=KHZVXao4qXs&t=4634s) A fading memory for the actor (eligibility traces)
A surprise now may be the fault of a move made several steps ago. This part gives the actor a way to pass the verdict back, the same device lecture 4 gave the learner of values.

Silver first sets out the two extremes. The actor can judge a move by the full return (everything collected to the end of the episode) minus a baseline, which is right on average (unbiased) but noisy. Or it can judge by the one-step TD target, the reward plus the critic's guess for the next state. That has less noise but some bias, because it leans on the critic's own estimates, which is called bootstrapping.

The mix of the two is a running record of the scores of recent moves that fades as they recede, called an eligibility trace. It is lecture 4's TD(λ) in its backward view, with one swap: wherever the value method used the gradient of the value, the actor uses the score. `e_{t+1} = λ e_t + ∇θ log π_θ(s,a)`, `Δθ = α δ e`. In words: keep a fading memory of recent pushes and apply each surprise to all of them.

Unlike REINFORCE, this runs online. The actor updates at every step and never needs the episode to end.

**On the island:** Not run on the island for an actor. SARSA LAMBDA uses traces for values only (11.8 falls per 100 against 16.3 for SARSA).

### [1:23:44](https://www.youtube.com/watch?v=KHZVXao4qXs&t=5024s) A critic that keeps the gradient true, a shortcut with no randomness, and the summary
A critic is only a guess, and a wrong guess could bend the gradient and send the actor the wrong way. Silver calls it the first question to ask about any actor-critic method: whether the actor still follows the true gradient once an estimate replaces the true value.

His answer is that it can. The critic does not bend the gradient if two things hold: the features it is built from are the policy's own score, and its weights minimise squared error. This result is called compatible function approximation.

At [1:26:06] he adds his group's deterministic policy gradient, which is not on these slides. A policy that explores by adding noise has to average over its own noise, and that estimate gets worse as the policy narrows in on a good action. So he starts from a policy with no noise at all. For continuous actions the critic already tells how the value would change if the action were a little higher or lower, and the actor follows that slope.

At [1:30:07]: "I'm going to skip the natural actor critic." The summary [1:30:32] puts the hour's methods in one frame: each moves the policy in the direction that gets more value, mostly the score multiplied by some estimate of value. They differ in how the critic makes that estimate and in how the actor uses it.

**On the island:** Not run on the island. Both would need a continuous action, such as a running angle.

## What the island measured for this lecture

| Measure | Policy gradient | Actor-critic | Q-learning |
|---|---|---|---|
| Runs | 15 | 17 | 11 |
| Falls per 100 training episodes (95% interval) | 96.5 (93.2 to 98.9) | 7.1 (6.8 to 7.5) | 26.5 (22.4 to 30.4) |
| Mean return, first 40 / last 40 | -112.3 / -101.6 | -45.4 / 34.7 | -57.6 / 7.5 |
| Runs never reaching the goal | 14 | 0 | 0 |
| Runs with 10 clean test crossings | 0/15 | 17/17 | 11/11 |

Last-40 return differences: actor-critic minus policy gradient 136.35 (135.66 to 137.17); policy gradient minus Q-learning -109.08 (-117.07 to -101.30); actor-critic minus Q-learning 27.27 (18.72 to 34.83). Falls, actor-critic minus Q-learning: -19.38 (-23.31 to -15.09). All four are exploratory, uncorrected for multiple comparisons; only SARSA against Q-learning on falls was planned. They show that, with untuned settings and 150 episodes, judging moves by the whole ending taught a softmax policy to step off, and a TD critic prevented it. MONTE CARLO, also judging by the ending, fell the same way (98.3 per 100). They do not show that REINFORCE fails in general: Silver's puck needed about 100 million iterations, and the bots' step sizes differ (0.02 against 0.1).

## Guess first

<details><summary>A new POLICY GRADIENT Tracer has seen three endings: wandered then fell (about -110), timed out (-150), stepped straight off (-101). Which move does REINFORCE with a baseline strengthen most?</summary>
Stepping off. It is the best ending she knows, so it beats her baseline; the +50 never enters her sums. Hence 14 of 15 runs never reached the goal.
</details>

<details><summary>ACTOR-CRITIC has the same kind of habit table but bootstraps like lecture 4's TD. Does she learn to jump?</summary>
No. Her verdict on a move is the TD error, which leans on the critic's guess for the next square, starting at zero, well above -101. Forward looks good before she sees the goal. All 17 runs clean.
</details>

<details><summary>Lecture 2 proved every MDP has a deterministic optimal policy. Does the aliased gridworld break that?</summary>
No. The theorem needs the true state. The agent sees only wall features, which two squares share, so what it observes is not an MDP [20:02].
</details>

<details><summary>Does subtracting a baseline change the average direction of the update, its noise, or both?</summary>
Only the noise: the baseline term averages to zero because probabilities sum to 1 [1:07:03]. So it could not stop POLICY GRADIENT from learning to step off.
</details>

<details><summary>On the full strip, would PLANNER do better with a coin flip somewhere?</summary>
No. The strip is fully observed and nearly deterministic (0.21 slips per 1,000 steps), so a fixed route is optimal: 39 every time. Randomness pays only against an adaptive opponent or under aliasing.
</details>

<details><summary>Lecture 5's MONTE CARLO control and this lecture's REINFORCE are different families. What shared habit made both fail on the island?</summary>
Both judge a move by the complete return after it, and early on the best return either has seen is stepping off. MONTE CARLO fell 98.3 times per 100, POLICY GRADIENT 96.5. Every TD learner reached the goal in every run.
</details>

## Cards

- Q: What do value-based, policy-based and actor-critic methods store? | A: Values; a policy; both.
- Q: Two reasons a stochastic policy can be optimal? | A: An exploiting opponent; aliased states needing different moves.
- Q: Why does greedy fail in the aliased gridworld? | A: Both grey squares share features, so it goes one way in both and bounces forever from one.
- Q: What is the score function? | A: The gradient of the log policy: the push that makes the chosen action likelier.
- Q: Policy gradient theorem? | A: Gradient of the objective equals expected score times Q of the action taken.
- Q: What does REINFORCE use for Q? | A: The actual return from that step to the episode's end.
- Q: Why subtract a baseline? | A: Lower variance, same expected gradient; with V it turns Q into the advantage.
- Q: Why can the TD error stand in for the advantage? | A: With the true V, its expected value is Q minus V.

## In language-model terms

A language model is a softmax policy, exactly: a preference for every token, the next drawn in proportion to e raised to it. The score for a sampled token is one for the token drawn minus its probability, the island habit table's arithmetic. Silver's main reason, no max over a vast action set, fits.

In tau-bench an agent reads a conversation, calls tools, and is scored at the end on whether a simulated customer's task was done (not from the lecture). Pushing up the tokens of well-scored conversations is REINFORCE; the average score of several attempts at the same task is a baseline; a model scoring partial conversations is a critic.

The island's trap is an analogy there: an agent that rarely sees success may learn the least-bad ending, such as handing off early. The mapping breaks in two places. An episode is thousands of token choices, so the noise is far worse. And the agent sees the conversation, not the customer's real wishes: partial observability, with sampling temperature as the grey squares' coin flip.

## The thread to partial observability

At [15:30] Silver ties aliasing to the loss of the Markov property, and treats "partially observed" and "my features hide something" as one situation. At [20:02] he limits the deterministic-policy theorem to a perfect state description. A policy reading only the current observation can need randomness, which greedy value methods cannot give, since aliased states get one value and so one action. Carry forward two remedies: randomise, the best a memoryless policy can do, or remember (an agent recalling its last move could leave the left grey square without a coin flip; this point is not from the lecture). The planned hidden-wall build sets RUNNER BLIND beside RUNNER REMEMBERS BUMPS, the smallest possible memory.

## Experiments the lecture asks for that the island has not run

- A softmax policy-gradient runner in the hidden-wall blind condition against greedy Q-learning: tests whether randomness beats a fixed habit under aliasing.
- REINFORCE with and without baseline, longer, at several step sizes.
- Actor-critic with a trace on the actor: tests whether credit reaches early moves faster.
- Finite differences on the 192 preferences: the cost of a gradient without the score function.
- A Gaussian policy over a continuous running angle, where policy methods matter most.
