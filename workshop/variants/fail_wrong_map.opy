/* Setup-failure test: a map that is not Workshop Island. Expected: the red 'island measurement looks wrong' status and a FAIL,island log line. */

#!allowMacroRedeclaration
#!include "../defaults.opy"

#!define DEF_MAP "workshopExpanse"
#!define FORCE_EXPERIMENT 0
#!define FORCE_ALGO 0

#!include "../lab.opy"
