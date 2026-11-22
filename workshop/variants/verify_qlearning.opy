/* Variant: cliff walk on Q-learning with per-step logging on. Used to check the in-game updates against the Python reference. */

macro FORCE_EXPERIMENT = 0
macro FORCE_ALGO = 1
macro DEF_LOG_STEPS = true
macro DEF_BLINK = false
macro DEF_CLOSED_LOOP = true

#!include "../lab.opy"
