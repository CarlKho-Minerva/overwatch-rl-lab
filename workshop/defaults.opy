# Default value of every Workshop Setting. The standard build uses these as they are.
# A test variant includes this file and then redefines the few it wants to change.

# -1 = choose in the menu; 0 cliff walk, 1 cliff walk + Widowmaker, 2 arena demo
#!define FORCE_EXPERIMENT (-1)
# -1 = choose in the menu; 0 SARSA, 1 Q-learning
#!define FORCE_ALGO (-1)
#!define DEF_START_PAUSED false
#!define DEF_MAX_STEPS 100
#!define DEF_GAME_SPEED 100
#!define DEF_ALPHA 0.5
#!define DEF_GAMMA 1
#!define DEF_EPSILON 0.1
#!define DEF_Q_INIT 0
#!define DEF_R_STEP (-1)
#!define DEF_R_GOAL 50
#!define DEF_R_FALL (-100)
#!define DEF_R_TIMEOUT (-50)
#!define DEF_R_KILLED (-100)
#!define DEF_R_HIT 0
#!define DEF_CELL 2
#!define DEF_MARGIN 0.5
#!define DEF_CLOSED_LOOP true
#!define DEF_DURATION_SCALE 100
#!define DEF_MOVE_SPEED 100
#!define DEF_WIDOW_INTERVAL 2
#!define DEF_WIDOW_RANGE 11
#!define DEF_WIDOW_DAMAGE 100
#!define DEF_WIDOW_STANDOFF 6
#!define DEF_OBSERVE_HEALTH true
#!define DEF_BLINK false
#!define DEF_LOG_STEPS false
#!define DEF_LOG_Q_EVERY 50

# The map, and two switches used only by the setup-failure test builds (variants/fail_*.opy).
#!define DEF_MAP "workshopIsland"
#!define DBG_ORIGIN_X 0
#!define DBG_ROOT_TRACER false

# Warm start: a Q-table carried over from an earlier match (written by tools/warm_start.py).
#!define WARM_START false
#!define WARM_Q []
