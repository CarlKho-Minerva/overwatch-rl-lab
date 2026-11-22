/* Setup test: the first ray is cast 500 m from the island, so it finds no floor. Expected: the 'stand on the island' status, then the host's position is used and the lab starts normally. */

#!allowMacroRedeclaration
#!include "../defaults.opy"

#!define DBG_ORIGIN_X 500
#!define FORCE_EXPERIMENT 0
#!define FORCE_ALGO 0
#!define DEF_LOG_STEPS true

#!include "../lab.opy"
