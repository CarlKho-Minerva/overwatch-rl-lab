/* Variant: cliff walk with every arena, learning and reward setting moved off its default, starting paused.
   Used to check that non-default settings behave in the game and that the replay still matches. */

#!allowMacroRedeclaration
#!include "../defaults.opy"

#!define FORCE_EXPERIMENT 0
#!define FORCE_ALGO 1
#!define DEF_LOG_STEPS true
#!define DEF_START_PAUSED true
#!define DEF_MAX_STEPS 40
#!define DEF_GAME_SPEED 80
#!define DEF_ALPHA 0.3
#!define DEF_GAMMA 0.9
#!define DEF_EPSILON 0.2
#!define DEF_Q_INIT 5
#!define DEF_R_STEP (-2)
#!define DEF_R_GOAL 30
#!define DEF_R_FALL (-60)
#!define DEF_R_TIMEOUT (-40)
#!define DEF_CELL 2.5
#!define DEF_MARGIN 0.25
#!define DEF_MOVE_SPEED 150
#!define DEF_LOG_Q_EVERY 10

#!include "../lab.opy"
