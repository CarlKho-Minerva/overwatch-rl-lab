/*
Overwatch RL Lab - main entry (standard defaults).
Compile:  npm run build      (writes workshop/compiled/overwatch-rl-lab.txt)
Everything in this mode runs inside the official Overwatch Workshop. No external controller.
*/

macro FORCE_EXPERIMENT = -1
macro FORCE_ALGO = -1
macro DEF_LOG_STEPS = false
macro DEF_BLINK = false
macro DEF_CLOSED_LOOP = true

#!include "lab.opy"
