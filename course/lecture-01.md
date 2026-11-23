# Lecture 1: Introduction to Reinforcement Learning

*David Silver's lecture 1 (UCL, 2015), gone through in his order and re-explained with the Tracer experiments on Workshop Island. The lecture and its slides are his: [video](https://www.youtube.com/watch?v=2pWv7GOvuf0), [course page](https://davidstarsilver.wordpress.com/teaching/). The words below are a re-explanation. Every island number comes from the logged runs in this repository.*

You load in as Tracer. Five white rings stand around you, a yellow line shows a score, and nobody tells you what the score is for. No callouts, no coach, just a number. All night on Workshop Island, ten Tracer bots get a harsher version: each starts at the left end of a strip of 48 squares beside the edge, and nobody tells them the edge kills. Two of them never learn a thing. RANDOM WALK picks moves at random all night, and PLANNER is handed the rules and works out her route before her first step (one is the floor, the other the ceiling, and every learner lives between them). This lecture asks what a situation like that is made of: what the learner sees, what she remembers, and what number she is trying to push up. Silver's answer is a loop of seeing, acting and getting scored, which he calls observation, action and reward. The hard part, it turns out, is choosing what to remember.

**Two windows:** this page, and [Game 1: No Coach](../workshop/games/g01.md), an Overwatch custom game for this lecture (paste `workshop/compiled/game-01.txt` into a custom game's settings and start it). The game opens at stop 1 and waits. Read down this page; at each box marked Alt+Tab, switch to the game, do that stop, and switch back. The game never moves on while you read.

## The lecture in order

### [09:47](https://www.youtube.com/watch?v=2pWv7GOvuf0&t=587s) Nobody tells you the right answer. You just get a number.

You finish a ranked game and your rank bar ticks up. That is the whole message. It does not say the Pulse Bomb did it, or that you should stop taking the left flank.

It says: up a bit.

This course is about that kind of learning: you act, a number comes back, and nobody hands you the right move. Silver calls it reinforcement learning, RL for short, and the science of making decisions.

(School has an answer key that marks exactly what you got wrong. Most of machine learning is school. This is ranked. Engineers call it optimal control; neuroscientists found it in the brain's dopamine system (06:51).)

Four things set it apart from the rest of machine learning, each annoying in its own way:

1. **No teacher.** No supervisor, in his word. Just the number, which he calls the reward: three points for this move, minus ten for that.
2. **The number can come late.** You make the play in round one and get paid in round three.
3. **Everything arrives in order.** Each second looks a lot like the last, so the moments are not separate facts.
4. **Your own moves decide what you see next** (11:39). Peek left, and you never learn what was on the right.

The one doing the choosing and learning, he calls the agent. In the game beside this page, that is you.

> **Alt+Tab · game 1 · stop 1 of 7: Guess what the number will do**
>
> **What he just said:** Silver's first point: there is no teacher pointing at the right move. You get a number, the reward, and it can show up long after the move that earned it. Think of your rank bar after a game: it moves, and it never says why.
>
> **In the game:** Five white rings stand around you, and the yellow line shows the last reward and the running total. A question floats in front of you. Answer with left click, right click or melee.
>
> **Before you press:** Commit to what the total will do while a round is running and you stand still.
>
> <details><summary>Back from the game: what you just saw</summary>It drops by 1 every second. That is all the score says: time costs something. Not where to go, not which ring is good. A teacher would point. The score only counts. That is reward without a supervisor. <em>In an agent:</em> An agent graded only on whether its task passed gets the same deal: one number, no reason attached.</details>

**On the island:** Nobody shows Tracer the right move either. She gets a number and nothing else: -1, +50, -100 or -50. What she sees depends on what she chooses, which is bad news for RANDOM WALK, who chooses at random. She reached the goal in 1.0% of her 2,308 episodes (an episode is one attempt at the crossing), so nearly everything she ever saw was a fall.

### [23:00](https://www.youtube.com/watch?v=2pWv7GOvuf0&t=1380s) The reward hypothesis: everything you want, as one running total

Think of everything you want from a match. Win the fight. Hold the point. Stop feeding. Land the Pulse Bomb you will rewatch three times. Silver's bet is that all of it fits into one number per moment, added up.

That number at each step is the reward. Your job, as the agent, is to make the total as large as you can.

Every goal, Silver says, can be described as making the expected total of future reward as large as possible, where expected means averaged over the ways things could turn out. He calls this the reward hypothesis, and he admits it is "a little bit controversial" (24:02).

"Finish fast", for instance, becomes -1 for every step, so the quickest finish scores highest (25:19).

Adding up has a consequence. A move can matter long after you make it, so sometimes you give up reward now to get more later. A kill is one blink away, you are low, and you take the health pack instead. Silver's version is a helicopter that stops its stunts to refuel (28:33).

When two goals conflict, he argues, you still have to pick one action, and that forces them onto one scale. "Not everyone has to agree with that." (33:48)

The game now tests whether a goal nobody states can reach you through the total alone.

> **Alt+Tab · game 1 · stop 2 of 7: Find the ring the score likes**
>
> **What he just said:** Silver's reward hypothesis: any goal can be written as one total to push as high as it will go. Even 'finish fast' fits, as minus one for every step.
>
> **In the game:** Walk with WASD when you are ready; the round's clock starts at your first step. Try the rings. The round ends when one of them pays, or 120 seconds after your first step.
>
> **Before you press:** Before you step, pick the ring you will try first and say how you will know whether it was the right one.
>
> <details><summary>Back from the game: what you just saw</summary>Most rings paid 0. One paid +50 and ended the round. Your total is 50 minus the seconds you spent, so every wrong ring cost you the walk to it. Nobody told you to hurry. The minus one a second did. That is the reward hypothesis in your hands: a goal (find it, be quick) turned into one number to push up.</details>

**On the island:** The bots' goal, "cross along the edge quickly without falling", is written as -1 per step, +50 at the goal, -100 for a fall, and -50 if 100 steps pass. The discount is 1, so a reward later counts the same as one now. The total for one episode, called the return, is 39 at best, and stepping straight off the edge scores -101. You can watch reward being traded for safety: SARSA kept 3.88 m from the edge in her last 40 episodes against 2.07 m for Q-LEARNING, and paid with 25.1 steps per episode against 18.6.

### [29:35](https://www.youtube.com/watch?v=2pWv7GOvuf0&t=1775s) You, the world, and the one wire between you

Strip a match down to what actually passes between you and the game. You press keys and move the mouse. The game sends back a screen and, now and then, a score. You cannot reach into the server and nudge the payload. Your hands are the only lever you have.

Silver draws this as two pictures facing each other. One is a brain: the part we build, the algorithm that decides what to do. He calls it the agent. The other is the world, everything on the other side, and he calls it the environment.

Every step runs the same way. The agent takes an action. The environment answers with two things: a snapshot of what the agent can see right now, called an observation, and a reward, the single number from the last part. Then the agent acts again. It has no say over the environment except through its actions.

Round and round it goes. The stream this produces, observations, rewards and actions in order, is what he calls the agent's experience.

That stream is all the data reinforcement learning ever gets.

> **Alt+Tab · game 1 · stop 3 of 7: Wait for the late bill**
>
> **What he just said:** Silver draws a loop. The learner acts, the world answers with what it now shows plus a reward, and round it goes. That stream of experience is all the data there is.
>
> **In the game:** Round 1 is over, and a question asks whether your total can still change. Answer with left click or right click, then watch the yellow line.
>
> **Before you press:** Commit: is the number on screen now your final total for round 1?
>
> <details><summary>Back from the game: what you just saw</summary>If you touched the billing ring, -20 turned up only now, after the round ended, with nothing saying which ring sent it. That is late feedback, and working out which past move earned it is called credit assignment. No bill? Then the billing ring is one you never touched. Either way you acted, read the number and acted again: action, observation, reward, in a loop. <em>In an agent:</em> A coding agent whose tests fail at the end of a long task gets the same late bill, and the same puzzle: which of its many edits sent it.</details>

> **Alt+Tab · game 1 · stop 4 of 7: Run round 2 on what you learned**
>
> **What he just said:** In that loop, the only thing the learner can improve from is the experience it has collected. Here, that experience is round 1.
>
> **In the game:** A question asks what your round 2 total will be if you go straight to the ring that paid. Answer, then walk to that ring with WASD; the clock starts at your first step. Both totals then sit side by side on the right.
>
> **Before you press:** Name what still limits your round 2 total, given that the layout has not changed.
>
> <details><summary>Back from the game: what you just saw</summary>Straight to the ring, you lose only the seconds of one walk, so the total lands a little under +50. The right side shows round 2 minus round 1. That gap is learning from reward: same map, same rules, a better total, and the only thing that changed is what the score showed you.</details>

**On the island:** Here the agent is one Tracer plus her table of stored numbers and her learning method. The environment is the game plus the Workshop script. Her actions are forward, back, inland and toward the edge, and each one is a real run to the next square. Her observation is the square she is on, read from where she really stands.

### [33:53](https://www.youtube.com/watch?v=2pWv7GOvuf0&t=2033s) The whole recording, and the two notes you actually use

Say you record your own screen for a whole match, keys and all. That file holds every frame you saw, every number that popped up and every button you pressed, in order. In principle it is everything you have. In practice nobody pauses a team fight to scrub through it. You play off a couple of notes: their Ana is on the high ground, their Genji has blade.

Silver calls the full record the history: what the agent saw, was paid and did, from the first step up to now.

What happens next depends on the history, but nobody can work from it in practice, because it is enormous (35:56). An agent may live a long time, and a single observation may be video.

So the agent keeps a summary, and Silver calls the summary the state. His definition is so broad it sounds like a loophole: a state is any function of the history, meaning anything you can compute from it (36:41). Keep only the latest screen, and that is a state. Keep the last four screens, as his Atari agent did (37:00), and that is a state too.

Which notes to keep is up to you. It is also the hard part.

<details markdown="1"><summary>The formulas, when you want them</summary>

`H_t = O_1, R_1, A_1, ..., A_(t-1), O_t, R_t`. In words: the ordered list of what the agent saw, was paid and did, from the first step up to now.

`S_t = f(H_t)`. In words: the state is whatever summary you choose to compute from the record.

</details>

The game's next question is what you act on once the screen stops helping.

> **Alt+Tab · game 1 · stop 5 of 7: Steer by memory with the rings gone**
>
> **What he just said:** Silver calls everything seen, done and scored so far the history. The state is whatever summary of it the learner keeps and acts on: the full recording of your match versus the two notes in your head.
>
> **In the game:** Answer a question about round 3 with left click or right click. Then you are held still for 2 seconds to look before the rings vanish. Answer the next question, then walk with WASD to where the paying ring was.
>
> **Before you press:** Before the rings go, commit to how you will find the paying ring once nothing on screen marks it.
>
> <details><summary>Back from the game: what you just saw</summary>With nothing on screen, you went where your memory said. Your history is every second, ring and bill so far. The one fact you kept from it, that ring over there, is your state. The first question was its price: going straight earns now but teaches you nothing about the rings you skipped. That is using what you know instead of trying things.</details>

**On the island:** On the strip, one episode's history is its list of squares, moves and rewards. Every bot keeps the same summary of it, the square she is on now (one of 48), except two bots who were handed coarser summaries on purpose.

### [37:13](https://www.youtube.com/watch?v=2pWv7GOvuf0&t=2233s) What the server knows, and what you carry in your head

Somewhere, a server knows exactly how much ult charge the enemy Ana has. You do not. You have a guess, based on how long it has been since she last used it.

Silver separates two kinds of state by who holds them.

The first belongs to the world. The environment has internal numbers that decide what the agent sees and is paid next, and these are the environment state. The agent usually cannot see them, and much of it would be useless anyway: a robot walking around a room does not need the arrangement of the atoms in Ayers Rock (38:39).

(What about other players? Asked about several agents sharing one world, he says each can treat the others as part of its environment (39:48). The enemy Ana is, for your purposes, weather.)

The second belongs to you. Whatever the algorithm stores and uses to pick its next action is the agent state. It can be any function of the history, and what to remember and what to throw away is our decision (41:03).

When an algorithm later in this course picks an action from a state, this is the state it means.

**On the island:** The environment state is everything the game holds in memory: Tracer's exact position and speed, the step count, the other nine bots. The agent state is only her square. In the two-player build, the blocker is simply part of the runner's environment.

### [42:04](https://www.youtube.com/watch?v=2pWv7GOvuf0&t=2524s) The Markov property: when you can forget how you got here

You get backfilled into a match in overtime. You missed everything before this moment, and you can still play: the payload, the timer and who is alive tell you most of what you need. (Not all of it. Nobody tells you who is sitting on an ult, and that gap is what this part is about.)

That is the test of a good summary. Could you keep playing well if the rest of the record were deleted? A state that passes, one that holds everything useful in the history, Silver calls an information state, or a Markov state. His phrase: "the future is independent of the past given the present" (43:11). Hold a state like that, and you can throw the history away.

A student asks about a helicopter (45:13). Its position, velocity, angle, how fast it is turning and the wind are roughly Markov. Know those, and where it was ten minutes ago changes nothing. Position alone is not Markov, because you would have to look back in time to work out its speed (46:00). It is the difference between a clip of a Tracer and one screenshot of her.

<details markdown="1"><summary>The formula, when you want it</summary>

A state is Markov if `P[S_(t+1) | S_t] = P[S_(t+1) | S_1, ..., S_t]`. In words: the whole past tells you nothing more about the next state than the present does.

</details>

Two states are always Markov: the environment state and the full history (47:02). So a Markov state always exists.

Finding a useful one is the real job.

**On the island:** Her square is nearly a Markov state: a step missed the square it aimed for only 0.21 times per 1,000. Nearly. The -50 after 100 steps depends on the step count, which the square does not hold, so knowing only her square she cannot tell step 5 from step 99.

### [47:57](https://www.youtube.com/watch?v=2pWv7GOvuf0&t=2877s) Be the rat: same events, three different guesses

Silver asks the class to be a rat. You are in an experiment, and every run ends one of two ways: cheese, or an electric shock. Each run is an episode.

1. Light, light, lever, bell. Shock.
2. Bell, light, lever, lever. Cheese.
3. Lever, light, lever, bell. Well?

Guess before you read on.

Many hands in the room go up for the shock, and a few for the cheese. Both answers make sense. They come from different notes.

Keep the last three things, and you have light, lever, bell, the same ending as the first run: shock. Keep counts, and you have one light, one bell and two levers, the same as the second run: cheese. Keep the whole sequence, and you have never seen this one before, so you cannot say.

Three rats, the same events, and the only difference is what each one kept, which is to say its state. As Silver puts it, "the state representation really defines what happens next" (50:55).

**On the island:** Q, ROW ONLY is a rat with bad notes. She was told only her row. She found the edge at once, but forward and back looked the same to her, and she dithered for 47.1 steps per episode against 18.6 for full Q-LEARNING.

### [51:14](https://www.youtube.com/watch?v=2pWv7GOvuf0&t=3074s) The nice case: nothing hidden, nothing to guess

Picture playing with the spectator's view: every player's position, health, cooldowns and ult charge, on your screen at once. Nothing hidden. Nothing to guess.

Silver calls this the nice case. The agent gets to look straight at the environment's internal numbers, the environment state from a few parts back, and use them as its own state.

Three things that used to be separate become one: what you observe, what you keep, and what the world holds. This is called full observability, and a problem set up this way is called a Markov decision process, MDP for short.

(In ranked, this would be cheating. In this course it is lecture 2, and most of what follows.)

<details markdown="1"><summary>The formula, when you want it</summary>

`O_t = S^a_t = S^e_t`. In words: what the agent observes, what it keeps and the environment's own state are one thing.

</details>

He warns that many real problems are not like this (52:09).

So hold on to everything about state from the last few parts. You will need it.

**On the island:** The main strip is treated as an MDP, with the square she is on as the state.

### [52:23](https://www.youtube.com/watch?v=2pWv7GOvuf0&t=3143s) The invisible Sombra problem, and three ways to build your own state

Somewhere near you is an invisible Sombra. She exists. Your screen does not mention her.

This happens a lot. A robot with a camera and no GPS has to work out where it is. A trading agent sees only the current prices. A poker agent sees only the cards face up on the table (52:36 to 53:12). As far as the agent's brain is concerned, the hidden part "may as well not exist" (53:28).

Silver calls this partial observability, and the problem a partially observable Markov decision process, POMDP for short (53:36). The agent cannot read the environment state, so it has to build a state of its own. He gives three ways, and every Overwatch player already uses the second:

1. **Remember everything** (53:49). The whole history is the state.
2. **Keep a belief** (53:59). Hold a probability for each situation the world might be in: probably she is on the left flank, possibly on the high ground. This is the Bayesian route.
3. **Let a network carry it** (54:38). A recurrent neural network mixes what it held a moment ago with what it sees now, every step. No probabilities needed.

<details markdown="1"><summary>The formulas, when you want them</summary>

`S^a_t = H_t`. In words: keep the complete history and treat the record itself as the state.

`S^a_t = (P[S^e_t = s^1], ..., P[S^e_t = s^n])`. In words: keep one probability for each state the environment might be in.

`S^a_t = sigma(S^a_(t-1) W_s + O_t W_o)`. In words: mix the old agent state with the new observation through weights the network has learned, then squash the result.

</details>

He closes with Atari (56:32). The environment state is the console's 1,024 bits, which the agent never sees. The agent's own state was the last four frames.

> **Alt+Tab · game 1 · stop 6 of 7: Trust your eyes in round 4**
>
> **What he just said:** Silver turns to worlds the learner sees only in part. One view can hide different situations, so the learner has to build its own state. Call it the invisible Sombra problem.
>
> **In the game:** The rings are back. A question asks whether your old ring will pay +50. Answer with left click or right click, then walk with WASD; the clock starts at your first step.
>
> **Before you press:** Decide whether what you can see is enough to know which ring pays now.
>
> <details><summary>Back from the game: what you just saw</summary>The island looked exactly like round 2, but the hidden payouts had been redrawn and the +50 ring had moved. Your old ring paid nothing, and you were back to trying things. Same view, different hidden state: that is partial observability, the problem the course ends on. <em>In an agent:</em> Two customers can open a support chat with the same first message and want different things. The agent sees the same view; the hidden state is different.</details>

**On the island:** In the two-player build, a runner who was not told the blocker's row faced a partially observable problem, by the fact sheet's own description. The hidden-wall build in lesson 11 puts all three ideas on the strip: RUNNER BLIND, RUNNER REMEMBERS BUMPS (the smallest possible belief, built from what happened to her) and RUNNER SEES THE WALL. With no row that is always open, they got through 52%, 90% and 94% of their test crossings. One remembered bump was most of the difference.

### [57:06](https://www.youtube.com/watch?v=2pWv7GOvuf0&t=3426s) Open up the agent: habits, a gut feeling, a map in its head

So far the lecture has only described the problem. Now Silver opens the agent up.

Think about what runs in your head mid-fight. Habits: healer alone, blink in. A gut feeling about how the fight is going. A rough sense of what happens if you press a given button. Silver's three pieces line up with those, and an agent may hold one or more of them. (He says the list is not complete, which seems fair. Heads are messy.)

1. **A policy:** how it picks a move from its state. It can be fixed, one move per state, which is called deterministic. Or it can involve chance, a probability for each move, which is called stochastic.

2. **A value function:** a forecast of the reward still to come if it keeps behaving the same way, with later rewards shrunk by a factor called the discount, written gamma. In Space Invaders the value climbs when the mothership appears and drops once it is shot, because it counts only reward still to come (gamma about 0.99, 1:05:09).

3. **A model:** its own picture of how the environment behaves, meaning where each move probably leads and what it pays right away. Of a maze map one agent learned, Silver says: "It's not reality, it's just the agent's model of reality." (1:10:45)

<details markdown="1"><summary>The formulas, when you want them</summary>

`a = pi(s)`. In words: one move for each state.

`pi(a|s) = P[A_t = a | S_t = s]`. In words: a probability for each move in each state.

`v_pi(s) = E_pi[R_(t+1) + gamma R_(t+2) + gamma^2 R_(t+3) + ... | S_t = s]`. In words: the reward you expect to collect from here on under this policy, with later rewards shrunk by the discount gamma.

`P^a_ss' = P[S_(t+1) = s' | S_t = s, A_t = a]`. In words: where each move probably leads.

`R^a_s = E[R_(t+1) | S_t = s, A_t = a]`. In words: what each move pays at once, on average.

</details>

**On the island:** RANDOM WALK's policy is stochastic: four moves, each with an equal chance. Her exact value is -114.4 at the start square and -135.5 at the far inland corner. PLANNER holds the grid's written rules as her model. DYNA-Q learns a table model from her own steps.

### [1:10:51](https://www.youtube.com/watch?v=2pWv7GOvuf0&t=4251s) Arrows, numbers or a map: sorting agents by what they carry

Ask three players how to get from spawn to the point. One says: left at the arch, up the stairs, through the door. One says: the corridor is fine, the courtyard is where you die. One sketches you a map.

Silver has just done the same with one small maze (1:08:03). In the first picture every square holds an arrow, the move to make there. In the second every square holds a number from -1 to -24, counting the steps still to go at -1 each. The third is a partial map, the part of the maze the agent has walked through. Arrows, numbers, map: the policy, the value function and the model from the last part.

Then he sorts agents by which of these they carry. Keep only the numbers and take whichever move leads to the best one, and you are value-based. Keep only the arrows and adjust them directly, and you are policy-based. Keep both, and you are an actor-critic.

A second sorting cuts across the first. Go straight from experience to a policy or a value function, without working out how the world behaves, and you are model-free. Build a model first and plan with it, and you are model-based (1:15:02).

Two questions, then: what do you carry, and do you bother drawing the map?

**On the island:** SARSA and Q-LEARNING are value-based and model-free. POLICY GRADIENT is policy-based. ACTOR-CRITIC is both. DYNA-Q and PLANNER are model-based.

### [1:16:11](https://www.youtube.com/watch?v=2pWv7GOvuf0&t=4571s) Learning versus planning: play it, or read the rules and think

There are two ways to get good at a new hero. Queue up and get flattened until something sticks. Or read every number on her wiki page and work the combos out on paper before you ever play.

Silver treats these as two separate problems, and he calls it maybe the most important distinction.

In the first, nobody tells the agent how the environment works. It improves its policy, its way of picking moves, by acting and seeing what comes back. This is the reinforcement learning problem.

In the second, the agent is handed a model: a full and correct description of how the environment behaves. It never has to act in the world at all. It computes with the model and improves its policy that way. This is called planning (1:17:24).

Atari shows both. In the learning version the agent sits in front of the screen with the score and the joystick, and nobody explains the rules. In the planning version it has a perfect emulator, a program that behaves exactly like the game, and it can ask what would happen after any move. So it can search ahead before it acts.

(The paper route only works if the wiki is right. Planning has the same catch.)

**On the island:** PLANNER plans. She runs value iteration on the grid's rules (repeated sweeps that update what every square is worth), which settled in 13 sweeps. Then she walks greedily, always taking the best-valued move. She never fell.

### [1:20:44](https://www.youtube.com/watch?v=2pWv7GOvuf0&t=4844s) Your main or a new hero; rate a plan or find the best one

Say you have a main. You know roughly what a game on her gets you. A game on someone new will probably go a bit worse, and it is also the only way to find out whether you are better on someone else.

Silver's version is a restaurant: your favourite, or the new place that might be worse tonight and might become your new favourite. Giving up reward you know about, so you can find out more, he calls exploration. Using what you already know to get the most reward, he calls exploitation. An agent has to balance the two. His second example is online advertising: show the advert people click most, or a new one that might do better.

Then come two questions. One takes the policy as given and asks how much reward it will collect: keep playing exactly like this, and where do you end up? He calls that prediction (1:24:37). The other asks which policy collects the most. That is control, and you usually have to solve the first to solve it (1:25:02).

He shows the gap on a small grid of squares, a gridworld. With moves chosen at random, the best square is worth 8.8. Under the best policy, that same square is worth more than 24.

Same square, same rules. Only the policy changed.

> **Alt+Tab · game 1 · stop 7 of 7: Read your four rounds back**
>
> **What he just said:** Silver ends on a trade every learner faces: use what you know and score now, or try something new and find out more. Your main, or the hero you have never queued.
>
> **In the game:** Nothing to press. The left side lists what you did, what it is called and where it shows up in a language-model agent, with your prediction score. The right side keeps all four round totals.
>
> **Before you press:** Before reading, guess which round cost you the most seconds, and why.
>
> <details><summary>Back from the game: what you just saw</summary>Round 1 was trying things. Round 2 was using what you knew. Rounds 3 and 4 asked what you were acting on. Your total went up when your memory matched the world and down when it did not. (The game is easier than Silver's setting: you always knew where you stood, so your memory was nearly a complete state.) <em>In an agent:</em> An agent scored only at the end of a task works the same way. The transcript is its history, and whatever its harness (the program that runs the model) shows it each turn is its state.</details>

**On the island:** Most learners explore with epsilon 0.1, which means a random move one step in ten. The value tables that follow RANDOM WALK do prediction. SARSA and the rest do control.

## What the island measured for this lecture

Give a Tracer four buttons and a whole night, and you would expect luck to carry her to the goal every so often. It is only twelve squares. And a bot handed the rules should do well, if not perfectly, in a real game where a step can miss.

Two bots test both guesses, and neither learns a thing. RANDOM WALK is the floor: no learning at all. PLANNER is the ceiling: she knows the rules.

| Bot | Runs | Falls per 100 (95% interval) | Return, first 40 | Return, last 40 | First goal (median episode) | Runs never reaching goal | Steps per episode |
|---|---|---|---|---|---|---|---|
| RANDOM WALK | 11 | 97.4 (96.9 to 97.9) | -111.3 | -113.3 | 37 | 2 | 14.9 |
| PLANNER | 10 | 0.0 (0.0 to 0.0) | 39.0 | 39.0 | 1 | 0 | 11.0 |

Luck did not carry her far. RANDOM WALK fell in 97.4 of every 100 episodes, and 2 of her 11 runs never reached the goal at all. Her first 40 episodes score about the same as her last 40, as they should: her policy never changes.

Over 2,308 episodes she averaged -112.7 (standard error 0.46, roughly how far that average would move if you ran the night again). Work the strip out on paper from its rules, with the time limit ignored, and her start square is worth -114.4.

Close. That is a sanity check that the game and the rules agree, not a test.

PLANNER swept the whole strip 13 times before her first step, and each sweep carried the good news from the goal back one more column. Then she walked, 11 steps an episode on average, and never fell. Her 39.0 is the best return the strip allows.

Neither bot was in a planned comparison; the night's only one was SARSA against Q-LEARNING on falls. These two are the ruler, not the race.

And a ruler has limits. A floor and a ceiling say nothing about how hard the climb between them is, and the climb is what learning means. PLANNER's spotless record also holds only because the rules she was handed match the game.

## Guess first

<details><summary>You know only which square Tracer stands on. Can you predict what her next step brings as well as someone who watched the whole episode?</summary>
Almost, but not quite. A step lands where she aimed all but 0.21 times in 1,000, so her square nearly settles what comes next. But the -50 arrives after 100 steps, and her square cannot tell step 5 from step 99. It is Silver's helicopter with a position and no velocity, in a mild form. What she nearly has is a Markov state.
</details>

<details><summary>A random Tracer can start right beside the drop, or in the far inland corner, as far from the drop as the strip goes. Which start scores better on average?</summary>
Beside the drop: -114.4, against -135.5 for the corner. Distance does not save her. From the corner she wanders longer, paying -1 a step, and usually falls anyway. Those two numbers are each square's value under her policy: the return you expect from there if she keeps moving at random.
</details>

<details><summary>One Tracer is told how far she is from the edge, but not how far along the strip. Against a Tracer told her exact square, does she fall more or less, and cross faster or slower?</summary>
Worse on both: 42.5 falls per 100 against 26.5, and 47.1 steps an episode against 18.6. She learns where the edge is at once. But as far as she can tell, forward and back both lead to where she already is, so she dithers along the edge row. She is Q, ROW ONLY, and her state is a summary too small to tell two places apart.
</details>

<details><summary>Back to the rat. Episode three was lever, light, lever, bell. A rat who keeps only a tally of lights, bells and levers has to bet: cheese or shock?</summary>
Cheese. Her tally reads two levers, one light and one bell, the same as episode two, which ended in cheese. A rat who keeps only the last three things sees light, lever, bell, the ending of episode one, and braces for the shock. Same events, different notes, different bet. The notes are what Silver calls her state.
</details>

<details><summary>One Tracer keeps her whole history as her state, every square, move and reward so far. Another keeps only her square. The history is always Markov. Which one do you bet on to learn the strip?</summary>
The one with only her square. The history grows every step and hardly ever repeats, so a table built on it almost never meets the same state twice, and nothing learned in one episode carries to the next. Always Markov, close to useless. The environment state is always Markov too, but usually hidden. The real job is a small summary that is nearly Markov.
</details>

<details><summary>PLANNER crossed the strip for 10 runs and never fell once. Is she the best reinforcement learner on the island?</summary>
She is not a learner at all. She was handed the rules, worked out what every square is worth in 13 sweeps without a single trial, and then walked. Her record shows what the rules allow, not what a bot can learn. Silver calls what she does planning, the other half of his split between learning and planning.
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

A language-model agent runs this exact loop, and it lines up with Silver's picture almost piece for piece. Take tau-bench (not from the lecture: a benchmark where a model serves a simulated customer through tools such as an airline database, and gets checked at the end).

The agent is the model plus its harness, the program that runs it. The environment is the simulated customer, the database and the tools. Actions are replies and tool calls. Observations are the customer's messages and the tool outputs. The reward is the check at the end of the episode, so the feedback comes late, exactly as Silver describes. This part of the mapping is exact.

The history is the transcript, also exact. The agent state is whatever the harness shows the model each turn: the full transcript, a truncated window or a summary. Each one is a function of the history, so each one is a state in Silver's sense, and choosing between them is the rat's problem all over again.

The customer's hidden instructions and the database contents are environment state the model never sees, which makes the task a POMDP. It is the invisible Sombra again, this time calling the help desk. What the model works out about the customer's goal behaves like a belief, but only by analogy: it is never written down as a list of probabilities.

The mapping breaks in two places.

1. **Nothing is learned during the run.** The weights do not change inside an episode. Reinforcement learning happens only if the scores are later used for training.
2. **One number carries several goals.** A single pass or fail squashes them into one score, which is the reward hypothesis Silver called controversial.

## The thread to partial observability

Everything in this lecture leans on one quiet piece of luck. Tracer is told her square, and her square is very nearly her whole situation. What she sees, what she keeps and what the world holds are one thing, the nice case from (51:14). Most of the course lives there.

Now take the luck away: put something on the strip that matters and that her screen does not show. Her square stops being a good summary, and Silver's three ways out come back: the whole history, a belief, or a network that carries it.

Three things from this lecture come along:

1. **Too small a state turns two situations into one.** Q, ROW ONLY saw every square in a row as the same place, so she could not tell forward from back.
2. **Memory is how you get back what you cannot see.** It does not have to be much.
3. **Choosing the summary is part of the problem.** Three rats, the same events, three different answers. It is not a chore you finish before the real work starts.

Lesson 11 takes the luck away for real. Before each episode one square on her path is shut, and nobody tells her which. RUNNER BLIND gets her square. RUNNER REMEMBERS BUMPS gets her square plus one memory, no bump yet or the row that stopped her: the smallest belief there is. RUNNER SEES THE WALL is told. On the short strip, where no row is always open, they got through 52%, 90% and 94% of their test crossings.

One remembered bump was the difference between stuck and through.

The 38-point gap between remembering and blind passed the test named before the runs. Whether seeing the wall beats remembering it is not yet conclusive. (On the long strip, where a way round always exists, none of the gaps is established.) The game for that lesson, Sombra's Room, puts you in the same seat, with a ping that is right 8 times in 10.

## Experiments the lecture asks for that the island has not run

- Add steps remaining to the state: tests whether the missing step count breaks the Markov property in practice.
- Give a bot her last three squares instead of her current one: the rat's "last three items" state.
- Remove the -1 per step: shows whether routes lengthen once speed leaves the reward.
- Hand PLANNER a wrong model (drop one row inland) and let her walk: a model that is not reality.
- Run Q-LEARNING with discount 0.9: the horizon idea from 1:05:09.
