/*
Overwatch RL Lab - Night School build.

Ten Tracer bots walk the same cliff at once. Each has its own table and its own learning method, so one
match is ten experiments under identical game conditions. The script schedules everything itself: runs,
greedy evaluation, logging, and a match restart when the log file is nearly full. Nobody presses a key.

Two strips: Team 1 bots use the island's -z edge (side 0), Team 2 bots the +z edge (side 1, mirrored).
State   = which of 48 cells the bot stands in (4 rows x 12 columns), read from its real position.
Actions = forward (+x), back (-x), inland, toward the edge. One action = one real run to the next cell.

Compile: npm run build   (writes workshop/compiled/night-school.txt)
Log format: docs/night-school.md
*/

settings {
    "main": {
        "modeName": "Overwatch RL Lab: Night School",
        "description": "Ten Tracer bots learn a cliff walk on Workshop Island at once, each with a different reinforcement learning method. github.com/CarlKho-Minerva/overwatch-rl-lab"
    },
    "lobby": {
        "team1Slots": 6,
        "team2Slots": 6
    },
    "gamemodes": {
        "skirmish": {
            "enabledMaps": [
                "workshopIsland"
            ]
        },
        "general": {
            "heroLimit": "off",
            "enableKillCam": false,
            "spawnHealthPacks": "disabled"
        }
    }
}

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
macro NCOLS = 12
macro NROWS = 4
macro NCELLS = 48
macro NA = 4
macro NSTATES = NCELLS * STATE_MULT     # 48, or 192 when the runner also sees which row a blocker stands in
macro NQ = NSTATES * NA
macro START_CELL = 0
macro GOAL_CELL = 11
macro MARGIN = 0.5
macro LOG_BUDGET = 232000      # the game stops writing a log file at 256 KB; leave room for the closing lines
macro STEP_LOG_N = STEP_LOG_STEPS

enum Alg:
    SARSA = 0
    QL
    ESARSA
    DYNA
    MC
    LAMBDA
    RANDOM
    DP
    PG
    AC

enum Outcome:
    RUNNING = 0
    GOAL
    FELL
    TIMEOUT

# ---------------------------------------------------------------------------
# Conditions. A bot's condition for a run = entry (bot index + a random offset drawn at match start + run number) of condOrder,
# so within a match the bots cover different conditions and across matches each bot meets all of them.
#   eps  -1 = decays as 1 / (1 + episode / 5), floor 0.01
# ---------------------------------------------------------------------------
macro NCOND = CONDITION_COUNT
globalvar cName = CONDITION_NAMES
globalvar cAlgo = CONDITION_ALGOS
globalvar cEps = CONDITION_EPS
globalvar cAlpha = CONDITION_ALPHAS
globalvar cQInit = CONDITION_QINITS
globalvar cPlan = CONDITION_PLANS
globalvar cLam = CONDITION_LAMBDAS
globalvar cBonus = CONDITION_BONUSES
globalvar cTrain = CONDITION_TRAIN_EPS
globalvar cAgg = CONDITION_AGGS
globalvar condOrder = CONDITION_ORDER     # which conditions the rotation walks through (all of them, or a weighted list)
globalvar cBlock = CONDITION_BLOCKS     # duel build: 0 no blocker, 1 a blocker that always stands in row 0, 2 a blocker that learns where to stand

# ---------------------------------------------------------------------------
# Workshop Settings (lobby > Settings > Workshop Settings)
# ---------------------------------------------------------------------------
globalvar cfgBotsPerTeam = createWorkshopSettingInt("Night School", "Bots per team", DEF_BOTS_PER_TEAM, 1, 5, 0)
globalvar cfgMoveSpeed = createWorkshopSettingInt("Night School", "Bot move speed percent", DEF_MOVE_SPEED, 50, 300, 1)
globalvar cfgEvalEps = createWorkshopSettingInt("Night School", "Greedy evaluation episodes per run", DEF_EVAL_EPS, 0, 100, 2)
globalvar cfgSoftMin = createWorkshopSettingInt("Night School", "No new run after this many minutes", DEF_SOFT_MIN, 1, 240, 3)
globalvar cfgRunMaxMin = createWorkshopSettingInt("Night School", "Longest run (minutes)", DEF_RUN_MAX_MIN, 1, 240, 4)
globalvar cfgAutoRestart = createWorkshopSettingBool("Night School", "Restart the match by itself when the block ends", DEF_AUTO_RESTART, 5)
globalvar cfgMaxSteps = createWorkshopSettingInt("Night School", "Episode step limit (training)", DEF_MAX_STEPS, 10, 500, 6)
globalvar cfgEvalMaxSteps = createWorkshopSettingInt("Night School", "Episode step limit (evaluation)", DEF_EVAL_MAX_STEPS, 10, 500, 7)
globalvar cfgCell = createWorkshopSettingFloat("Night School", "Cell size (m)", 2, 1.5, 3, 8)
globalvar gamma = createWorkshopSettingFloat("Night School", "Discount factor gamma", 1, 0, 1, 9)
globalvar rStep = createWorkshopSettingFloat("Rewards", "Reward per action", -1, -50, 0, 0)
globalvar rGoal = createWorkshopSettingFloat("Rewards", "Reward for reaching the goal", 50, 0, 1000, 1)
globalvar rFall = createWorkshopSettingFloat("Rewards", "Reward for falling off the island", -100, -1000, 0, 2)
globalvar rTimeout = createWorkshopSettingFloat("Rewards", "Reward for timeout", -50, -1000, 0, 3)

# ---------------------------------------------------------------------------
# Global state
# ---------------------------------------------------------------------------
globalvar calStage = 0          # 0 measuring, 1 geometry known, 2 running, 3 block finished, -1 failed (see calMsg)
globalvar calMsg = "measuring the island"
globalvar floorY
globalvar isleCenter
globalvar edgeXMin
globalvar edgeXMax
globalvar edgeZMin
globalvar edgeZMax
globalvar probeDir
globalvar probeLo
globalvar probeHi
globalvar probeMid
globalvar probeI
globalvar cell
globalvar gridX0
globalvar zBase = [0, 0]
globalvar zSign = [1, -1]
globalvar cellPos = []          # [side * 48 + cell]
globalvar startPos = [0, 0]
globalvar goalPos = [0, 0]
globalvar camEye
globalvar camLook
globalvar runSpeed
globalvar coastDist
globalvar actTimeout
globalvar calP0
globalvar calP1
globalvar calT0
globalvar spawnTry
globalvar spawnI
globalvar spawnCalls = 0
globalvar n1
globalvar n2
globalvar bots = []
globalvar nBots = 0
globalvar condOffset = 0
globalvar matchT0 = 0
globalvar stopping = false
globalvar logBytes = 0
globalvar totalEpisodes = 0
globalvar totalSteps = 0
globalvar feat = [null, null]   # the bot whose policy arrows are drawn on each strip
globalvar featI = 0
globalvar uiI
globalvar uiJ
globalvar glyphSet = [["→", "←", "↓", "↑"], ["→", "←", "↑", "↓"]]   # drawn for the overhead camera
globalvar stopReason = 0
globalvar hudHead = ""
globalvar hudLine = []
globalvar hudFeat = ["", ""]
globalvar hudI
globalvar duelT1 = []
globalvar duelT2 = []
globalvar logQ = []
globalvar flushN
globalvar flushI
globalvar scriptPlan = SCRIPT_PLAN      # golden test only: every bot takes these actions in order instead of choosing

# ---------------------------------------------------------------------------
# Per-bot state
# ---------------------------------------------------------------------------
playervar bid = -1
playervar side = 0
playervar done = false
playervar died = false
playervar runCount = 0
playervar cond
playervar algo
playervar alpha
playervar eps
playervar eps0
playervar planN
playervar lam
playervar bonus
playervar trainEps
playervar isTraining = true
playervar runT0
playervar epCount = 0
playervar evalCount = 0
playervar cntGoal = 0
playervar cntFell = 0
playervar cntTimeout = 0
playervar evGoal = 0
playervar evFell = 0
playervar evTimeout = 0
playervar runSteps = 0
playervar runSlips = 0
playervar lastReturn = 0
playervar lastOutcome = 0
playervar Q = []
playervar Nsa = []
playervar E = []
playervar mS2 = []
playervar mR = []
playervar mKnown = []
playervar mSeen = []
playervar Vtd = []
playervar Vmc = []
playervar Vtd2 = []
playervar Nv = []
playervar epS = []
playervar epR = []
playervar glyph = []
playervar curS
playervar curCell
playervar nextCell
playervar agg = 0
playervar isBlocker = false
playervar partner = null        # the runner's blocker (duel build)
playervar blockMode = 0
playervar station = -1          # the row the blocker stands in this episode
playervar seenRow = 0           # what the runner is told about it (0 when it is not told)
playervar Qb = [0, 0, 0, 0]     # the blocker's score for each row, learned as a four-armed bandit
playervar Nb = [0, 0, 0, 0]
playervar bumps = 0
playervar curA
playervar curExplore
playervar nextS
playervar nextA
playervar nextExplore
playervar reward
playervar terminal
playervar outcome
playervar epSteps
playervar epReturn
playervar epEdgeSum
playervar epSlips
playervar stepCol
playervar stepRow
playervar tgtCol
playervar tgtRow
playervar tgtPos
playervar actDir
playervar intended
playervar obsP
playervar obsCell
playervar selS
playervar selA
playervar selExplore
playervar rowQ
playervar rowMax
playervar idx
playervar qOld
playervar tgt
playervar delta
playervar g
playervar k
playervar a
playervar sweep
playervar vDelta
playervar qNew
playervar s2
playervar pIdx
playervar gS
playervar theta = []
playervar probs = []
playervar baseline = 0
playervar u
playervar actCount = 0
playervar qDirect = 0

subroutine probeEdge
subroutine observe
subroutine resetBot
subroutine chooseAction
subroutine stepEnv
subroutine learnStep
subroutine learnEpisodeEnd
subroutine updateGlyph
subroutine planDP
subroutine startRun
subroutine endRun
subroutine runEpisode
subroutine logTables

macro NOW = getTotalTimeElapsed()

# The Workshop Inspector records what the script does, not only log lines, and when its store is full it stops
# recording and the log file stops with it, with no message. Measured on 2026-11-21 with ten bots:
#   recording always on                      the log stopped after 80 seconds
#   recording on only around each log line   the log stopped after 7 minutes 43 seconds
# The second number shows that switching recording on for one line lets in more than that line. So log lines
# are queued, and one rule writes the whole queue in a single frame once a second, with recording on only then.
macro LOG(s):
    logQ.append(s)

rule "Log: write the queued lines in one frame, once a second":
    wait(1)
    if len(logQ) > 0:
        flushN = min(len(logQ), 150)
        enableInspector()
        for flushI in range(flushN):
            logToInspector(logQ[flushI])
        disableInspector()
        logQ = logQ.slice(flushN, 1000)
    loop()

macro BELOW = (eventPlayer.getPosition().y < floorY - 1.2)
# What the bot is told about where it stands (Lecture 6). 0: the exact cell, 48 states. 1: the row and which
# quarter of the strip, 16 states. 2: the row only, 4 states. The real cell still decides what happens to it.
#                                          3: the exact cell and the row the blocker stands in this episode, 192 states.
macro AGG(c):
    (c if eventPlayer.agg == 0 else (floor(c / NCOLS) * 4 + floor((c % NCOLS) / 3) if eventPlayer.agg == 1 else (floor(c / NCOLS) if eventPlayer.agg == 2 else c + NCELLS * eventPlayer.seenRow)))
macro onPlatform(p):
    abs(raycast(p + vect(0, 2, 0), p - vect(0, 2, 0), null, null, false).getHitPosition().y - floorY) < 0.3

# ---------------------------------------------------------------------------
# Calibration: measure the island with ray casts (nothing is hard-coded).
# ---------------------------------------------------------------------------
def probeEdge():
    @Name "Calibration: find one edge (binary search on downward rays)"
    probeLo = 0
    probeHi = 4
    while onPlatform(isleCenter + probeDir * probeHi) and probeHi < 512:
        probeLo = probeHi
        probeHi *= 2
    for probeI in range(16):
        probeMid = (probeLo + probeHi) / 2
        if onPlatform(isleCenter + probeDir * probeMid):
            probeLo = probeMid
        else:
            probeHi = probeMid
    wait()

rule "Init: measure the island and lay out both strips":
    disableInspector()
    pauseMatchTime()
    wait(1)
    isleCenter = raycast(vect(0, 60, 0), vect(0, -60, 0), null, null, false).getHitPosition()
    floorY = isleCenter.y
    probeDir = vect(1, 0, 0)
    probeEdge()
    edgeXMax = isleCenter.x + probeLo
    probeDir = vect(-1, 0, 0)
    probeEdge()
    edgeXMin = isleCenter.x - probeLo
    probeDir = vect(0, 0, 1)
    probeEdge()
    edgeZMax = isleCenter.z + probeLo
    probeDir = vect(0, 0, -1)
    probeEdge()
    edgeZMin = isleCenter.z - probeLo
    if isleCenter.y < -59 or edgeXMax - edgeXMin < 26 or edgeZMax - edgeZMin < 22 or edgeXMax - edgeXMin > 500:
        calStage = -1
        calMsg = "island measurement looks wrong. Is the map Workshop Island?"
        LOG("NS,FAIL,island,{},{},{},{},{}".format(edgeXMin, edgeXMax, edgeZMin, edgeZMax, floorY))
        return
    cell = min(cfgCell, (edgeXMax - edgeXMin - 4) / NCOLS)
    gridX0 = (edgeXMin + edgeXMax) / 2 - NCOLS * cell / 2
    zBase = [edgeZMin + MARGIN, edgeZMax - MARGIN]
    for probeI in range(2 * NCELLS):
        cellPos[probeI] = vect(gridX0 + (probeI % NCOLS + 0.5) * cell, floorY, zBase[floor(probeI / NCELLS)] + zSign[floor(probeI / NCELLS)] * (floor((probeI % NCELLS) / NCOLS) + 0.5) * cell)
    startPos = [cellPos[START_CELL], cellPos[NCELLS + START_CELL]]
    goalPos = [cellPos[GOAL_CELL], cellPos[NCELLS + GOAL_CELL]]
    camEye = vect((edgeXMin + edgeXMax) / 2, floorY + CAM_HEIGHT, (edgeZMin + edgeZMax) / 2 + CAM_BACK)
    camLook = vect((edgeXMin + edgeXMax) / 2, floorY, (edgeZMin + edgeZMax) / 2 + CAM_LOOK_Z)
    calStage = 1
    calMsg = "spawning bots"

rule "Init: spawn the bots, measure their run speed, start the block":
    @Condition calStage == 1
    # Up to five tries: on 2026-11-21 a bot failed to appear in two matches in a row, cause not found.
    for spawnTry in range(5):
        n1 = len([p for p in getPlayers(Team.1) if p.isDummy()])
        n2 = len([p for p in getPlayers(Team.2) if p.isDummy()])
        if n1 < cfgBotsPerTeam or n2 < cfgBotsPerTeam:
            for spawnI in range(cfgBotsPerTeam - n1):
                createDummy(Hero.TRACER, Team.1, -1, startPos[0], vect(1, 0, 0))
                spawnCalls += 1
                wait(0.25)
            for spawnI in range(cfgBotsPerTeam - n2):
                createDummy(Hero.TRACER, Team.2, -1, startPos[1], vect(1, 0, 0))
                spawnCalls += 1
                wait(0.25)
            wait(1.5)
    bots = [p for p in getPlayers(Team.1) if p.isDummy()].concat([p for p in getPlayers(Team.2) if p.isDummy()])
    if DUEL:
        # Lecture 10 build: one runner per strip, and one blocker from the other team standing on the same strip.
        # Enemy heroes cannot walk through each other, so the blocker's body is a real obstacle.
        duelT1 = [p for p in getPlayers(Team.1) if p.isDummy()]
        duelT2 = [p for p in getPlayers(Team.2) if p.isDummy()]
        bots = [duelT1[0], duelT2[0]]
        duelT1[0].partner = duelT2[1]
        duelT2[0].partner = duelT1[1]
        duelT2[1].isBlocker = true
        duelT1[1].isBlocker = true
        duelT2[1].side = 0
        duelT1[1].side = 1
        duelT2[1].startForcingPosition(vect((edgeXMin + edgeXMax) / 2 - 3, floorY, (edgeZMin + edgeZMax) / 2), false)
        duelT1[1].startForcingPosition(vect((edgeXMin + edgeXMax) / 2 + 3, floorY, (edgeZMin + edgeZMax) / 2), false)
    nBots = len(bots)
    if nBots < 1:
        calStage = -1
        calMsg = "no bot spawned. Leave free slots on both teams, then Esc > Show Lobby > Restart Match"
        LOG("NS,FAIL,spawn,{},{}".format(len(getPlayers(Team.1)), len(getPlayers(Team.2))))
        return
    bots.setMoveSpeed(cfgMoveSpeed)

    # Speed run with the first bot: its real run speed, and how far it coasts after the throttle stops.
    calMsg = "measuring run speed"
    bots[0].startForcingPosition(cellPos[2 * NCOLS], false)
    wait(0.25)
    bots[0].stopForcingPosition()
    bots[0].setFacing(vect(1, 0, 0), Relativity.TO_WORLD)
    wait(0.4)
    bots[0].startThrottleInDirection(vect(1, 0, 0), 1, Relativity.TO_WORLD, Throttle.REPLACE_EXISTING, ThrottleReeval.NONE)
    wait(0.4)
    calP0 = bots[0].getPosition()
    calT0 = NOW
    wait(0.6)
    calP1 = bots[0].getPosition()
    runSpeed = distance(calP0, calP1) / (NOW - calT0)
    bots[0].stopThrottleInDirection()
    wait(0.5)
    coastDist = distance(calP1, bots[0].getPosition())
    if runSpeed < 1:
        calStage = -1
        calMsg = "the bot did not move under throttle control"
        LOG("NS,FAIL,throttle,{},{},{}".format(runSpeed, calP0, calP1))
        return
    actTimeout = 2.5 * cell / runSpeed + 0.25
    condOffset = random.randint(0, len(condOrder) - 1) if FORCE_OFFSET < 0 else FORCE_OFFSET
    feat = [bots[0], bots.last()]
    matchT0 = NOW
    # M: version, bots, team1 bots, cell, run speed, coast, move speed %, eval episodes, step limit, eval step limit,
    #    gamma*1000, r_step, r_goal, r_fall, r_timeout, condition offset, spawn calls, conditions, no-new-run minute, longest run (minutes)
    LOG("NS,M,{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{}".format(BUILD_VERSION, nBots, len([p for p in getPlayers(Team.1) if p.isDummy()]), cell, runSpeed, coastDist, cfgMoveSpeed, cfgEvalEps, cfgMaxSteps, cfgEvalMaxSteps, round(gamma * 1000), rStep, rGoal, rFall, rTimeout, condOffset, spawnCalls, NCOND, cfgSoftMin, cfgRunMaxMin))
    LOG("NS,CAL,{},{},{},{},{},{},{}".format(floorY, edgeXMin, edgeXMax, edgeZMin, edgeZMax, gridX0, actTimeout))
    logBytes += 260
    for spawnI in range(nBots):
        bots[spawnI].side = 0 if bots[spawnI].getTeam() == Team.1 else 1
        bots[spawnI].bid = spawnI
    calStage = 2
    calMsg = "running"

# ---------------------------------------------------------------------------
# Environment
# ---------------------------------------------------------------------------
def observe():
    @Name "Environment: read the cell from the bot's real position"
    eventPlayer.obsP = eventPlayer.getPosition()
    eventPlayer.obsCell = min(max(floor(zSign[eventPlayer.side] * (eventPlayer.obsP.z - zBase[eventPlayer.side]) / cell), 0), NROWS - 1) * NCOLS + min(max(floor((eventPlayer.obsP.x - gridX0) / cell), 0), NCOLS - 1)

def resetBot():
    @Name "Environment: put the bot back on its start cell"
    eventPlayer.stopThrottleInDirection()
    if eventPlayer.isDead():
        eventPlayer.resurrect()
        wait(0.25)
        if eventPlayer.isDead():
            eventPlayer.respawn()
            waitUntil(eventPlayer.isAlive(), 3)
    eventPlayer.startForcingPosition(startPos[eventPlayer.side], false)
    wait(0.15)
    eventPlayer.stopForcingPosition()
    eventPlayer.setFacing(vect(1, 0, 0), Relativity.TO_WORLD)
    waitUntil(eventPlayer.isOnGround(), 1)
    eventPlayer.died = false

rule "Environment: a bot died (fell too far before the reset caught it)":
    @Event playerDied
    @Condition eventPlayer.isDummy()
    eventPlayer.died = true

def stepEnv():
    @Name "Environment: carry out action curA with the real bot and observe the result"
    eventPlayer.stepCol = eventPlayer.curCell % NCOLS
    eventPlayer.stepRow = floor(eventPlayer.curCell / NCOLS)
    eventPlayer.actDir = [vect(1, 0, 0), vect(-1, 0, 0), vect(0, 0, zSign[eventPlayer.side]), vect(0, 0, 0 - zSign[eventPlayer.side])][eventPlayer.curA]
    eventPlayer.tgtCol = eventPlayer.stepCol + [1, -1, 0, 0][eventPlayer.curA]
    eventPlayer.tgtRow = eventPlayer.stepRow + [0, 0, 1, -1][eventPlayer.curA]
    eventPlayer.reward = rStep
    eventPlayer.terminal = false
    eventPlayer.outcome = Outcome.RUNNING
    if eventPlayer.tgtCol < 0 or eventPlayer.tgtCol >= NCOLS or eventPlayer.tgtRow >= NROWS:
        # Blocked: that side of the grid is open floor and the rule says no. The step still costs its reward.
        eventPlayer.intended = eventPlayer.curCell
        wait(0.032)
    else:
        eventPlayer.intended = eventPlayer.tgtRow * NCOLS + eventPlayer.tgtCol
        eventPlayer.tgtPos = vect(gridX0 + (eventPlayer.tgtCol + 0.5) * cell, floorY, zBase[eventPlayer.side] + zSign[eventPlayer.side] * (eventPlayer.tgtRow + 0.5) * cell)
        eventPlayer.setFacing(eventPlayer.actDir, Relativity.TO_WORLD)
        eventPlayer.startThrottleInDirection(eventPlayer.actDir, 1, Relativity.TO_WORLD, Throttle.REPLACE_EXISTING, ThrottleReeval.NONE)
        if eventPlayer.tgtRow < 0:
            # Off the edge: keep running until the bot is really falling.
            waitUntil(BELOW or eventPlayer.died, actTimeout)
        else:
            # Cut the throttle one coast distance short, so the bot slides to a stop on the cell centre.
            waitUntil(dotProduct(eventPlayer.tgtPos - eventPlayer.getPosition(), eventPlayer.actDir) <= coastDist or BELOW or eventPlayer.died, actTimeout)
        eventPlayer.stopThrottleInDirection()
        if eventPlayer.tgtRow < 0:
            waitUntil(BELOW or eventPlayer.died, 1)
        else:
            waitUntil(eventPlayer.getHorizontalSpeed() < 0.2 or BELOW or eventPlayer.died, 0.4)
    observe()
    eventPlayer.nextCell = eventPlayer.obsCell
    eventPlayer.nextS = AGG(eventPlayer.nextCell)
    if BELOW or eventPlayer.died:
        eventPlayer.terminal = true
        eventPlayer.outcome = Outcome.FELL
        eventPlayer.reward += rFall
        if eventPlayer.tgtRow >= 0:
            eventPlayer.epSlips += 1
    else:
        eventPlayer.epEdgeSum += zSign[eventPlayer.side] * (eventPlayer.obsP.z - zBase[eventPlayer.side]) + MARGIN
        if eventPlayer.nextCell != eventPlayer.intended:
            eventPlayer.epSlips += 1
        if eventPlayer.nextCell == GOAL_CELL:
            eventPlayer.terminal = true
            eventPlayer.outcome = Outcome.GOAL
            eventPlayer.reward += rGoal
        elif eventPlayer.epSteps + 1 >= (cfgMaxSteps if eventPlayer.isTraining else cfgEvalMaxSteps):
            eventPlayer.terminal = true
            eventPlayer.outcome = Outcome.TIMEOUT
            eventPlayer.reward += rTimeout

# ---------------------------------------------------------------------------
# Agents
# ---------------------------------------------------------------------------
def chooseAction():
    @Name "Agent: action for state selS"
    eventPlayer.selExplore = false
    if SCRIPTED and eventPlayer.isTraining:
        # Golden test: a fixed walk, so every table can be recomputed outside the game and compared.
        eventPlayer.selA = scriptPlan[eventPlayer.actCount % len(scriptPlan)]
        eventPlayer.actCount += 1
        return
    if eventPlayer.algo == Alg.RANDOM:
        eventPlayer.selA = random.randint(0, NA - 1)
        eventPlayer.selExplore = true
        return
    if eventPlayer.algo == Alg.PG or eventPlayer.algo == Alg.AC:
        # Softmax policy over action preferences theta (Lecture 7). Sample in training, take the mode in evaluation.
        eventPlayer.rowQ = eventPlayer.theta.slice(eventPlayer.selS * NA, NA)
        eventPlayer.rowMax = sorted(eventPlayer.rowQ).last()
        eventPlayer.probs = eventPlayer.rowQ.map(lambda x: 2.718281828 ** (x - eventPlayer.rowMax))
        eventPlayer.g = eventPlayer.probs[0] + eventPlayer.probs[1] + eventPlayer.probs[2] + eventPlayer.probs[3]
        eventPlayer.probs = eventPlayer.probs.map(lambda x: x / eventPlayer.g)
        if eventPlayer.isTraining:
            eventPlayer.u = random.uniform(0, 1)
            eventPlayer.selA = 0 if eventPlayer.u < eventPlayer.probs[0] else (1 if eventPlayer.u < eventPlayer.probs[0] + eventPlayer.probs[1] else (2 if eventPlayer.u < eventPlayer.probs[0] + eventPlayer.probs[1] + eventPlayer.probs[2] else 3))
            eventPlayer.selExplore = eventPlayer.rowQ[eventPlayer.selA] < eventPlayer.rowMax - 0.0001
        else:
            eventPlayer.selA = random.choice([0, 1, 2, 3].filter(lambda x: eventPlayer.rowQ[x] >= eventPlayer.rowMax - 0.0001))
        return
    eventPlayer.rowQ = eventPlayer.Q.slice(eventPlayer.selS * NA, NA)
    if eventPlayer.bonus > 0 and eventPlayer.isTraining:
        # Count bonus: actions tried less often look better (Lecture 9, optimism in the face of uncertainty).
        eventPlayer.rowQ = eventPlayer.rowQ.map(lambda q, i: q + eventPlayer.bonus / sqrt(eventPlayer.Nsa[eventPlayer.selS * NA + i] + 1))
    eventPlayer.rowMax = sorted(eventPlayer.rowQ).last()
    eventPlayer.selA = random.choice([0, 1, 2, 3].filter(lambda x: eventPlayer.rowQ[x] >= eventPlayer.rowMax - 0.0001))
    if eventPlayer.isTraining and random.uniform(0, 1) < eventPlayer.eps:
        eventPlayer.selA = random.randint(0, NA - 1)
        eventPlayer.selExplore = true

def updateGlyph():
    @Name "Agent: refresh the policy arrow for cell gS"
    if eventPlayer.gS == GOAL_CELL:
        eventPlayer.glyph[eventPlayer.gS] = "G"
        return
    eventPlayer.rowQ = (eventPlayer.theta if (eventPlayer.algo == Alg.PG or eventPlayer.algo == Alg.AC) else eventPlayer.Q).slice(AGG(eventPlayer.gS) * NA, NA)
    eventPlayer.rowMax = sorted(eventPlayer.rowQ).last()
    if sorted(eventPlayer.rowQ)[0] == eventPlayer.rowMax:
        eventPlayer.glyph[eventPlayer.gS] = "·"
    else:
        eventPlayer.glyph[eventPlayer.gS] = glyphSet[eventPlayer.side][eventPlayer.rowQ.index(eventPlayer.rowMax)]

def learnStep():
    @Name "Agent: the update after one real step"
    eventPlayer.idx = eventPlayer.curS * NA + eventPlayer.curA
    eventPlayer.qOld = eventPlayer.Q[eventPlayer.idx]
    eventPlayer.qDirect = eventPlayer.qOld
    eventPlayer.tgt = 0
    if eventPlayer.algo == Alg.SARSA:
        # SARSA: score the move by the action the bot will really take next.
        eventPlayer.tgt = eventPlayer.reward + (0 if eventPlayer.terminal else gamma * eventPlayer.Q[eventPlayer.nextS * NA + eventPlayer.nextA])
        eventPlayer.Q[eventPlayer.idx] = eventPlayer.qOld + eventPlayer.alpha * (eventPlayer.tgt - eventPlayer.qOld)
    elif eventPlayer.algo == Alg.QL or eventPlayer.algo == Alg.DYNA:
        # Q-learning: score the move by the best action available next.
        eventPlayer.tgt = eventPlayer.reward + (0 if eventPlayer.terminal else gamma * sorted(eventPlayer.Q.slice(eventPlayer.nextS * NA, NA)).last())
        eventPlayer.Q[eventPlayer.idx] = eventPlayer.qOld + eventPlayer.alpha * (eventPlayer.tgt - eventPlayer.qOld)
        eventPlayer.qDirect = eventPlayer.Q[eventPlayer.idx]
        if eventPlayer.algo == Alg.DYNA and eventPlayer.outcome != Outcome.TIMEOUT:
            # Dyna-Q (Lecture 8): remember what this move did, then replay remembered moves in imagination.
            # A timeout is a property of the clock, not of the move, so it is kept out of the model.
            if not eventPlayer.mKnown[eventPlayer.idx]:
                eventPlayer.mKnown[eventPlayer.idx] = true
                eventPlayer.mSeen.append(eventPlayer.idx)
            eventPlayer.mS2[eventPlayer.idx] = -1 if eventPlayer.terminal else eventPlayer.nextS
            eventPlayer.mR[eventPlayer.idx] = eventPlayer.reward
            for eventPlayer.k in range(eventPlayer.planN):
                eventPlayer.pIdx = random.choice(eventPlayer.mSeen)
                eventPlayer.s2 = eventPlayer.mS2[eventPlayer.pIdx]
                eventPlayer.qNew = eventPlayer.mR[eventPlayer.pIdx] + (0 if eventPlayer.s2 < 0 else gamma * sorted(eventPlayer.Q.slice(eventPlayer.s2 * NA, NA)).last())
                eventPlayer.Q[eventPlayer.pIdx] += eventPlayer.alpha * (eventPlayer.qNew - eventPlayer.Q[eventPlayer.pIdx])
    elif eventPlayer.algo == Alg.ESARSA:
        # Expected SARSA: score the move by the average over what the bot might do next.
        eventPlayer.rowQ = eventPlayer.Q.slice(eventPlayer.nextS * NA, NA)
        eventPlayer.tgt = eventPlayer.reward + (0 if eventPlayer.terminal else gamma * ((1 - eventPlayer.eps) * sorted(eventPlayer.rowQ).last() + eventPlayer.eps * (eventPlayer.rowQ[0] + eventPlayer.rowQ[1] + eventPlayer.rowQ[2] + eventPlayer.rowQ[3]) / 4))
        eventPlayer.Q[eventPlayer.idx] = eventPlayer.qOld + eventPlayer.alpha * (eventPlayer.tgt - eventPlayer.qOld)
    elif eventPlayer.algo == Alg.LAMBDA:
        # SARSA(lambda), replacing traces: one surprise updates every recently visited move, fading with age.
        eventPlayer.tgt = eventPlayer.reward + (0 if eventPlayer.terminal else gamma * eventPlayer.Q[eventPlayer.nextS * NA + eventPlayer.nextA])
        eventPlayer.delta = eventPlayer.tgt - eventPlayer.qOld
        eventPlayer.E[eventPlayer.idx] = 1
        eventPlayer.Q = eventPlayer.Q.map(lambda q, i: q + eventPlayer.alpha * eventPlayer.delta * eventPlayer.E[i])
        eventPlayer.E = eventPlayer.E.map(lambda e: e * gamma * eventPlayer.lam)
    elif eventPlayer.algo == Alg.MC or eventPlayer.algo == Alg.PG:
        # Monte Carlo and REINFORCE wait for the episode to end: only remember the step.
        eventPlayer.epS.append(eventPlayer.idx)
        eventPlayer.epR.append(eventPlayer.reward)
    elif eventPlayer.algo == Alg.AC:
        # One-step actor-critic (Lecture 7): a critic (Vtd) predicts the return from each cell; the move just
        # taken is made more likely if the prediction went up across it, less likely if it went down.
        eventPlayer.delta = eventPlayer.reward + (0 if eventPlayer.terminal else gamma * eventPlayer.Vtd[eventPlayer.nextS]) - eventPlayer.Vtd[eventPlayer.curS]
        eventPlayer.Vtd[eventPlayer.curS] += 0.2 * eventPlayer.delta
        eventPlayer.rowQ = eventPlayer.theta.slice(eventPlayer.curS * NA, NA)
        eventPlayer.rowMax = sorted(eventPlayer.rowQ).last()
        eventPlayer.probs = eventPlayer.rowQ.map(lambda x: 2.718281828 ** (x - eventPlayer.rowMax))
        eventPlayer.u = eventPlayer.probs[0] + eventPlayer.probs[1] + eventPlayer.probs[2] + eventPlayer.probs[3]
        for eventPlayer.a in range(NA):
            eventPlayer.theta[eventPlayer.curS * NA + eventPlayer.a] += eventPlayer.alpha * eventPlayer.delta * ((1 if eventPlayer.a == eventPlayer.curA else 0) - eventPlayer.probs[eventPlayer.a] / eventPlayer.u)
    elif eventPlayer.algo == Alg.RANDOM:
        # Prediction (Lecture 4): the policy is fixed (uniform random); TD(0) learns its value every step.
        eventPlayer.tgt = eventPlayer.reward + (0 if eventPlayer.terminal else gamma * eventPlayer.Vtd[eventPlayer.nextS])
        eventPlayer.Vtd[eventPlayer.curS] += eventPlayer.alpha * (eventPlayer.tgt - eventPlayer.Vtd[eventPlayer.curS])
        # A second TD(0) table with a five times larger step, to show what the step size does.
        eventPlayer.Vtd2[eventPlayer.curS] += 0.5 * (eventPlayer.reward + (0 if eventPlayer.terminal else gamma * eventPlayer.Vtd2[eventPlayer.nextS]) - eventPlayer.Vtd2[eventPlayer.curS])
        eventPlayer.epS.append(eventPlayer.curS)
        eventPlayer.epR.append(eventPlayer.reward)
    eventPlayer.Nsa[eventPlayer.idx] += 1
    eventPlayer.gS = eventPlayer.curCell
    updateGlyph()

def learnEpisodeEnd():
    @Name "Agent: the update at the end of an episode (Monte Carlo, REINFORCE, MC prediction)"
    eventPlayer.g = 0
    if eventPlayer.algo == Alg.MC:
        # Every-visit Monte Carlo control: move each visited Q toward the return that actually followed.
        for eventPlayer.k in range(len(eventPlayer.epS) - 1, -1, -1):
            eventPlayer.g = gamma * eventPlayer.g + eventPlayer.epR[eventPlayer.k]
            eventPlayer.Q[eventPlayer.epS[eventPlayer.k]] += eventPlayer.alpha * (eventPlayer.g - eventPlayer.Q[eventPlayer.epS[eventPlayer.k]])
    elif eventPlayer.algo == Alg.RANDOM:
        # Every-visit Monte Carlo prediction: V(s) is the running mean of the returns seen from s.
        for eventPlayer.k in range(len(eventPlayer.epS) - 1, -1, -1):
            eventPlayer.g = gamma * eventPlayer.g + eventPlayer.epR[eventPlayer.k]
            eventPlayer.Nv[eventPlayer.epS[eventPlayer.k]] += 1
            eventPlayer.Vmc[eventPlayer.epS[eventPlayer.k]] += (eventPlayer.g - eventPlayer.Vmc[eventPlayer.epS[eventPlayer.k]]) / eventPlayer.Nv[eventPlayer.epS[eventPlayer.k]]
    elif eventPlayer.algo == Alg.PG:
        # REINFORCE with a baseline (Lecture 7): raise the preference of each action taken in proportion to
        # how much better than usual the episode went from there on. Q doubles as the baseline per state-action.
        for eventPlayer.k in range(len(eventPlayer.epS) - 1, -1, -1):
            eventPlayer.g = gamma * eventPlayer.g + eventPlayer.epR[eventPlayer.k]
            eventPlayer.idx = eventPlayer.epS[eventPlayer.k]
            eventPlayer.s2 = floor(eventPlayer.idx / NA)
            eventPlayer.rowQ = eventPlayer.theta.slice(eventPlayer.s2 * NA, NA)
            eventPlayer.rowMax = sorted(eventPlayer.rowQ).last()
            eventPlayer.probs = eventPlayer.rowQ.map(lambda x: 2.718281828 ** (x - eventPlayer.rowMax))
            eventPlayer.u = eventPlayer.probs[0] + eventPlayer.probs[1] + eventPlayer.probs[2] + eventPlayer.probs[3]
            eventPlayer.delta = eventPlayer.g - eventPlayer.Vtd[eventPlayer.s2]
            eventPlayer.Vtd[eventPlayer.s2] += 0.2 * eventPlayer.delta
            for eventPlayer.a in range(NA):
                eventPlayer.theta[eventPlayer.s2 * NA + eventPlayer.a] += eventPlayer.alpha * eventPlayer.delta * ((1 if eventPlayer.a == eventPlayer.idx % NA else 0) - eventPlayer.probs[eventPlayer.a] / eventPlayer.u)
            eventPlayer.Q[eventPlayer.idx] += 0.2 * (eventPlayer.g - eventPlayer.Q[eventPlayer.idx])

def planDP():
    @Name "Agent: value iteration on the grid's rules, no walking (Lecture 3)"
    # The planner is told the rules: where each move leads, what it costs, where the cliff and the goal are.
    for eventPlayer.sweep in range(60):
        eventPlayer.vDelta = 0
        for eventPlayer.k in range(NCELLS):
            if eventPlayer.k != GOAL_CELL:
                for eventPlayer.a in range(NA):
                    eventPlayer.tgtCol = eventPlayer.k % NCOLS + [1, -1, 0, 0][eventPlayer.a]
                    eventPlayer.tgtRow = floor(eventPlayer.k / NCOLS) + [0, 0, 1, -1][eventPlayer.a]
                    if eventPlayer.tgtRow < 0:
                        eventPlayer.qNew = rStep + rFall
                    else:
                        eventPlayer.s2 = eventPlayer.k if (eventPlayer.tgtCol < 0 or eventPlayer.tgtCol >= NCOLS or eventPlayer.tgtRow >= NROWS) else eventPlayer.tgtRow * NCOLS + eventPlayer.tgtCol
                        eventPlayer.qNew = rStep + (rGoal if eventPlayer.s2 == GOAL_CELL else gamma * sorted(eventPlayer.Q.slice(eventPlayer.s2 * NA, NA)).last())
                    eventPlayer.vDelta = max(eventPlayer.vDelta, abs(eventPlayer.qNew - eventPlayer.Q[eventPlayer.k * NA + eventPlayer.a]))
                    eventPlayer.Q[eventPlayer.k * NA + eventPlayer.a] = eventPlayer.qNew
                eventPlayer.gS = eventPlayer.k
                updateGlyph()
            if eventPlayer.k % 6 == 5:
                wait()
        LOG("NS,V,{},{},{},{}".format(eventPlayer.bid, eventPlayer.runCount, eventPlayer.sweep, eventPlayer.vDelta))
        logBytes += 36
        wait(0.4)
        if eventPlayer.vDelta < 0.001:
            break

def startRun():
    @Name "Run: pick the condition, clear the tables, log the header"
    eventPlayer.cond = condOrder[(eventPlayer.bid + condOffset + eventPlayer.runCount) % len(condOrder)]
    eventPlayer.algo = cAlgo[eventPlayer.cond]
    eventPlayer.alpha = cAlpha[eventPlayer.cond]
    eventPlayer.eps0 = cEps[eventPlayer.cond]
    eventPlayer.eps = 1 if eventPlayer.eps0 < 0 else eventPlayer.eps0
    eventPlayer.planN = cPlan[eventPlayer.cond]
    eventPlayer.lam = cLam[eventPlayer.cond]
    eventPlayer.bonus = cBonus[eventPlayer.cond]
    eventPlayer.trainEps = cTrain[eventPlayer.cond]
    eventPlayer.agg = cAgg[eventPlayer.cond]
    eventPlayer.blockMode = cBlock[eventPlayer.cond]
    eventPlayer.seenRow = 0
    eventPlayer.bumps = 0
    if entityExists(eventPlayer.partner):
        eventPlayer.partner.Qb = [0, 0, 0, 0]
        eventPlayer.partner.Nb = [0, 0, 0, 0]
        eventPlayer.partner.station = -1
    eventPlayer.Q = []
    eventPlayer.Q[NQ - 1] = 0
    if cQInit[eventPlayer.cond] != 0:
        eventPlayer.Q = eventPlayer.Q.map(lambda q: cQInit[eventPlayer.cond])
    eventPlayer.Nsa = []
    eventPlayer.Nsa[NQ - 1] = 0
    eventPlayer.E = []
    eventPlayer.E[NQ - 1] = 0
    eventPlayer.theta = []
    eventPlayer.theta[NQ - 1] = 0
    eventPlayer.mKnown = []
    eventPlayer.mKnown[NQ - 1] = false
    eventPlayer.mS2 = []
    eventPlayer.mR = []
    eventPlayer.mSeen = []
    eventPlayer.Vtd = []
    eventPlayer.Vtd[NSTATES - 1] = 0
    eventPlayer.Vmc = []
    eventPlayer.Vmc[NCELLS - 1] = 0
    eventPlayer.Vtd2 = []
    eventPlayer.Vtd2[NCELLS - 1] = 0
    eventPlayer.Nv = []
    eventPlayer.Nv[NCELLS - 1] = 0
    for eventPlayer.k in range(NCELLS):
        eventPlayer.glyph[eventPlayer.k] = "·"
    eventPlayer.glyph[GOAL_CELL] = "G"
    eventPlayer.epCount = 0
    eventPlayer.evalCount = 0
    eventPlayer.cntGoal = 0
    eventPlayer.cntFell = 0
    eventPlayer.cntTimeout = 0
    eventPlayer.evGoal = 0
    eventPlayer.evFell = 0
    eventPlayer.evTimeout = 0
    eventPlayer.runSteps = 0
    eventPlayer.runSlips = 0
    eventPlayer.isTraining = true
    eventPlayer.actCount = 0
    eventPlayer.runT0 = NOW
    eventPlayer.startForcingName("{} {}".format(cName[eventPlayer.cond], eventPlayer.bid))
    # H: bot, run, condition, algo, eps*1000 (-1000 = decays), alpha*1000, initial Q, planning steps, lambda*1000, bonus, training episodes, side, t, state detail (0 cell, 1 quarter, 2 row)
    LOG("NS,H,{},{},{},{},{},{},{},{},{},{},{},{},{},{}".format(eventPlayer.bid, eventPlayer.runCount, eventPlayer.cond, eventPlayer.algo, round(eventPlayer.eps0 * 1000), round(eventPlayer.alpha * 1000), cQInit[eventPlayer.cond], eventPlayer.planN, round(eventPlayer.lam * 1000), eventPlayer.bonus, eventPlayer.trainEps, eventPlayer.side, NOW - matchT0, eventPlayer.agg))
    logBytes += 70
    if eventPlayer.algo == Alg.DP:
        planDP()

def logTables():
    @Name "Log: the bot's tables (Q or preferences per visited state; value tables for the prediction bot)"
    if eventPlayer.algo == Alg.RANDOM:
        # P: bot, run, episode, kind (0 TD(0) step 0.1, 1 Monte Carlo, 2 visits, 3 TD(0) step 0.5), row, then the 12 values of that row
        for eventPlayer.k in range(NROWS):
            LOG("NS,P,{},{},{},0,{},{},{},{},{},{},{},{},{},{},{},{},{}".format(eventPlayer.bid, eventPlayer.runCount, eventPlayer.epCount, eventPlayer.k, eventPlayer.Vtd[eventPlayer.k * NCOLS], eventPlayer.Vtd[eventPlayer.k * NCOLS + 1], eventPlayer.Vtd[eventPlayer.k * NCOLS + 2], eventPlayer.Vtd[eventPlayer.k * NCOLS + 3], eventPlayer.Vtd[eventPlayer.k * NCOLS + 4], eventPlayer.Vtd[eventPlayer.k * NCOLS + 5], eventPlayer.Vtd[eventPlayer.k * NCOLS + 6], eventPlayer.Vtd[eventPlayer.k * NCOLS + 7], eventPlayer.Vtd[eventPlayer.k * NCOLS + 8], eventPlayer.Vtd[eventPlayer.k * NCOLS + 9], eventPlayer.Vtd[eventPlayer.k * NCOLS + 10], eventPlayer.Vtd[eventPlayer.k * NCOLS + 11]))
            LOG("NS,P,{},{},{},1,{},{},{},{},{},{},{},{},{},{},{},{},{}".format(eventPlayer.bid, eventPlayer.runCount, eventPlayer.epCount, eventPlayer.k, eventPlayer.Vmc[eventPlayer.k * NCOLS], eventPlayer.Vmc[eventPlayer.k * NCOLS + 1], eventPlayer.Vmc[eventPlayer.k * NCOLS + 2], eventPlayer.Vmc[eventPlayer.k * NCOLS + 3], eventPlayer.Vmc[eventPlayer.k * NCOLS + 4], eventPlayer.Vmc[eventPlayer.k * NCOLS + 5], eventPlayer.Vmc[eventPlayer.k * NCOLS + 6], eventPlayer.Vmc[eventPlayer.k * NCOLS + 7], eventPlayer.Vmc[eventPlayer.k * NCOLS + 8], eventPlayer.Vmc[eventPlayer.k * NCOLS + 9], eventPlayer.Vmc[eventPlayer.k * NCOLS + 10], eventPlayer.Vmc[eventPlayer.k * NCOLS + 11]))
            LOG("NS,P,{},{},{},2,{},{},{},{},{},{},{},{},{},{},{},{},{}".format(eventPlayer.bid, eventPlayer.runCount, eventPlayer.epCount, eventPlayer.k, eventPlayer.Nv[eventPlayer.k * NCOLS], eventPlayer.Nv[eventPlayer.k * NCOLS + 1], eventPlayer.Nv[eventPlayer.k * NCOLS + 2], eventPlayer.Nv[eventPlayer.k * NCOLS + 3], eventPlayer.Nv[eventPlayer.k * NCOLS + 4], eventPlayer.Nv[eventPlayer.k * NCOLS + 5], eventPlayer.Nv[eventPlayer.k * NCOLS + 6], eventPlayer.Nv[eventPlayer.k * NCOLS + 7], eventPlayer.Nv[eventPlayer.k * NCOLS + 8], eventPlayer.Nv[eventPlayer.k * NCOLS + 9], eventPlayer.Nv[eventPlayer.k * NCOLS + 10], eventPlayer.Nv[eventPlayer.k * NCOLS + 11]))
            LOG("NS,P,{},{},{},3,{},{},{},{},{},{},{},{},{},{},{},{},{}".format(eventPlayer.bid, eventPlayer.runCount, eventPlayer.epCount, eventPlayer.k, eventPlayer.Vtd2[eventPlayer.k * NCOLS], eventPlayer.Vtd2[eventPlayer.k * NCOLS + 1], eventPlayer.Vtd2[eventPlayer.k * NCOLS + 2], eventPlayer.Vtd2[eventPlayer.k * NCOLS + 3], eventPlayer.Vtd2[eventPlayer.k * NCOLS + 4], eventPlayer.Vtd2[eventPlayer.k * NCOLS + 5], eventPlayer.Vtd2[eventPlayer.k * NCOLS + 6], eventPlayer.Vtd2[eventPlayer.k * NCOLS + 7], eventPlayer.Vtd2[eventPlayer.k * NCOLS + 8], eventPlayer.Vtd2[eventPlayer.k * NCOLS + 9], eventPlayer.Vtd2[eventPlayer.k * NCOLS + 10], eventPlayer.Vtd2[eventPlayer.k * NCOLS + 11]))
            logBytes += 400
            wait()
        return
    # Q: bot, run, state, the four values (action preferences for the policy-gradient bots), visits to the state
    for eventPlayer.k in range(NSTATES):
        eventPlayer.u = eventPlayer.Nsa[eventPlayer.k * NA] + eventPlayer.Nsa[eventPlayer.k * NA + 1] + eventPlayer.Nsa[eventPlayer.k * NA + 2] + eventPlayer.Nsa[eventPlayer.k * NA + 3]
        if eventPlayer.u > 0 or (eventPlayer.algo == Alg.DP and eventPlayer.k != GOAL_CELL):
            if eventPlayer.algo == Alg.PG or eventPlayer.algo == Alg.AC:
                LOG("NS,Q,{},{},{},{},{},{},{},{}".format(eventPlayer.bid, eventPlayer.runCount, eventPlayer.k, eventPlayer.theta[eventPlayer.k * NA], eventPlayer.theta[eventPlayer.k * NA + 1], eventPlayer.theta[eventPlayer.k * NA + 2], eventPlayer.theta[eventPlayer.k * NA + 3], eventPlayer.u))
            else:
                LOG("NS,Q,{},{},{},{},{},{},{},{}".format(eventPlayer.bid, eventPlayer.runCount, eventPlayer.k, eventPlayer.Q[eventPlayer.k * NA], eventPlayer.Q[eventPlayer.k * NA + 1], eventPlayer.Q[eventPlayer.k * NA + 2], eventPlayer.Q[eventPlayer.k * NA + 3], eventPlayer.u))
            logBytes += 52
        if eventPlayer.k % 8 == 7:
            wait()

def endRun():
    @Name "Run: log the footer and the tables"
    # F: bot, run, condition, complete (1) or cut short (0), training episodes, goals, falls, timeouts,
    #    evaluation episodes, goals, falls, timeouts, real steps, slips, seconds
    LOG("NS,F,{},{},{},{},{},{},{},{},{},{},{},{},{},{},{}".format(eventPlayer.bid, eventPlayer.runCount, eventPlayer.cond, 1 if (eventPlayer.epCount >= eventPlayer.trainEps and eventPlayer.evalCount >= (0 if eventPlayer.algo == Alg.RANDOM else cfgEvalEps)) else 0, eventPlayer.epCount, eventPlayer.cntGoal, eventPlayer.cntFell, eventPlayer.cntTimeout, eventPlayer.evalCount, eventPlayer.evGoal, eventPlayer.evFell, eventPlayer.evTimeout, eventPlayer.runSteps, eventPlayer.runSlips, NOW - eventPlayer.runT0))
    logBytes += 80
    if eventPlayer.blockMode > 0 and entityExists(eventPlayer.partner):
        # B: bot, run, the blocker's score for rows 0 to 3, then how many training episodes it stood in each
        LOG("NS,B,{},{},{},{},{},{},{},{},{},{}".format(eventPlayer.bid, eventPlayer.runCount, eventPlayer.partner.Qb[0], eventPlayer.partner.Qb[1], eventPlayer.partner.Qb[2], eventPlayer.partner.Qb[3], eventPlayer.partner.Nb[0], eventPlayer.partner.Nb[1], eventPlayer.partner.Nb[2], eventPlayer.partner.Nb[3]))
        logBytes += 70
    logTables()

def runEpisode():
    @Name "Run: one episode"
    if eventPlayer.eps0 < 0:
        eventPlayer.eps = max(0.01, 1 / (1 + eventPlayer.epCount / 5))
    if eventPlayer.blockMode > 0 and entityExists(eventPlayer.partner):
        # The blocker picks a row for this episode: always row 0, or (learning) the row its scores rate best,
        # with one random pick in ten. It stands mid-strip and is pinned there for the episode.
        if eventPlayer.blockMode == 1:
            eventPlayer.partner.station = 0
        else:
            eventPlayer.rowMax = sorted(eventPlayer.partner.Qb).last()
            eventPlayer.partner.station = random.choice([0, 1, 2, 3].filter(lambda x: eventPlayer.partner.Qb[x] >= eventPlayer.rowMax - 0.0001))
            if eventPlayer.isTraining and random.uniform(0, 1) < 0.1:
                eventPlayer.partner.station = random.randint(0, 3)
        # A second "start forcing position" on a bot that is already pinned does nothing (seen in the game, 2026-11-22:
        # the blockers stayed where the setup had parked them). Release, move, pin again.
        eventPlayer.partner.stopForcingPosition()
        eventPlayer.partner.teleport(cellPos[eventPlayer.side * NCELLS + eventPlayer.partner.station * NCOLS + BLOCK_COL])
        if PIN_BLOCKER:
            eventPlayer.partner.startForcingPosition(cellPos[eventPlayer.side * NCELLS + eventPlayer.partner.station * NCOLS + BLOCK_COL], false)
        eventPlayer.seenRow = eventPlayer.partner.station if eventPlayer.agg == 3 else 0
    resetBot()
    eventPlayer.epSteps = 0
    eventPlayer.epReturn = 0
    eventPlayer.epEdgeSum = 0
    eventPlayer.epSlips = 0
    eventPlayer.epS = []
    eventPlayer.epR = []
    if eventPlayer.algo == Alg.LAMBDA:
        eventPlayer.E = []
        eventPlayer.E[NQ - 1] = 0
    observe()
    eventPlayer.curCell = eventPlayer.obsCell
    eventPlayer.curS = AGG(eventPlayer.curCell)
    eventPlayer.selS = eventPlayer.curS
    chooseAction()
    eventPlayer.curA = eventPlayer.selA
    eventPlayer.curExplore = eventPlayer.selExplore
    eventPlayer.terminal = false
    while not eventPlayer.terminal:
        stepEnv()
        if not eventPlayer.terminal:
            # Choose the next action now, with the behaviour policy, for every method.
            eventPlayer.selS = eventPlayer.nextS
            chooseAction()
            eventPlayer.nextA = eventPlayer.selA
            eventPlayer.nextExplore = eventPlayer.selExplore
        if eventPlayer.isTraining and eventPlayer.algo != Alg.DP:
            learnStep()
            if eventPlayer.runSteps < STEP_LOG_N and eventPlayer.algo <= Alg.DYNA:
                # S: bot, run, step in run, s, a, r, s', a', terminal, explored, Q before, Q after the real step's update, target, eps*1000
                LOG("NS,S,{},{},{},{},{},{},{},{},{},{},{},{},{},{}".format(eventPlayer.bid, eventPlayer.runCount, eventPlayer.runSteps, eventPlayer.curS, eventPlayer.curA, eventPlayer.reward, eventPlayer.nextS, eventPlayer.nextA, eventPlayer.terminal, eventPlayer.curExplore, eventPlayer.qOld, eventPlayer.qDirect if eventPlayer.algo == Alg.DYNA else eventPlayer.Q[eventPlayer.curS * NA + eventPlayer.curA], eventPlayer.tgt, round(eventPlayer.eps * 1000)))
                logBytes += 75
        eventPlayer.epSteps += 1
        eventPlayer.runSteps += 1
        eventPlayer.epReturn += eventPlayer.reward
        eventPlayer.curS = eventPlayer.nextS
        eventPlayer.curCell = eventPlayer.nextCell
        eventPlayer.curA = eventPlayer.nextA
        eventPlayer.curExplore = eventPlayer.nextExplore
    eventPlayer.stopThrottleInDirection()
    if eventPlayer.isTraining:
        learnEpisodeEnd()
        if eventPlayer.algo == Alg.DYNA or eventPlayer.algo == Alg.MC or eventPlayer.algo == Alg.LAMBDA or eventPlayer.algo == Alg.PG or eventPlayer.agg > 0:
            # These methods change many cells per episode: redraw every arrow.
            for eventPlayer.gS in range(NCELLS):
                updateGlyph()
        eventPlayer.epCount += 1
        if eventPlayer.outcome == Outcome.GOAL:
            eventPlayer.cntGoal += 1
        elif eventPlayer.outcome == Outcome.FELL:
            eventPlayer.cntFell += 1
        else:
            eventPlayer.cntTimeout += 1
    else:
        eventPlayer.evalCount += 1
        if eventPlayer.outcome == Outcome.GOAL:
            eventPlayer.evGoal += 1
        elif eventPlayer.outcome == Outcome.FELL:
            eventPlayer.evFell += 1
        else:
            eventPlayer.evTimeout += 1
    if eventPlayer.blockMode > 0 and entityExists(eventPlayer.partner):
        # Zero-sum: what the runner lost, the blocker won. The blocker's score for the row it chose moves a tenth
        # of the way toward that (only while the runner is training, so evaluation leaves both sides frozen).
        if eventPlayer.isTraining:
            eventPlayer.partner.Nb[eventPlayer.partner.station] += 1
            if eventPlayer.blockMode == 2:
                eventPlayer.partner.Qb[eventPlayer.partner.station] += 0.1 * ((0 - eventPlayer.epReturn) - eventPlayer.partner.Qb[eventPlayer.partner.station])
    eventPlayer.runSlips += eventPlayer.epSlips
    eventPlayer.lastReturn = eventPlayer.epReturn
    eventPlayer.lastOutcome = eventPlayer.outcome
    totalEpisodes += 1
    totalSteps += eventPlayer.epSteps
    # E: bot, run, episode (evaluation episodes continue the count), mode (0 training, 1 evaluation), return, steps,
    #    outcome (1 goal, 2 fell, 3 timeout), mean distance from the edge (m), slips, seconds since match start,
    #    the row the blocker stood in (-1 when there is no blocker)
    LOG("NS,E,{},{},{},{},{},{},{},{},{},{},{}".format(eventPlayer.bid, eventPlayer.runCount, eventPlayer.epCount + eventPlayer.evalCount, 0 if eventPlayer.isTraining else 1, eventPlayer.epReturn, eventPlayer.epSteps, eventPlayer.outcome, eventPlayer.epEdgeSum / max(1, eventPlayer.epSteps), eventPlayer.epSlips, NOW - matchT0, eventPlayer.partner.station if eventPlayer.blockMode > 0 else -1))
    logBytes += 50
    if eventPlayer.algo == Alg.RANDOM and eventPlayer.isTraining and (eventPlayer.epCount == 10 or eventPlayer.epCount == 30 or eventPlayer.epCount == 100):
        logTables()

rule "Bot: run after run until the block ends":
    @Event eachPlayer
    @Condition eventPlayer.isDummy()
    @Condition eventPlayer.bid >= 0
    @Condition eventPlayer.isBlocker == false
    @Condition calStage == 2
    wait(0.5 + eventPlayer.bid * 0.35)
    while calStage == 2 and not stopping and NOW - matchT0 < cfgSoftMin * 60:
        startRun()
        while eventPlayer.epCount < eventPlayer.trainEps and not stopping and NOW - eventPlayer.runT0 < cfgRunMaxMin * 60:
            runEpisode()
            wait(0.1)
        if eventPlayer.algo != Alg.RANDOM:
            eventPlayer.isTraining = false
            while eventPlayer.evalCount < cfgEvalEps and not stopping and NOW - eventPlayer.runT0 < cfgRunMaxMin * 60 + 120:
                runEpisode()
                wait(0.1)
        endRun()
        eventPlayer.runCount += 1
        wait(0.5)
    eventPlayer.done = true
    eventPlayer.startForcingPosition(startPos[eventPlayer.side], false)

# ---------------------------------------------------------------------------
# Block control: end the block, restart the match (a new match starts a new log file).
# ---------------------------------------------------------------------------
rule "Block: end when every bot is done, the log file is nearly full, or the hard time limit passes":
    @Condition calStage == 2
    waitUntil(bots.all(lambda b: b.done) or logBytes > LOG_BUDGET or NOW - matchT0 > (cfgSoftMin + cfgRunMaxMin + 4) * 60, 99999)
    stopReason = 1 if bots.all(lambda b: b.done) else (2 if logBytes > LOG_BUDGET else 3)
    stopping = true
    waitUntil(bots.all(lambda b: b.done), 150)
    # X: reason (1 all bots done, 2 log budget, 3 time limit), seconds, episodes, real steps, estimated log bytes, server load now / average / peak
    LOG("NS,X,{},{},{},{},{},{},{},{}".format(stopReason, NOW - matchT0, totalEpisodes, totalSteps, logBytes, getServerLoad(), getAverageServerLoad(), getPeakServerLoad()))
    calMsg = "block finished"
    # Stage 3 stops the once-a-minute line, so if the restart below does not fire the log goes quiet and the
    # watcher outside the game can tell.
    calStage = 3
    waitUntil(len(logQ) == 0, 20)
    wait(2)
    if cfgAutoRestart:
        restartMatch()

rule "Telemetry: server load once a minute":
    @Condition calStage == 2
    wait(60)
    # L: seconds, load now, average, peak, episodes, real steps, estimated log bytes
    LOG("NS,L,{},{},{},{},{},{},{}".format(NOW - matchT0, getServerLoad(), getAverageServerLoad(), getPeakServerLoad(), totalEpisodes, totalSteps, logBytes))
    logBytes += 60
    if ruleCondition:
        loop()

# ---------------------------------------------------------------------------
# Host: no hero-select click, overhead camera, clean screen.
# ---------------------------------------------------------------------------
rule "Host: force a hero so the match needs no click":
    @Event eachPlayer
    @Condition eventPlayer.isDummy() == false
    # Soldier: 76 has no ability that puts a prompt on team-mates (Mercy's did, over the bots).
    eventPlayer.startForcingHero(Hero.SOLDIER)

rule "Host: place the observer above the island":
    @Event eachPlayer
    @Condition eventPlayer.isDummy() == false
    @Condition eventPlayer.hasSpawned()
    @Condition eventPlayer.isAlive()
    @Condition calStage >= 1
    wait(0.25)
    eventPlayer.setStatusEffect(null, Status.PHASED_OUT, 99999)
    eventPlayer.setInvisibility(Invis.ALL)
    eventPlayer.teleport(vect((edgeXMin + edgeXMax) / 2, floorY, (edgeZMin + edgeZMax) / 2))
    eventPlayer.disableHeroHud()
    eventPlayer.disableGamemodeHud()
    eventPlayer.disableKillFeed()
    eventPlayer.startCamera(camEye, camLook, 0)

rule "Host: Interact = end this block now":
    @Event eachPlayer
    @Condition eventPlayer == hostPlayer
    @Condition eventPlayer.isHoldingButton(Button.INTERACT)
    @Condition calStage == 2
    stopping = true
    smallMessage(getAllPlayers(), "Ending the block after the current episodes")

# ---------------------------------------------------------------------------
# Dashboard
# ---------------------------------------------------------------------------
rule "UI: dashboard":
    @Condition calStage == 2
    # The HUD shows strings that a separate rule rebuilds once a second. Formatting them inside the HUD text
    # itself re-ran every frame and was a large share of the server load (peaks over 100% in the first block).
    hudText(getAllPlayers(), "Overwatch RL Lab: Night School", null, null, HudPosition.LEFT, 0, Color.ORANGE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, null, hudHead, HudPosition.LEFT, 1, Color.WHITE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)
    for uiI in range(nBots):
        hudText(getAllPlayers(), null, null, hudLine[evalOnce(uiI)], HudPosition.LEFT, 2 + uiI, Color.WHITE, Color.WHITE, Color.SKY_BLUE if bots[evalOnce(uiI)].side == 0 else Color.YELLOW, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, hudFeat[0], null, HudPosition.TOP, 0, Color.WHITE, Color.SKY_BLUE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, hudFeat[1], null, HudPosition.TOP, 1, Color.WHITE, Color.YELLOW, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)

rule "UI: rebuild the dashboard text once a second":
    @Condition calStage == 2
    hudHead = "{} bots, each learning the same cliff walk its own way\nspeed {}%  |  block {} min  |  episodes {}  |  real steps {}\nserver load {}%  |  log {} KB of 256".format(nBots, cfgMoveSpeed, floor((NOW - matchT0) / 60), totalEpisodes, totalSteps, getServerLoad(), floor(logBytes / 1024))
    for hudI in range(nBots):
        hudLine[hudI] = "{} {}  ep {}/{}  goal {}  fell {}  last {}".format(cName[bots[hudI].cond], "(top)" if bots[hudI].side == 0 else "(bottom)", bots[hudI].epCount + bots[hudI].evalCount, bots[hudI].trainEps, bots[hudI].cntGoal, bots[hudI].cntFell, bots[hudI].lastReturn)
    wait(1)
    if ruleCondition:
        loop()

rule "UI: status while setting up, or when something failed":
    hudText(getAllPlayers(), null, null, "status: {}".format(calMsg), HudPosition.RIGHT, 0, Color.WHITE, Color.WHITE, Color.LIGHT_RED if calStage == -1 else Color.WHITE, HudReeval.VISIBILITY_SORT_ORDER_STRING_AND_COLOR)

rule "UI: strips, start and goal":
    @Condition calStage == 2
    for uiJ in range(2):
        # The red line is the real island edge.
        createBeam(getAllPlayers(), Beam.BAD, vect(gridX0, floorY + 0.1, zBase[uiJ]), vect(gridX0 + NCOLS * cell, floorY + 0.1, zBase[uiJ]), Color.RED, EffectReeval.NONE)
        createBeam(getAllPlayers(), Beam.GRAPPLE, vect(gridX0, floorY + 0.1, zBase[uiJ] + zSign[uiJ] * NROWS * cell), vect(gridX0 + NCOLS * cell, floorY + 0.1, zBase[uiJ] + zSign[uiJ] * NROWS * cell), Color.WHITE, EffectReeval.NONE)
        createBeam(getAllPlayers(), Beam.GRAPPLE, vect(gridX0, floorY + 0.1, zBase[uiJ]), vect(gridX0, floorY + 0.1, zBase[uiJ] + zSign[uiJ] * NROWS * cell), Color.WHITE, EffectReeval.NONE)
        createBeam(getAllPlayers(), Beam.GRAPPLE, vect(gridX0 + NCOLS * cell, floorY + 0.1, zBase[uiJ]), vect(gridX0 + NCOLS * cell, floorY + 0.1, zBase[uiJ] + zSign[uiJ] * NROWS * cell), Color.WHITE, EffectReeval.NONE)
        createEffect(getAllPlayers(), Effect.RING, Color.SKY_BLUE, startPos[uiJ], cell / 2, EffectReeval.NONE)
        createEffect(getAllPlayers(), Effect.RING, Color.GREEN, goalPos[uiJ], cell / 2, EffectReeval.NONE)
        createEffect(getAllPlayers(), Effect.LIGHT_SHAFT, Color.GREEN, goalPos[uiJ], cell / 2, EffectReeval.NONE)

rule "UI: policy arrows, redrawn as a snapshot of one bot per strip every 10 seconds":
    @Condition calStage == 2
    # 96 floor texts that re-read a bot's table every frame cost more server time than the learning itself.
    # A snapshot every 10 seconds shows the same thing: the plan of one bot, changing as it learns.
    featI += 1
    feat[0] = [b for b in bots if b.side == 0][featI % max(1, len([b for b in bots if b.side == 0]))]
    feat[1] = [b for b in bots if b.side == 1][featI % max(1, len([b for b in bots if b.side == 1]))]
    hudFeat = ["arrows on the top strip: {}".format(cName[feat[0].cond]), "arrows on the bottom strip: {}".format(cName[feat[1].cond])]
    destroyAllInWorldText()
    for uiJ in range(2 * NCELLS):
        createInWorldText(getAllPlayers(), feat[floor(uiJ / NCELLS)].glyph[uiJ % NCELLS], cellPos[uiJ] + vect(0, 0.4, 0), 2, Clip.NONE, WorldTextReeval.NONE, Color.GREEN if uiJ % NCELLS == GOAL_CELL else Color.WHITE)
        if uiJ % 16 == 15:
            wait()
    wait(10)
    if ruleCondition:
        loop()
