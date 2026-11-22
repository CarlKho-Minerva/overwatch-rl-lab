# Episode 2: Markov Decision Processes

*Outline for one episode of a video series, "RL with Overwatch". Footage: the island runs in this repository.*

**Working title:** "What a square is worth"
**Cold open (first 10 seconds):** RANDOM WALK steps forward, back, inland, then off the edge. Score line: -101.
**Beats:**
1. The strip from above, arrows on each square. "This is the whole world: 48 squares, four moves, and a price list."
2. Score lines for each move: -1, +50, -100. "Write the moves and prices down and you have a Markov decision process."
3. RANDOM WALK falls again and again; her running average settles. "Her start square is worth -114.4 on paper. In the game she averaged -112.7."
4. A RANDOM WALK bot wanders into the inland rows and still falls, the far corner highlighted. "Inland is worse, -135.5: she wanders longer and falls anyway."
5. Arrows change column by column back from the goal. "Take the best move, average the dice, repeat: thirteen sweeps."
6. PLANNER crosses eleven squares along the edge, ten crossings in a row, score line 39. "The best any policy can get, every time."
**The experiment shown:** RANDOM WALK's measured score against the exact value, then the PLANNER.
**Closing line:** "The PLANNER was handed the rules. The next bots will not be."

**The game for this episode:** [Game 2: Mini or Mega](../workshop/games/g02.md). The viewer can load it and play along (`workshop/compiled/game-02.txt`).
