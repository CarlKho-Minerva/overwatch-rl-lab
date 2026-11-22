# Lecture 4: Model-Free Prediction

*David Silver's lecture 4 (UCL, 2015), gone through in his order and re-explained with the Tracer experiments on Workshop Island. The lecture and its slides are his: [video](https://www.youtube.com/watch?v=PnHCvfgC_ZA), [course page](https://davidstarsilver.wordpress.com/teaching/). The words below are a re-explanation. Every island number comes from the logged runs in this repository.*

The RANDOM WALK bot wanders the strip at random and nearly always falls, and three tables of 48 numbers follow her without knowing the island's rules. Each must work out, from her steps alone, how good each square is for a walker like her. The lecture asks how: wait for the episode to end and average what happened (Monte Carlo), or correct each guess after every step using the next guess (temporal-difference learning). Both reach the true values, paying in noise or in bias from their own guesses, and one dial, lambda, runs between them.

## The lecture in order

### [04:29](https://www.youtube.com/watch?v=PnHCvfgC_ZA&t=269s) No one hands you the rules, and first you only measure
Silver starts from a factory whose equations nobody can write down. Lecture 3 solved a known Markov decision process (MDP, the formal map of states, moves, rewards and odds); now the agent gets only experience. Prediction means estimating the value function (expected total future reward from each state) for a given policy; control, finding the best policy, is lecture 5.
**On the island:** The policy, her rule for choosing a move, is fixed: RANDOM WALK picks each of four moves with equal chance. Prediction fills in, for each square, the total score she will collect from there. PLANNER did this in lecture 3 by reading the rules; the tables only watch.

### [05:17](https://www.youtube.com/watch?v=PnHCvfgC_ZA&t=317s) Monte Carlo: the value is the average of what happened
Monte Carlo learning plays whole episodes and averages the returns (the total reward from a moment to the end). One episode returns 5, the next 7, so the start is worth 6. No model is needed, but episodes must end. `v(s) = E[G_t | S_t = s]`, estimated by the mean of the observed G_t.
In words: a state's value is the average return after standing in it, and Monte Carlo uses the average of the samples it has.
**On the island:** Episodes always end. Over 2,308 random-walk episodes the mean return was -112.7 (standard error 0.46); the exact start value, which ignores the time limit, is -114.4.

### [09:00](https://www.youtube.com/watch?v=PnHCvfgC_ZA&t=540s) First visit or every visit, and why rare states stay noisy
If an episode returns to a state, first-visit Monte Carlo counts only the return after the first visit; every-visit counts one per visit. Both converge by the law of large numbers, and each state's error shrinks with its own visit count, whatever the size of the state space. In his blackjack example (200 states, stick only on 20 or 21) the usable-ace states are still noisy after 10,000 hands because they are rarer; it takes about 500,000. Nobody told the agent the deck or the dealer's rule.
**On the island:** The table is every-visit, and revisits are common because walking into a side wall leaves her in place. Far inland squares are rarely reached before she falls; the error score weights squares by visits, so they count less. First-visit was not run.

### [26:21](https://www.youtube.com/watch?v=PnHCvfgC_ZA&t=1581s) The incremental mean, and forgetting on purpose
A mean can be updated one sample at a time: `mu_k = mu_(k-1) + (1/k)(x_k - mu_(k-1))`.
In words: the new average is the old one moved toward the new sample by a fraction of the surprise.
Nearly every algorithm in the lecture has this shape. With a constant step alpha instead of 1/k, `V(S_t) <- V(S_t) + alpha (G_t - V(S_t))`, old episodes fade.
In words: move the value a fixed fraction of the way toward the latest return.
He prefers this because once the policy improves, the thing measured keeps changing.
**On the island:** The MONTE CARLO control bot uses a constant step of 0.2. The Monte Carlo value table that follows RANDOM WALK uses the plain running average: a step of 1/k on the k-th visit to a square, every visit counted.

### [34:11](https://www.youtube.com/watch?v=PnHCvfgC_ZA&t=2051s) Temporal difference: update a guess toward a guess
TD learning works from incomplete episodes. TD(0) takes one real step and replaces the rest of the return with its own estimate of where it landed; using your own estimate in the target is bootstrapping. `V(S_t) <- V(S_t) + alpha (R_(t+1) + gamma V(S_(t+1)) - V(S_t))`.
In words: nudge the value of where you were toward the reward you just got plus your current guess for where you are now.
R + gamma V(next) is the TD target; its gap from the old value is the TD error. His case is the near crash: a car swerves at you and misses, and TD lowers the value of the moment before at once. "You don't need to wait until you die to update your value function."
**On the island:** Two TD(0) tables, steps 0.1 and 0.5, discount (gamma) 1. From square A to B, the target is -1 plus the table's number for B; off the edge, it is -101.

### [39:50](https://www.youtube.com/watch?v=PnHCvfgC_ZA&t=2390s) Driving home: two ways to revise a forecast
From Sutton and Barto: you predict 30 minutes, rain makes it 40, a clear highway 35, a truck 40, and you arrive at 43. Monte Carlo waits and pulls every forecast toward 43. TD moves the 30 toward 40 at the rain, then the 40 toward 35, "updating guess towards a guess" until the arrival grounds the last one. There are no actions: a fixed policy turns an MDP into a Markov reward process.
**On the island:** A random episode lasts 14.9 steps. The TD tables change after each; the Monte Carlo table waits for the end.

### [47:31](https://www.youtube.com/watch?v=PnHCvfgC_ZA&t=2851s) Bias and variance, and who cares about the starting values
TD also learns from unfinished sequences and never-ending tasks. The deeper difference is statistical. The return is an unbiased sample of the value; so is R + gamma times the true next value (lecture 2's Bellman equation). TD's real target uses its estimate V, so it is biased, but its variance (spread) is far lower: one step of randomness, not a whole trajectory. "It's not noisy, it's biased." Monte Carlo: zero bias, high variance, converges even with function approximation, not very sensitive to starting values. TD: some bias, low variance, usually more efficient, converges in a table (a proof he credits to Peter Dayan) but not always with function approximation, and more sensitive to starting values because it feeds off itself.
**On the island:** A random return can be -101 (off at once), about -110 (wander, then fall), -150 (time out), or in 1.0% of episodes a goal: Monte Carlo's variance. The TD tables start at zero; most true values are below -100.

### [53:35](https://www.youtube.com/watch?v=PnHCvfgC_ZA&t=3215s) The random walk: in Silver's example, TD wins
Five states in a row, random left or right, reward 1 only for leaving on the right; true values 1/6 to 5/6. TD(0) from 0.5 everywhere looks right after about 100 episodes. On the error curves (root mean squared error over states), TD with a good step size beats Monte Carlo. A constant step keeps bouncing near the answer; exact convergence needs a shrinking step (the Robbins-Monro conditions).
**On the island:** This is the experiment, and it came out the other way: after 10 episodes, TD 0.1 112.7, TD 0.5 100.5, Monte Carlo 25.9; after 200, 85.6, 46.5, 15.3. The next section says why.

### [58:05](https://www.youtube.com/watch?v=PnHCvfgC_ZA&t=3485s) Batch learning and the AB example: two right answers
Replay eight episodes forever: A then B, rewards 0 and 0; six of B with reward 1; one of B with reward 0. V(B) is 0.75. Monte Carlo says V(A) = 0, the one return seen from A. TD(0) says V(A) = 0.75: it acts as if it had built the most likely model (A always leads to B, reward 0) and solved it, which is certainty equivalence. So TD exploits the Markov property (the current state carries all that matters for the future) and is usually more efficient where it holds; Monte Carlo is often better where it fails.
**On the island:** The game is nearly Markov, with 0.21 slips per 1,000 steps. Batch replay was not run.

### [1:09:11](https://www.youtube.com/watch?v=PnHCvfgC_ZA&t=4151s) Two dials: bootstrapping and sampling
Bootstrapping means the update uses an estimate: TD and dynamic programming do, Monte Carlo does not. Sampling means it uses one drawn outcome instead of an average over all outcomes: Monte Carlo and TD do, dynamic programming does not. Exhaustive search does neither. Asked why the later guess corrects the earlier and not the reverse, he says the reverse gives wrong answers: the step between holds one step of the real world.
**On the island:** PLANNER bootstraps without sampling, the Monte Carlo table samples without bootstrapping, the TD tables do both. PLANNER's good news "travels back one column per sweep"; TD's news travels the same way, but only along steps she really walks.

### [1:15:56](https://www.youtube.com/watch?v=PnHCvfgC_ZA&t=4556s) n-step returns and the lambda return
Take n real rewards, then add the estimate where you land: `G_t^(n) = R_(t+1) + ... + gamma^(n-1) R_(t+n) + gamma^n V(S_(t+n))`.
In words: n steps of real reward plus your guess for the rest.
n = 1 is TD(0); n to the end is Monte Carlo. On a walk of about 21 states the best n was 3 to 5, but it shifted with walk size and update timing. So average all n with geometric weights: `G_t^lambda = (1 - lambda) sum over n of lambda^(n-1) G_t^(n)`.
In words: the one-step return gets weight 1 minus lambda, each longer one lambda times less, and the leftover weight goes to the full return.
Geometric weights are memoryless, so the method costs no more than TD(0). Updating toward this target, the forward view, needs complete episodes; the best lambda moves far less with walk size than the best n.
**On the island:** No prediction table used n-step returns or lambda. SARSA LAMBDA, a control bot, uses lambda 0.8.

### [1:30:42](https://www.youtube.com/watch?v=PnHCvfgC_ZA&t=5442s) Eligibility traces: the backward view
The rat hears a bell three times, a light comes on, and it is shocked. Blame the bell (most frequent) or the light (most recent). An eligibility trace keeps both: `E_t(s) = gamma lambda E_(t-1)(s) + 1(S_t = s)`, then `V(s) <- V(s) + alpha delta_t E_t(s)` for every state.
In words: each state's trace jumps on a visit and fades every step, and each one-step TD error is sent back to states in proportion to their trace.
Lambda 0 is TD(0). With lambda 1 and updates applied at episode end, the total equals Monte Carlo's; offline, backward equals forward for any lambda. Online they differ slightly, unless a 2014 method is used.
**On the island:** SARSA LAMBDA keeps replacing traces (reset to one on a revisit). Against plain SARSA she fell 4.51 fewer times per 100 episodes (95% interval -6.21 to -2.78), an exploratory comparison.

## What the island measured for this lecture

| Typical error against exact values (weighted by visits) | TD(0), step 0.1 | TD(0), step 0.5 | Every-visit Monte Carlo |
|---|---|---|---|
| After 10 episodes | 112.7 | 100.5 | 25.9 |
| After 200 episodes | 85.6 | 46.5 | 15.3 |

All three tables followed the same walker from a start of zero. Monte Carlo was closest at both checkpoints, and the faster TD table beat the slower. the island fact sheet gives no intervals, and this comparison was not planned (the only planned comparison was SARSA against Q-learning on falls), so it is a first look. The likely reason is the start. In Silver's walk the guess of 0.5 is at most a third from the truth; here zero is about 100 points too high for most squares, and TD is the method he calls sensitive to starting values. With discount 1, each square must learn its value from neighbours that also start at zero: the -100 of a fall enters only beside the edge, and each inland square takes only part of a partly learned neighbour per visit, so the bad news crawls inward square by square, as PLANNER's good news moved one column per sweep. A plain Monte Carlo average (the island fact sheet does not give its step) swaps the zero for a real return of about -100 on the first visit. Step 0.5 beating 0.1 fits: the error was mostly starting bias, not noise. This does not show Monte Carlo is better in general, or how they compare once the start is forgotten (the lecture says TD usually wins). The exact values ignore the 100-step limit, so even a perfect table would not score zero.

## Guess first

<details><summary>AB example, replayed forever: does Monte Carlo give V(A) = 0 or 0.75? And TD(0)?</summary>
Monte Carlo gives 0: the one return seen from A was 0. TD(0) gives 0.75: A always went to B with reward 0, and B is worth 0.75. TD answers for the best-fitting model, Monte Carlo for the returns.
</details>

<details><summary>RANDOM WALK's first episode: she steps straight off the edge from the start for -101. What does each table now hold for the start square?</summary>
TD step 0.5: -50.5 (half way from 0 to -101). TD step 0.1: -10.1. A plain Monte Carlo average: -101, its only sample. That is the island result in small: from zero, Monte Carlo jumps to the scale of the truth and TD creeps.
</details>

<details><summary>Lecture 3's PLANNER and the TD(0) table both bootstrap. Which needs her to walk, and what does that mean for the far inland corner?</summary>
TD does. PLANNER averages over all four moves with the known rules, so every square updates every sweep. TD updates only squares she stands on, so a rarely reached corner learns slowly. Bootstrapping is shared; sampling is the difference.
</details>

<details><summary>From lecture 2: is R + gamma times the TRUE next value an unbiased target, and is R + gamma V(next)?</summary>
The first is unbiased: the Bellman expectation equation says the value equals expected reward plus discounted true next value. The second is biased, because V is the current estimate, which could be all zeros.
</details>

<details><summary>True or false: TD(lambda) with lambda 1 is exactly Monte Carlo.</summary>
True only with offline updates, applied at episode end: then the total matches every-visit Monte Carlo. Online, values change mid-episode and the two differ slightly, unless a 2014 variant of the trace is used.
</details>

<details><summary>A bot told only her row cannot tell forward from back. Predicting values with that blurred state, would TD(0) or Monte Carlo cope better?</summary>
Silver says Monte Carlo: it still finds the expected return given what it is told, while TD(0) leans on a Markov property the blurred state breaks. Not run for prediction; Q, ROW ONLY was a control bot, dithering at 47.1 steps per episode.
</details>

## Cards

- Q: What is prediction? | A: Estimating each state's value for a fixed, given policy, without improving it.
- Q: Monte Carlo's target? | A: The actual return from that moment to the end of the episode.
- Q: TD(0)'s target? | A: The reward just received plus the current estimate of the next state's value.
- Q: What is bootstrapping? | A: Updating an estimate toward a target that contains another estimate.
- Q: Which is biased, which is noisy? | A: TD's target is biased, low variance; Monte Carlo's return is unbiased, high variance.
- Q: Batch TD(0) converges to? | A: The values of the most likely model fitted to the data (certainty equivalence).
- Q: Lambda 0 and lambda 1 give? | A: TD(0), and (offline) every-visit Monte Carlo.
- Q: What does an eligibility trace combine? | A: Frequency and recency: it rises on each visit and fades by gamma times lambda per step.

## In language-model terms

A model on a tau-bench task reads the conversation, calls tools against a store's database and talks to a simulated customer; at the end the benchmark checks the database. That is an episode with one reward at the end, like Silver's random walk. Scoring every turn by the final pass or fail is Monte Carlo prediction: unbiased and noisy, since a good tool call in a conversation that failed for another reason gets the failure's score.

The TD version needs a value model that reads a half-finished transcript and predicts the chance of passing; each turn is judged by how that prediction moved across it. The form is exact, and so is the weakness: a badly wrong starting predictor feeds on itself, as the zero tables did. Many policy-gradient setups for language models use a lambda-weighted advantage (not from the lecture), the lambda return under another name.

Where it breaks: Silver's guarantees are for a table and a fixed policy. A conversation is a history, so the value model approximates, where he warns TD may not converge, and the policy is usually training too.

## The thread to partial observability

At [1:04:24] Silver says TD exploits the Markov property, and that when states are aliased (different situations look the same), Monte Carlo can be the better choice. At [1:05:00] he describes the partially observed MDP: a real MDP underneath, of which the agent sees only part, some cards and not others. Monte Carlo still finds the expected return given what it sees, even for "a blind robot"; TD(0) does not work well. So lambda is also a dial for how far to trust the state. The hidden-wall build (planned and running, no results yet) is this case: a blind runner sees one square where there are two situations. Carry forward: bootstrapping assumes the state is complete, and a memory of the episode can turn a blurred observation back into something closer to a state.

## Experiments the lecture asks for that the island has not run

- Start the TD tables at -100: how much of Monte Carlo's lead was the start.
- A shrinking step (1 over visits) for all three: whether TD catches up once the start is forgotten.
- Batch-replay the logged episodes to Monte Carlo and TD(0), against a model built by counting transitions: the AB example at full size.
- n-step and TD(lambda) prediction tables on the same walk: the lecture's large random walk figure.
- Prediction with the row-only view: whether Monte Carlo beats TD(0) on a blurred state ([1:04:24]).
