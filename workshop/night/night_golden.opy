/*
Night School, golden test. Every bot takes the same scripted walk (four episodes, 37 steps: a fall, a clean
crossing, a fall, a crossing with a blocked move and a step back) under each condition in turn, then logs its
tables. analysis/tests/test_night_golden.py recomputes every table from the logged walk and compares.
Planning is off for Dyna-Q here, because its imagined updates are drawn at random.
*/

#!allowMacroRedeclaration
#!include "night_defaults.opy"
#!define BUILD_VERSION 9207
#!define SCRIPTED true
#!define SCRIPT_PLAN [2, 0, 0, 3, 3,   2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3,   0, 0, 3,   1, 2, 0, 1, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
#!define FORCE_OFFSET 0
#!define DEF_SOFT_MIN 1
#!define DEF_RUN_MAX_MIN 2
#!define DEF_EVAL_EPS 0
#!define DEF_AUTO_RESTART false
#!define STEP_LOG_STEPS 40
#!define CONDITION_PLANS [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
#!define CONDITION_TRAIN_EPS [4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4]

#!include "night_lab.opy"
