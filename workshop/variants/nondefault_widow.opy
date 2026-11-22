/* Variant: Widowmaker experiment with Tracer blind to her own health, a penalty per hit, and Widowmaker's
   interval, range, damage and distance moved off their defaults. */

#!allowMacroRedeclaration
#!include "../defaults.opy"

#!define FORCE_EXPERIMENT 1
#!define FORCE_ALGO 0
#!define DEF_LOG_STEPS true
#!define DEF_OBSERVE_HEALTH false
#!define DEF_R_HIT (-10)
#!define DEF_R_KILLED (-80)
#!define DEF_WIDOW_INTERVAL 1.5
#!define DEF_WIDOW_RANGE 9
#!define DEF_WIDOW_DAMAGE 50
#!define DEF_WIDOW_STANDOFF 4

#!include "../lab.opy"
