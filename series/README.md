# RL with Overwatch: the series

A plan for a video series built from this repository: one episode per lecture of David Silver's course, each built
around one experiment you can watch the bots run. These are outlines, written from the lectures and the logged runs.
They are a starting point for whoever records them.

## The shape of an episode (about eight minutes)

1. Cold open, ten seconds, in the game: a bot doing the thing the episode is about, no words.
2. The question, in one sentence a player would ask.
3. The idea, shown on the strip: which bot, which rule, what she is told.
4. The experiment: two bots side by side, one number each.
5. What the number does and does not show.
6. The same idea in a language-model agent, in thirty seconds.
7. One line that sets up the next episode.

## Episodes

| # | Working title | Lecture | Cold open | The experiment shown | Build to load |
|---|---|---|---|---|---|
| 1 | [The Bot Who Never Learns, and the Bot Who Already Knows](episode-01.md) | Introduction to Reinforcement Learning | The Tracer named RANDOM WALK takes a few steps along Workshop Island's edge and runs off the drop. | RANDOM WALK against PLANNER on the same strip, with their mean returns. | `workshop/compiled/night-school.txt` |
| 2 | [What a square is worth](episode-02.md) | Markov Decision Processes | RANDOM WALK steps forward, back, inland, then off the edge. Score line: -101. | RANDOM WALK's measured score against the exact value, then the PLANNER. | `workshop/compiled/night-school.txt` |
| 3 | [The Bot Who Never Fell](episode-03.md) | Planning by Dynamic Programming | nine Tracers on the strip, names over their heads, tumbling off the edge one by one; at the left end, PLANNER standing still. | value iteration on the strip, 13 sweeps as arrows, then the greedy walk. | `workshop/compiled/night-school.txt` |
| 4 | [Three Bookkeepers and a Falling Tracer](episode-04.md) | Model-Free Prediction | RANDOM WALK, name over her head, takes three random steps and drops off the edge; the score line reads -101. | the three tables on one random walker. | `workshop/compiled/night-school.txt` |
| 5 | [One line apart](episode-05.md) | Model-Free Control | Q-LEARNING steps off the edge; SARSA, a row inland, keeps walking. | SARSA against Q-LEARNING, falls per 100 and distance from the edge. | `workshop/compiled/night-school.txt` |
| 6 | [Tell her less.](episode-06.md) | Value Function Approximation | three Tracers named Q-LEARNING, Q, 16 COARSE STATES and Q, ROW ONLY; the row-only one runs left, right, left along the edge. | falls per 100 training episodes, with intervals, for the three amounts of detail. | `workshop/compiled/night-school.txt` |
| 7 | [The Tracer who learned to jump](episode-07.md) | Policy Gradient | a Tracer with POLICY GRADIENT over her head spawns at the edge row and runs straight off. Respawn. Same move. | POLICY GRADIENT against ACTOR-CRITIC, return per episode. | `workshop/compiled/night-school.txt` |
| 8 | [Twenty Steps in Her Head](episode-08.md) | Integrating Learning and Planning | two Tracers at the left end of the edge row, DYNA-Q and Q-LEARNING over their heads; both take early random steps and Q-LEARNING walks off the edge. | DYNA-Q against Q-LEARNING, mean return over the first 40 episodes (-31.7 against -57.6) and the last 40 (15.1 against 7.5, inconclusive). | `workshop/compiled/night-school.txt` |
| 9 | [The price of finding out](episode-09.md) | Exploration and Exploitation | ten Tracers on the strip; Q + OPTIMISM steps off the edge on purpose, and her score line drops by 100. | the four Q explorers, falls per 100. | `workshop/compiled/night-school.txt` |
| 10 | [The Blocker](episode-10.md) | Classic Games | a Tracer runs the edge row and stops dead against a standing enemy bot at column 6; cut to the name over each. | the two-player build, 12 short runs, labelled exploratory. | `workshop/compiled/night-school-duel.txt` |
| 11 | [The Wall She Cannot See](episode-11.md) | Partial observability (lecture 1's thread, picked up) | A Tracer walks at an empty-looking square and stops dead, three times. | BLIND against REMEMBERS BUMPS on the short strip: test crossings reaching the goal. Then the same forgetting in a support chat. | `workshop/compiled/night-school-pomdp4.txt` |

10 of the ten lecture outlines are written so far.

## Footage this repository can produce

- Any build in `workshop/compiled/` runs by itself in a private custom game on Workshop Island: paste, start, and the
  bots train. The name over each bot is her method. Arrows on the squares show what a bot currently rates best.
- Spectate from above for the whole strip, or follow one bot. A red ball above the strip marks a bot's hidden wall in
  the hidden-wall builds (the bots are not shown it).
- Every figure in `analysis/figures/night/` is drawn from the logs by `python -m rllab.night_summary`.
- The numbers to say out loud are in `course/island-fact-sheet.md`, each with its interval.
