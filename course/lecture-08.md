# Lecture 8: Integrating Learning and Planning

*David Silver's lecture 8 (UCL, 2015), gone through in his order and re-explained with the Tracer experiments on Workshop Island. The lecture and its slides are his: [video](https://www.youtube.com/watch?v=ItMutbeOHtc), [course page](https://davidstarsilver.wordpress.com/teaching/). The words below are a re-explanation. Every island number comes from the logged runs in this repository.*

The game cannot run faster than real time, so every real step costs Tracer about a quarter of a second. Q-LEARNING learns only from steps she really takes; DYNA-Q also keeps a table of what each move did and replays 20 imagined moves from it after every real one. Silver's eighth lecture asks how much more an agent can learn per real step by building its own copy of the world and practising inside it. His answer: learn a model from real experience, then plan by running your usual learning method on experience sampled from that model, as long as thinking time allows.

## The lecture in order

### [02:40](https://www.youtube.com/watch?v=ItMutbeOHtc&t=160s) This time the agent learns a model of the world
Until now the agent learned a policy (its rule for choosing a move) or a value function (its estimate of reward to come) straight from experience. Here it learns a model: how one state leads to the next, and what each move pays. With it she can take imagined steps in a cartoon copy of the world. The loop: experience builds the model, the model is used to plan, planning gives values, values choose the next real action.
**On the island:** the model is a table of landing square and reward for each square and move. DYNA-Q builds one as she walks; PLANNER was handed the true rules.

### [11:43](https://www.youtube.com/watch?v=ItMutbeOHtc&t=703s) Why build one: sometimes the rules are simpler than the values
In chess, moving one piece one square can turn a won position into a lost one, so values are hard to learn directly, while the model is just the simple rules. A model is learned by supervised learning (learning from examples with the answer attached), since every step shows where that move led, and it lets the agent reason about what it does not know. The cost: two sources of error, an approximate model and then approximate values computed from it.
**On the island:** the rules fit in one line, while the values took PLANNER 13 sweeps to settle, good news travelling back one column per sweep.

### [15:54](https://www.youtube.com/watch?v=ItMutbeOHtc&t=954s) A model predicts the next state and the reward
The model is the agent's version of the MDP (Markov decision process: states, actions, transition probabilities, rewards), with parameters eta. States and actions are assumed known, so it estimates `S' ~ P_eta(S' | S, A)` and `R = R_eta(R | S, A)`. In words: given where you are and what you did, predict where you land and what you are paid. The reward part is regression (fit a number). The next-state part is density estimation (fit a spread of outcomes, as for a helicopter the wind pushes left 30% of the time and right 70%).
**On the island:** each real step is one example, (square, move) in, (reward, next square) out. A step misses its square only 0.21 times per 1,000 steps, so the spread is nearly a single point.

### [27:54](https://www.youtube.com/watch?v=ItMutbeOHtc&t=1674s) The table lookup model is counting, shown on the AB example
The simplest model counts: `P_hat(s' | s, a) = N(s, a, s') / N(s, a)`. In words: the chance of landing in s' is the share of past tries from s with a that landed there. The reward estimate is the average reward seen. Storing every experience tuple and sampling a matching one is equivalent. On the AB example from lecture 4 (A, 0, B, 0 once; B, 1 six times; B, 0 once), counting gives: A always leads to B with reward 0, and B pays 1 six times in eight.
**On the island:** DYNA-Q's model is a table over 48 squares and 4 moves. the island fact sheet does not say whether it keeps counts or tuples; with slips this rare they agree.

### [33:17](https://www.youtube.com/watch?v=ItMutbeOHtc&t=1997s) Sample-based planning: treat the model as if it were the world
Planning means solving the learned MDP, for example by value iteration. Silver prefers using the model only to generate samples, then applying a model-free method (Monte Carlo, Sarsa, Q-learning) to them. Sampling spends effort on likely outcomes, which breaks the curse of dimensionality (work exploding with the number of states). Eight episodes sampled from the AB model give V(A) = 1 and V(B) = 0.75. On splitting time between acting and thinking: act at the world's rate, and "You plan at whatever rate you can think at."
**On the island:** this is the principled answer to the speed question. The clock cannot be sped up, so DYNA-Q gets more learning per real step: 20 imagined updates per real one.

### [44:23](https://www.youtube.com/watch?v=ItMutbeOHtc&t=2663s) A wrong model gives a confident wrong answer
Even perfect planning only finds the best policy for the model: "model-based RL is only as good as the model that we've learned." Remedies: fall back on model-free learning, or reason explicitly about model uncertainty (the Bayesian approach, left to bonus slides).
**On the island:** the model is nearly exact, so this is hard to provoke. The hidden-wall build being run now, with a square shut at random each episode, is a world a square-only table cannot model; no results yet.

### [51:18](https://www.youtube.com/watch?v=ItMutbeOHtc&t=3078s) Dyna and Dyna-Q: learn from real and imagined steps together
Sutton's Dyna learns the model from real experience and the values from both real and simulated experience. Dyna-Q (54:01), after each real step, does a Q-learning update, `Q(S, A) <- Q(S, A) + alpha (R + gamma max_a' Q(S', a') - Q(S, A))`, then a model update, then n more updates on (state, action) pairs seen before, with the model supplying the outcome. In words: nudge a move's value toward its reward plus the best value where it leads, once for real and n times in imagination. In Sutton's maze, n = 0 needs about 30 episodes; n = 5 is near the best path of about 14 steps after a couple. Before the first goal there is little signal, so the first episode barely differs (1:00:59).
**On the island:** DYNA-Q uses n = 20. Her first-40 mean return was -31.7 against Q-LEARNING's -57.6, yet both had a median first goal at episode 13: a model cannot replay a +50 it has never seen.

### [1:01:09](https://www.youtube.com/watch?v=ItMutbeOHtc&t=3669s) When the maze changes, planning does not replace exploring
Silver moves the gap in the maze wall partway through. If the known path is blocked, the model still says it works, planning keeps sending the agent there, and performance flatlines until exploration finds the new gap. Dyna-Q+ adds a bonus for pairs untried for a long time, so it recovers sooner. If a shortcut opens instead, plain Dyna-Q never notices; Dyna-Q+ revisits stale places and finds it.
**On the island:** Not run on the island. The experiment would shut an edge-row square mid-run and compare DYNA-Q with a DYNA-Q+ bot.

### [1:04:33](https://www.youtube.com/watch?v=ItMutbeOHtc&t=3873s) Forward search: only the situation you are in now matters
A climber needs the next handhold, not tomorrow's lunch. Forward search builds a tree rooted at the current state; "Solving the whole MDP is a big waste of resource." Simulation-based search does this by sampling whole episodes from now. Simple Monte Carlo search runs K episodes per root action under a fixed simulation policy and scores `Q(s_t, a) = (1/K) * sum of the K returns`. In words: try each first move many times in imagination and pick the one whose imagined games went best on average.
**On the island:** Not run on the island. PLANNER solved the whole grid before moving, the opposite approach.

### [1:13:49](https://www.youtube.com/watch?v=ItMutbeOHtc&t=4429s) Monte Carlo tree search improves its own simulations
MCTS stores, at every state and action its simulations pass through, their mean return. Inside the tree, a tree policy picks the best-valued move (with some exploration) and improves as values improve; beyond the tree, a fixed default policy, often random, plays to the end. This is Monte Carlo control on simulated episodes from now, so it converges on the best search tree. Asked whether one random rollout is a poor guide, Silver says the tree grows over it, and "uniform random isn't as dumb as you might think."
**On the island:** Not run on the island. Under the random policy the start square is worth -114.4, worse than the -101 of stepping off: the trap that sent MONTE CARLO over the edge.

### [1:18:52](https://www.youtube.com/watch?v=ItMutbeOHtc&t=4732s) Go: where search by simulation won
In Go, chess-style brute-force search got nowhere. Reward is 0 until the end, then 1 if Black wins, so `v(s) = P[Black wins | S = s]`. In words: a position's value is the chance Black wins from it. Four random games from a position, two won, give 0.5; the tree fills with win counts (1 of 1, 1 of 2, 2 of 3) as promising branches deepen. Programs jumped once MoGo and CrazyStone brought Monte Carlo search, reaching about six dan by his account. It is best-first, needs only a black-box model, and can stop any time.
**On the island:** Not run on the island. The lecture 10 two-player build has a blocker, but its runner is Q-learning, not a search.

### [1:30:57](https://www.youtube.com/watch?v=ItMutbeOHtc&t=5457s) TD search: bootstrap inside the search
TD search runs the same simulations from now but updates by Sarsa at each step: `delta Q(S, A) = alpha (R + gamma Q(S', A') - Q(S, A))`. In words: move a move's value toward its reward plus the value of the next move chosen, without waiting for the imagined game to end. Bootstrapping lowers variance, raises bias, and is usually more efficient, most of all where many paths reach the same state.
**On the island:** Not run on the island. The strip has many paths to each square; the experiment would pit TD search against MCTS from the start square.

### [1:35:08](https://www.youtube.com/watch?v=ItMutbeOHtc&t=5708s) Dyna-2: long-term and short-term memory
Dyna-2 keeps two sets of weights: long-term, learned from real experience by TD (general knowledge), and short-term, learned by TD search from now (this situation only, the loose rock under this handhold). Their sum is the value. Against MoGo, TD on real Go games won about 5%; the same updates on simulations from the current position beat MCTS after about a thousand steps of computation; Dyna-2 did best.
**On the island:** Not run on the island. Every bot's Q table is long-term memory only.

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
