# Episode 5: Model-Free Control

*Outline for one episode of a video series, "RL with Overwatch". Footage: the island runs in this repository.*

- Title: "One line apart"
- Cold open: Q-LEARNING steps off the edge; SARSA, a row inland, keeps walking.
- Beat 1: PLANNER walking the edge row. "With the rules this is easy. Without them, she learns by falling."
- Beat 2: arrows on squares. "She scores moves, not squares, and picks the biggest arrow."
- Beat 3: a bot stepping off for no reason. "One move in ten is random, on purpose, so she keeps learning."
- Beat 4: both names over their score lines. "SARSA scores the move she will really make next; Q-LEARNING scores the best one."
- Beat 5: falls counters. "Q-LEARNING falls about 26 times per 100 episodes, SARSA about 16."
- Beat 6: exploring off, Q-LEARNING crossing cleanly. "Without randomness, the one who fell more has the better map."
- Experiment shown: SARSA against Q-LEARNING, falls per 100 and distance from the edge.
- Closing line: "Learn about the walker you are, or the walker you could be: two routes along one cliff."

**The game for this episode:** [Game 5: Slippery Boots](../workshop/games/g05.md). The viewer can load it and play along (`workshop/compiled/game-05.txt`).
