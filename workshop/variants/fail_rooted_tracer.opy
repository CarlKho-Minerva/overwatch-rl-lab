/* Setup-failure test: Tracer is rooted during the speed measurement. Expected: the red 'Tracer did not move' status and a FAIL,throttle log line. */

#!allowMacroRedeclaration
#!include "../defaults.opy"

#!define DBG_ROOT_TRACER true
#!define FORCE_EXPERIMENT 0
#!define FORCE_ALGO 0

#!include "../lab.opy"
