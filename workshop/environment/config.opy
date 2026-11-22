# ---------------------------------------------------------------------------
# Constants and Workshop Settings.
# Workshop Settings appear in the lobby under Settings > Workshop Settings.
# They are read once, when the match starts.
# ---------------------------------------------------------------------------

macro NCOLS = 12
macro NROWS = 4
macro NCELLS = 48
macro NA = 5            # width of one Q-table row (4 moves + Blink)
macro NSTATES = 192     # 48 cells x health bit x blink bit
macro START_CELL = 0
macro GOAL_CELL = 11

enum Act:
    FWD = 0     # +x, along the edge toward the goal
    BACK        # -x
    IN          # +z, away from the edge
    EDGE        # -z, toward the edge
    BLINK       # Tracer's Blink, toward the goal

enum Outcome:
    RUNNING = 0
    GOAL
    FELL
    TIMEOUT
    KILLED

enum Exp:
    CLIFF = 0
    WIDOW
    DEMO

enum Algo:
    SARSA = 0
    QLEARNING

# 1 Experiment
# FORCE_EXPERIMENT / FORCE_ALGO are -1 in the normal build. The test variants set them to skip the menu.
globalvar cfgExperiment = createWorkshopSettingEnum("1 Experiment", "Experiment", 0, ["Cliff walk", "Cliff walk + Widowmaker", "Arena demo (scripted patrol)"], 0) if FORCE_EXPERIMENT < 0 else FORCE_EXPERIMENT
globalvar paused = createWorkshopSettingBool("1 Experiment", "Start paused", DEF_START_PAUSED, 1)
globalvar cfgMaxSteps = createWorkshopSettingInt("1 Experiment", "Episode duration (max steps)", DEF_MAX_STEPS, 10, 500, 2)
globalvar cfgSlowMo = createWorkshopSettingInt("1 Experiment", "Game speed percent", DEF_GAME_SPEED, 10, 100, 3)
globalvar camOn = createWorkshopSettingBool("1 Experiment", "Overhead camera for the host", true, 4)

# 2 Learning
globalvar algo = createWorkshopSettingEnum("2 Learning", "Algorithm", 0, ["SARSA", "Q-learning"], 0) if FORCE_ALGO < 0 else FORCE_ALGO
globalvar alpha = createWorkshopSettingFloat("2 Learning", "Learning rate alpha", DEF_ALPHA, 0, 1, 1)
globalvar gamma = createWorkshopSettingFloat("2 Learning", "Discount factor gamma", DEF_GAMMA, 0, 1, 2)
globalvar epsilon = createWorkshopSettingFloat("2 Learning", "Exploration probability epsilon", DEF_EPSILON, 0, 1, 3)
globalvar wantTraining = createWorkshopSettingEnum("2 Learning", "Start mode", 0, ["Training", "Greedy evaluation"], 4) == 0
globalvar cfgQInit = createWorkshopSettingFloat("2 Learning", "Initial Q-value", DEF_Q_INIT, -1000, 1000, 5)

# 3 Rewards
globalvar rStep = createWorkshopSettingFloat("3 Rewards", "Reward per action", DEF_R_STEP, -50, 0, 0)
globalvar rGoal = createWorkshopSettingFloat("3 Rewards", "Reward for reaching the goal", DEF_R_GOAL, 0, 1000, 1)
globalvar rFall = createWorkshopSettingFloat("3 Rewards", "Reward for falling off the island", DEF_R_FALL, -1000, 0, 2)
globalvar rTimeout = createWorkshopSettingFloat("3 Rewards", "Reward for timeout", DEF_R_TIMEOUT, -1000, 0, 3)
globalvar rKilled = createWorkshopSettingFloat("3 Rewards", "Reward for being killed by Widowmaker", DEF_R_KILLED, -1000, 0, 4)
globalvar rHit = createWorkshopSettingFloat("3 Rewards", "Reward per hit taken", DEF_R_HIT, -200, 0, 5)

# 4 Arena
globalvar cfgCell = createWorkshopSettingFloat("4 Arena", "Cell size (m)", DEF_CELL, 1.5, 3, 0)
globalvar cfgMargin = createWorkshopSettingFloat("4 Arena", "Gap between grid and island edge (m)", DEF_MARGIN, 0, 0.75, 1)
globalvar cfgClosedLoop = createWorkshopSettingBool("4 Arena", "Stop each move at the cell centre (off = fixed duration)", DEF_CLOSED_LOOP, 2)
globalvar cfgDurationScale = createWorkshopSettingInt("4 Arena", "Fixed-duration move length percent", DEF_DURATION_SCALE, 25, 300, 3)
globalvar cfgMoveSpeed = createWorkshopSettingInt("4 Arena", "Tracer move speed percent", DEF_MOVE_SPEED, 50, 200, 4)

# 5 Widowmaker
globalvar cfgWidowInterval = createWorkshopSettingFloat("5 Widowmaker", "Seconds between shots", DEF_WIDOW_INTERVAL, 0.5, 10, 0)
globalvar cfgWidowRange = createWorkshopSettingFloat("5 Widowmaker", "Firing range (m)", DEF_WIDOW_RANGE, 1, 100, 1)
globalvar cfgWidowDamage = createWorkshopSettingInt("5 Widowmaker", "Damage percent", DEF_WIDOW_DAMAGE, 0, 500, 2)
globalvar cfgWidowStandoff = createWorkshopSettingFloat("5 Widowmaker", "Distance behind the grid (m)", DEF_WIDOW_STANDOFF, 2, 25, 3)
globalvar cfgObserveHealth = createWorkshopSettingBool("5 Widowmaker", "Tracer observes her own health", DEF_OBSERVE_HEALTH, 4)
globalvar cfgBlink = createWorkshopSettingBool("5 Widowmaker", "Enable Blink as a fifth action", DEF_BLINK, 5)

# 6 Logging
globalvar cfgLogSteps = createWorkshopSettingBool("6 Logging", "Log every step to the Inspector", DEF_LOG_STEPS, 0)
globalvar cfgLogQEvery = createWorkshopSettingInt("6 Logging", "Log the Q-table every N episodes (0 = never)", DEF_LOG_Q_EVERY, 0, 1000, 1)
globalvar cfgShowCal = createWorkshopSettingBool("6 Logging", "Show calibration HUD", true, 2)

# Loop counters shared by every file (Workshop for-loops need a variable).
globalvar i
globalvar j

# Subroutines, declared up front so files can call each other in any order.
subroutine probeEdge
subroutine layoutArena
subroutine resetTracer
subroutine observeState
subroutine stepEnv
subroutine chooseAction
subroutine updateGlyph
subroutine resetLearning
subroutine runEpisode
subroutine logRunHeader
subroutine logEpisode
subroutine logStep
subroutine logQTable
subroutine botLost
