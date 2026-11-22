/*
Night School, lecture 10 build, short probe: a runner against a blocker.

One runner per strip learns the usual cliff walk with Q-learning. A bot from the other team stands mid-strip
in one of the four rows, pinned for the episode. Enemy heroes cannot walk through each other, so its body is
a real obstacle. The game is zero-sum: whatever return the runner loses, the blocker gains.

Four conditions, rotated like the others:
  RUNNER BLIND, BLOCKER FIXED     the blocker always stands in the edge row; the runner is told nothing
  RUNNER BLIND, BLOCKER LEARNS    the blocker learns which row costs the runner most (a four-armed bandit)
  RUNNER SEES, BLOCKER FIXED      the runner's state includes the blocker's row
  RUNNER SEES, BLOCKER LEARNS
*/

#!allowMacroRedeclaration
#!include "night_defaults.opy"
#!define BUILD_VERSION 9302
#!define DUEL true
#!define STATE_MULT 4
#!define DEF_BOTS_PER_TEAM 2
#!define DEF_SOFT_MIN 3
#!define DEF_RUN_MAX_MIN 2
#!define DEF_EVAL_EPS 3
#!define DEF_AUTO_RESTART false
#!define DEF_MAX_STEPS 40
#!define DEF_EVAL_MAX_STEPS 40
#!define CONDITION_COUNT 4
#!define CONDITION_NAMES ["RUNNER BLIND, BLOCKER FIXED", "RUNNER BLIND, BLOCKER LEARNS", "RUNNER SEES, BLOCKER FIXED", "RUNNER SEES, BLOCKER LEARNS"]
#!define CONDITION_ALGOS [1, 1, 1, 1]
#!define CONDITION_EPS [0.1, 0.1, 0.1, 0.1]
#!define CONDITION_ALPHAS [0.5, 0.5, 0.5, 0.5]
#!define CONDITION_QINITS [0, 0, 0, 0]
#!define CONDITION_PLANS [0, 0, 0, 0]
#!define CONDITION_LAMBDAS [0, 0, 0, 0]
#!define CONDITION_BONUSES [0, 0, 0, 0]
#!define CONDITION_TRAIN_EPS [15, 15, 15, 15]
#!define CONDITION_AGGS [0, 0, 3, 3]
#!define CONDITION_BLOCKS [1, 2, 1, 2]

#!include "night_lab.opy"
