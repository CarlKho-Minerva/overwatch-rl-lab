# Lecture 10: Classic Games

*David Silver's lecture 10 (UCL, 2015), gone through in his order and re-explained with the Tracer experiments on Workshop Island. The lecture and its slides are his: [video](https://www.youtube.com/watch?v=kZ_AUmFcZtk), [course page](https://davidstarsilver.wordpress.com/teaching/). The words below are a re-explanation. Every island number comes from the logged runs in this repository.*

For nine lectures nothing on the island had a plan of its own. For the last one a blocker from the other team stands in one of the four rows, and her score is the runner's loss. The question is what "best" means when the other side is choosing too. Silver's answer: in a two-player game where one side's gain is the other's loss, it is a pair of policies that neither side would change on its own, and the programs that came closest play themselves, learn a value function by TD, and use it inside a search.

**Play it first:** [Game 10: The Peek](../workshop/games/g10.md), an Overwatch custom game for this lecture that you play yourself (paste `workshop/compiled/game-10.txt` into a custom game's settings). It asks you to predict before it shows you.

## The lecture in order

### [02:38](https://www.youtube.com/watch?v=kZ_AUmFcZtk&t=158s) Games are small worlds with simple rules and deep play
Game rules fit in a paragraph, yet people need centuries to play well, and a game can isolate one hard real-world feature, such as hidden information. Silver's tables show reinforcement learning programs at the top level in five of seven classic games, with chess the weakest case (international master).
**On the island:** the two-player build is the only part of the lab that is a game in Silver's sense, with two sides and opposite interests.

### [08:01](https://www.youtube.com/watch?v=kZ_AUmFcZtk&t=481s) Against a fixed opponent, "best" is a best response
In an MDP (the single-agent setting of earlier lectures) optimal means the most reward. In a game the best policy depends on the others: against someone who always plays rock, the best response is always paper. Hold the other players fixed and you can fold them into the environment's dynamics, so the game becomes an ordinary MDP whose optimal policy is the best response (13:17). Asked whether Easy21 did this with the dealer, Silver says yes (18:05).
**On the island:** the "fixed" blocker always stands in the edge row, so she is part of the environment and Q-learning seeks a best response. The one blind run against her ended at a mean return of -14.0 over its last 40 episodes, reaching the goal 70% of the time.

### [10:25](https://www.youtube.com/watch?v=kZ_AUmFcZtk&t=625s) A Nash equilibrium is where nobody wants to change alone
A Nash equilibrium is a joint policy (a rule for every player at once) in which each player's policy is a best response to the others. Always-paper is not one, because the opponent would switch to scissors. In rock, paper, scissors the equilibrium is each move one third of the time. It is not unique in general (17:21), but these two-player zero-sum games have a unique minimax value (25:09).
`pi^i = pi*^i(pi^-i)`
In words: every player's policy is the best response to everyone else's, all at once.
**On the island:** Not run on the island. The experiment would freeze each trained bot and train a fresh opponent against her: if neither fresh opponent does better, the pair is near an equilibrium.

### [13:17](https://www.youtube.com/watch?v=kZ_AUmFcZtk&t=797s) The equilibrium is where self-play comes to rest
In self-play one learner controls every player and learns from games against itself. Each side keeps learning a best response to the other, so every improvement changes the other's problem. If the chase stops, the resting point is a Nash equilibrium. Silver cites Michael Littman's thesis: standard algorithms such as Q-learning do converge this way with table lookup (one stored number per state).
**On the island:** the chase without self-play. The runner (Q-learning) and the blocker (a four-armed bandit, one running score per row) are different programs. Against a blind runner the learning blocker ended in the far inland row 76% of the time, and the runner's return was -46.1, against -14.0 with a fixed blocker (2 runs and 1, exploratory).

### [18:53](https://www.youtube.com/watch?v=kZ_AUmFcZtk&t=1133s) Two players, opposite rewards, and who sees what
The lecture narrows to two players taking turns in a zero-sum game, where what is good for one is equally bad for the other.
`R1 + R2 = 0`
In words: the rewards add to zero, so one value function, negated, serves both sides.
In a perfect-information game both players see the whole state: chess, Go, and backgammon, whose dice add chance but hide nothing. In an imperfect-information game part of it is hidden: the opponent's Scrabble letters, the opponent's poker cards (21:05).
**On the island:** the blocker's score is the runner's return negated, so the build is exactly zero-sum, though not turn-based. The "sees" runner is told the blocker's row; the "blind" runner plays an imperfect-information game.

### [21:40](https://www.youtube.com/watch?v=kZ_AUmFcZtk&t=1300s) Minimax: assume the other side always answers with its best move
The minimax value is the game's outcome when white tries hardest to raise it and black tries hardest to lower it.
`v*(s) = max over pi1, min over pi2, of v_pi(s)`
In words: the value of a position under perfect play by both sides, taken in turn order (25:50).
Its policy is a Nash equilibrium. Minimax search (Claude Shannon's, run on paper) finds it by searching to the end and backing values up. In the worked tree (27:39) max takes the larger of each leaf pair (+7, -2, +9, -4), min the smaller of those (-2, -4), and the root is -2, so max opens with a1.
**On the island:** Not run on the island. Solving the strip once per blocker row and letting the blocker take the worst row for the runner would give the seeing game's minimax value.

### [29:56](https://www.youtube.com/watch?v=kZ_AUmFcZtk&t=1796s) Cut the search short and let a value function score the leaves
Trees grow exponentially, so programs search a few moves and score the stopping points with a value function, sped up by alpha-beta pruning (31:53). The classic one is binary-linear: one yes-or-no feature per fact ("white has a rook"), each with a weight.
`v(s, w) = x(s) . w`
In words: add up the weights of the features switched on in this position.
Deep Blue (36:15) used 8,000 hand-made features and grandmaster-tuned weights, searched 200 million positions a second, and beat Kasparov in 1997 with no learning. Chinook (38:19) added stored endgame tables, took two of Marion Tinsley's seven career losses, and later solved checkers (2007).
**On the island:** PLANNER is the island's Chinook: the strip is small enough to solve outright (13 sweeps, no falls in 10 runs).

### [42:24](https://www.youtube.com/watch?v=kZ_AUmFcZtk&t=2544s) Self-play TD is the same code, plus afterstates
Monte Carlo, TD(0) and TD(lambda) carry over unchanged. Only policy improvement changes: white maximises, black minimises.
`Delta w = alpha (v(S_t+1, w) - v(S_t, w)) grad_w v(S_t, w)`
In words: if one move later you expect a different result, nudge the weights toward the newer guess.
With known deterministic rules you need only the afterstate, the position a move leads to (44:55).
`q*(s, a) = v*(succ(s, a))`
In words: a move is worth what the position it creates is worth.
**On the island:** the island is nearly deterministic (0.21 slips per 1,000 steps), and PLANNER already picks moves by the value of the square each reaches. No learning bot uses afterstates.

### [47:37](https://www.youtube.com/watch?v=kZ_AUmFcZtk&t=2857s) Logistello and TD-Gammon: self-play that reached the top
Logistello found 1.5 million stone patterns as features, learned their weights by self-play policy iteration with Monte Carlo targets, searched every move, and beat Takeshi Murakami 6-0. TD-Gammon (52:38) trained a small neural network from random weights by self-play TD, greedily, with no exploration. The dice made that work: they push play everywhere (56:31) and smooth the value function (57:44). The recipe diverged in chess and checkers, and even TD-Gammon reached superhuman play only with a 3-ply (three-move) search.
**On the island:** no dice, so a greedy learner must be pushed to explore. Greedy Q + OPTIMISM (every Q starts at 40) fell 7.2 times per 100 episodes, against 26.5 for Q-learning (exploratory).

### [1:02:20](https://www.youtube.com/watch?v=kZ_AUmFcZtk&t=3740s) Let the search supply the learning targets
Plain TD failed in chess, where tactics are invisible without search. TD root, from Arthur Samuel's 1959 checkers player (1:07:47), moves the current value toward a deep search from the next position. TD leaf (1:08:38) moves this step's search toward the next step's search, through the principal leaf, the leaf whose value decided the result.
`v+(S_t, w) <- v+(S_t+1, w)`
In words: push this move's search result toward the next move's (the plus means "after searching").
KnightCap (1:18:04) reached master level this way, but needed an expert opponent and known piece values.
**On the island:** Not run on the island. A runner with a two-step look-ahead, learning toward that look-ahead value, would be the test.

### [1:20:26](https://www.youtube.com/watch?v=kZ_AUmFcZtk&t=4826s) TreeStrap: every node of one search becomes a lesson
TreeStrap (with Joel Veness) moves every node of one search toward the search value below it.
`v(s, w) <- v+(s, w)`
In words: teach the quick guess at each position to predict a deeper search from there.
Meep learned this way from random weights in self-play and won 13 of 15 games against international masters. Learning from your own search drifts from reality, Silver warns (1:25:48): "you have to ground it" in games played to a real end.
**On the island:** DYNA-Q learns from imagined steps grounded by a model of real ones. Her first-40 return beat Q-learning's by 25.98 (15.53 to 36.25, exploratory); they were level by the last 40. That is not a minimax search.

### [1:26:39](https://www.youtube.com/watch?v=kZ_AUmFcZtk&t=5199s) Simulation-based search, and the first hidden information
Self-play games played out from the current position give Monte Carlo tree search; UCT, a UCB bandit (lecture 9) at each node, converges on minimax values. Maven (1:31:44) scored each Scrabble word by short rollouts plus a learned value of its leftover letters, and beat champion Adam Logan with MOUTHPART. But it drew the opponent's hidden rack at random, ignoring what the opponent's plays reveal (1:39:43).
**On the island:** no bot rolls out futures, but the blind runner shares Maven's shortcut: one table averaging over wherever the blocker tends to stand, with no update on clues during an episode.

### [1:40:21](https://www.youtube.com/watch?v=kZ_AUmFcZtk&t=6021s) Imperfect information: one search tree per player, and an average to aim at
In poker each player needs her own tree over information states. An information state summarises what one player knows (her cards, what she has seen), and many real states share one (1:43:28, and the slide). Naive MCTS here "blows up. It doesn't work. It diverges." (1:42:13). Smooth UCT borrows fictitious play: respond to the opponent's average behaviour so far, not her current one, so the sides stop chasing each other.
`pi_avg(a|s) = N(s,a) / N(s);  A ~ UCT(S) with probability eta, else pi_avg(.|S)`
In words: the share of times each action was taken is the average strategy; act by UCT some of the time and by that average otherwise.
It found the equilibrium in small poker games. The slide credits counterfactual regret minimization with near-perfect limit Hold'em; Silver, without naming it, describes Alberta's near-perfect player (1:45:20), which the self-play agent could not beat head to head but outscored at the competition by exploiting other entrants.
**On the island:** the blind runner against the learning blocker is this case. Her information state is her square; the true state adds the blocker's row. She bumped 0.47 times per episode, against 0.20 with a fixed blocker. The blocker chases recent results, the kind Smooth UCT calms; no averaging was run.

### [1:47:03](https://www.youtube.com/watch?v=kZ_AUmFcZtk&t=6423s) The recipe, and a warning about it
Game after game: binary features, a mostly linear value function, a TD-family algorithm, self-play, and search on top. Then he says to "question our assumptions": he had argued Go needed search, until a deep network played as well as a million-simulation tree search with none (1:49:49). Search and knowledge trade off.
**On the island:** the island's row: squares, a table, Q-learning, a fixed or bandit opponent (not self-play), and no search.

## What the island measured for this lecture

| Condition | Runs | Runner's mean return, last 40 | Goal reached, last 40 | Bumps per episode | Blocker's share of rows 0-3, last third |
|---|---|---|---|---|---|
| Runner blind, blocker fixed | 1 | -14.0 | 70% | 0.20 | [1.0, 0.0, 0.0, 0.0] |
| Runner blind, blocker learns | 2 | -46.1 | 41% | 0.47 | [0.18, 0.0, 0.06, 0.76] |
| Runner sees, blocker fixed | 5 | -35.1 | 48% | 0.22 | [1.0, 0.0, 0.0, 0.0] |
| Runner sees, blocker learns | 4 | -66.4 | 29% | 0.46 | [0.36, 0.28, 0.14, 0.21] |

All exploratory: 12 nine-minute runs (66 to 99 training episodes, 40-step limit), nothing planned in advance, no intervals, runners still early in learning. In both pairings a learning blocker cost the runner more than a fixed one and about doubled the bumps, and the seeing runner did worse than the blind one. One untested reading: 192 states instead of 48 means a quarter of the visits per state. The blocker's spread against the seeing runner looks like mixing, but 4 runs cannot tell an equilibrium from noise. The build shows no Nash equilibrium, minimax, self-play or search: the blocker decides once per episode, so this is two learners with opposite rewards, not a game played move by move. Unblocked Q-learning's 7.5 came from longer runs with a 100-step limit and is not comparable.

## Guess first

<details><summary>The seeing runner is told the blocker's row; the blind runner is not. In nine-minute runs, which scores higher?</summary>
The blind one, in both pairings (-14.0 against -35.1, and -46.1 against -66.4). Information pays only once learned, and 192 states each need their own visits. It is lecture 6's trade: a richer state is more exact and slower to fill (exploratory, few runs).
</details>

<details><summary>The blocker always stands in the edge row. Is the blind runner's problem a game or an MDP?</summary>
An MDP. A fixed opponent folds into the dynamics (13:17), so Q-learning seeks a best response, and her square is a complete state because the blocker never moves. It becomes a game once the blocker can choose.
</details>

<details><summary>TD-Gammon learned greedily with no exploration. Would a greedy Q-learner starting from zeros manage that on the island?</summary>
Probably not: the island has no dice to push play around (0.21 slips per 1,000 steps), so a greedy learner repeats herself. No greedy zero-start bot was run. Q + OPTIMISM is greedy yet explores, because every Q starts at 40 (lecture 9).
</details>

<details><summary>TreeStrap learns from its own search and DYNA-Q from imagined steps (lecture 8). What keeps either from drifting into fantasy?</summary>
Real outcomes. Silver's answer on convergence (1:25:48) is grounding in games played to a real end. DYNA-Q's model is built only from real steps; her imagined updates sped early learning but did not cut falls.
</details>

<details><summary>Your opponent always plays rock. Should you play the rock, paper, scissors equilibrium?</summary>
No, if beating this opponent is the goal. The equilibrium cannot be exploited but wins nothing on average against always-rock, while always-paper wins every round. Silver's poker result turns on the same gap: the self-play agent won more by exploiting weaker entrants.
</details>

<details><summary>Plain MCTS diverged on poker. What change made Smooth UCT converge?</summary>
Answering the opponent's average behaviour instead of her current one (fictitious play). Chasing the current policy circles: paper chases rock and is chased by scissors. The average moves slowly and settles. The island's blocker chases recent results.
</details>

## Cards

- Q: Best response? | A: The optimal policy against fixed opponents: the optimal policy of the MDP made by folding them into the environment.
- Q: Nash equilibrium? | A: A joint policy where each player's policy is a best response to the others.
- Q: Rock, paper, scissors equilibrium? | A: Each move one third of the time.
- Q: Self-play and Nash? | A: A fixed point of self-play learning is a Nash equilibrium (Littman, table lookup).
- Q: Minimax value? | A: The outcome under perfect play by both sides; unique in two-player zero-sum perfect-information games, and its policy is Nash.
- Q: Afterstate? | A: The position a move leads to; with known deterministic rules a move is worth its afterstate.
- Q: TD root, TD leaf, TreeStrap? | A: Value toward next search; search toward next search; every node of one search toward its deeper value.
- Q: Why did Smooth UCT converge? | A: It mixes UCT with the opponent's average strategy, which stops the chase.

## In language-model terms

A tool-using model on tau-bench talks to a simulated customer. With the simulator fixed, this is exactly Silver's best-response case: the customer is part of the environment, and training learns a best response to that one simulator, which is not the same as learning customers. A different simulated customer is the nearest thing to an exploitability check.

The game picture stops there. Customer service is not zero-sum, so minimax fits only red-team tests with an adversarial user, and self-play is only an analogy, though two models trained against each other can cycle as Silver's poker players did.

Search maps more directly. Sampling continuations, scoring them and keeping the best is simulation-based search. But a real customer cannot be rolled out, so the search samples a model of one, like Maven sampling the rack, and inherits Maven's flaw if it ignores what the conversation revealed. A verifier trained on search outcomes is TreeStrap's idea and needs the same grounding.

## The thread to partial observability

This lecture names the hidden-state case. In imperfect-information games the tree is built over information states, what one player knows, each shared by many real states (1:43:28). Maven guessed the hidden rack at random and ignored what play revealed (1:39:43): the gap between one guess and a belief, a probability over hidden states updated from history. Poker adds an opponent who chooses the hidden thing and exploits predictability, so the answer was an average strategy. The blind runner facing a learning blocker sits exactly here. Carry forward: information state against true state, belief built from history, and the cost of ignoring clues within an episode. The hidden-wall build, now running, gives the runner the smallest such memory.

## Experiments the lecture asks for that the island has not run

- Minimax by planning: solve the strip per blocker row; the worst row is the seeing game's value.
- Exploitability: freeze each trained bot and train a fresh opponent against her.
- True self-play: one program plays both sides.
- Fictitious-play blocker: respond to the runner's average, to see whether the chase stops.
- TD-leaf runner: two-step look-ahead targets against plain Q-learning.
