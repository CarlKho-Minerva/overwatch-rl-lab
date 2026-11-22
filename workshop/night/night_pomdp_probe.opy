/*
Night School, hidden-wall build, scripted check. Every bot takes the same 16-step walk with the wall forced into
the edge row: five steps forward, two bumps into the wall, around it through the second row, one bump into it
from the far side, then on to the goal. Two episodes under each of the three conditions.
analysis/tests/test_pomdp.py rebuilds the states the bot should have reported and every table entry.
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
#!define BUILD_VERSION 9402
#!define SCRIPTED true
#!define SCRIPT_PLAN [0, 0, 0, 0, 0,   0, 0,   2, 0, 0, 3,   1,   0, 0, 0, 0,   0, 0, 0, 0, 0,   0, 0,   2, 0, 0, 3,   1,   0, 0, 0, 0]
#!define FORCE_OFFSET 0
#!define FORCE_WALL 0
#!define DEF_SOFT_MIN 2
#!define DEF_RUN_MAX_MIN 2
#!define DEF_EVAL_EPS 0
#!define DEF_AUTO_RESTART false
#!define STEP_LOG_STEPS 40
#!define CONDITION_TRAIN_EPS [2, 2, 2]

#!include "night_lab.opy"
