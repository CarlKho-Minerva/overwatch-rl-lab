/*
Night School, hidden-wall build: the lesson on partial observability.

Ten Q-learning runners cross the usual strip. For every episode, one square at column 6 is shut: the one in the
edge row or the one in the second row, drawn at random. A runner who walks at it does not move, and pays for the
step. The runner's true situation is (her square, which square is shut). What she is told differs by condition:

  RUNNER BLIND             her own square only. Two different situations look identical to her.
  RUNNER REMEMBERS BUMPS   her own square, plus a memory of this episode: no bump yet, or the row she bumped into.
                           The memory is a belief about the hidden wall, built from what happened to her.
  RUNNER SEES THE WALL     her own square and the wall's row: the fully observed version, for comparison.

Same learning rule, same rewards, same walls in all three. Only the state the runner is given changes.
The wall is enforced by the script, not by an enemy body, so that ten bots can each have their own at once
(the lecture 10 build, night_duel.opy, has the real body: one runner per strip). A red ball above the strip
marks each bot's wall for whoever is watching; the bots cannot see it.

Named in advance, before any run (2026-11-22): the measure is the 20 greedy test crossings at the end of each
run, as the share that reach the goal and the steps they take. Training return is reported but is not the
measure, because a route that avoids the wall also moves away from the edge, which changes how often the
one-in-ten random step ends in a fall.
*/

#!allowMacroRedeclaration
#!include "night_defaults.opy"
#!define VWALL true
#!define STATE_MULT 5
#!define POMDP_ROWS 2
#!define DEF_MAX_STEPS 40
#!define DEF_EVAL_MAX_STEPS 40
#!define CONDITION_COUNT 3
#!define CONDITION_NAMES ["RUNNER BLIND", "RUNNER REMEMBERS BUMPS", "RUNNER SEES THE WALL"]
#!define CONDITION_ALGOS [1, 1, 1]
#!define CONDITION_EPS [0.1, 0.1, 0.1]
#!define CONDITION_ALPHAS [0.5, 0.5, 0.5]
#!define CONDITION_QINITS [0, 0, 0]
#!define CONDITION_PLANS [0, 0, 0]
#!define CONDITION_LAMBDAS [0, 0, 0]
#!define CONDITION_BONUSES [0, 0, 0]
#!define CONDITION_AGGS [0, 4, 3]
#!define CONDITION_BLOCKS [3, 3, 3]
#!define CONDITION_ORDER [0, 1, 2]
#!define BUILD_VERSION 1102
#!define DEF_SOFT_MIN 5
#!define DEF_RUN_MAX_MIN 26
#!define DEF_EVAL_EPS 20
#!define EVAL_GRACE_SEC 420
#!define STEP_LOG_STEPS 40
#!define CONDITION_TRAIN_EPS [200, 200, 200]

#!include "night_lab.opy"
