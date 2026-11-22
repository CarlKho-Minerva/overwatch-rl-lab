# Lecture 10: Classic Games

*David Silver's lecture 10 (UCL, 2015), gone through in his order and re-explained with the Tracer experiments on Workshop Island. The lecture and its slides are his: [video](https://www.youtube.com/watch?v=kZ_AUmFcZtk), [course page](https://davidstarsilver.wordpress.com/teaching/). The words below are a re-explanation. Every island number comes from the logged runs in this repository.*

You are Tracer with two ways to peek a Widowmaker, the fast left flank or the safe right corner, while she scopes one of them, and every point you win is a point she loses. For nine lectures nothing on the island had a plan of its own; for this last one a blocker from the other team stands in one of the four rows, and her score is the runner's loss. The hour asks what "best" means when the other side is choosing too, and for a two-player game where one side's gain is the other's loss Silver's answer is a pair of rules for choosing moves, called policies, that neither side would change on its own. The programs that came closest play against themselves, learn a score for each position (a value function) by temporal-difference learning (TD), which corrects each guess with the next one, and use it inside a search.

**Two windows:** this page, and [Game 10: The Peek](../workshop/games/g10.md), an Overwatch custom game for this lecture (paste `workshop/compiled/game-10.txt` into a custom game's settings and start it). The game opens at stop 1 and waits. Read down this page; at each box marked Alt+Tab, switch to the game, do that stop, and switch back. The game never moves on while you read.

## The lecture in order

### [02:38](https://www.youtube.com/watch?v=kZ_AUmFcZtk&t=158s) Games are small worlds with simple rules and deep play
The rules of chess fit in a paragraph or two, and people have still spent hundreds of years working out how to play it well. Silver opens with that as his reason for studying games: the rules are simple and the play is deep. Games also come with human experts who have given decades to them, so a program can be measured against the best people there are.

A game can also isolate one hard feature of the real world. His example is a game where a player cannot see everything, which is called hidden information. The game keeps that one difficulty and strips everything else down to simple rules.

Then he shows two slides. The first gives the best level any program has reached in seven classic games: checkers, chess, Othello, backgammon, Scrabble, Go and poker. The second gives the level reached by programs that learned from reward by trial and error, which is reinforcement learning. In five of the seven the two slides match. Chess is the weakest case, and even there a learning program reached international master.

**On the island:** the two-player build is the only part of the lab that is a game in Silver's sense: two sides who want opposite things.

### [08:01](https://www.youtube.com/watch?v=kZ_AUmFcZtk&t=481s) Against a fixed opponent, "best" is a best response
If your opponent in rock, paper, scissors always plays rock, you play paper every time. Against one who always plays paper you would do something else. Silver starts here: in a game, the best way to play depends on how the others play.

That was not so before. Every earlier lecture had one learner alone in its world, a setting called a Markov decision process, or MDP. There the best rule for choosing a move, the optimal policy, was the one that collects the most reward.

So he takes the easy case first: the other players never change how they play. The best policy against them is called the best response. Against always-rock it is always-paper.

An opponent who never changes is, to the learner, part of the world. Silver folds her into the rules for what happens after each move, the environment's dynamics, and the game becomes an ordinary MDP whose optimal policy is the best response (13:17). A student asks whether the course assignment, Easy21, did this with its dealer. Silver says yes (18:05).

> **Alt+Tab · game 10 · stop 1 of 6: Peek a Widowmaker who never moves**
>
> **What he just said:** Against an opponent who never changes, the best you can do is answer her habit: fold her into the world and solve it like any one-player problem.
>
> **In the game:** A question at the top asks which peek wins the most against a Widowmaker who always holds the right corner; answer with LEFT CLICK, RIGHT CLICK or MELEE. Then the game waits for 4 peeks: LEFT CLICK peeks the left corner, RIGHT CLICK the right one.
>
> **Before you press:** Against someone who always holds right, should you mix your peeks or take one corner every time?
>
> <details><summary>Back from the game: what you just saw</summary>She never looked left, so every left peek was clean and paid 3. Her habit made the problem one-sided, and one pure answer beats any mix against it. That answer is called a best response: the best plan against an opponent who stays fixed, who is then simply part of the map. <em>In an agent:</em> An agent tuned against one fixed simulated customer is learning a best response to that simulator.</details>

**On the island:** the "fixed" blocker always stands in the edge row, so she is part of the environment, and the runner's Q-learning is looking for a best response. The one blind run against her (the runner is not told the blocker's row) ended at a mean return of -14.0 over its last 40 episodes, reaching the goal 70% of the time.

### [10:25](https://www.youtube.com/watch?v=kZ_AUmFcZtk&t=625s) A Nash equilibrium is where nobody wants to change alone
Always playing paper beats an opponent who always plays rock, but only until she changes. If she switches to scissors, always-paper loses every round. The best answer to one opponent is not yet the best way to play the game.

Silver's standard for that is a set of plans, one for each player, in which every plan is already the best answer to all the others, so nobody would gain by changing alone. A rule for every player at once is called a joint policy, and one in which each player's policy is a best response to the others is a Nash equilibrium. `pi^i = pi*^i(pi^-i)`. In words: every player's policy is the best response to everyone else's, all at once.

In rock, paper, scissors the equilibrium is to play each move one third of the time. Stray from that, and the other player can find a way to exploit it.

A student asks whether there is only one equilibrium. In general, no (17:21). But in the games this lecture mostly studies, where two players see everything and one side's gain is the other's loss, the worth of a position under best play by both sides is unique (25:09). That worth is called the minimax value.

**On the island:** Not run on the island. The experiment would freeze each trained bot and train a fresh opponent against her: if neither fresh opponent does better, the pair is near an equilibrium.

### [13:17](https://www.youtube.com/watch?v=kZ_AUmFcZtk&t=797s) The equilibrium is where a learner playing itself comes to rest
Picture two players who keep adjusting to each other: one finds a better counter, the other has to counter that, and so on. Silver uses this chase to explain how a program could learn its way to the set of plans nobody would change alone, the Nash equilibrium.

Put one learner in control of every player and let it learn from the games it plays against itself. This is called self-play. Each side keeps learning the best answer to how the other side plays now, its best response, and every improvement on one side changes the problem the other is solving.

If the chase ever stops, it has stopped at a Nash equilibrium, because by then each side is already giving the best answer to the other. Silver warns that it may not stop. But he cites Michael Littman's thesis for one solid result: standard methods such as Q-learning, which learns a score for each move from experience, do settle there (converge) when they keep one stored number per state, which is called table lookup.

> **Alt+Tab · game 10 · stop 2 of 6: Peek a Widowmaker who learns you**
>
> **What he just said:** When both sides learn, each improvement changes the other side's problem, and the place where that chase comes to rest, if it does, is an equilibrium.
>
> **In the game:** A question asks for her best answer if you always peeked left. Then the game waits for 5 peeks, LEFT CLICK or RIGHT CLICK, against a new Widowmaker who watched your first 4. The red bar on the right shows her odds of aiming left before each peek.
>
> **Before you press:** If you peeked left every time, where should she aim?
>
> <details><summary>Back from the game: what you just saw</summary>Half the time she aims where your habit says you go; the other half she repeats her own past aims. If your first 4 peeks were left, her odds opened high on the left, so the habit that won stop 1 was the first thing she punished. Watch her red bar after you switch sides: when the opponent learns, the target you are aiming at moves. <em>In an agent:</em> A model trained hard against one user simulator learns that simulator's habits, and a different simulator can punish them.</details>

**On the island:** the same chase, without self-play: the runner (Q-learning) and the blocker (a four-armed bandit, which keeps one running score per row) are different programs. Against a blind runner the learning blocker ended in the far inland row 76% of the time, and the runner's return was -46.1, against -14.0 with a fixed blocker (2 runs and 1, exploratory).

### [18:53](https://www.youtube.com/watch?v=kZ_AUmFcZtk&t=1133s) Two players, opposite rewards, and who sees what
In chess two players take turns, and whatever helps one of them hurts the other by the same amount. From here on Silver studies only games of that kind. He calls the players white and black whatever the game is.

A game where what is good for one side is equally bad for the other is called zero-sum. It means the score for how good a position is, the value function of earlier lectures, does not have to be kept twice. `R1 + R2 = 0`. In words: the rewards add to zero, so one value function, negated, serves both sides.

He then sorts games by what the players can see. In some, both players see the whole situation, the state of the game: chess, Go, and backgammon, whose dice add chance but hide nothing. These are perfect-information games. In others part of the state is hidden from a player, such as the opponent's Scrabble letters or the opponent's poker cards (21:05). These are imperfect-information games.

Most of the hour stays with the first kind, and the hidden kind returns at the end.

> **Alt+Tab · game 10 · stop 3 of 6: Find the peek she cannot read**
>
> **What he just said:** In some games part of the state is hidden, like the cards in a poker hand, and there a player whose choices can be predicted can be exploited.
>
> **In the game:** Two questions wait at the top. The first, through lecture 7's rock, paper, scissors, asks whether any fixed pattern of peeks is safe (LEFT CLICK or RIGHT CLICK). The second asks whether the safe mix peeks left more or less than half the time (LEFT CLICK, RIGHT CLICK or MELEE).
>
> **Before you press:** Left pays more when it works; does the safe mix use it more than half the time, or less?
>
> <details><summary>Back from the game: what you just saw</summary>Any fixed pattern can be counted and punished, so the safe plan is random on purpose, as lecture 7's policies were. It peeks left only 2 times in 7, the share at which both of her aims pay her the same, so studying you gains her nothing. A plan that rolls dice on purpose like this is called a mixed strategy.</details>

**On the island:** the blocker's score is the runner's return with the sign flipped, so the build is exactly zero-sum, though the two do not take turns. The "sees" runner is told the blocker's row. The "blind" runner is not, so she plays an imperfect-information game.

### [21:40](https://www.youtube.com/watch?v=kZ_AUmFcZtk&t=1300s) Minimax: assume the other side always answers with its best move
Before a move in chess you ask what your opponent will do about it, and the safe assumption is that she finds her best reply. Silver defines the worth of a position on that assumption.

Take a score for a position, and let white do everything possible to raise it while black does everything possible to lower it. What comes out is called the minimax value. `v*(s) = max over pi1, min over pi2, of v_pi(s)`. In words: the value of a position under perfect play by both sides, taken in turn order (25:50). Playing that way is a Nash equilibrium, since neither side would change alone.

Finding it takes a search that follows every line of play to the end of the game and passes the results back up. This is minimax search, first described by Claude Shannon, who ran his chess program on paper. In Silver's worked tree (27:39), with players called max and min, max takes the larger of each pair of final scores (+7, -2, +9, -4), min takes the smaller of each two of those (-2, -4), and max takes the larger again, so the starting position, the root, is worth -2 and max opens with a1.

> **Alt+Tab · game 10 · stop 4 of 6: Peek by the die**
>
> **What he just said:** The minimax value is what a game is worth when each side plays its best against the other's best, and in a two-player game where one side's gain is the other's loss, the plans that reach it form an equilibrium.
>
> **In the game:** A question asks what you can expect per peek against a perfect Widowmaker. Then the game waits for 5 more peeks, LEFT CLICK or RIGHT CLICK, while the right side shows what a die says each time (LEFT 2 times in 7). Follow it or not.
>
> **Before you press:** Against a perfect Widowmaker, is the most you can expect per peek nothing, a little, or about a point?
>
> <details><summary>Back from the game: what you just saw</summary>With the 2 in 7 mix you win 1/7 of a point a peek on average, whatever she does, and a perfect Widowmaker can hold you to no more. That number is the minimax value of the game. Look at how often you followed the die rather than at your total: 5 peeks are far too few for 1/7 a peek to show through the luck.</details>

**On the island:** Not run on the island. Solving the strip once per blocker row and letting the blocker take the worst row for the runner would give the seeing game's minimax value.

### [29:56](https://www.youtube.com/watch?v=kZ_AUmFcZtk&t=1796s) Cut the search short and score the stopping points with an estimate
Nobody can follow every line of chess to the end of the game, because the tree of possibilities multiplies with every move you look ahead. Real programs look a few moves ahead and stop. At each stopping point they put an estimate of how good that position is, which is the value function of earlier lectures in a new job. The search is also sped up by skipping branches that neither player would ever choose, a method called alpha-beta pruning (31:53).

The classic value function asks a list of yes-or-no questions about the position, such as "white has a rook". Each question is a feature, and each feature has a weight, a number for how much a yes is worth. The form is called binary-linear. `v(s, w) = x(s) . w`. In words: add up the weights of the features switched on in this position.

Two famous programs were built this way. Deep Blue (36:15) used 8,000 hand-made features with weights tuned by grandmasters, searched 200 million positions a second, and beat Kasparov in 1997 with no learning. Chinook (38:19), a checkers program, added stored tables of endgame positions it could play perfectly. It won two of the only seven games Marion Tinsley lost in his whole checkers career, and later solved checkers (2007).

**On the island:** PLANNER is the island's Chinook: the strip is small enough to solve outright (13 sweeps, no falls in 10 runs).

### [42:24](https://www.youtube.com/watch?v=kZ_AUmFcZtk&t=2544s) Learning by self-play is the same code as before, plus afterstates
A program that plays both sides of a game can learn with the methods from earlier lectures. Silver says the code does not even have to change. One learner playing against itself is called self-play, and what it learns is still a score for each position, the value function.

All three learning rules carry over, and each works by adjusting the weights the score is built from. Monte Carlo moves the score toward who really won the game. TD(lambda) covers the range between that and TD(0), which moves the score toward the program's own guess one move later. `Delta w = alpha (v(S_t+1, w) - v(S_t, w)) grad_w v(S_t, w)`. In words: if one move later you expect a different result, nudge the weights toward the newer guess.

One step does change. When the program improves its rule for choosing a move, its policy, white picks the move with the highest value and black the move with the lowest.

Games allow a shortcut too. When the rules are known and a move always leads to the same position (deterministic rules), a move needs no score of its own. You score the position it leads to, called the afterstate (44:55). `q*(s, a) = v*(succ(s, a))`. In words: a move is worth what the position it creates is worth.

**On the island:** the island is nearly deterministic (0.21 slips per 1,000 steps), and PLANNER already picks moves by the value of the square each reaches. No learning bot uses afterstates.

### [47:37](https://www.youtube.com/watch?v=kZ_AUmFcZtk&t=2857s) Logistello and TD-Gammon: self-play that reached the top
Two programs taught themselves a board game by playing it against themselves, and both ended up stronger than the best human players.

The first, Logistello, played Othello. It found its own features: 1.5 million patterns of stones, each a yes-or-no fact with a weight. It learned the weights in a loop of playing a batch of games against itself, scoring each position by who went on to win (a Monte Carlo target), and choosing moves by the new scores. This is policy iteration by self-play. It searched before every move, and it beat the human world champion, Takeshi Murakami, 6-0.

The second, TD-Gammon (52:38), played backgammon. It trained a small neural network from random weights by playing itself and correcting each guess toward the next one (self-play TD). It always took the move that looked best, which is called greedy, and it never explored.

Silver asks why that worked, and both answers are the dice. They push play into every kind of position (56:31), and they smooth the learned score for each position, the value function (57:44). In chess and checkers the same recipe never settled (it diverged). Even TD-Gammon reached superhuman play only with a 3-ply (three-move) search on top.

**On the island:** there are no dice, so a greedy learner has to be pushed to explore. Greedy Q + OPTIMISM (every Q starts at 40) fell 7.2 times per 100 episodes, against 26.5 for Q-learning (exploratory).

### [1:02:20](https://www.youtube.com/watch?v=kZ_AUmFcZtk&t=3740s) Let the search tell the learner what to aim for
Counting rooks and bishops will not tell you that a checkmate is coming. Looking ahead will. This is why plain TD, which corrects one quick guess with the next quick guess, did poorly in chess: the tactics are invisible without search.

Until now the programs learned their quick score for a position, the value function, first and searched with it afterwards. Silver asks whether the search can improve the learning itself, and gives two ways.

The older way comes from Arthur Samuel's 1959 checkers player (1:07:47). After a move, the program runs a deep search from the new position and moves its quick score for the previous position toward what the search found. Silver calls this TD root.

The second way takes the whole search result at one move and pushes it toward the search result at the next. It is called TD leaf (1:08:38). `v+(S_t, w) <- v+(S_t+1, w)`. In words: push this move's search result toward the next move's (the plus means "after searching"). Only one number has to change: the score of the end position the search settled on, called the principal leaf. A chess program called KnightCap (1:18:04) reached master level this way, but it needed an expert opponent and had to be told what the pieces are worth.

**On the island:** Not run on the island. A runner with a two-step look-ahead, learning toward that look-ahead value, would be the test.

### [1:20:26](https://www.youtube.com/watch?v=kZ_AUmFcZtk&t=4826s) TreeStrap: every node of one search becomes a lesson
One search looks at millions of positions and works out a value for every one of them. The two methods before this kept a single value from each search and threw the rest away. Silver, with Joel Veness, built a method that uses them all, called TreeStrap.

It needs only one search. For every position inside it, the program compares its quick score with what the search found by looking deeper from that position, and moves the quick score toward the deeper answer. `v(s, w) <- v+(s, w)`. In words: teach the quick guess at each position to predict a deeper search from there.

A chess program called Meep learned this way. It started from random weights (the numbers its score is built from), played only against itself, and won 13 of 15 games against international masters.

Asked whether any of this is sure to settle, Silver answers with a warning (1:25:48). A program that learns only from its own search drifts from reality, so "you have to ground it" in games played to a real end.

**On the island:** DYNA-Q learns from imagined steps, and they are grounded because her model is built from real ones. Her return over the first 40 episodes beat Q-learning's by 25.98 (15.53 to 36.25, exploratory), and the two were level by the last 40. That is not a minimax search.

### [1:26:39](https://www.youtube.com/watch?v=kZ_AUmFcZtk&t=5199s) Search by playing games out, and the first hidden information
There is another way to judge a move: imagine playing the rest of the game many times and see how it tends to end. Silver comes back to this kind of search, with the program now playing both sides of every imagined game.

Done with care, those imagined games grow into a tree of positions, a method called Monte Carlo tree search. Its most successful version puts a bandit, the slot-machine problem of lecture 9, at every position in the tree, and uses that lecture's UCB rule to pick which move to try next. This version is called UCT. In self-play its values settle on what each position is worth under best play by both sides, the minimax values.

Sometimes a simpler search is enough. Maven (1:31:44), a Scrabble program, scored each word it could play by short imagined games, called rollouts, plus a learned value for the letters left on its rack. It beat the champion Adam Logan with the word MOUTHPART.

Scrabble hides something, though: the opponent's rack. Maven drew those letters at random and ignored what the opponent's plays reveal about them (1:39:43).

**On the island:** no bot plays out imagined futures. But the blind runner shares Maven's shortcut: she keeps one table that averages over wherever the blocker tends to stand, and she does not update on clues during an episode.

### [1:40:21](https://www.youtube.com/watch?v=kZ_AUmFcZtk&t=6021s) Hidden cards: one search tree per player, and an average to aim at
In poker you cannot see the other player's cards. Silver says that Monte Carlo tree search (MCTS), the last part's search by imagined games, applied naively to such a game "blows up. It doesn't work. It diverges." (1:42:13).

The repair borrows an idea from game theory: respond to the opponent's average behaviour so far, not her current one, so the two sides stop chasing each other. The idea is called fictitious play, and the search built on it is Smooth UCT. `pi_avg(a|s) = N(s,a) / N(s);  A ~ UCT(S) with probability eta, else pi_avg(.|S)`. In words: the share of times each action was taken is the average strategy; act by UCT some of the time and by that average otherwise. In small poker games it found the equilibrium, where neither side gains by changing.

Each player also needs her own tree, built over what she knows: her cards and what she has seen. That summary is called an information state, and many real states share one (1:43:28, and the slide).

The slide credits a method named counterfactual regret minimization with near-perfect limit Hold'em. Silver does not name it, but he describes Alberta's near-perfect player (1:45:20), which the Smooth UCT agent could not beat head to head but outscored at the competition by exploiting other entrants.

> **Alt+Tab · game 10 · stop 5 of 6: Start two learners, watch the averages**
>
> **What he just said:** In poker, search that chased the opponent's latest move went round in circles, and the fix was to answer her average behaviour so far, an idea called fictitious play.
>
> **In the game:** A question asks what two learners settle into (LEFT CLICK, RIGHT CLICK or MELEE). Then press F (INTERACT) to start 300 peeks of a learning Tracer bot against a learning Widowmaker, shown every 20 peeks on the two bars while the Widowmaker turns to the side she picks.
>
> **Before you press:** After 300 peeks of two learners answering each other, do they lock onto one corner, settle near the safe mix, or never settle?
>
> <details><summary>Back from the game: what you just saw</summary>Each bot plays the best answer to the other's average so far. Their actual choices kept flipping (the Tracer switched 12 times), yet the averages ended at 28% and 55% left, close to the safe 29% and 57%. A pair of plans where neither side gains by changing alone is a Nash equilibrium, and learning by playing a learning opponent is self-play. <em>In an agent:</em> Two models trained against each other can circle the same way, which is why averaging over past opponents is a common fix.</details>

**On the island:** the blind runner against the learning blocker is this case. Her information state is her square; the true state adds the blocker's row. She bumped 0.47 times per episode, against 0.20 with a fixed blocker. The blocker chases recent results, the kind of chasing Smooth UCT calms; no averaging was run.

### [1:47:03](https://www.youtube.com/watch?v=kZ_AUmFcZtk&t=6423s) The recipe, and a warning about it
Silver ends with one slide that lines up every program from the hour and asks what they share. The same ingredients come up in game after game.

Every program described a position with yes-or-no facts about it, the binary features. On top of those sat a score for the position, a value function; in most it was a weighted sum of the features (a linear function), and TD-Gammon's neural network was the exception. The score was learned with an algorithm from the TD family, which for Silver takes in Monte Carlo, TD leaf and TreeStrap as well as plain TD. Each program trained against itself, by self-play, and each ran a search on top.

Then he tells the room to "question our assumptions". He had argued for years that Go needed search. Then a deep neural network, with no search at all, played Go as well as a tree search running a million simulations (1:49:49).

His closing point is that search and knowledge trade off. A program can put more knowledge into its value function or it can search deeper, and he counts both as ways to make progress.

> **Alt+Tab · game 10 · stop 6 of 6: Read the debrief**
>
> **What he just said:** Silver sums up the recipe behind the strong game programs (simple features, a learned value, self-play and search on top) and warns that search and knowledge trade off, so the assumptions deserve questioning.
>
> **In the game:** Press F (INTERACT) for the debrief. Three lines appear on the left, with your prediction score and your points for the 14 peeks.
>
> **Before you press:** Before you press, decide which of your three opponents taught you the most about the game itself, and which only about her.
>
> <details><summary>Back from the game: what you just saw</summary>You met three opponents: a fixed one, beaten by a best response; a learner, who punished your habits; and a perfect one, held off only by the minimax mix. This game is one two-by-two choice replayed, with no positions, no search tree and no learned value, which is where Silver's programs did their real work. <em>In an agent:</em> Testing an agent against one fixed simulated user measures how well it learned that user; a second, different simulator is the nearest thing to checking whether it can be exploited.</details>

**On the island:** the island's row on that slide would read: squares as the features, a table as the value function, Q-learning, a fixed or bandit opponent (not self-play), and no search.

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
