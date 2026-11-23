# Lecture 10: Classic Games

*David Silver's lecture 10 (UCL, 2015), gone through in his order and re-explained with the Tracer experiments on Workshop Island. The lecture and its slides are his: [video](https://www.youtube.com/watch?v=kZ_AUmFcZtk), [course page](https://davidstarsilver.wordpress.com/teaching/). The words below are a re-explanation. Every island number comes from the logged runs in this repository.*

You are Tracer, about to peek a Widowmaker. Left is the fast flank, right is the safe corner, she is scoped on one of them, and every point you win is a point she loses. She is thinking about you as hard as you are thinking about her. For nine lectures nothing on the island had a plan of its own; in this last one, a blocker from the other team stands in one of the four rows, and her score is the runner's loss. So the hour asks what "best" even means when the other side is choosing too. For a two-player game where your gain is her loss, Silver's answer is a pair of rules for choosing moves, called policies, that neither side would change on its own. The programs that came closest played against themselves, learned a score for each position (a value function) by temporal-difference learning (TD, which corrects each guess with the next one), and used that score inside a search.

**Two windows:** this page, and [Game 10: The Peek](../workshop/games/g10.md), an Overwatch custom game for this lecture (paste `workshop/compiled/game-10.txt` into a custom game's settings and start it). The game opens at stop 1 and waits. Read down this page; at each box marked Alt+Tab, switch to the game, do that stop, and switch back. The game never moves on while you read.

## The lecture in order

### [02:38](https://www.youtube.com/watch?v=kZ_AUmFcZtk&t=158s) Simple rules, deep play, and a scoreboard of champions
You can learn the rules of Overwatch in a minute (stand on the point, do not die) and spend years learning to play it.

Silver says the same about chess: its rules fit in a paragraph or two, and people have spent hundreds of years learning to play it well. That is why he studies games. They also come with experts who have given decades to them, so you can measure a program against the best people there are.

A game can also isolate one hard feature of the real world and keep the rest simple. His example: you cannot see everything, which is called hidden information.

Two slides follow. The first gives the best level any program has reached in seven classic games: checkers, chess, Othello, backgammon, Scrabble, Go and poker. The second gives the level reached by programs that learned from reward by trial and error, which is reinforcement learning.

In five of the seven, the learners matched the best program of any kind.

Chess is the weakest case, and even there a learning program reached international master.

**On the island:** the two-player build is the only part of the lab that is a game in Silver's sense: two sides who want opposite things.

### [08:01](https://www.youtube.com/watch?v=kZ_AUmFcZtk&t=481s) Against a Widowmaker who never moves, peek the other side
Sooner or later you meet a Widowmaker who holds the same sightline every round. Against her you need no theory: peek the other side, every time.

Silver starts with rock, paper, scissors. Against always-rock you play paper every time; against always-paper you would do something else. In a game, the best way to play depends on how the others play.

That never came up before. Every earlier lecture had one learner alone in its world, a Markov decision process, or MDP, where the best rule for choosing moves, the optimal policy, collects the most reward.

So he takes the easy case first: opponents who never change. The best policy against them is called the best response. Against always-rock, it is always-paper.

To you, an opponent who never changes is part of the map, like a turret.

Silver folds her into the environment's dynamics, the rules for what happens after each move, and the game becomes an ordinary MDP whose optimal policy is the best response (13:17). Asked whether the course assignment, Easy21, did this with its dealer, he says yes (18:05).

> **Alt+Tab · game 10 · stop 1 of 6: Peek a Widowmaker who never moves**
>
> **What he just said:** An opponent who never changes is not really an opponent. She is part of the map, like a turret. Silver folds her into the world and solves it like any one-player problem: you just answer her habit.
>
> **In the game:** A question at the top asks which peek wins the most against a Widowmaker who always holds the right corner; answer with LEFT CLICK, RIGHT CLICK or MELEE. Then the game waits for 4 peeks: LEFT CLICK peeks the left corner, RIGHT CLICK the right one.
>
> **Before you press:** Against someone who always holds right, should you mix your peeks or take one corner every time?
>
> <details><summary>Back from the game: what you just saw</summary>She never looked left, so every left peek was clean and paid 3. Against a habit like that, mixing only wastes peeks: one pure answer beats any mix. Silver calls it a best response, the best plan against an opponent who stays fixed. She was never really an opponent, just a turret with a scope. <em>In an agent:</em> Tune an agent against one fixed simulated customer and it learns a best response to that simulator: one Widowmaker's favourite angle, not customers in general.</details>

**On the island:** the "fixed" blocker always stands in the edge row, so she is part of the environment, and the runner's Q-learning is looking for a best response. The one blind run against her (the runner is not told the blocker's row) ended at a mean return of -14.0 over its last 40 episodes, reaching the goal 70% of the time.

### [10:25](https://www.youtube.com/watch?v=kZ_AUmFcZtk&t=625s) Nash equilibrium: the point where nobody wants to switch alone
Then the Widowmaker notices. You peeked left four rounds running, and now she is scoped left before you get there.

Always-paper beats always-rock only until she changes. If she switches to scissors, always-paper loses every round. The best answer to one opponent is not yet the best way to play the game.

So Silver asks for more: a set of plans, one per player, in which every plan is already the best answer to all the others. A rule for every player at once is called a joint policy, and one where each player's policy is a best response to the rest is a Nash equilibrium.

Nobody gains by changing alone, so nobody does.

<details markdown="1"><summary>The formula, when you want it</summary>

`pi^i = pi*^i(pi^-i)`. In words: every player's policy is the best response to everyone else's, all at once.

</details>

In rock, paper, scissors the equilibrium is each move one third of the time. Lean on any one of them and the other player can exploit it.

A student asks whether there is only one. In general, no (17:21). But in the games this lecture mostly studies, where two players see everything and one side's gain is the other's loss, the worth of a position under best play by both sides is unique (25:09). That worth is called the minimax value.

**On the island:** Not run on the island. The experiment would freeze each trained bot and train a fresh opponent against her: if neither fresh opponent does better, the pair is near an equilibrium.

### [13:17](https://www.youtube.com/watch?v=kZ_AUmFcZtk&t=797s) The counter-swap spiral, and where it comes to rest
You know the counter-swap spiral. They go Pharah, you go Soldier. They go Winston to dive your Soldier, you go Reaper. Nobody ends up on the hero they wanted.

Silver uses a chase like that to explain how a program could learn its way to a Nash equilibrium.

Put one learner in charge of every player and let it learn from games against itself. This is called self-play. Each side keeps learning its best response to the other side as it plays right now, so every improvement on one side changes the problem the other is solving.

If the chase ever stops, it has stopped at a Nash equilibrium. Nobody is swapping, because each side is already giving the best answer to the other.

Silver warns that it may never stop.

He does cite one solid result, from Michael Littman's thesis: standard methods such as Q-learning, which learns a score for each move from experience, do settle there (converge) when they keep one stored number per state, which is called table lookup.

> **Alt+Tab · game 10 · stop 2 of 6: Peek a Widowmaker who learns you**
>
> **What he just said:** Now both sides learn. Every time you get better, her problem changes, and every time she gets better, yours does. If that chase ever comes to rest, Silver says, the resting place is an equilibrium.
>
> **In the game:** A question asks for her best answer if you always peeked left. Then the game waits for 5 peeks, LEFT CLICK or RIGHT CLICK, against a new Widowmaker who watched your first 4. The red bar on the right shows her odds of aiming left before each peek.
>
> **Before you press:** If you peeked left every time, where should she aim?
>
> <details><summary>Back from the game: what you just saw</summary>Half the time she aims where your habit says you go; the other half she repeats her own past aims. If your first 4 peeks were left, her odds opened high on the left, so the habit that won stop 1 was the first thing she punished. Switch sides and watch her red bar follow you. Against a learner, the target moves while you are aiming at it. <em>In an agent:</em> Train a model hard against one user simulator and it learns that simulator's habits. A different simulator can punish them, the way this Widowmaker punished your left peeks.</details>

**On the island:** the same chase, without self-play: the runner (Q-learning) and the blocker (a four-armed bandit, which keeps one running score per row) are different programs. Against a blind runner the learning blocker ended in the far inland row 76% of the time, and the runner's return was -46.1, against -14.0 with a fixed blocker (2 runs and 1, exploratory).

### [18:53](https://www.youtube.com/watch?v=kZ_AUmFcZtk&t=1133s) What you win, she loses, and who gets to see what
No ranked game has ever ended with both teams winning.

In chess, players take turns, and whatever helps one hurts the other by exactly as much. From here on Silver studies only games like that, and calls the players white and black whatever the game is.

Such a game is called zero-sum, and it saves you work: the score for how good a position is, the value function, need not be kept twice. Flip its sign and it serves the other side.

<details markdown="1"><summary>The formula, when you want it</summary>

`R1 + R2 = 0`. In words: the rewards add to zero, so one value function, negated, serves both sides.

</details>

Then he sorts games by what the players can see. In chess, Go and backgammon, both players see the whole situation, the state of the game. Backgammon's dice add chance but hide nothing. These are perfect-information games. (Think of Overwatch with every wall made of glass.)

In others, part of the state is hidden, like the opponent's Scrabble letters or poker cards (21:05). Overwatch is one of these: you never see the enemy Ana's ult charge. These are imperfect-information games.

Most of the hour stays with the first kind. The hidden kind comes back at the end.

> **Alt+Tab · game 10 · stop 3 of 6: Find the peek she cannot read**
>
> **What he just said:** Some games hide part of the state, like the cards in a poker hand. There, a player you can predict is a player you can exploit.
>
> **In the game:** Two questions wait at the top. The first, through lecture 7's rock, paper, scissors, asks whether any fixed pattern of peeks is safe (LEFT CLICK or RIGHT CLICK). The second asks whether the safe mix peeks left more or less than half the time (LEFT CLICK, RIGHT CLICK or MELEE).
>
> **Before you press:** Left pays more when it works; does the safe mix use it more than half the time, or less?
>
> <details><summary>Back from the game: what you just saw</summary>Any fixed pattern can be counted and punished, so the safe plan is random on purpose, as lecture 7's policies were. It peeks left only 2 times in 7: at that share both of her aims pay her the same, so studying you gains her nothing. Being unreadable is the whole trick. A plan that rolls dice on purpose like this is called a mixed strategy.</details>

**On the island:** the blocker's score is the runner's return with the sign flipped, so the build is exactly zero-sum, though the two do not take turns. The "sees" runner is told the blocker's row. The "blind" runner is not, so she plays an imperfect-information game.

### [21:40](https://www.youtube.com/watch?v=kZ_AUmFcZtk&t=1300s) Minimax: assume she always finds her best reply
Before you walk through a choke, you ask what the enemy will do about it. The safe assumption is the unpleasant one: their Zarya has been saving Graviton for exactly this moment.

Silver defines the worth of a position on that assumption. White does everything possible to raise the score and black everything possible to lower it, turn by turn. What comes out is the minimax value (25:50), the worth under perfect play by both sides, and playing that way is a Nash equilibrium, since neither side would change alone.

<details markdown="1"><summary>The formula, when you want it</summary>

`v*(s) = max over pi1, min over pi2, of v_pi(s)`. In words: the value of a position under perfect play by both sides, taken in turn order.

</details>

To find it, you follow every line of play to the end of the game and pass the results back up. This is minimax search, first described by Claude Shannon, who ran his chess program on paper.

Silver works one tree by hand (27:39), with players called max and min. Max takes the larger of each pair of final scores, leaving +7, -2, +9 and -4. Min takes the smaller of each two, -2 and -4. Max takes the larger again: the starting position, the root, is worth -2, and max opens with a1.

The +9 was never really on offer. Min would not let you near it.

> **Alt+Tab · game 10 · stop 4 of 6: Peek by the die**
>
> **What he just said:** The minimax value is what a game is worth when each side plays its best against the other's best. In a two-player game where your gain is her loss, the plans that reach it form an equilibrium.
>
> **In the game:** A question asks what you can expect per peek against a perfect Widowmaker. Then the game waits for 5 more peeks, LEFT CLICK or RIGHT CLICK, while the right side shows what a die says each time (LEFT 2 times in 7). Follow it or not.
>
> **Before you press:** Against a perfect Widowmaker, is the most you can expect per peek nothing, a little, or about a point?
>
> <details><summary>Back from the game: what you just saw</summary>With the 2 in 7 mix you win 1/7 of a point a peek on average, whatever she does, and a perfect Widowmaker can hold you to no more. That small number is the minimax value of the game. Judge yourself on how often you followed the die, not on your total: 5 peeks are far too few for 1/7 a peek to show through the luck.</details>

**On the island:** Not run on the island. Solving the strip once per blocker row and letting the blocker take the worst row for the runner would give the seeing game's minimax value.

### [29:56](https://www.youtube.com/watch?v=kZ_AUmFcZtk&t=1796s) Nobody searches to the end, so you score the spot where you stop
Mid-fight, you do not play out every possible next minute. You look a moment ahead and judge: high ground, yes; their Mercy alive, no; our Graviton ready, yes. Some of those count for more than others.

That snap judgement is what chess programs run on.

No program can follow every line of chess to the end, because the possibilities multiply with every move you look ahead. So real programs look a few moves ahead, stop, and put an estimate at each stopping point: the value function, your score for a position, in a new job. Branches neither player would choose get skipped, which is called alpha-beta pruning (31:53).

The classic value function is that checklist. Each yes-or-no question, such as "white has a rook", is a feature, with a weight for how much a yes is worth. The form is called binary-linear.

<details markdown="1"><summary>The formula, when you want it</summary>

`v(s, w) = x(s) . w`. In words: add up the weights of the features switched on in this position.

</details>

Deep Blue (36:15) used 8,000 hand-made features with weights tuned by grandmasters, searched 200 million positions a second, and beat Kasparov in 1997 with no learning at all. Chinook (38:19), a checkers program, added stored tables of endgame positions it could play perfectly. It won two of the only seven games Marion Tinsley lost in his whole checkers career, and later solved checkers (2007).

**On the island:** PLANNER is the island's Chinook: the strip is small enough to solve outright (13 sweeps, no falls in 10 runs).

### [42:24](https://www.youtube.com/watch?v=kZ_AUmFcZtk&t=2544s) Self-play is the old code with both chairs filled, plus one shortcut
Play chess against yourself and you just turn the board around after each move. Same brain, both chairs.

Programs work the same way. One that plays both sides can learn with the methods from earlier lectures, and Silver says the code does not even have to change. This is self-play, and what it learns is still a score for each position, the value function.

All three learning rules carry over, and each one adjusts the weights the score is built from:

1. **Monte Carlo** moves the score toward who really won the game.
2. **TD(0)** moves it toward the program's own guess one move later.
3. **TD(lambda)** covers the whole range in between.

<details markdown="1"><summary>The formula, when you want it</summary>

`Delta w = alpha (v(S_t+1, w) - v(S_t, w)) grad_w v(S_t, w)`. In words: if one move later you expect a different result, nudge the weights toward the newer guess.

</details>

One step does change. When the program improves its rule for choosing a move, its policy, white picks the move with the highest value and black the move with the lowest.

Games also allow a shortcut. When the rules are known and a move always leads to the same position (deterministic rules), a move needs no score of its own. A Mercy picking where to fly does not score the flight, only the spot she lands on. That spot is called the afterstate (44:55).

A move is worth what it leaves behind.

<details markdown="1"><summary>The formula, when you want it</summary>

`q*(s, a) = v*(succ(s, a))`. In words: a move is worth what the position it creates is worth.

</details>

**On the island:** the island is nearly deterministic (0.21 slips per 1,000 steps), and PLANNER already picks moves by the value of the square each reaches. No learning bot uses afterstates.

### [47:37](https://www.youtube.com/watch?v=kZ_AUmFcZtk&t=2857s) Logistello and TD-Gammon: no teacher, and still better than the champions
Picture learning Overwatch with no coach, only custom games against a copy of yourself. Two programs did that with board games and ended up stronger than the best humans.

**Logistello** played Othello and found its own features: 1.5 million patterns of stones, each a yes-or-no fact with a weight. It learned them in a loop: play a batch of games against itself, score each position by who went on to win (a Monte Carlo target), choose moves by the new scores. That is policy iteration by self-play. It searched before every move and beat the human world champion, Takeshi Murakami, 6-0.

**TD-Gammon** (52:38) played backgammon. It trained a small neural network from random weights by playing itself and nudging each guess toward the next (self-play TD). It always took the move that looked best, called greedy, and never explored.

After lecture 9, that should sound like a mistake.

It worked because of the dice, Silver says. They push play into every kind of position (56:31), like solo queue handing you fights you would never pick, and smooth the learned value function (57:44). In chess and checkers the same recipe never settled (it diverged). Even TD-Gammon was superhuman only with a 3-ply (three-move) search on top.

**On the island:** there are no dice, so a greedy learner has to be pushed to explore. Greedy Q + OPTIMISM (every Q starts at 40) fell 7.2 times per 100 episodes, against 26.5 for Q-learning (exploratory).

### [1:02:20](https://www.youtube.com/watch?v=kZ_AUmFcZtk&t=3740s) Let the search grade the gut feeling
It is 5v4 and your gut says take the fight. Your gut does not know that their Reinhardt has Earthshatter and your team is standing in a line. Looking ahead would.

Chess has the same problem: counting rooks and bishops will not tell you a checkmate is coming. So plain TD, which corrects one quick guess with the next quick guess, did poorly there. The tactics are invisible without search.

Until now the programs learned their quick score, the value function, first and searched with it afterwards. Silver asks whether the search can teach the quick score instead.

Here the search is the coach, and the gut is the student.

**TD root** is the older way, from Arthur Samuel's 1959 checkers player (1:07:47). After a move, it runs a deep search from the new position and moves its quick score for the previous position toward what the search found.

**TD leaf** (1:08:38) pushes the whole search result at one move toward the search result at the next. Only one number changes: the score of the end position the search settled on, the principal leaf. KnightCap (1:18:04), a chess program, reached master level this way, though it needed an expert opponent and had to be told what the pieces are worth.

<details markdown="1"><summary>The formula, when you want it</summary>

`v+(S_t, w) <- v+(S_t+1, w)`. In words: push this move's search result toward the next move's (the plus means "after searching").

</details>

**On the island:** Not run on the island. A runner with a two-step look-ahead, learning toward that look-ahead value, would be the test.

### [1:20:26](https://www.youtube.com/watch?v=kZ_AUmFcZtk&t=4826s) TreeStrap: a lesson from every fight in the replay, not just the last one
You can watch a whole match replay and take away one lesson, or pause at every fight and take one from each. Same replay, far more lessons.

One search looks at millions of positions and values each one. TD root and TD leaf kept one value from each search and threw the rest away. Silver, with Joel Veness, built a method that keeps them all, called TreeStrap.

It needs one search. At every position inside it, the program compares its quick score with what the search found by looking deeper, and moves the quick score toward the deeper answer.

<details markdown="1"><summary>The formula, when you want it</summary>

`v(s, w) <- v+(s, w)`. In words: teach the quick guess at each position to predict a deeper search from there.

</details>

A chess program called Meep learned this way. It started from random weights (the numbers its score is built from), played only against itself, and won 13 of 15 games against international masters.

Asked whether this is sure to settle, Silver warns (1:25:48) that a program learning only from its own search drifts from reality, so "you have to ground it" in games played to a real end.

Your own imagination is a generous referee.

**On the island:** DYNA-Q learns from imagined steps, and they are grounded because her model is built from real ones. Her return over the first 40 episodes beat Q-learning's by 25.98 (15.53 to 36.25, exploratory), and the two were level by the last 40. That is not a minimax search.

### [1:26:39](https://www.youtube.com/watch?v=kZ_AUmFcZtk&t=5199s) Play the rest of the game in your head, many times over
Before you dive the backline, you play it out in your head. They turn, you die. They don't, you get the Zenyatta. Run it enough times and you know how the dive tends to end.

Silver comes back to this kind of search, with the program now playing both sides of every imagined game. Done with care, the imagined games grow into a tree of positions: Monte Carlo tree search.

Its best version, UCT, puts a bandit (lecture 9's slot-machine problem) at every position and picks the next move to try with that lecture's UCB rule. In self-play its values settle on the minimax values.

A simpler search can be enough. Maven (1:31:44), a Scrabble program, scored each possible word by short imagined games, called rollouts, plus a learned value for the letters left on its rack, and beat the champion Adam Logan with MOUTHPART.

Scrabble hides something, though: the opponent's rack. Maven drew those letters at random and ignored what the opponent's plays reveal about them (1:39:43).

That is flipping a coin on whether Ana has sleep, right after she slept you.

**On the island:** no bot plays out imagined futures. But the blind runner shares Maven's shortcut: she keeps one table that averages over wherever the blocker tends to stand, and she does not update on clues during an episode.

### [1:40:21](https://www.youtube.com/watch?v=kZ_AUmFcZtk&t=6021s) Poker: stop answering her last swap and answer her average
Now play the counter-swap spiral with the enemy team hidden. In poker you cannot see the other player's cards, and Silver says Monte Carlo tree search (MCTS), the last part's search by imagined games, applied naively to such a game "blows up. It doesn't work. It diverges." (1:42:13).

The repair borrows an idea from game theory. Stop answering what she did last. Answer what she has done on average so far, which moves slowly, so the two sides stop chasing each other.

In your terms: stop swapping every time they swap, and pick what beats the mix they have played all match. This is called fictitious play, and the search built on it is Smooth UCT. In small poker games it found the equilibrium, where neither side gains by changing.

<details markdown="1"><summary>The formula, when you want it</summary>

`pi_avg(a|s) = N(s,a) / N(s);  A ~ UCT(S) with probability eta, else pi_avg(.|S)`. In words: the share of times each action was taken is the average strategy; act by UCT some of the time and by that average otherwise.

</details>

Each player also needs her own tree, built over what she knows: her cards and what she has seen. That summary is called an information state, and many real states share one (1:43:28, and the slide).

The slide credits a method named counterfactual regret minimization with near-perfect limit Hold'em. Silver does not name it, but he describes Alberta's near-perfect player (1:45:20). The Smooth UCT agent could not beat it head to head.

It outscored it at the competition anyway, by exploiting the other entrants.

> **Alt+Tab · game 10 · stop 5 of 6: Start two learners, watch the averages**
>
> **What he just said:** In poker, search that chased the opponent's latest move went round in circles, like a counter-swap spiral. The fix was to answer her average behaviour so far, an idea called fictitious play.
>
> **In the game:** A question asks what two learners settle into (LEFT CLICK, RIGHT CLICK or MELEE). Then press F (INTERACT) to start 300 peeks of a learning Tracer bot against a learning Widowmaker, shown every 20 peeks on the two bars while the Widowmaker turns to the side she picks.
>
> **Before you press:** After 300 peeks of two learners answering each other, do they lock onto one corner, settle near the safe mix, or never settle?
>
> <details><summary>Back from the game: what you just saw</summary>The picks never settled: the Tracer switched 12 times. The averages did, ending at 28% and 55% left, close to the safe 29% and 57%. Each bot plays the best answer to the other's average so far. A pair of plans where neither side gains by changing alone is a Nash equilibrium, and learning by playing a learning opponent is self-play. <em>In an agent:</em> Two models trained against each other can circle the same way. Averaging over past opponents is a common fix, for the same reason it calmed these two.</details>

**On the island:** the blind runner against the learning blocker is this case. Her information state is her square; the true state adds the blocker's row. She bumped 0.47 times per episode, against 0.20 with a fixed blocker. The blocker chases recent results, the kind of chasing Smooth UCT calms; no averaging was run.

### [1:47:03](https://www.youtube.com/watch?v=kZ_AUmFcZtk&t=6423s) Every champion ran the same comp, until one did not
At the end of a season, someone always lines up the winning teams and notices they all ran the same comp. Silver's last slide does that for every program from the hour.

1. **Binary features**: yes-or-no facts that describe a position.
2. **A value function** on top, the score for a position. In most it was a weighted sum of the features (a linear function); TD-Gammon's neural network was the exception.
3. **A TD-family learner**, which for Silver includes Monte Carlo, TD leaf and TreeStrap as well as plain TD.
4. **Self-play**: each program trained against itself.
5. **Search** on top.

Then he tells the room to "question our assumptions". He had argued for years that Go needed search. Then a deep neural network, with no search at all, played Go as well as a tree search running a million simulations (1:49:49).

That is the meta, broken.

His closing point: search and knowledge trade off. A program can put more knowledge into its value function or search deeper, and he counts both as progress. For you, that is reading the fight better, or thinking further ahead.

> **Alt+Tab · game 10 · stop 6 of 6: Read the debrief**
>
> **What he just said:** Silver's last slide is the meta every strong game program ran: simple features, a learned value, self-play and search on top. Then he warns that search and knowledge trade off, so the assumptions deserve questioning.
>
> **In the game:** Press F (INTERACT) for the debrief. Three lines appear on the left, with your prediction score and your points for the 14 peeks.
>
> **Before you press:** Before you press, decide which of your three opponents taught you the most about the game itself, and which only about her.
>
> <details><summary>Back from the game: what you just saw</summary>Three opponents, three lessons. The fixed one fell to a best response. The learner punished your habits. The perfect one could be held off only by the minimax mix. This game is one two-by-two choice replayed, with no positions, no search tree and no learned value, and that is where Silver's programs did their real work. <em>In an agent:</em> Testing an agent against one fixed simulated user tells you how well it learned that user. A second, different simulator is the nearest thing to checking whether it can be exploited.</details>

**On the island:** the island's row on that slide would read: squares as the features, a table as the value function, Q-learning, a fixed or bandit opponent (not self-play), and no search.

## What the island measured for this lecture

Before the runs, you would put money on two things. A blocker who learns where to stand should hurt the runner more than one who stands in the same row every time. And a runner who is told where the blocker is should beat one who has to walk into her to find out.

In these short runs the first bet paid. The second one lost, in both pairings.

| Condition | Runs | Runner's mean return, last 40 | Goal reached, last 40 | Bumps per episode | Blocker's share of rows 0-3, last third |
|---|---|---|---|---|---|
| Runner blind, blocker fixed | 1 | -14.0 | 70% | 0.20 | [1.0, 0.0, 0.0, 0.0] |
| Runner blind, blocker learns | 2 | -46.1 | 41% | 0.47 | [0.18, 0.0, 0.06, 0.76] |
| Runner sees, blocker fixed | 5 | -35.1 | 48% | 0.22 | [1.0, 0.0, 0.0, 0.0] |
| Runner sees, blocker learns | 4 | -66.4 | 29% | 0.46 | [0.36, 0.28, 0.14, 0.21] |

The first bet came in as expected. In both pairings a learning blocker cost the runner more than a fixed one and about doubled the bumps.

The second is the strange one. The seeing runner was handed the one fact the blind runner has to bump into to learn, and she did worse than the blind one: -35.1 against -14.0 with a fixed blocker, -66.4 against -46.1 with a learning one.

One untested reading: knowing the blocker's row turns 48 states into 192, so in the same nine minutes each state gets about a quarter of the visits. She knows more, and she has practised each thing she knows far less.

Then there is the blocker facing the seeing runner. Her time came out spread over all four rows, which looks like the mixing of rock, paper, scissors. It might be. But 4 runs cannot tell an equilibrium from noise.

What the island did not show is most of the lecture. There is no Nash equilibrium here, no minimax, no self-play and no search. The blocker decides once per episode and then stands still, so this is two learners with opposite rewards, not a game played move by move.

And read every number above as a first look. All of it is exploratory: 12 nine-minute runs (66 to 99 training episodes, 40-step limit), nothing planned in advance, no intervals, runners still early in learning. With so few runs, every gap in the table is not yet conclusive. (Nor should any of it be held up against unblocked Q-learning's 7.5, which came from longer runs with a 100-step limit and is not comparable.)

## Guess first

<details><summary>Two Tracers get nine minutes of practice each. One is told the blocker's row at every step, like a teammate calling it out. The other is told nothing and finds out by bumping into her. Who scores more?</summary>
The one told nothing, in both pairings: -14.0 against -35.1 with a fixed blocker, -46.1 against -66.4 with a learning one. The callout splits her 48 squares into 192 situations, each needing its own visits, so nine minutes spreads thin. Information pays only once it is learned. It is lecture 6's trade: a richer state is more exact and slower to fill (exploratory, few runs).
</details>

<details><summary>The enemy bot stands in the edge row every single episode, like a Widowmaker who never changes her sightline. Is the runner playing a game against her, or just learning a map?</summary>
A map. An opponent who never changes folds into the environment's rules (13:17), as much a part of them as the drop, and the runner's square is a complete state because the blocker never moves. So this is an ordinary MDP, and what Q-learning is looking for is called a best response. It becomes a game the moment the blocker can choose.
</details>

<details><summary>TD-Gammon always took the move that looked best, never explored, and still learned backgammon. Put a Tracer on the island who does the same, with every score starting at zero. Does she find her way?</summary>
Probably not, though nobody ran that bot. TD-Gammon had dice shoving it into new positions. The island has almost no randomness (0.21 slips per 1,000 steps), so a learner who always takes the best-looking move repeats herself. That habit is called greedy. The island's greedy bot that did explore, Q + OPTIMISM, managed it because every Q starts at 40, so an untried move always looks better than a tried one (lecture 9).
</details>

<details><summary>TreeStrap grades its gut with its own search. DYNA-Q practises on steps she only imagines (lecture 8). Both learn from inside their own heads. What stops either one from talking itself into a fantasy?</summary>
Real games. Asked whether this is sure to settle (1:25:48), Silver says the learning has to be tied to games played to a real end. DYNA-Q is tied by design: her imagined steps come from a model built only from real ones. Her imagined practice sped up early learning, but it did not cut her falls. Silver's word for that tie is grounding.
</details>

<details><summary>Your opponent will throw rock every single round, and you know it. Do you still play the unbeatable mix, a third rock, a third paper, a third scissors?</summary>
No, not if you want to beat this opponent. The mix cannot be exploited, but against always-rock it wins nothing on average, while always-paper, the best response, wins every round. The mix is the equilibrium: it keeps you safe, and it punishes nobody. Silver's poker result turns on the same gap: the self-play agent won more by exploiting weaker entrants.
</details>

<details><summary>Plain tree search diverged at poker, the two sides chasing each other like a counter-swap spiral: they go Pharah, you go Soldier, they go Winston, forever. What one change to what you answer makes the spiral stop?</summary>
Answer her average, not her latest. Pick what beats everything she has played so far, not what she played last. The latest move jumps about, so chasing it circles: paper chases rock and is chased by scissors. The average moves slowly, so the chase settles. That is fictitious play, and Smooth UCT is the search built on it. The island's blocker still chases recent results.
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

Remember the Widowmaker who holds the same angle every round. A tool-using model on tau-bench talks to a simulated customer, and with the simulator fixed, that customer is her. This is exactly Silver's best-response case: the customer is part of the environment, and training learns a best response to that one simulator. That is not the same as learning customers.

The nearest thing to an exploitability check is a different simulated customer.

The game picture stops there. Customer service is not zero-sum (the customer is not trying to make you lose), so minimax fits only red-team tests with an adversarial user. Self-play is only an analogy, though two models trained against each other can cycle the way Silver's poker players did.

Search maps more directly. When you sample continuations, score them and keep the best, that is simulation-based search. But you cannot roll out a real customer, so the search samples a model of one, the way Maven sampled the rack, and it inherits Maven's flaw if it ignores what the conversation has already revealed. A verifier trained on search outcomes is TreeStrap's idea, and it needs the same grounding.

## The thread to partial observability

The enemy Sombra goes invisible, and the fight does not wait for you. She is still somewhere. You still have to decide where to stand.

Almost everything in this hour quietly assumed the opposite. Minimax gives every position one worth, and part of what makes that work is that white and black both see every piece (25:09). Monte Carlo tree search can settle on that worth because every imagined game starts from the real position. And a score for a position needs a position you know you are in.

Hide part of the board and all three wobble.

Applied naively to poker, tree search diverges (1:42:13). Silver's repair is to build each player's tree over what she knows, her cards and what she has seen, which he calls an information state; many real states share one (1:43:28). Poker adds an opponent who chooses the hidden thing and exploits you if you are predictable, so the answer there was an average strategy.

Maven never got that far. It drew the opponent's letters at random and ignored what their plays gave away (1:39:43). That is the gap between a guess and a belief: a probability over the hidden part, updated from everything that has happened so far.

The blind runner facing a learning blocker lives in that gap. Her information state is her square; the true state adds the blocker's row. A bump tells her where the blocker is this episode, and she has nowhere to keep it.

Lesson 11 gives her somewhere. One square on her way is shut, a different one each episode, and nobody says which. On the short strip, where no row is always open, the blind runner got 52% of her test crossings to the goal. A runner with the smallest memory there is, one slot that reads "no bump yet" or the row that stopped her, got 90%. A runner simply told where the wall is got 94%.

One remembered bump was worth 38 more crossings in every 100 (95% interval 10 to 66), a real difference by the rule set before the runs. Being told against remembering, 3 more in every 100, is not yet conclusive.

And this lecture's surprise comes back. On the long strip, where a way round exists, the real runs settled nothing yet, and the simulation by the rules alone has the blind runner ahead at 200 episodes and level by 400. A richer state is a cost first and a benefit later.

Carry forward: what she knows against what is true, a belief built from history, and the price of throwing away a clue you have already paid for.

## Experiments the lecture asks for that the island has not run

- Minimax by planning: solve the strip per blocker row; the worst row is the seeing game's value.
- Exploitability: freeze each trained bot and train a fresh opponent against her.
- True self-play: one program plays both sides.
- Fictitious-play blocker: respond to the runner's average, to see whether the chase stops.
- TD-leaf runner: two-step look-ahead targets against plain Q-learning.
