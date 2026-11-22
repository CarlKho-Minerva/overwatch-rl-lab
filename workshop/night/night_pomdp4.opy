/*
Night School, hidden-wall build, short strip with no way round.

The same three runners as night_pomdp.opy, with two changes chosen by simulating the grid's rules first
(docs/night-school.md, "The short strip"):

  - the wall can stand in any of the four rows, so there is no row a runner can always get through;
  - the goal is at column 5 and the wall at column 3, so a run can learn the task in 200 episodes.

A runner who is told only her square cannot both go forward at the wall's column and not go forward there: the
same square needs two different moves depending on something she is not given. The other two runners can.
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
#!define BUILD_VERSION 1103
#!define DEF_SOFT_MIN 5
#!define DEF_RUN_MAX_MIN 20
#!define DEF_EVAL_EPS 20
#!define EVAL_GRACE_SEC 420
#!define STEP_LOG_STEPS 40
#!define CONDITION_TRAIN_EPS [200, 200, 200]

#!include "night_lab.opy"
