/*
Night School, short test block: two bots a side, 12-episode runs, the block ends after about three minutes
and does not restart. Used to check a new build in the game before a long session.
*/

#!allowMacroRedeclaration
#!include "night_defaults.opy"
#!define BUILD_VERSION 9208
#!define DEF_BOTS_PER_TEAM 5
#!define DEF_SOFT_MIN 3
#!define DEF_RUN_MAX_MIN 2
#!define DEF_EVAL_EPS 3
#!define DEF_AUTO_RESTART false
#!define CONDITION_TRAIN_EPS [12, 12, 12, 12, 12, 12, 12, 12, 12, 30, 6, 12, 12, 12]

#!include "night_lab.opy"
