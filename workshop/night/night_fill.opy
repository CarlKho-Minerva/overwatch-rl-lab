/*
Night School, fill-in blocks. The standard build draws its rotation offset at random, and by 05:00 on the first
night that had given Q-learning 4 finished runs and SARSA 5 while other conditions had 14. This variant walks a
weighted list instead, so the conditions that were short get most of the runs. Everything else is the standard build.
*/

#!allowMacroRedeclaration
#!include "night_defaults.opy"
#!define BUILD_VERSION 211
#!define CONDITION_ORDER [0, 1, 0, 1, 0, 1, 3, 8, 13, 9]

#!include "night_lab.opy"
