/*
Game 8: Recall (Lecture 8, Integrating Learning and Planning).

A maze of 7 by 3 pads with a wall down the middle and one gap in it. The player walks it once; every step he takes
is written into the memory (the model) of the replaying bot. Then two Tracer bots learn the maze by the same
Q-learning rule: PLAIN learns only from its real steps, REPLAYING also replays remembered steps after each real one
(Dyna-Q). Before each race the player sets the number of replays (0, 5 or 20) and predicts. Then the gap moves.

The bots' dice are a small fixed generator (x -> 171 x mod 30269), seeded once and logged, so each race is worked
out once before the player predicts (unseen) and then run again with the same dice in front of him: the answer key
is the race he watches. analysis/tests/test_game_08.py replays every race from the log.

Pads: pad = row * 7 + column. Column 0 is at x = -12, row 0 at z = -4, 4 m apart. Start pad 7 (0, 1), goal 13 (6, 1).
The wall is column 3: open only in the gap row (row 0, later row 2).
Moves: 0 = +x, 1 = -x, 2 = +z (row up), 3 = -z. A move off the maze or into the wall stays put. Reward 1 at the goal.
*/
settings {
    "main": {
        "modeName": "RL course 8: Recall",
        "description": "Walk a maze once, then coach two Tracer bots: one learns only from real steps, one also replays remembered steps. github.com/CarlKho-Minerva/overwatch-rl-lab"
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

#!define GAME_ID 8
#!define GAME_VERSION 2
#!define GAME_TITLE "RL 8: RECALL"
#!define LEARNER_HERO Hero.TRACER
#!define HOME_POS vect(-12, 0, 0)

#!include "common.opy"

# ---------------------------------------------------------------------------------------------------------------------
# The maze and the learning rule
# ---------------------------------------------------------------------------------------------------------------------
macro NCOLS = 7
macro NROWS = 3
macro NPADS = 21
macro NQ = 84
macro WALLCOL = 3
macro START = 7
macro GOAL = 13
macro OLD_GAP = 0
macro NEW_GAP = 2
macro OLD_GAP_MOVE = 8           # pad (2, 0) moving +x: through the old gap
macro NEW_GAP_PAD = 17           # pad (3, 2): the new gap
macro ALPHA = 0.5
macro GAMMA = 0.9
macro DICE_M = 30269
macro EPSX = 3027                # explore when the dice show less than this: one time in ten
macro TRIPS = 10
macro CAP = 200                  # a trip stops after this many real steps
macro SHORT = 10                 # a short trip: 10 real steps or fewer (the shortest is 8)
macro WALL_REPLAYS = 20
macro X0 = -12
macro Z0 = -4
macro PAD = 4

macro LCG(v):
    (((v) * 171) % DICE_M)
macro SEED2(v):
    (((v) * 7 + 13) % DICE_M)
macro CC(s):
    ((s) % NCOLS)
macro CR(s):
    floor((s) / NCOLS)
macro TC(s, a):
    (CC(s) + [1, -1, 0, 0][a])
macro TR(s, a):
    (CR(s) + [0, 0, 1, -1][a])
macro SHUT(c, r, g):
    ((c) < 0 or (c) >= NCOLS or (r) < 0 or (r) >= NROWS or ((c) == WALLCOL and (r) != (g)))
macro NEXTCELL(s, a, g):
    ((s) if SHUT(TC(s, a), TR(s, a), g) else TR(s, a) * NCOLS + TC(s, a))
macro QNEW(q, r, nm):
    ((q) + ALPHA * ((r) + GAMMA * (nm) - (q)))
macro CELLPOS(s):
    vect(X0 + PAD * CC(s), FLOOR_Y, Z0 + PAD * CR(s))
macro VIEW = vect(0, 0, -14)

globalvar seed = 1
globalvar seed2 = 20
globalvar gap = 0
globalvar nRep = 20
globalvar raceNo = 0
globalvar showRace = false
globalvar countStale = false
globalvar raceGo = false
globalvar paused = false
globalvar botP = null
globalvar botD = null
globalvar REPS = [0, 5, 20]
globalvar pickI = 2
globalvar usedR = -1
globalvar picking = false
globalvar r1 = 0
globalvar r2 = 0
globalvar walking = false
globalvar walkDone = false
globalvar walkCur = 7
globalvar walkPos
globalvar walkCol
globalvar walkRow
globalvar walkCell
globalvar walkDC
globalvar walkDR
globalvar walkA
globalvar walkK = []
globalvar walkRew = []
globalvar walkS2 = []
globalvar walkBumps = 0
globalvar autoPath = [8, 9, 10, 2, 3, 4, 5, 6, 13]
globalvar autoI
globalvar drawI
globalvar revI
globalvar knowP = 0
globalvar knowD = 0
globalvar sTotP = 0
globalvar sTotD = 0
globalvar sFsP = 0
globalvar sFsD = 0
globalvar sFix = -1
globalvar sThrough = -1
globalvar totD1 = 0
globalvar ctrl = ""
globalvar raceHead = ""
globalvar hudP = ""
globalvar hudD = ""
globalvar hudTot = ""
globalvar debriefOn = false
globalvar db1 = ""
globalvar db2 = ""
globalvar db3 = ""

playervar role = -1
playervar Q = []
playervar dx = 1
playervar dy = 1
playervar mS2 = []
playervar mR = []
playervar mSeen = []
playervar saveQ = []
playervar saveS2 = []
playervar saveR = []
playervar saveSeen = []
playervar cur = 7
playervar a
playervar k
playervar s2
playervar r
playervar row
playervar rmax
playervar ties
playervar j
playervar pk
playervar ps
playervar ps2
playervar tr
playervar t
playervar b
playervar batch = 1
playervar tripN = 0
playervar atGoal = false
playervar trips = []
playervar total = 0
playervar firstShort = 11
playervar firstGoal = false
playervar knowOwn = 0
playervar stale = 0
playervar fixStep = -1
playervar throughStep = -1
playervar steps = 0
playervar done = true
playervar c
playervar cnt
playervar off
playervar tripStr = ""

subroutine drawMaze
subroutine realStep
subroutine freshTables
subroutine runRace
subroutine pickReplays
subroutine raceSummary

def drawMaze():
    @Name "Game 8: draw the pads (red balls are wall, blue is the start, green the goal)"
    for drawI in range(NPADS):
        if CC(drawI) == WALLCOL and CR(drawI) != gap:
            createEffect(getAllPlayers(), Effect.SPHERE, Color.RED, CELLPOS(drawI) + vect(0, 1, 0), 1.3, EffectReeval.NONE)
        elif drawI == START:
            createEffect(getAllPlayers(), Effect.RING, Color.SKY_BLUE, CELLPOS(drawI), 1.4, EffectReeval.NONE)
        elif drawI == GOAL:
            createEffect(getAllPlayers(), Effect.RING, Color.GREEN, CELLPOS(drawI), 1.4, EffectReeval.NONE)
            createEffect(getAllPlayers(), Effect.LIGHT_SHAFT, Color.GREEN, CELLPOS(drawI), 1.4, EffectReeval.NONE)
        else:
            createEffect(getAllPlayers(), Effect.RING, Color.WHITE, CELLPOS(drawI), 1.4, EffectReeval.NONE)

# ---------------------------------------------------------------------------------------------------------------------
# One bot's learning (runs in the bot's own rule, so eventPlayer is the bot)
# ---------------------------------------------------------------------------------------------------------------------
def freshTables():
    @Name "Bot: empty value table; the replaying bot's memory starts as the player's walk"
    eventPlayer.Q = []
    for eventPlayer.j in range(NQ):
        eventPlayer.Q.append(0)
    eventPlayer.mS2 = []
    eventPlayer.mR = []
    eventPlayer.mSeen = []
    if eventPlayer.role == 1:
        for eventPlayer.j in range(len(walkK)):
            if not (walkK[eventPlayer.j] in eventPlayer.mSeen):
                eventPlayer.mSeen.append(walkK[eventPlayer.j])
            eventPlayer.mS2[walkK[eventPlayer.j]] = walkS2[eventPlayer.j]
            eventPlayer.mR[walkK[eventPlayer.j]] = walkRew[eventPlayer.j]

def realStep():
    @Name "Bot: one real step, its Q-learning update, then (replaying bot) remember it and replay memories"
    # Choose: one time in ten a random move, else the best-valued move (ties broken by the dice).
    eventPlayer.dx = LCG(eventPlayer.dx)
    if eventPlayer.dx < EPSX:
        eventPlayer.dx = LCG(eventPlayer.dx)
        eventPlayer.a = floor(eventPlayer.dx * 4 / DICE_M)
    else:
        eventPlayer.row = eventPlayer.Q.slice(eventPlayer.cur * 4, 4)
        eventPlayer.rmax = sorted(eventPlayer.row).last()
        eventPlayer.ties = [0, 1, 2, 3].filter(lambda i: eventPlayer.row[i] >= eventPlayer.rmax - 0.0001)
        if showRace and len([0, 1, 2, 3].filter(lambda i: abs(eventPlayer.rmax - eventPlayer.row[i] - 0.0001) < 0.00003)) > 0:
            # A move sits near the tie margin, where 32-bit rounding decides: log the tie set (bit i = move i) so the
            # replay outside the game can use it. Version 1 of this game did not log these and could not be replayed.
            LOG("RLG,E,{},tie,{},{},{},{}".format(GAME_ID, raceNo, eventPlayer.role, eventPlayer.steps + 1, (1 if 0 in eventPlayer.ties else 0) + (2 if 1 in eventPlayer.ties else 0) + (4 if 2 in eventPlayer.ties else 0) + (8 if 3 in eventPlayer.ties else 0)))
        eventPlayer.dx = LCG(eventPlayer.dx)
        eventPlayer.a = eventPlayer.ties[floor(eventPlayer.dx * len(eventPlayer.ties) / DICE_M)]
    eventPlayer.k = eventPlayer.cur * 4 + eventPlayer.a
    eventPlayer.s2 = NEXTCELL(eventPlayer.cur, eventPlayer.a, gap)
    eventPlayer.r = 0
    if eventPlayer.s2 == GOAL:
        eventPlayer.r = 1
        eventPlayer.s2 = -1
    # Q-learning (Lecture 5): nudge the move's value toward its reward plus the best value where it landed.
    eventPlayer.Q[eventPlayer.k] = QNEW(eventPlayer.Q[eventPlayer.k], eventPlayer.r, 0 if eventPlayer.s2 < 0 else sorted(eventPlayer.Q.slice(eventPlayer.s2 * 4, 4)).last())
    eventPlayer.tripN += 1
    eventPlayer.steps += 1
    if eventPlayer.role == 1:
        # Dyna-Q (Lecture 8): write what the move did into memory, then replay nRep remembered moves.
        if not (eventPlayer.k in eventPlayer.mSeen):
            eventPlayer.mSeen.append(eventPlayer.k)
        eventPlayer.mS2[eventPlayer.k] = eventPlayer.s2
        eventPlayer.mR[eventPlayer.k] = eventPlayer.r
        for eventPlayer.j in range(nRep):
            eventPlayer.dy = LCG(eventPlayer.dy)
            eventPlayer.pk = eventPlayer.mSeen[floor(eventPlayer.dy * len(eventPlayer.mSeen) / DICE_M)]
            eventPlayer.ps2 = eventPlayer.mS2[eventPlayer.pk]
            if countStale:
                # Count replays of a memory the moved wall has made untrue (moves from a pad that is now wall excepted).
                eventPlayer.ps = floor(eventPlayer.pk / 4)
                if not SHUT(CC(eventPlayer.ps), CR(eventPlayer.ps), gap):
                    eventPlayer.tr = NEXTCELL(eventPlayer.ps, eventPlayer.pk % 4, gap)
                    if eventPlayer.tr == GOAL:
                        eventPlayer.tr = -1
                    if eventPlayer.tr != eventPlayer.ps2:
                        eventPlayer.stale += 1
            eventPlayer.Q[eventPlayer.pk] = QNEW(eventPlayer.Q[eventPlayer.pk], eventPlayer.mR[eventPlayer.pk], 0 if eventPlayer.ps2 < 0 else sorted(eventPlayer.Q.slice(eventPlayer.ps2 * 4, 4)).last())
        if countStale:
            if eventPlayer.k == OLD_GAP_MOVE and eventPlayer.fixStep < 0:
                eventPlayer.fixStep = eventPlayer.steps
            if eventPlayer.s2 == NEW_GAP_PAD and eventPlayer.throughStep < 0:
                eventPlayer.throughStep = eventPlayer.steps

rule "Bot: run the ten trips of one race":
    @Event eachPlayer
    @Condition eventPlayer == botP or eventPlayer == botD
    @Condition raceGo
    if raceNo < 3:
        freshTables()
    else:
        eventPlayer.Q = eventPlayer.saveQ
        eventPlayer.mS2 = eventPlayer.saveS2
        eventPlayer.mR = eventPlayer.saveR
        eventPlayer.mSeen = eventPlayer.saveSeen
    eventPlayer.dx = seed
    eventPlayer.dy = seed2
    eventPlayer.trips = []
    eventPlayer.total = 0
    eventPlayer.steps = 0
    eventPlayer.firstShort = TRIPS + 1
    eventPlayer.firstGoal = false
    eventPlayer.stale = 0
    eventPlayer.fixStep = -1
    eventPlayer.throughStep = -1
    eventPlayer.tripStr = ""
    eventPlayer.off = vect(0, 0, -0.8) if eventPlayer.role == 0 else vect(0, 0, 0.8)
    for eventPlayer.t in range(TRIPS):
        eventPlayer.cur = START
        eventPlayer.tripN = 0
        eventPlayer.atGoal = false
        if showRace:
            eventPlayer.teleport(CELLPOS(START) + eventPlayer.off)
        while not eventPlayer.atGoal and eventPlayer.tripN < CAP:
            # Real steps per frame: slow at first in front of the player, fast when nobody needs to watch.
            if showRace and not AUTOPLAY:
                eventPlayer.batch = 1 if eventPlayer.steps < 30 else (2 if (eventPlayer.role == 0 or nRep < 20) else 1)
            else:
                eventPlayer.batch = 6 if (eventPlayer.role == 0 or nRep == 0) else (3 if nRep <= 5 else 1)
            for eventPlayer.b in range(eventPlayer.batch):
                realStep()
                if eventPlayer.s2 < 0:
                    eventPlayer.atGoal = true
                    break
                eventPlayer.cur = eventPlayer.s2
                if eventPlayer.tripN >= CAP:
                    break
            if showRace:
                eventPlayer.teleport(CELLPOS(GOAL if eventPlayer.atGoal else eventPlayer.cur) + eventPlayer.off)
                if not AUTOPLAY and eventPlayer.steps < 30:
                    wait(0.08)
            wait()
            if getServerLoad() > 180:
                wait(0.05)
            if paused:
                waitUntil(not paused, 30)
        eventPlayer.trips.append(eventPlayer.tripN)
        eventPlayer.total += eventPlayer.tripN
        if eventPlayer.tripN <= SHORT and eventPlayer.firstShort > TRIPS:
            eventPlayer.firstShort = eventPlayer.t + 1
        if eventPlayer.atGoal and not eventPlayer.firstGoal:
            eventPlayer.firstGoal = true
            # Pads whose best move has a value above zero: the pads that know the way to the goal.
            eventPlayer.cnt = 0
            for eventPlayer.c in range(NPADS):
                if sorted(eventPlayer.Q.slice(eventPlayer.c * 4, 4)).last() > 0:
                    eventPlayer.cnt += 1
            eventPlayer.knowOwn = eventPlayer.cnt
            if showRace:
                LOG("RLG,E,{},firstgoal,{},{},{},{}".format(GAME_ID, raceNo, eventPlayer.role, eventPlayer.t + 1, eventPlayer.knowOwn))
            if showRace and raceNo == 1 and eventPlayer.role == 0:
                # Lecture 5, shown: after its first arrival the plain bot knows one pad. Pause both bots and light it.
                paused = true
                knowP = eventPlayer.knowOwn
                knowD = 0
                for revI in range(NPADS):
                    if sorted(eventPlayer.Q.slice(revI * 4, 4)).last() > 0:
                        createEffect(getAllPlayers(), Effect.LIGHT_SHAFT, Color.ORANGE, CELLPOS(revI), 1, EffectReeval.NONE)
                    if sorted(botD.Q.slice(revI * 4, 4)).last() > 0:
                        knowD += 1
                        createEffect(getAllPlayers(), Effect.SPHERE, Color.SKY_BLUE, CELLPOS(revI) + vect(0, 0.3, 0.8), 0.45, EffectReeval.NONE)
                LOG("RLG,E,{},know,{},{},{}".format(GAME_ID, knowP, knowD, nRep))
                coach = "Plain bot's first time at the goal: {} pad knows the way (orange). Replaying bot now: {} (blue).".format(knowP, knowD)
                wait(1.5 if AUTOPLAY else 7)
                destroyAllEffects()
                drawMaze()
                coach = "Good news moves back one pad per visit for the plain bot. Replays carry it further between steps."
                paused = false
        if showRace:
            LOG("RLG,E,{},trip,{},{},{},{}".format(GAME_ID, raceNo, eventPlayer.role, eventPlayer.t + 1, eventPlayer.tripN))
            eventPlayer.tripStr = "{} {}".format(eventPlayer.tripStr, eventPlayer.tripN)
            if eventPlayer.role == 0:
                hudP = "PLAIN, steps per trip:{}".format(eventPlayer.tripStr)
            else:
                hudD = "REPLAYING, steps per trip:{}".format(eventPlayer.tripStr)
    if showRace and raceNo == 2:
        eventPlayer.saveQ = eventPlayer.Q
        eventPlayer.saveS2 = eventPlayer.mS2
        eventPlayer.saveR = eventPlayer.mR
        eventPlayer.saveSeen = eventPlayer.mSeen
    if showRace:
        eventPlayer.teleport(CELLPOS(START) + eventPlayer.off)
    eventPlayer.done = true

def runRace():
    @Name "Game 8: run one race (raceNo, nRep, gap, showRace set by the caller) and wait for both bots"
    botP.done = false
    botD.done = false
    raceGo = true
    waitUntil(botP.done and botD.done, 240)
    raceGo = false
    wait(0.1)

def raceSummary():
    @Name "Game 8: the totals line under the race"
    hudTot = "Real steps in 10 trips: plain {}, replaying {}. First short trip: plain {}, replaying {}.".format(botP.total, botD.total, botP.firstShort if botP.firstShort <= TRIPS else "none", botD.firstShort if botD.firstShort <= TRIPS else "none")

# ---------------------------------------------------------------------------------------------------------------------
# The player's choices
# ---------------------------------------------------------------------------------------------------------------------
def pickReplays():
    @Name "Game 8: the player sets the replays per real step for the next race (F changes it, R starts)"
    if REPS[pickI] == usedR:
        pickI = (pickI + 1) % 3
    nRep = REPS[pickI]
    raceHead = "Race {}: the replaying bot gets {} replays per real step".format(raceNo, nRep)
    hudP = ""
    hudD = ""
    hudTot = ""
    ctrl = "F (Interact): change the replays (0, 5, 20{}). R (Reload): start the race.".format("" if usedR < 0 else ", not {} again".format(usedR))
    if AUTOPLAY:
        wait(0.5)
        nRep = 0 if raceNo == 1 else 20
    else:
        picking = true
        waitUntil(not picking, 60)
        picking = false
    raceHead = "Race {}: the replaying bot gets {} replays per real step".format(raceNo, nRep)
    ctrl = "Answer: left click, right click, melee."
    LOG("RLG,E,{},pick,{},{}".format(GAME_ID, raceNo, nRep))

rule "Game 8: F changes the replays":
    @Event eachPlayer
    @Condition eventPlayer == learner
    @Condition picking
    @Condition eventPlayer.isHoldingButton(Button.INTERACT)
    pickI = (pickI + 1) % 3
    if REPS[pickI] == usedR:
        pickI = (pickI + 1) % 3
    nRep = REPS[pickI]
    raceHead = "Race {}: the replaying bot gets {} replays per real step".format(raceNo, nRep)

rule "Game 8: R starts the race":
    @Event eachPlayer
    @Condition eventPlayer == learner
    @Condition picking
    @Condition eventPlayer.isHoldingButton(Button.RELOAD)
    picking = false

# ---------------------------------------------------------------------------------------------------------------------
# The player's walk: each step from pad to pad goes into the replaying bot's memory
# ---------------------------------------------------------------------------------------------------------------------
rule "Game 8: read the walk, pad by pad":
    @Condition walking
    if learner.fell:
        putHome()
    walkPos = learner.getPosition()
    walkCol = round((walkPos.x - X0) / PAD)
    walkRow = round((walkPos.z - Z0) / PAD)
    if walkCol >= 0 and walkCol < NCOLS and walkRow >= 0 and walkRow < NROWS:
        walkCell = walkRow * NCOLS + walkCol
        if walkCell != walkCur and distance(vect(walkPos.x, FLOOR_Y, walkPos.z), CELLPOS(walkCell)) < 1.4:
            walkDC = walkCol - CC(walkCur)
            walkDR = walkRow - CR(walkCur)
            if abs(walkDC) + abs(walkDR) != 1:
                learner.teleport(CELLPOS(walkCur))
                coach = "One pad at a time: step straight onto a pad next to yours."
            else:
                walkA = 0 if walkDC == 1 else (1 if walkDC == -1 else (2 if walkDR == 1 else 3))
                walkK.append(walkCur * 4 + walkA)
                if walkCol == WALLCOL and walkRow != gap:
                    walkRew.append(0)
                    walkS2.append(walkCur)
                    walkBumps += 1
                    learner.teleport(CELLPOS(walkCur))
                    coach = "Wall. You bounced back, and that bump is in its memory too."
                elif walkCell == GOAL:
                    walkRew.append(1)
                    walkS2.append(-1)
                    walkDone = true
                else:
                    walkRew.append(0)
                    walkS2.append(walkCell)
                    walkCur = walkCell
                LOG("RLG,E,{},walk,{},{},{}".format(GAME_ID, walkK.last(), walkRew.last(), walkS2.last()))
                hudTot = "Your steps: {} (bumps into the wall: {}). Each one is in its memory.".format(len(walkK), walkBumps)
    wait(0.05)
    if walking and not walkDone:
        loop()

# ---------------------------------------------------------------------------------------------------------------------
# The game
# ---------------------------------------------------------------------------------------------------------------------
rule "Game 8: run":
    @Condition ready
    CHECK("Q update at the goal", 0.5, QNEW(0, 1, 0))
    CHECK("good news one pad back", 0.225, QNEW(0, 0, 0.5))
    CHECK("dice", 171, LCG(1))
    CHECK("dice to a move", 3, floor(LCG(171) * 4 / DICE_M))
    CHECK("second dice", 20, SEED2(1))
    CHECK("step from the start", 8, NEXTCELL(7, 0, 0))
    CHECK("the wall stops you", 9, NEXTCELL(9, 0, 0))
    CHECK("old gap open", 3, NEXTCELL(2, 0, OLD_GAP))
    CHECK("old gap shut after the move", 2, NEXTCELL(2, 0, NEW_GAP))
    CHECK("new gap open after the move", 17, NEXTCELL(16, 0, NEW_GAP))
    CHECK("edge of the maze", 20, NEXTCELL(20, 2, OLD_GAP))
    gap = OLD_GAP
    drawMaze()
    createInWorldText(getAllPlayers(), "START", CELLPOS(START) + vect(0, 2.2, 0), 1.6, Clip.NONE, WorldTextReeval.NONE, Color.SKY_BLUE)
    createInWorldText(getAllPlayers(), "GOAL", CELLPOS(GOAL) + vect(0, 3, 0), 1.6, Clip.NONE, WorldTextReeval.NONE, Color.GREEN)
    # The two bots, on the learner's team so nobody collides.
    createDummy(Hero.TRACER, learner.getTeam(), -1, vect(-16, 0, -2), vect(1, 0, 0))
    wait(0.6)
    botP = [p for p in getPlayers(learner.getTeam()) if p.isDummy() and p != learner][0]
    botP.role = 0
    createDummy(Hero.TRACER, learner.getTeam(), -1, vect(-16, 0, 2), vect(1, 0, 0))
    wait(0.6)
    botD = [p for p in getPlayers(learner.getTeam()) if p.isDummy() and p != learner and p != botP][0]
    botD.role = 1
    createInWorldText(getAllPlayers(), "PLAIN: real steps only", botP.getPosition() + vect(0, 2.3, 0), 1.3, Clip.NONE, WorldTextReeval.VISIBILITY_POSITION_AND_STRING, Color.ORANGE)
    createInWorldText(getAllPlayers(), "REPLAYING: {} per step".format(nRep), botD.getPosition() + vect(0, 2.7, 0), 1.3, Clip.NONE, WorldTextReeval.VISIBILITY_POSITION_AND_STRING, Color.SKY_BLUE)
    seed = random.randint(1, DICE_M - 1)
    seed2 = SEED2(seed)
    if seed2 == 0:
        seed2 = 1
    LOG("RLG,E,{},seed,{},{}".format(GAME_ID, seed, seed2))
    learner.disallowButton(Button.ABILITY_1)
    learner.disallowButton(Button.ABILITY_2)
    learner.disallowButton(Button.ULTIMATE)

    # --- Round 1: the player walks the maze; his steps become the replaying bot's memory ---------------------------
    coach = "Tracer's Recall rewinds her last steps. A learner can do that with its memories between real steps."
    wait(1 if AUTOPLAY else 6)
    coach = "Walk from the blue pad to the green one, pad by pad. Each step you take goes into one bot's memory."
    ctrl = "WASD: walk onto a pad next to yours. Red balls are wall."
    putHome()
    walkCur = START
    walkDone = false
    walking = true
    if AUTOPLAY:
        wait(0.5)
        for autoI in range(len(autoPath)):
            learner.teleport(CELLPOS(autoPath[autoI]))
            wait(0.45)
    waitUntil(walkDone == true, 20 if AUTOPLAY else 120)
    walking = false
    LOG("RLG,E,{},walkend,{},{},{}".format(GAME_ID, len(walkK), walkBumps, 1 if walkDone else 0))
    coach = "{} Your {} steps are now the replaying bot's memory: its own copy of what each move does.".format("Goal." if walkDone else "Time.", len(walkK))
    wait(1 if AUTOPLAY else 6)
    learner.teleport(VIEW)
    learner.setFacing(vect(0, 0, 1), Relativity.TO_WORLD)

    # --- Round 2: race 1 -----------------------------------------------------------------------------------------
    raceNo = 1
    gap = OLD_GAP
    coach = "You are the coach. The plain bot learns from real steps only; the other replays memories after each."
    pickReplays()
    r1 = nRep
    usedR = nRep
    # The race is worked out once, unseen, while the player answers; then the same dice run it in front of him.
    showRace = false
    raceGo = false
    botP.done = false
    botD.done = false
    raceGo = true
    qId = 1
    qText = "Lecture 5 check. When the plain bot first reaches the goal, how many pads will know the way?"
    qOpts = ["just the last pad", "about half its path", "its whole path"]
    qCorrect = 0
    qAuto = 0
    qWhy = "Q-learning's one-step update moves good news back one pad per visit."
    ask()
    waitUntil(botP.done and botD.done, 240)
    raceGo = false
    sTotP = botP.total
    sTotD = botD.total
    sFsP = botP.firstShort
    sFsD = botD.firstShort
    wait(0.1)
    qId = 2
    qText = "{} replays per real step. Who takes a short trip (10 steps or fewer) first?".format(nRep)
    qOpts = ["the replaying bot", "the plain bot", "a tie"]
    qCorrect = 0 if sFsD < sFsP else (1 if sFsP < sFsD else 2)
    qAuto = 0
    qWhy = "Replays spread its memory, your walk included, through its values between real steps."
    if qCorrect == 2:
        qWhy = "With 0 replays it is the plain bot: same rule, same dice, same trips." if nRep == 0 else "Both got there on the same trip this time."
    elif qCorrect == 1:
        qWhy = "The dice favoured the plain bot this time."
    ask()
    coach = "Race 1. Both bots take one real step at a time. Watch the steps per trip on the right."
    showRace = true
    runRace()
    totD1 = botD.total
    raceSummary()
    LOG("RLG,E,{},pass,{},{},{},{},{},{}".format(GAME_ID, raceNo, sTotP, botP.total, sTotD, botD.total, nRep))
    coach = "Each real step costs both bots the same. The replaying bot gets more learning out of each one." if nRep > 0 else "0 replays: the second bot is the plain bot. Memory unused is memory wasted."
    wait(2 if AUTOPLAY else 8)

    # --- Round 3: race 2, a different number of replays ------------------------------------------------------------
    raceNo = 2
    coach = "Race 2: pick a different number. The plain bot rolls the same dice again: it is your yardstick."
    pickReplays()
    r2 = nRep
    showRace = false
    coach = "Race 2 set: {} replays per real step.".format(nRep)
    runRace()
    sTotP = botP.total
    sTotD = botD.total
    qId = 3
    qText = "Now {} replays (last race {}). The replaying bot's real steps in 10 trips, against last race?".format(r2, r1)
    qOpts = ["far fewer", "about the same", "far more"]
    qCorrect = 0 if sTotD * 3 < totD1 * 2 else (2 if sTotD * 2 > totD1 * 3 else 1)
    qAuto = 0
    if qCorrect == 0:
        qWhy = "With more replays each real step is spread further through its memory."
    elif qCorrect == 2:
        qWhy = "Fewer replays: less of its memory is used per real step, so it needs more real steps."
    else:
        qWhy = "Once the way has spread through its memory, more replays cannot make 8 steps shorter."
    ask()
    coach = "Race 2."
    showRace = true
    runRace()
    raceSummary()
    LOG("RLG,E,{},pass,{},{},{},{},{},{}".format(GAME_ID, raceNo, sTotP, botP.total, sTotD, botD.total, nRep))
    coach = "Replay only spreads what it has seen: past a point, more thinking stops paying."
    wait(2 if AUTOPLAY else 7)

    # --- Round 4: the gap moves -----------------------------------------------------------------------------------
    raceNo = 3
    nRep = WALL_REPLAYS
    gap = NEW_GAP
    destroyAllEffects()
    drawMaze()
    raceHead = "Race 3: the gap moved. Both bots keep what they learned. Replays: {}".format(nRep)
    hudP = ""
    hudD = ""
    hudTot = ""
    coach = "The gap moved, like the enemy team rotating: your read on where they set up is now out of date."
    LOG("RLG,E,{},pick,{},{}".format(GAME_ID, raceNo, nRep))
    showRace = false
    countStale = true
    runRace()
    sTotP = botP.total
    sTotD = botD.total
    sFix = botD.fixStep
    sThrough = botD.throughStep
    qId = 4
    qText = "The gap moved to the far side. Over 10 trips, which bot needs more real steps?"
    qOpts = ["the replaying bot: stale memory", "the plain bot", "about the same"]
    qCorrect = 0 if sTotD * 4 > sTotP * 5 else (1 if sTotP * 4 > sTotD * 5 else 2)
    qAuto = 0
    if qCorrect == 1:
        qWhy = "The plain bot unlearns its old map one real step at a time. Replays fix the other bot faster."
    elif qCorrect == 0:
        qWhy = "This time its memory kept sending it to the old gap for longer."
    else:
        qWhy = "Both had to stumble on the new gap: thinking cannot find what was never seen."
    ask()
    qId = 5
    qText = "Its memory says the old gap is open and knows nothing of the new one. Which happens later?"
    qOpts = ["it fixes the old-gap memory", "it finds the new gap", "about the same time"]
    if sFix < 0 and sThrough < 0:
        qCorrect = 2
    elif sThrough < 0 or (sFix >= 0 and sFix < sThrough):
        qCorrect = 1
    else:
        qCorrect = 0
    qAuto = 1
    if qCorrect == 1:
        qWhy = "A bump fixes the old line at once. No memory points at the new gap: only exploring finds it."
    elif qCorrect == 0:
        qWhy = "A random step found the new gap before it tried the old one."
    else:
        qWhy = "Neither happened in 10 trips."
    ask()
    coach = "Race 3, the moved gap."
    showRace = true
    runRace()
    countStale = false
    raceSummary()
    LOG("RLG,E,{},pass,{},{},{},{},{},{}".format(GAME_ID, raceNo, sTotP, botP.total, sTotD, botD.total, nRep))
    LOG("RLG,E,{},wall,{},{},{}".format(GAME_ID, botD.stale, botD.fixStep, botD.throughStep))
    coach = "It replayed untrue memories {} times. A bump fixed the old gap at step {}; new gap found at step {}.".format(botD.stale, botD.fixStep if botD.fixStep >= 0 else "never", botD.throughStep if botD.throughStep >= 0 else "never")
    wait(2 if AUTOPLAY else 9)

    # --- Debrief ---------------------------------------------------------------------------------------------------
    ctrl = ""
    db1 = "You walked once and coached two bots: one learned from real steps, one also replayed its memory."
    db2 = "That is Dyna-Q: learn a model (its own copy of what moves do) from real steps, then plan by replaying it."
    db3 = "In an LLM agent: practising on a simulated user. If the simulation is wrong, it learns wrong things fast."
    debriefOn = true
    coach = "Simplified: one tiny maze, an exact memory of each move, no bonus for old moves (Dyna-Q+), no search."
    LOG("RLG,E,{},runs,{},{}".format(GAME_ID, r1, r2))
    finish()
    learner.allowButton(Button.ABILITY_1)
    learner.allowButton(Button.ABILITY_2)
    learner.allowButton(Button.ULTIMATE)

rule "Game 8: the screen":
    hudText(getAllPlayers(), null, null, ctrl, HudPosition.LEFT, 3, Color.WHITE, Color.WHITE, Color.YELLOW, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers() if debriefOn else null, null, null, db1, HudPosition.LEFT, 4, Color.WHITE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers() if debriefOn else null, null, null, db2, HudPosition.LEFT, 5, Color.WHITE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers() if debriefOn else null, null, null, db3, HudPosition.LEFT, 6, Color.WHITE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, null, raceHead, HudPosition.RIGHT, 0, Color.WHITE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, null, hudP, HudPosition.RIGHT, 1, Color.WHITE, Color.WHITE, Color.ORANGE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, null, hudD, HudPosition.RIGHT, 2, Color.WHITE, Color.WHITE, Color.SKY_BLUE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, null, hudTot, HudPosition.RIGHT, 3, Color.WHITE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)
