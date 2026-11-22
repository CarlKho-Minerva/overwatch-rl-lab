/*
Night School, hidden-wall build, short strip, scripted check. Every bot takes the same 10-step walk with the wall
forced into the edge row at column 3: two steps forward, two bumps, around through the second row, one bump from
the far side, then the goal at column 5. Two episodes under each of the three conditions.
*/

#!allowMacroRedeclaration
#!include "night_defaults.opy"
#!define VWALL true
#!define STATE_MULT 5
#!define POMDP_ROWS 4
#!define GOAL_CELL_N 5
#!define BLOCK_COL 3
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
#!define BUILD_VERSION 9403
#!define SCRIPTED true
#!define SCRIPT_PLAN [0, 0,   0, 0,   2, 0, 0, 3,   1,   0,   0, 0,   0, 0,   2, 0, 0, 3,   1,   0]
#!define FORCE_OFFSET 0
#!define FORCE_WALL 0
#!define DEF_SOFT_MIN 2
#!define DEF_RUN_MAX_MIN 2
#!define DEF_EVAL_EPS 0
#!define DEF_AUTO_RESTART false
#!define STEP_LOG_STEPS 40
#!define CONDITION_TRAIN_EPS [2, 2, 2]

#!include "night_lab.opy"
