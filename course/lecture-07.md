# Lecture 7: Policy Gradient

*David Silver's lecture 7 (UCL, 2015), gone through in his order and re-explained with the Tracer experiments on Workshop Island. The lecture and its slides are his: [video](https://www.youtube.com/watch?v=KHZVXao4qXs), [course page](https://davidstarsilver.wordpress.com/teaching/). The words below are a re-explanation. Every island number comes from the logged runs in this repository.*

A bot locks in its hero before you have even picked yours, and its whole brain is three bars: its odds of going Tracer, Widowmaker or Pharah. It keeps no score for any hero. When a pick wins, its odds go up, and that is all it ever does. This hour is about learners that adjust their odds directly like that, which Silver calls policy gradient, and one awkward question: should each move be judged by how the whole episode ended, or by the running guess of a second learner called a critic? On the island that single choice split two Tracers with the same kind of brain (a habit table: how strongly she leans toward each move on each square). POLICY GRADIENT learned to step off the edge almost at once and never reached the goal in 14 of 15 runs. ACTOR-CRITIC crossed cleanly in all 17.

**Two windows:** this page, and [Game 7: Counter-Pick](../workshop/games/g07.md), an Overwatch custom game for this lecture (paste `workshop/compiled/game-07.txt` into a custom game's settings and start it). The game opens at stop 1 and waits. Read down this page; at each box marked Alt+Tab, switch to the game, do that stop, and switch back. The game never moves on while you read.

## The lecture in order

### [05:03](https://www.youtube.com/watch?v=KHZVXao4qXs&t=303s) Throw out the tier list, keep the habit

Some players pick from a tier list. Every hero has a number, they lock in the top one, and now and then they go off-meta for fun. If you ask why they are on Tracer, they point at the number. The choice falls out of the list.

Every bot in this course so far has played like that. It kept a score for each move, an estimate of the reward still to come that Silver calls a value, and took the top one, with a random move now and then (lecture 5's epsilon-greedy rule). The rule for choosing was never stored.

Silver now stores the rule itself.

The rule for choosing a move is called the policy, and he gives it adjustable numbers of its own, which he calls u (the slides write θ). They set how likely each move is in each situation, and they can live in a table, a simple formula (a linear rule) or a neural network.

<details markdown="1"><summary>The formula, when you want it</summary>

`π_θ(s, a) = P[a | s, θ]`. In words: the policy is the chance of taking move a (an action) in situation s (a state), and θ sets those chances.

</details>

Learning now means turning those numbers until more reward comes in, from experience alone, with no rulebook of the world. The game starts there: a bot made of nothing but odds, and the question of what it does when one move keeps winning.

> **Alt+Tab · game 7 · stop 1 of 8: Predict the bars against a one-trick**
>
> **What he just said:** Silver stops keeping a score for every move. Instead the policy, the rule for choosing a move, gets adjustable numbers of its own, and those numbers set how likely each move is. No tier list. Just habits.
>
> **In the game:** The question floats in front of you. Answer with LEFT CLICK, RIGHT CLICK or MELEE, as the line under it says.
>
> **Before you press:** Commit to what the bot's three bars will do if you pick the same hero six rounds in a row.
>
> <details><summary>Back from the game: what you just saw</summary>It raises the odds of whatever won, and that is all it does. Against one hero only that hero's counter keeps winning, so that is the bar that climbs. Those three bars are the bot's whole brain: three preferences, turned into three odds by a softmax, a rule that makes the odds add up to 100%. <em>In an agent:</em> A language model is this bot with one bar per word: a preference for every word, turned into odds by a softmax. Same brain, much bigger roster.</details>

> **Alt+Tab · game 7 · stop 2 of 8: Play one hero six times**
>
> **What he just said:** Those numbers can sit in a table, a simple formula or a neural network. Learning means turning them, not filling in a table of move scores.
>
> **In the game:** Pick a hero with LEFT CLICK (Tracer), RIGHT CLICK (Widowmaker) or MELEE (Pharah), then pick the same one five more times. The bot locks in its own pick before you press, from its odds alone.
>
> **Before you press:** Before each press, guess whether the bar of the hero that beats yours will go up, go down or stay put this round.
>
> <details><summary>Back from the game: what you just saw</summary>Your counter's bar climbed, round after round. The coach line shows each push: nudge size 0.6 times (reward minus its usual reward) times (1 minus the odds it gave that pick). So a pick it thought unlikely moves more. It never scored a single hero. Silver calls the odds a policy, and learning them like this a policy gradient. <em>In an agent:</em> Training a model on outputs that scored well is this same push, applied to every word of the output.</details>

**On the island:** POLICY GRADIENT and ACTOR-CRITIC each hold a "tabular softmax policy": a table of four preferences, one for each move, for each of 48 squares. The value-based bots (SARSA, Q-LEARNING, MONTE CARLO and the rest) hold move scores instead.

### [10:26](https://www.youtube.com/watch?v=KHZVXao4qXs&t=626s) Why bother? Because nobody can check a trillion moves

Imagine that before every shot you had to score every angle you could flick to, then take the best one. You would never fire.

That is a scoring bot facing a huge set of moves, and it is Silver's main reason to drop the tier list. He gives three, plus one honest cost.

1. **Smoother learning.** Bots that choose from scores can swing sharply in what they do, and earlier lectures showed some oscillating or even diverging. A policy changed in small steps moves smoothly. If every step goes the way that raises reward fastest (the gradient), it is sure to reach at least a peak, though maybe not the highest (a local optimum). Learning a policy this way is called policy gradient.

2. **Huge sets of moves.** The main one. A scoring bot must find the best of all its moves at every step (the max). That is hopeless with a trillion moves, or with a robot whose moves are continuous turning forces (torques). A policy never runs that search. It shifts its odds a little at a time.

3. **Randomness on purpose.** A policy can be random by design, which Silver calls stochastic.

The cost: plain policy gradient is slower and noisier than learning scores.

Epsilon-greedy is random sometimes too. The game asks where its randomness goes.

> **Alt+Tab · game 7 · stop 3 of 8: Find where the random picks go**
>
> **What he just said:** Why learn a policy directly? Silver gives reasons, and the third is that a policy can be random on purpose. A rule that always takes the best-scored move cannot.
>
> **In the game:** Answer the question with LEFT CLICK, RIGHT CLICK or MELEE.
>
> **Before you press:** Decide where a bot that takes its best hero, plus a random hero one time in ten, spends its randomness.
>
> <details><summary>Back from the game: what you just saw</summary>Lecture 5's rule, epsilon-greedy, sprays its randomness evenly: its best hero 93% of the time and each other hero 3%, whatever they earned. This bot aims its randomness. Each hero's odds come from what that hero did, so a softmax policy is random in the amounts that worked. <em>In an agent:</em> Sampling temperature spreads the model's own learned odds. That is aimed randomness, not a flat chance of a random word.</details>

**On the island:** With only four moves the max is trivial, and PLANNER's fixed route earns 39 every time.

### [14:29](https://www.youtube.com/watch?v=KHZVXao4qXs&t=869s) Rock-paper-scissors, or the Widowmaker on the same perch

Everyone has played against the Widowmaker who takes the same perch every round. By round three the enemy Winston is landing on it before she has scoped in.

A player who always does the same thing can be read, and a player who has been read loses. Silver's example is rock-paper-scissors: scissors beats paper, rock beats scissors, paper beats rock. If he always plays rock, he says, you will soon work out that you should play paper, and he will lose every time.

You do not even need a habit that strong. A lean is enough. Play one option a little more often than the others and an opponent will learn to exploit it.

So the best play is random.

The only policy that cannot be exploited plays each option a third of the time. It is the one point where neither player gains by changing alone, which game theory calls a Nash equilibrium. This is the first of Silver's two cases where a policy has to be random to be the best one. (The counter-pick game beside this page is the same triangle with heroes in it.)

> **Alt+Tab · game 7 · stop 4 of 8: Beat a bot that has a rule**
>
> **What he just said:** In rock-paper-scissors any fixed choice gets exploited. Always throw rock, and anyone who notices throws paper and wins every time.
>
> **In the game:** Answer the question with LEFT CLICK, RIGHT CLICK or MELEE, then read the line that follows about two squares that look alike.
>
> **Before you press:** Decide what beats a bot that must pick by a fixed rule, such as always Pharah, or the three heroes in turn.
>
> <details><summary>Back from the game: what you just saw</summary>Anyone who spots the rule beats it, every round, however clever the rule is. Only odds that are random on purpose cannot be read. Silver's aliased gridworld, two squares that look the same, makes the same point from the other side: one fixed move fails in one of them, and a coin flip gets out. <em>In an agent:</em> A support agent sees the conversation, not the customer's real wishes. Two different customers can look identical to it, like the two grey squares.</details>

> **Alt+Tab · game 7 · stop 5 of 8: Name the mix nobody can beat**
>
> **What he just said:** Rock-paper-scissors has one stable answer: play each option a third of the time. It is the point where neither player gains by changing alone.
>
> **In the game:** Answer the question with LEFT CLICK, RIGHT CLICK or MELEE.
>
> **Before you press:** Commit to the mix of your own picks that no counter-picker can beat on average.
>
> <details><summary>Back from the game: what you just saw</summary>A third each. Against it every counter wins exactly as often as it loses, so even a perfect counter-picker nets zero. Silver calls this the Nash equilibrium, the mix neither player can improve on alone. Here the best policy has to be random.</details>

**On the island:** In the exploratory lecture 10 build, a learning blocker faced a runner who could see which row the blocker stood in, and the blocker spread herself over all four rows (0.36, 0.28, 0.14, 0.21). Four short runs cannot tell a mixed strategy from unfinished learning.

### [15:26](https://www.youtube.com/watch?v=KHZVXao4qXs&t=926s) Two squares that look the same, and a coin that gets you out

Every level of a parking garage looks the same. "Left out of the stairwell" finds your car on one level and a blank wall on the next, and you cannot tell which level you are on.

That is Silver's second case for randomness. His slide: five squares in a corridor, money below the middle one, skulls below the two ends, squares two and four grey.

It happens (15:30) when what you see stops telling you everything that matters: the Markov property fails. The world is only partly observed, or, the same thing, your features (the facts you describe a situation by) hide something.

A student spots the trap (17:49). Both grey squares have walls north and south only, so moving west looks the same from either. They are called aliased. A policy with one fixed move per situation (deterministic) must do the same in both (18:15), and a value function gives them equal values, so greedy goes always west or always east.

Say west. From the right grey square you drop onto the money. From the left you hit the corner, which sends you east, back to grey, west again.

Greedy bounces forever. Epsilon-greedy, for a long time.

The fix (19:15) is a coin flip: in a grey square, east or west with probability 0.5, and you reach the money in a few steps.

<details markdown="1"><summary>The formula, when you want it</summary>

`π_θ(wall to N and S, move E) = 0.5`. In words: when she cannot tell which grey square she is in, a coin flip beats every fixed choice.

At (19:54): "whenever state aliasing occurs, a stochastic policy can do better than a deterministic policy."

His features (16:20) each pair a wall with a move, such as an outside wall to the north while moving east. And (20:02) none of this breaks lecture 2's theorem that every MDP (Markov decision process, the formal model of a problem) has a deterministic optimal policy, because that theorem assumes a perfect description of the state.

</details>

**On the island:** Q, ROW ONLY is told only which row she is in. Her case is milder. Forward is the right move in every edge-row square, but forward and back both seem to lead "to the place she is already in", so she dithers (47.1 steps per episode against 18.6 for full Q-learning; 3 of 10 runs clean at test). The planned hidden-wall build is the island's version of the grey squares: RUNNER BLIND meets two situations that look identical. It has no results yet.

### [20:42](https://www.youtube.com/watch?v=KHZVXao4qXs&t=1242s) Better by which number?

Your career profile can make you look good by a dozen different numbers: win rate, eliminations, damage per 10 minutes. Before you can get better, someone has to say which one counts.

A policy has the same problem. Silver offers three ways to give a whole policy one number to push up, and he calls that number the objective.

1. **Start value.** If every episode begins in the same place, as an Atari game does, score the policy by the total reward it expects to collect from that start.

2. **Average value.** Some tasks never end and have no start. For those, average the value of the states the policy visits, where a state's value is the reward expected from there on. If it might be in a state worth 10 or one worth 20, the objective might be 15.

3. **Average reward per step.** Damage per 10 minutes, more or less.

<details markdown="1"><summary>The formula, when you want it</summary>

`J_1(θ) = V^πθ(s_1)`. In words: a policy's score is the reward it collects on average from the start.

</details>

Then the relief: he does not have to choose.

All three give the same gradient direction, or near enough (the direction in which to change the numbers), so every method that follows serves any of them. (Overwatch stats are less cooperative. Eliminations and win rate can point different ways.)

**On the island:** The objective is the expected return of a crossing. The best is 39; the exact start value under RANDOM WALK is -114.4.

### [26:37](https://www.youtube.com/watch?v=KHZVXao4qXs&t=1597s) The blunt way: nudge one dial, play a few games

You drop your sensitivity a hair, play a few games, and check whether your aim got better. Then you try the next setting. One dial at a time, and every check is noisy, because a few games prove very little.

That is the plainest way to learn which way to turn a policy's numbers. Picture them as dials and the objective, its overall score, as a meter. Turn one dial slightly and watch the meter.

Silver first points out that a policy can be improved with no slope at all, by search methods such as hill climbing or genetic algorithms. Those work. But a method that knows which way is uphill, the gradient, is usually more efficient.

The crudest way to get a gradient is your sensitivity routine: nudge one number, measure the objective again, repeat for every number. This is called finite differences. It works even when nobody knows how to take the policy's slope by calculus (a non-differentiable policy).

<details markdown="1"><summary>The formula, when you want it</summary>

`∂J/∂θ_k ≈ (J(θ + ε u_k) − J(θ)) / ε`. In words: the slope along one dial is how much the score changes when you turn it slightly.

</details>

The catch: a policy with a million numbers needs a million evaluations, each one noisy.

It has worked, though (30:19). RoboCup's AIBO robot dogs walk with a gait set by 12 numbers. Each dog ran up the field a dozen times for every gradient step, and ended with a much faster walk.

**On the island:** Not run on the island. Each step would need many crossings for each of 192 nudged preferences.

### [33:46](https://www.youtube.com/watch?v=KHZVXao4qXs&t=2026s) The score function: how to make that move a little more likely

You try a pick you almost never make, and it wins. Which way should each of the policy's numbers turn so that move comes a little more often? There is an exact recipe.

Silver gets there with a step of calculus called the likelihood-ratio trick, and what comes out is the gradient of the log of the policy, called the score function. It is the same direction that learning from a teacher's examples (maximum-likelihood learning) follows to make an action more likely. And it turns the gradient into an average over the bot's own moves, which the bot can sample by playing.

He works it out twice.

A policy that gives each move a preference, and a probability proportional to e raised to that preference, is called softmax (36:41). Its score is the chosen action's features (the facts that describe it) minus the average features. The push is "this was the move I made" minus "how likely I was to make it". A long shot that worked gets a big push.

For continuous actions (39:25) the policy aims at a mean action and adds noise around it, called Gaussian. Its score is the action minus the mean, times the features, over the variance (the spread of the noise).

Both say "how much more than usual am I doing something" (41:14).

<details markdown="1"><summary>The formula, when you want it</summary>

The trick: multiply and divide the policy's gradient by the policy, and you get the policy times the gradient of the log of the policy.

`∇θ log π_θ(s,a) = φ(s,a) − E_πθ[φ(s,·)]`. In words: for softmax, the features of the move you made, minus the features you would expect on average.

</details>

**On the island:** With a table of preferences the score is simple. The chosen move gets 1 minus its probability, and each other move gets minus its probability.

### [41:45](https://www.youtube.com/watch?v=KHZVXao4qXs&t=2505s) The policy gradient theorem: push each move by how well it went

The score tells you which way makes a move more likely. It does not say how hard to push, or whether to push toward the move or away from it.

Silver starts with the smallest problem there is: see a situation, make one move, get one reward, done. That is a one-step problem, also called a contextual bandit. (The counter-pick game beside this page is the simplest kind: one situation, one pick, one result, round over.)

There, the gradient of the expected reward is the average of the score times the reward. A big win pushes hard toward the move you made. A big loss pushes away from it. No model (no rulebook of the world) is needed: the bot knows its own score and uses the reward it actually got.

Then (46:32) he moves to many steps, and one swap does it. Replace the single reward with the long-run value of the action, the total reward expected after making that move in that place, written Q. The result is the policy gradient theorem.

<details markdown="1"><summary>The formula, when you want it</summary>

`∇θ J(θ) = E_πθ[∇θ log π_θ(s,a) Q^πθ(s,a)]`. In words: make good moves more likely in proportion to how good they are.

</details>

A coach who tells you the right play is supervised learning: you push toward whatever the teacher names.

Here nobody names anything. Every move gets pushed by how good it turned out to be.

**On the island:** Q for stepping off from row 0 is about -101. Q for stepping forward is the number the two bots estimate differently.

### [48:26](https://www.youtube.com/watch?v=KHZVXao4qXs&t=2906s) REINFORCE: judge every play by the final score

Review a match with one rule: if you won, every play was good, and if you lost, every play was bad. The sleep dart that saved a fight takes the blame for a loss. Walking off the map on Ilios takes credit for a win.

Over many matches that evens out. In any one match it is wild.

That is the simplest way to fill in Q, the move's long-run value: nobody hands the bot that number, so it plays the episode out and counts. The total reward from a step to the end is called the return (learning from whole episodes is lecture 4's Monte Carlo way), and the return that actually followed a move stands in for Q. On average the two are equal, so the direction is still right.

Silver calls it Monte Carlo policy gradient, roughly the same as an old algorithm named REINFORCE.

<details markdown="1"><summary>The formula, when you want it</summary>

`Δθ_t = α ∇θ log π_θ(s_t, a_t) v_t`. In words: after the episode, push each move by its score times the reward that followed, times a step size α.

</details>

His example (50:56) is a puck sliding with very little friction toward a target that moves now and then, steered by a small force each step. It learns smoothly, where value-based learning tends to be jagged, but it takes around 100 million iterations. Each update rests on one complete return, and returns differ a great deal between episodes: slow, and high variance (52:28).

The rest of the hour goes after that noise.

> **Alt+Tab · game 7 · stop 6 of 8: Free play against a fresh bot**
>
> **What he just said:** REINFORCE, the simplest policy gradient, waits for the episode to end, then pushes each move it made by the reward that followed, times a step size. Every play gets judged by the final score.
>
> **In the game:** A fresh bot starts at a third each. Play five rounds with LEFT CLICK, RIGHT CLICK or MELEE, and try to leave it no pattern.
>
> **Before you press:** Guess how close to zero you can bring the number that says what a perfect counter-picker would win against your mix.
>
> <details><summary>Back from the game: what you just saw</summary>The left block shows your mix and what a perfect counter-picker would net against it, in wins minus losses per 100 rounds. Five picks cannot split into thirds, so 20 is the best you can do. The bars wander instead of climbing, because no hero keeps winning. Each round is a whole episode, so its reward is the return REINFORCE pushes by. <em>In an agent:</em> Training on whole conversations scored at the end works like this: one reward, pushed back onto every token the agent chose, the good ones and the bad.</details>

**On the island:** POLICY GRADIENT is this method with a per-state baseline (explained two parts below) and step 0.02. A beginner rarely sees the +50. Of the endings she does see, stepping off at once (-101) beats wandering then falling (about -110) or timing out (-150). She fell in 96.5 of every 100 training episodes, and her last-40 return was -101.6.

### [52:54](https://www.youtube.com/watch?v=KHZVXao4qXs&t=3174s) Actor-critic: hire a caster

A caster never touches a mouse. They watch the fight and tell you, right then, whether that play was worth it. Nobody waits for the end screen.

Silver hires one. One ending is a poor judge of one move, because so much chance sits between a move and the final score. So he stops waiting for the ending and trains a second learner to do the judging.

The actor holds the policy and makes the moves. The critic decides nothing. It watches and estimates how good the actor's moves are, by any evaluation method from earlier lectures, and the actor shifts its policy the way the critic points.

<details markdown="1"><summary>The formula, when you want it</summary>

`Δθ = α ∇θ log π_θ(s,a) Q_w(s,a)`. In words: push each move by the critic's opinion of it, not by one noisy ending.

</details>

In his worked version, the Q actor-critic (57:14), the critic is a weighted sum of features (linear) trained by TD(0), the rule that corrects each guess after one step. Nothing waits for the ending, so both update at every step. His Venn diagram (1:01:37) puts actor-critic methods where the two families overlap: they hold both a value and a policy.

The actor plays. The critic judges. Both learn mid-match.

<details markdown="1"><summary>Two questions from students</summary>

In some of these algorithms the step size sets how greedy the learner is: an infinite step (1:04:47) would push one move's probability to one and the others to zero, and small steps keep learning smooth.

On getting stuck at a lower peak, a local optimum (1:05:27): a softmax policy kept as a table and following the gradient is known to reach the global optimum, the highest peak. With neural networks neither family is guaranteed to.

</details>

> **Alt+Tab · game 7 · stop 7 of 8: Quadruple the nudge and watch**
>
> **What he just said:** Silver treats the step size as a dial between smooth learning and greedy jumps. Turn it up and the other odds get driven toward zero.
>
> **In the game:** Answer the question, then play four more rounds with LEFT CLICK, RIGHT CLICK or MELEE. The nudge size is now 2.5 instead of 0.6.
>
> **Before you press:** Commit to what the bars will do once each push is about four times bigger.
>
> <details><summary>Back from the game: what you just saw</summary>One lucky round can now throw a bar most of the way to the top. A single win from even odds lifts a pick to 48% at nudge 0.6 and to 86% at nudge 2.5. Near the top, 1 minus its odds is close to zero, so later rounds barely move it back. One lucky win and the bot is a one-trick. That is the step size Silver warns about. <em>In an agent:</em> A training run with too large a step can lock a model onto one answer that later updates barely move.</details>

**On the island:** ACTOR-CRITIC is the one-step kind, with a TD(0) critic (actor step 0.1, critic 0.2).

### [1:07:03](https://www.youtube.com/watch?v=KHZVXao4qXs&t=4023s) Baselines: was that good, or just normal?

Thirty eliminations sounds like a great game. If you usually get thirty-five on that hero, it was a slightly bad one. A number only means something next to your usual.

Silver's example is starker. One move earns a reward of a million and the next earns 999,000. Both are huge, so both moves get pushed up hard, and the only thing that matters, the gap between them, is buried.

So measure each reward against what is normal. The number you compare against is called a baseline. You may subtract any baseline from the value in the policy gradient, as long as it depends only on the state and not on the move chosen.

The proof is short. In any one state the probabilities of the moves sum to 1, a constant, and the gradient of a constant is 0. So the subtracted term does nothing on average.

The noise falls. The direction holds.

The baseline he picks is how good it is to be in a state in general, the state value V. Subtract it from Q, the value of one move there, and what is left is called the advantage (Silver calls it D, the slides write A): how much better than usual this move is here.

<details markdown="1"><summary>The formula, when you want it</summary>

`∇θ J(θ) = E_πθ[∇θ log π_θ(s,a) A^πθ(s,a)]`. In words: push up moves that beat your usual result from that square.

</details>

> **Alt+Tab · game 7 · stop 8 of 8: Read the debrief**
>
> **What he just said:** Silver subtracts a baseline, the usual result from that situation, from each reward. On average the push keeps its direction, and it gets much less noisy.
>
> **In the game:** Nothing to press. Read the three debrief lines on the left and your prediction score.
>
> **Before you press:** Before reading, name the one number the bot compared every reward against.
>
> <details><summary>Back from the game: what you just saw</summary>The bot compared each reward with its usual reward, a running average that moved a quarter of the way toward each new reward. A win it expected barely moved its odds. A draw when it usually won counted against the pick. That usual reward is the baseline, and reward minus baseline is what Silver calls the advantage. <em>In an agent:</em> A language model draws each word from a softmax, temperature sets how spread the odds are, and training pushes up answers that beat the average of several tries.</details>

**On the island:** POLICY GRADIENT had this baseline. Stepping off really was better than her usual ending, so it still got pushed up.

### [1:13:06](https://www.youtube.com/watch?v=KHZVXao4qXs&t=4386s) The TD error: one step of surprise is the verdict

Your team is up on the point and you feel like you are winning. You dive in alone, you die, the fight falls apart behind you, and now you feel like you are losing. You do not need the end screen to know the dive was bad.

That is Silver's picture for this part. The size of your change of mind is the TD error from lecture 4: the reward you just got, plus your guess for where you landed (shrunk a little by the discount γ), minus your guess for where you stood.

<details markdown="1"><summary>The formula, when you want it</summary>

`δ = r + γ V_v(s') − V_v(s)`. In words: the surprise after one step is the verdict on the move just made.

</details>

Here is why it is the right verdict. If those guesses were the true state values V, the average TD error after a given move in a given state would be exactly Q minus V, the advantage from the last part. At (1:14:47): "the TD error is an unbiased sample of the advantage function."

Unbiased means right on average. Any one sample can be off.

So the critic only has to learn V, the value of each state, not a separate score for every move. Silver calls this probably the most commonly used form of actor-critic. (In practice the critic's V is itself an estimate, so the update is a good approximation to the true gradient, no longer an exact one.)

**On the island:** This is ACTOR-CRITIC. Her critic's guess for a square she has not visited starts at zero, far above -101, so forward kept looking better than the edge: 7.1 falls per 100.

### [1:17:14](https://www.youtube.com/watch?v=KHZVXao4qXs&t=4634s) A fading memory, so the blame reaches back

You lose a fight. The last thing you pressed gets some of the blame, but so does the cooldown you burned ten seconds earlier, a bit less. What you did a minute ago gets almost none.

That is the device this part gives the actor, the same one lecture 4 gave the learner of values. A surprise now may be the fault of a move several steps back.

Silver sets out the two extremes. Judge a move by the full return (everything collected to the end of the episode) minus a baseline: right on average (unbiased) but noisy. Or judge it by the one-step TD target, the reward plus the critic's guess for the next state: less noise, some bias, because it leans on the critic's own estimates, which is called bootstrapping.

The mix is a running record of the scores of recent moves that fades as they recede, called an eligibility trace. It is lecture 4's TD(λ) in its backward view, with one swap: wherever the value method used the gradient of the value, the actor uses the score.

<details markdown="1"><summary>The formula, when you want it</summary>

`e_{t+1} = λ e_t + ∇θ log π_θ(s,a)`, `Δθ = α δ e`. In words: keep a fading memory of recent pushes and apply each surprise to all of them.

</details>

Unlike REINFORCE, this runs online: the actor updates at every step and never needs the end.

**On the island:** Not run on the island for an actor. SARSA LAMBDA uses traces for values only (11.8 falls per 100 against 16.3 for SARSA).

### [1:23:44](https://www.youtube.com/watch?v=KHZVXao4qXs&t=5024s) Trusting the critic, a policy with no dice, and the hour in one line

A caster who loves every dive will teach you to dive too much. The critic is only a guess too, and a wrong guess could bend the gradient and send the actor the wrong way. Silver calls it the first question to ask of any actor-critic method: does the actor still follow the true gradient once an estimate replaces the true value?

It can.

The critic leaves the gradient true if two things hold: the features it is built from are the policy's own score, and its weights minimise squared error. This is called compatible function approximation.

He then adds his group's deterministic policy gradient (1:26:06), not on these slides. A policy that explores by adding noise has to average over its own noise, and that estimate gets worse as the policy narrows in on a good action. So he drops the noise entirely. For continuous actions the critic already says how the value would change if the action were a little higher or lower, and the actor follows that slope.

At (1:30:07): "I'm going to skip the natural actor critic."

The summary (1:30:32) in one line: every method moves the policy toward more value, mostly by the score times some estimate of value. They differ in how the critic makes that estimate and how the actor uses it.

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

Every time a language model writes a token, it does what the bot in the game does. It is a softmax policy, exactly: a preference for every token, the next drawn in proportion to e raised to it. The score for a sampled token is one for the token drawn minus its probability, the island habit table's arithmetic. Silver's main reason fits too: no max over a vast action set.

Take tau-bench (not from the lecture). An agent reads a conversation, calls tools, and is scored at the end on whether a simulated customer's task was done. If you push up the tokens of well-scored conversations, you are running REINFORCE. The average score of several attempts at the same task is a baseline. A model that scores partial conversations is a critic.

So the island's trap has a cousin: an agent that rarely sees success may learn the least-bad ending, such as handing off early. Picture the island's Tracer stepping off the edge with a headset on.

(The analogy breaks in two places. An episode is thousands of token choices, so the noise is far worse. And the agent sees the conversation, not the customer's real wishes: partial observability, with sampling temperature as the grey squares' coin flip.)

## The thread to partial observability

At [15:30] Silver ties aliasing to the loss of the Markov property, and treats "partially observed" and "my features hide something" as one situation. At [20:02] he limits the deterministic-policy theorem to a perfect state description. A policy reading only the current observation can need randomness, which greedy value methods cannot give, since aliased states get one value and so one action. Carry forward two remedies: randomise, the best a memoryless policy can do, or remember (an agent recalling its last move could leave the left grey square without a coin flip; this point is not from the lecture). The planned hidden-wall build sets RUNNER BLIND beside RUNNER REMEMBERS BUMPS, the smallest possible memory.

## Experiments the lecture asks for that the island has not run

- A softmax policy-gradient runner in the hidden-wall blind condition against greedy Q-learning: tests whether randomness beats a fixed habit under aliasing.
- REINFORCE with and without baseline, longer, at several step sizes.
- Actor-critic with a trace on the actor: tests whether credit reaches early moves faster.
- Finite differences on the 192 preferences: the cost of a gradient without the score function.
- A Gaussian policy over a continuous running angle, where policy methods matter most.
