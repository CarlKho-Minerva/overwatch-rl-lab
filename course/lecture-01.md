# Lecture 1: Introduction to Reinforcement Learning

*David Silver's lecture 1 (UCL, 2015), gone through in his order and re-explained with the Tracer experiments on Workshop Island. The lecture and its slides are his: [video](https://www.youtube.com/watch?v=2pWv7GOvuf0), [course page](https://davidstarsilver.wordpress.com/teaching/). The words below are a re-explanation. Every island number comes from the logged runs in this repository.*

Ten Tracers stand at the left end of a strip of 48 squares beside the edge of Workshop Island, and nobody tells them the edge kills. Two never learn: RANDOM WALK picks moves at random all night, and PLANNER is handed the rules and computes her route before her first step. This lecture asks what the setup is made of: what she sees, remembers and tries to maximise. The answer: a loop of observation, action and reward, where the hard part is choosing what to remember.

## The lecture in order

### [09:47](https://www.youtube.com/watch?v=2pWv7GOvuf0&t=587s) Learning from a score, not from an answer key

Silver calls reinforcement learning (RL) the science of decision making, studied as optimal control in engineering and in the brain's dopamine system (06:51). Four things set it apart from other machine learning. There is no supervisor, only a reward saying a move was worth three points or minus ten. Feedback can arrive late. Data come as a correlated sequence, not independent samples. And the agent's actions decide what data it sees next (11:39).

**On the island:** Nobody shows Tracer the right move; she only gets -1, +50, -100 or -50. Her data depend on her choices: RANDOM WALK reached the goal in 1.0% of her 2,308 episodes, so she saw almost only falls.

### [23:00](https://www.youtube.com/watch?v=2pWv7GOvuf0&t=1380s) The reward hypothesis: every goal is a total to maximise

A reward is a single number per step saying how well the agent is doing; the agent's job is to make the total large. The reward hypothesis says all goals can be described as maximising the expected total of future reward. Silver calls it "a little bit controversial" (24:02). "Finish fast" becomes -1 per step (25:19). Because actions have long-term effects, the agent may need to give up reward now for more later, like a helicopter that stops its stunts to refuel (28:33). On conflicting goals, he argues one action forces them onto one scale: "Not everyone has to agree with that." (33:48)

**On the island:** "Cross along the edge quickly without falling" is written as -1 per step, +50 at the goal, -100 for a fall, -50 if 100 steps pass, with discount 1. The return (an episode's total reward) is at best 39; stepping straight off gives -101. Giving up reward for safety is visible: SARSA kept 3.88 m from the edge in her last 40 episodes against 2.07 m for Q-LEARNING, and took 25.1 steps per episode against 18.6.

### [29:35](https://www.youtube.com/watch?v=2pWv7GOvuf0&t=1775s) The loop between agent and environment

The agent is the brain we build. Each step it acts, then receives an observation and a reward from the environment, everything on the other side. That stream is the agent's experience and the whole of RL's data.

**On the island:** The agent is one Tracer with her table and method. The environment is the game plus the Workshop script. Actions are forward, back, inland and toward the edge, each one real run to the next square; the observation is her square, read from her real position.

### [33:53](https://www.youtube.com/watch?v=2pWv7GOvuf0&t=2033s) History, and state as a summary of it

The history is everything observed so far: `H_t = O_1, R_1, A_1, ..., A_(t-1), O_t, R_t`. In words: the ordered record of what the agent saw, got and did up to now. It is enormous (35:56), so we use a state instead, formally any function of the history (36:41): `S_t = f(H_t)`. In words: the state is whatever summary you choose to compute from the record. The Atari agent kept the last four screens (37:00).

**On the island:** One episode's history is its list of squares, moves and rewards. Every bot uses the same summary, her current square (one of 48), except two bots given coarser ones on purpose.

### [37:13](https://www.youtube.com/watch?v=2pWv7GOvuf0&t=2233s) Environment state versus agent state

The environment state is the environment's private numbers that decide the next observation and reward. It is usually hidden, and often irrelevant: a robot here does not need the atomic layout of Ayers Rock (38:39). The agent state is what our algorithm keeps and uses to pick the next action, and choosing it is our decision (41:03). Other agents count as part of the environment (39:48).

**On the island:** The environment state is the game's memory: Tracer's exact position and speed, the step count, the other nine bots. The agent state is her square. In the two-player build the blocker is simply part of the runner's environment.

### [42:04](https://www.youtube.com/watch?v=2pWv7GOvuf0&t=2524s) The Markov property: when the past can be thrown away

An information state, or Markov state, holds everything useful in the history. A state is Markov if `P[S_(t+1) | S_t] = P[S_(t+1) | S_1, ..., S_t]`. In words: the whole past tells you nothing more about the next state than the present does. Silver's phrase: "the future is independent of the past given the present" (43:11). For a helicopter (45:13), position, velocity, angle and wind are roughly Markov; position alone is not, since you would need the past to recover speed (46:00). The environment state and the full history are always Markov (47:02); the task is finding a useful one.

**On the island:** Her square is nearly Markov: a step missed its aimed square only 0.21 times per 1,000. But the -50 after 100 steps depends on the step count, which the square does not hold. Knowing only her square, she cannot tell step 5 from step 99.

### [47:57](https://www.youtube.com/watch?v=2pWv7GOvuf0&t=2877s) The rat: what you predict depends on the state you chose

The class plays a rat. Episode one: light, light, lever, bell, shock. Episode two: bell, light, lever, lever, cheese. Episode three: lever, light, lever, bell, and the class must predict the ending. A rat whose state is the last three items expects the shock. A rat counting lights, bells and levers expects cheese. A rat keeping the whole sequence cannot say. As Silver puts it, "the state representation really defines what happens next" (50:55).

**On the island:** Q, ROW ONLY is a rat with a bad summary. Told only her row, she learned the edge at once but could not tell forward from back, and dithered for 47.1 steps per episode against 18.6 for full Q-LEARNING.

### [51:14](https://www.youtube.com/watch?v=2pWv7GOvuf0&t=3074s) Full observability: the Markov decision process

When the agent sees the environment state directly, `O_t = S^a_t = S^e_t`. In words: what she observes, what she keeps and the environment's own state are one thing. This is a Markov decision process (MDP), the subject of lecture 2 and most of the course. Many real problems are not like this, he warns (52:09).

**On the island:** The main strip is treated as an MDP, with her square as the state.

### [52:23](https://www.youtube.com/watch?v=2pWv7GOvuf0&t=3143s) Partial observability, and three ways to build your own state

Here the agent sees the world indirectly: a camera robot without GPS must work out where it is, a trading agent sees only prices, a poker agent sees only the public cards (52:36 to 53:12). The hidden part "may as well not exist" as far as the agent's brain is concerned (53:28). This is a partially observable MDP, a POMDP (53:36), and the agent must build its own state. Silver gives three ways.

1. The complete history (53:49): `S^a_t = H_t`. In words: remember everything and treat the record itself as the state.
2. A belief (53:59): `S^a_t = (P[S^e_t = s^1], ..., P[S^e_t = s^n])`. In words: keep one probability for each state the environment might be in, the Bayesian route.
3. A recurrent neural network (54:38): `S^a_t = sigma(S^a_(t-1) W_s + O_t W_o)`. In words: mix the old agent state with the new observation through learned weights, then squash the result; no probabilities needed.

He closes with Atari (56:32): the environment state is the console's 1,024 bits, which the agent never sees, and its own state was the last four frames.

**On the island:** In the two-player build, a runner not told the blocker's row faced a partially observable problem, by the fact sheet's own description. The hidden-wall build, planned and being run now, puts all three ideas on the strip: RUNNER BLIND, RUNNER REMEMBERS BUMPS (the smallest possible belief, built from what happened to her) and RUNNER SEES THE WALL. It has no results yet.

### [57:06](https://www.youtube.com/watch?v=2pWv7GOvuf0&t=3426s) What can be inside an agent: policy, value function, model

An agent may contain one or more of three things; the list is not exhaustive. A policy is its behaviour, deterministic `a = pi(s)` or stochastic `pi(a|s) = P[A_t = a | S_t = s]`. In words: a move for each state, or a probability for each move in each state. A value function predicts future reward under a policy: `v_pi(s) = E_pi[R_(t+1) + gamma R_(t+2) + gamma^2 R_(t+3) + ... | S_t = s]`. In words: the reward you expect to collect from here on if you keep behaving this way, later rewards shrunk by the discount gamma. In Space Invaders the value climbs when the mothership appears and drops after it is shot, since value counts only reward still to come (gamma about 0.99, 1:05:09). A model predicts the environment: `P^a_ss' = P[S_(t+1) = s' | S_t = s, A_t = a]` and `R^a_s = E[R_(t+1) | S_t = s, A_t = a]`. In words: where each move probably leads, and what it pays at once. Of a learned maze map: "It's not reality, it's just the agent's model of reality." (1:10:45)

**On the island:** RANDOM WALK's policy is stochastic, four moves with equal chance. Her exact value is -114.4 at the start square and -135.5 at the far inland corner. PLANNER holds the grid's written rules as her model; DYNA-Q learns a table model from her own steps.

### [1:10:51](https://www.youtube.com/watch?v=2pWv7GOvuf0&t=4251s) Sorting agents by what they keep

Value-based agents keep a value function and pick the best-valued move. Policy-based agents keep only a policy and adjust it directly. Actor-critic agents keep both. Separately, model-free agents go straight from experience to policy or value, while model-based agents build a model and plan with it (1:15:02). The maze (1:08:03) shows all three: arrows (policy), numbers from -1 to -24 (value), a partial map (model).

**On the island:** SARSA and Q-LEARNING are value-based and model-free, POLICY GRADIENT is policy-based, ACTOR-CRITIC is both, and DYNA-Q and PLANNER are model-based.

### [1:16:11](https://www.youtube.com/watch?v=2pWv7GOvuf0&t=4571s) Learning versus planning

Silver calls this maybe the most important distinction. In reinforcement learning the environment is unknown and the agent improves by interacting with it. In planning (1:17:24) the model is given and the agent improves by computing with it, with no outside interaction. Atari makes the contrast: learn from pixels and score, or search ahead with a perfect emulator.

**On the island:** PLANNER plans: value iteration on the grid's rules, settled in 13 sweeps, then a greedy walk. She never fell.

### [1:20:44](https://www.youtube.com/watch?v=2pWv7GOvuf0&t=4844s) Exploring versus exploiting, predicting versus controlling

Exploration gives up reward you know about to find out more; exploitation uses what you know. His examples: a favourite or a new restaurant, the best advert or a new one. Prediction (1:24:37) asks how well a given policy will do; control asks for the best policy, and you usually solve prediction to solve control (1:25:02). In his gridworld the best square is worth 8.8 under random moves and more than 24 under the best policy.

**On the island:** Most learners explore with epsilon 0.1, a random move one step in ten. The value tables following RANDOM WALK do prediction; SARSA and the rest do control.

## What the island measured for this lecture

The pairing is the setup itself, with RANDOM WALK as the floor (no learning) and PLANNER as the ceiling (knows the rules).

| Bot | Runs | Falls per 100 (95% interval) | Return, first 40 | Return, last 40 | First goal (median episode) | Runs never reaching goal | Steps per episode |
|---|---|---|---|---|---|---|---|
| RANDOM WALK | 11 | 97.4 (96.9 to 97.9) | -111.3 | -113.3 | 37 | 2 | 14.9 |
| PLANNER | 10 | 0.0 (0.0 to 0.0) | 39.0 | 39.0 | 1 | 0 | 11.0 |

Over 2,308 episodes RANDOM WALK averaged -112.7 (standard error 0.46). The exact start-square value, solved with the time limit ignored, is -114.4; their closeness is a sanity check, not a test. PLANNER settled in 13 sweeps, good news moving back one column per sweep, and her 39.0 is the best possible return. Neither bot was in a planned comparison; the only planned comparison was SARSA against Q-LEARNING on falls. These numbers mark the range a learner lives in. They do not show how hard the task is to learn, and PLANNER's record holds only because her rules match the game.

## Guess first

<details><summary>The strip's state is her square. Markov, yes or no?</summary>
Almost, not quite. A step missed its aimed square only 0.21 times per 1,000, so the square nearly fixes the next one. But the -50 after 100 steps depends on the step count, which the square lacks. It is Silver's helicopter with position but no velocity, in a mild form.
</details>

<details><summary>Under RANDOM WALK's policy, which is worth more: the start beside the edge, or the far inland corner?</summary>
The start, at -114.4, against -135.5 for the corner. From the corner she wanders longer, paying -1 a step, and still usually falls.
</details>

<details><summary>Q, ROW ONLY knows her row, not her column. More or fewer falls than full Q-LEARNING, and faster or slower crossings?</summary>
Worse on both: 42.5 falls per 100 against 26.5, and 47.1 steps per episode against 18.6. Forward and back look identical to her, so she dithers along the edge.
</details>

<details><summary>In the third rat episode, what does a rat whose state is "counts of lights, bells and levers" predict?</summary>
Cheese. Two levers, one light and one bell match episode two, which ended in cheese. A rat using the last three items predicts the shock. Same history, different state, different prediction.
</details>

<details><summary>The full history is always a Markov state. Why not just use it?</summary>
It grows without limit and never repeats, so nothing learned in one history carries to another. The environment state is also Markov, but usually hidden.
</details>

<details><summary>PLANNER never fell in 10 runs. Is she doing reinforcement learning?</summary>
No, she is planning: given the model, she computed values without trial and error, then walked. Her record shows what the rules allow, not what a bot can learn.
</details>

## Cards

- Q: Four ways RL differs from supervised learning? | A: No supervisor, only reward; delayed feedback; sequential, correlated data; actions change the data received.
- Q: The reward hypothesis? | A: Every goal can be described as maximising the expected total of future reward.
- Q: What is the history? | A: The ordered record of all observations, actions and rewards up to now.
- Q: Formal definition of state? | A: Any function of the history, S_t = f(H_t).
- Q: When is a state Markov? | A: When the next state's distribution given it equals that given the whole past.
- Q: Three ways to build agent state in a POMDP? | A: Keep the complete history, keep a belief over environment states, or run a recurrent neural network.
- Q: Value-based, policy-based, actor-critic? | A: Keeps a value function only; keeps a policy only; keeps both.
- Q: Learning versus planning? | A: Learning: environment unknown, improve by interacting. Planning: model given, improve by computing.

## In language-model terms

Take tau-bench (not from the lecture: a benchmark where a model serves a simulated customer through tools such as an airline database, checked at the end). The agent is the model plus its harness. The environment is the simulated customer, the database and the tools. Actions are replies and tool calls; observations are the customer's messages and tool outputs. The reward is the end-of-episode check, so feedback is delayed exactly as Silver describes. This mapping is exact.

The history is the transcript, also exact. The agent state is whatever the harness shows the model each turn: the full transcript, a truncated window or a summary, each a function of the history. The customer's hidden instructions and the database contents are environment state the model cannot see, so the task is a POMDP. What the model infers about the customer's goal works like a belief, but only by analogy; it is never an explicit list of probabilities.

The mapping breaks in two places. During a benchmark run the weights do not change, so nothing is learned inside an episode; RL happens only if the scores are later used for training. And one pass or fail number compresses several goals, the reward hypothesis Silver called controversial.

## The thread to partial observability

Silver makes the history the only thing an agent ever has, defines state as a function of it, and uses the Markov property as the test of a good summary. He splits the fully observed case (the MDP, most of the course) from the partially observed one (the POMDP), and names three ways to build an agent state: the whole history, a belief, a recurrent network. Carry three things forward. A non-Markov state makes a bot treat two situations as one, as Q, ROW ONLY did. Memory is how an agent recovers what it cannot see; RUNNER REMEMBERS BUMPS in the hidden-wall build is the smallest belief there is. And the rat shows that choosing the summary is part of the problem, not a preprocessing step.

## Experiments the lecture asks for that the island has not run

- Add steps remaining to the state: tests whether the missing step count breaks the Markov property in practice.
- Give a bot her last three squares instead of her current one: the rat's "last three items" state.
- Remove the -1 per step: shows whether routes lengthen once speed leaves the reward.
- Hand PLANNER a wrong model (drop one row inland) and let her walk: a model that is not reality.
- Run Q-LEARNING with discount 0.9: the horizon idea from 1:05:09.
