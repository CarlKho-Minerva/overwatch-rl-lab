# Lecture 1: Introduction to Reinforcement Learning

*David Silver's lecture 1 (UCL, 2015), gone through in his order and re-explained with the Tracer experiments on Workshop Island. The lecture and its slides are his: [video](https://www.youtube.com/watch?v=2pWv7GOvuf0), [course page](https://davidstarsilver.wordpress.com/teaching/). The words below are a re-explanation. Every island number comes from the logged runs in this repository.*

You are Tracer, five white rings stand around you, one line on screen shows a score, and nobody tells you what the score rewards. All night on Workshop Island, ten Tracer bots face their own version of this at the left end of a strip of 48 squares beside the edge, and nobody tells them the edge kills. Two of them never learn: RANDOM WALK picks moves at random all night, and PLANNER is handed the rules and computes her route before her first step. This lecture asks what such a situation is made of, meaning what the learner sees, what she remembers and what she tries to make as large as she can; Silver's answer is a loop of seeing, acting and being scored (observation, action and reward), and the hard part is choosing what to remember.

**Two windows:** this page, and [Game 1: No Coach](../workshop/games/g01.md), an Overwatch custom game for this lecture (paste `workshop/compiled/game-01.txt` into a custom game's settings and start it). The game opens at stop 1 and waits. Read down this page; at each box marked Alt+Tab, switch to the game, do that stop, and switch back. The game never moves on while you read.

## The lecture in order

### [09:47](https://www.youtube.com/watch?v=2pWv7GOvuf0&t=587s) Learning from a score, not from an answer key

A student with an answer key can check each answer against the right one. Silver's subject is learning without the key. You act, a number comes back, and nobody tells you what the right move was. This is called reinforcement learning, RL for short, and he describes it as the science of decision making. Other fields study the same problem under other names: engineers as optimal control, and neuroscientists in the brain's dopamine system (06:51).

He lists four things that set it apart from the rest of machine learning. First, there is no teacher, which he calls a supervisor. There is only a number called the reward, which says a move was worth three points or minus ten. Second, that number can arrive late, many steps after the move that earned it.

Third, the data come as one stream, in order. What the learner sees at one moment looks much like what it sees at the next, so the pieces are not independent of each other. Fourth, the learner's own moves decide what data it sees next (11:39). He calls the learner, the thing that chooses the moves, the agent.

The game starts with the first of the four: what a score can tell you when nobody explains it.

> **Alt+Tab · game 1 · stop 1 of 7: Guess what the number will do**
>
> **What he just said:** Silver says reinforcement learning has no teacher who shows the right move: the learner gets only a number, called the reward, and that number can come long after the move that earned it.
>
> **In the game:** Five white rings stand around you, and the yellow line shows the last reward and the running total. A question floats in front of you. Answer with left click, right click or melee.
>
> **Before you press:** Commit to what the total will do while a round is running and you stand still.
>
> <details><summary>Back from the game: what you just saw</summary>It drops by 1 every second. The score says that time costs something and nothing else: not where to go, not which ring is good. That is reward without a supervisor. A teacher would point; the score only counts. <em>In an agent:</em> An agent graded only on whether its task passed gets the same kind of signal: one number, with no reason attached.</details>

**On the island:** Nobody shows Tracer the right move. She only gets a number: -1, +50, -100 or -50. What she sees depends on what she chooses. RANDOM WALK, who picks every move at random, reached the goal in 1.0% of her 2,308 episodes (an episode is one attempt at the crossing), so she saw almost only falls.

### [23:00](https://www.youtube.com/watch?v=2pWv7GOvuf0&t=1380s) The reward hypothesis: every goal is one total to make as large as you can

A scoreboard only helps if you know what to do with it, and Silver's answer is to add it up. At every step the agent (the learner) receives one number that says how well it is doing at that step. That number is the reward, and the agent's job is to make the total as large as it can.

Underneath is a claim about goals in general: every goal can be described as making the expected total of future reward as large as possible, where expected means averaged over the ways things could turn out. He calls this the reward hypothesis, and he calls it "a little bit controversial" (24:02). A goal like "finish fast" becomes -1 for every step, so the quickest finish scores highest (25:19).

Adding up has a consequence. A move can have effects long afterwards, so the agent sometimes has to give up reward now to get more later, like a helicopter that stops its stunts to refuel (28:33). And when two goals conflict, he argues that the agent still has to pick one action, which forces them onto one scale: "Not everyone has to agree with that." (33:48)

The game now tests whether a goal that nobody states can reach you through the total alone.

> **Alt+Tab · game 1 · stop 2 of 7: Find the ring the score likes**
>
> **What he just said:** Silver's reward hypothesis says any goal can be written as a total to make as large as possible, so 'finish fast' becomes minus one for every step.
>
> **In the game:** Walk with WASD when you are ready; the round's clock starts at your first step. Try the rings. The round ends when one of them pays, or 120 seconds after your first step.
>
> **Before you press:** Before you step, pick the ring you will try first and say how you will know whether it was the right one.
>
> <details><summary>Back from the game: what you just saw</summary>Most rings paid 0, and one paid +50 and ended the round. Your total is 50 minus the seconds you spent, so every wrong ring cost you the walk to it. Nobody told you to hurry; the minus one a second did. That is the reward hypothesis in your hands: a goal, find it and be quick, turned into one number to push up.</details>

**On the island:** The goal "cross along the edge quickly without falling" is written as -1 per step, +50 at the goal, -100 for a fall, and -50 if 100 steps pass. The discount is 1, so a later reward counts the same as one now. The total reward of one episode, called the return, is at best 39, and stepping straight off the edge gives -101. Reward given up for safety is visible: SARSA kept 3.88 m from the edge in her last 40 episodes against 2.07 m for Q-LEARNING, and took 25.1 steps per episode against 18.6.

### [29:35](https://www.youtube.com/watch?v=2pWv7GOvuf0&t=1775s) The loop between the learner and its world: agent and environment

Silver draws the whole problem as two pictures facing each other. One is a brain. It stands for the part we build, the algorithm that decides what to do, and he calls it the agent. The other is a picture of the world. It stands for everything on the other side, and he calls it the environment.

Every step runs the same way. The agent takes an action. The environment answers with two things: a snapshot of what the agent can see at that moment, called an observation, and a reward, the single number from the last part. Then the agent acts again. The agent has no control over the environment except through its actions.

The loop goes on step after step. The stream it produces, of observations, rewards and actions in order, is what he calls the agent's experience. That stream is all the data reinforcement learning has.

> **Alt+Tab · game 1 · stop 3 of 7: Wait for the late bill**
>
> **What he just said:** Silver draws a loop: the learner acts, the world answers with what it now shows and a reward, and that stream of experience is all the data there is.
>
> **In the game:** Round 1 is over, and a question asks whether your total can still change. Answer with left click or right click, then watch the yellow line.
>
> **Before you press:** Commit: is the number on screen now your final total for round 1?
>
> <details><summary>Back from the game: what you just saw</summary>If you touched the billing ring, -20 arrived only now, after the round ended, and nothing says which ring sent it. That is late feedback, and working out which past move earned it is called credit assignment. If no bill came, the billing ring is one you never touched. Either way you acted, read the number and acted again: action, observation, reward, in a loop. <em>In an agent:</em> A coding agent whose tests fail at the end of a long task faces the same puzzle: which of its many edits caused it.</details>

> **Alt+Tab · game 1 · stop 4 of 7: Run round 2 on what you learned**
>
> **What he just said:** In that loop the learner's only way to get better is the experience it has collected, and here round 1 is that experience.
>
> **In the game:** A question asks what your round 2 total will be if you go straight to the ring that paid. Answer, then walk to that ring with WASD; the clock starts at your first step. Both totals then sit side by side on the right.
>
> **Before you press:** Name what still limits your round 2 total, given that the layout has not changed.
>
> <details><summary>Back from the game: what you just saw</summary>Going straight there, you lose only the seconds of one walk, so the total lands a little under +50. The right side shows round 2 minus round 1. That gap is learning from reward: the same map and the same rules, and a better total because of what the score showed you.</details>

**On the island:** The agent is one Tracer together with her table of stored numbers and her learning method. The environment is the game plus the Workshop script. Her actions are forward, back, inland and toward the edge, and each one is a real run to the next square. Her observation is the square she is on, read from her real position.

### [33:53](https://www.youtube.com/watch?v=2pWv7GOvuf0&t=2033s) The full record and the summary you keep: history and state

After an hour of play you could, in principle, write down everything that happened: every screen, every score, every button press. Silver calls that full record the history. `H_t = O_1, R_1, A_1, ..., A_(t-1), O_t, R_t`. In words: the ordered list of what the agent (the learner) saw, was paid and did, from the first step up to now.

What happens next depends on the history, but it is impractical to work from, because it is enormous (35:56). An agent may live a long time, and a single observation (one snapshot of what it sees) may be video.

So the agent works from a summary of the history, which he calls the state. The formal definition is broad: a state is any function of the history, meaning anything you can compute from it (36:41). `S_t = f(H_t)`. In words: the state is whatever summary you choose to compute from the record. Keeping only the latest observation counts. So does keeping the last four screens, which is what his Atari agent did (37:00).

The game's next question is what you act on once the screen stops helping.

> **Alt+Tab · game 1 · stop 5 of 7: Steer by memory with the rings gone**
>
> **What he just said:** Silver calls everything seen, done and scored so far the history, and calls the state whatever summary of it the learner keeps and acts on.
>
> **In the game:** Answer a question about round 3 with left click or right click. Then you are held still for 2 seconds to look before the rings vanish. Answer the next question, then walk with WASD to where the paying ring was.
>
> **Before you press:** Before the rings go, commit to how you will find the paying ring once nothing on screen marks it.
>
> <details><summary>Back from the game: what you just saw</summary>With nothing on screen, you went where your memory said. Your history is every second, ring and bill so far; the one fact you kept from it, that ring over there, is your state. The first question was its price: going straight earns now but teaches nothing about the rings you skipped. That is using what you know instead of trying things.</details>

**On the island:** The history of one episode is its list of squares, moves and rewards. Every bot keeps the same summary of it, the square she is on now (one of 48), except two bots that were given coarser summaries on purpose.

### [37:13](https://www.youtube.com/watch?v=2pWv7GOvuf0&t=2233s) What the world holds and what the learner holds: environment state and agent state

A game holds numbers that never reach your screen. Silver separates two kinds of state (a state is a summary of what has happened so far) by who holds the summary.

The first is held by the world. The environment (everything outside the learner) has internal numbers that decide what the agent sees and is paid next, its next observation and reward. Those numbers are called the environment state. The agent, the learner, usually cannot see them, and many of them would be no use anyway: a robot walking around a room does not need the arrangement of the atoms in Ayers Rock (38:39). Asked about several agents sharing one world, he says each agent can treat the others as part of its environment (39:48).

The second is held by the learner. Whatever our algorithm stores and uses to pick its next action is called the agent state. It can be any function of the history, the full record so far, and what to remember and what to throw away is our decision (41:03). When an algorithm in this course picks an action from a state, this is the state it means.

**On the island:** The environment state is everything the game holds in memory: Tracer's exact position and speed, the step count, the other nine bots. The agent state is only her square. In the two-player build, the blocker is simply part of the runner's environment.

### [42:04](https://www.youtube.com/watch?v=2pWv7GOvuf0&t=2524s) The Markov property: when the past can be thrown away

A good summary is one you could keep acting on after the rest of the record was deleted. Silver gives that idea an exact form. A state (the summary the agent keeps) that holds everything useful in the history, the full record, is called an information state, or a Markov state.

A state is Markov if `P[S_(t+1) | S_t] = P[S_(t+1) | S_1, ..., S_t]`. In words: the whole past tells you nothing more about the next state than the present does. His own phrase is "the future is independent of the past given the present" (43:11). With such a state in hand, the history can be thrown away.

A student asks about a helicopter (45:13). Its position, velocity and angle, how fast it is turning, and the wind are roughly Markov: once you know them, where it was ten minutes ago makes no difference. Position alone is not Markov, because you would have to look back in time to work out its speed (46:00).

Two states are always Markov: the environment state (the world's own internal numbers) and the full history (47:02). So a Markov state always exists, and the task is finding a useful one.

**On the island:** Her square is nearly a Markov state: a step missed the square it aimed for only 0.21 times per 1,000. But the -50 after 100 steps depends on the step count, and the square does not hold that. Knowing only her square, she cannot tell step 5 from step 99.

### [47:57](https://www.youtube.com/watch?v=2pWv7GOvuf0&t=2877s) The rat: what you expect next depends on the summary you kept

Two people can watch the same events and expect different things next, because they kept different notes. Silver shows this by asking the class to be a rat in an experiment that ends in either cheese or an electric shock.

Each run of the experiment is an episode. The first goes light, light, lever, bell, and ends in the shock. The second goes bell, light, lever, lever, and ends in cheese. The third goes lever, light, lever, bell, and the class must predict the ending. Many hands go up for the shock and a few for the cheese.

Each answer follows from a choice of state, the summary the rat keeps. A rat that keeps the last three items has light, lever, bell, the same last three as the first episode, and expects the shock. A rat that keeps counts has one light, one bell and two levers, the same counts as the second episode, and expects cheese. A rat that keeps the whole sequence has not seen this one before and cannot say.

All three rats lived through the same events and differ only in what they kept. As Silver puts it, "the state representation really defines what happens next" (50:55).

**On the island:** Q, ROW ONLY is a rat with a bad summary. She was told only her row. She learned the edge at once, but she could not tell forward from back, and she dithered for 47.1 steps per episode against 18.6 for full Q-LEARNING.

### [51:14](https://www.youtube.com/watch?v=2pWv7GOvuf0&t=3074s) When nothing is hidden: the Markov decision process

The easiest world to learn in is one where nothing is hidden. Silver calls it the nice case. The agent (the learner) gets to look inside the environment, the world it acts in, and see the internal numbers that decide what happens next, the environment state. It uses them as its own state, the summary it acts on.

Three things that were separate then become one. `O_t = S^a_t = S^e_t`. In words: what the agent observes, what it keeps and the environment's own state are one thing. This case is called full observability, and a problem set up this way is called a Markov decision process, MDP for short. It is the subject of lecture 2 and of most of the course.

He warns that many real problems are not like this (52:09), so the ideas about state from the last few parts are still needed.

**On the island:** The main strip is treated as an MDP, with the square she is on as the state.

### [52:23](https://www.youtube.com/watch?v=2pWv7GOvuf0&t=3143s) When part of the world is hidden, and three ways to build your own state

Often a learner can see only part of what matters. A robot with a camera and no GPS has to work out where it is. A trading agent sees only the current prices. A poker agent sees only the cards face up on the table (52:36 to 53:12). As far as the brain of the agent (the learner) is concerned, the hidden part "may as well not exist" (53:28).

Silver calls this partial observability, and a problem of this kind is a partially observable Markov decision process, POMDP for short (53:36). The agent does not know the state of the environment (the world outside it), so it has to build its own state, the summary it acts on. He gives three ways.

1. Remember everything (53:49). `S^a_t = H_t`. In words: keep the complete history and treat the record itself as the state.
2. Keep a list of how likely each hidden possibility is, called a belief (53:59). `S^a_t = (P[S^e_t = s^1], ..., P[S^e_t = s^n])`. In words: keep one probability for each state the environment might be in. This is the Bayesian route.
3. Use a network that carries its own state forward from step to step, called a recurrent neural network (54:38). `S^a_t = sigma(S^a_(t-1) W_s + O_t W_o)`. In words: mix the old agent state with the new observation through weights the network has learned, then squash the result. No probabilities are needed.

He closes with Atari (56:32). The environment state is the console's 1,024 bits, which the agent never sees. The agent's own state was the last four frames.

> **Alt+Tab · game 1 · stop 6 of 7: Trust your eyes in round 4**
>
> **What he just said:** Silver turns to problems where the learner sees the world only in part, so one view can hide different situations and the learner must build its own state.
>
> **In the game:** The rings are back. A question asks whether your old ring will pay +50. Answer with left click or right click, then walk with WASD; the clock starts at your first step.
>
> **Before you press:** Decide whether what you can see is enough to know which ring pays now.
>
> <details><summary>Back from the game: what you just saw</summary>The island looked exactly like round 2, but the hidden payouts had been redrawn and the +50 ring had moved. Your old ring paid nothing, and you were back to trying things. The same view with a different hidden state is partial observability, the problem the course ends on. <em>In an agent:</em> Two customers can open a support chat with the same first message and want different things the agent cannot see.</details>

**On the island:** In the two-player build, a runner who was not told the blocker's row faced a partially observable problem, by the fact sheet's own description. The hidden-wall build, planned and being run now, puts all three ideas on the strip: RUNNER BLIND, RUNNER REMEMBERS BUMPS (the smallest possible belief, built from what happened to her) and RUNNER SEES THE WALL. It has no results yet.

### [57:06](https://www.youtube.com/watch?v=2pWv7GOvuf0&t=3426s) What can be inside an agent: a way of acting, a forecast, a picture of the world

Up to here the lecture has described only the problem. Now Silver opens the agent (the learner) up. It may contain one or more of three things, and he says the list is not complete.

The first is its way of choosing a move from its state (the summary it acts on), called the policy. A policy can be fixed, which is called deterministic. `a = pi(s)`. In words: one move for each state. Or it can involve chance, which is called stochastic. `pi(a|s) = P[A_t = a | S_t = s]`. In words: a probability for each move in each state.

The second is a forecast of the reward still to come if the agent keeps behaving the same way, called the value function. `v_pi(s) = E_pi[R_(t+1) + gamma R_(t+2) + gamma^2 R_(t+3) + ... | S_t = s]`. In words: the reward you expect to collect from here on under this policy, with later rewards shrunk by a factor called the discount, written gamma. In Space Invaders the value climbs when the mothership appears and drops after it is shot, because value counts only reward still to come (gamma about 0.99, 1:05:09).

The third is the agent's own picture of how the environment (the world outside it) behaves, called a model. `P^a_ss' = P[S_(t+1) = s' | S_t = s, A_t = a]`. In words: where each move probably leads. `R^a_s = E[R_(t+1) | S_t = s, A_t = a]`. In words: what each move pays at once, on average. Of a maze map that an agent learned, he says: "It's not reality, it's just the agent's model of reality." (1:10:45)

**On the island:** RANDOM WALK's policy is stochastic: four moves, each with an equal chance. Her exact value is -114.4 at the start square and -135.5 at the far inland corner. PLANNER holds the grid's written rules as her model. DYNA-Q learns a table model from her own steps.

### [1:10:51](https://www.youtube.com/watch?v=2pWv7GOvuf0&t=4251s) Sorting agents by what they keep

Silver has just shown one small maze three ways (1:08:03). In the first, every square holds an arrow, the move to make there. In the second, every square holds a number from -1 to -24, which counts the steps still to go at -1 each. The third is a partial map, the part of the maze the agent has walked through. These are the three things from the last part: a policy (a way of choosing moves), a value function (a forecast of reward to come) and a model (the agent's picture of the world).

He then sorts agents, the learners, by which of these they keep. An agent that keeps only the numbers and picks whichever move leads to the best number is called value-based. An agent that keeps only the arrows and adjusts them directly is called policy-based. An agent that keeps both is called an actor-critic.

A second sorting cuts across the first. An agent that goes straight from experience to a policy or a value function, without working out how the world behaves, is called model-free. An agent that first builds a model and then plans with it is called model-based (1:15:02).

**On the island:** SARSA and Q-LEARNING are value-based and model-free. POLICY GRADIENT is policy-based. ACTOR-CRITIC is both. DYNA-Q and PLANNER are model-based.

### [1:16:11](https://www.youtube.com/watch?v=2pWv7GOvuf0&t=4571s) Finding out by trying or working it out from the rules: learning and planning

There are two ways to get good at a game: play it and find out, or be given the rules and think. Silver treats them as two different problems, and he calls this maybe the most important distinction.

The first is the reinforcement learning problem. The environment (the world the learner acts in) is unknown, and nobody tells the agent, the learner, how it works. It improves its policy, its way of choosing moves, by acting and seeing what comes back.

In the second, the agent is given a model, a full and correct description of how the environment behaves. It does not have to act in the world at all. It computes with the model and improves its policy that way. This is called planning (1:17:24).

Atari shows both. In the learning version the agent sits in front of the game with the screen, the score and the joystick, and nobody tells it the rules. In the planning version it has a perfect emulator, a program that behaves exactly like the game, and it can ask the emulator what would happen after any move. So it can search ahead before it acts.

**On the island:** PLANNER plans. She runs value iteration on the grid's rules (repeated sweeps that update what every square is worth), which settled in 13 sweeps. Then she walks greedily, always taking the best-valued move. She never fell.

### [1:20:44](https://www.youtube.com/watch?v=2pWv7GOvuf0&t=4844s) Try something new or use what you know; judge a policy or find the best one

Go to your favourite restaurant and you know roughly what you will get. Try a new one and tonight's meal may be worse, but you may find a better favourite. Silver names the two sides. Giving up some reward you know about, so that you can find out more, is called exploration. Using what you already know to get the most reward is called exploitation. An agent (a learner) has to balance the two. His second example is online advertising: show the advert people click most, or show a new one to see whether it does better.

The last distinction is between two questions. One takes a policy (a way of choosing moves) as given and asks how much reward it will collect. He calls that prediction (1:24:37). The other asks which policy collects the most reward, and he calls that control. Usually you have to solve the first to solve the second (1:25:02).

He shows the gap on a small grid of squares, a gridworld. With moves chosen at random, the best square is worth 8.8. Under the best policy, the same square is worth more than 24.

> **Alt+Tab · game 1 · stop 7 of 7: Read your four rounds back**
>
> **What he just said:** Silver ends on a trade every learner faces: use what you know to score now, or try something new to find out more.
>
> **In the game:** Nothing to press. The left side lists what you did, what it is called and where it shows up in a language-model agent, with your prediction score. The right side keeps all four round totals.
>
> **Before you press:** Before reading, guess which round cost you the most seconds, and why.
>
> <details><summary>Back from the game: what you just saw</summary>Round 1 was trying things and round 2 was using what you knew; rounds 3 and 4 asked what you were acting on. Your total rose when your memory matched the world and fell when it did not. The game is simpler than Silver's setting: you always knew where you stood, so your memory was nearly a complete state. <em>In an agent:</em> An agent scored only at the end of a task works the same way: the transcript is its history, and what the program that runs the model (its harness) shows it each turn is its state.</details>

**On the island:** Most learners explore with epsilon 0.1, which means a random move one step in ten. The value tables that follow RANDOM WALK do prediction. SARSA and the rest do control.

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
