/*
Game 5: Slippery Boots (lecture 5, model-free control). The player is Tracer on a strip of pads beside the island's real
edge. An enemy Lucio boops her one pad in a random direction, one pad in ten. Four crossings, a lane chosen before each:
the EDGE lane (11 steps, every step taken from a pad next to the drop) or the INLAND lane (13 steps, one pad in).

The boop is the lecture's epsilon-greedy random move, applied to a person: on each step, with chance 0.1 the move she
made is replaced by one of the four moves at random, from the pad she stepped off. A replacement toward the drop from
an edge pad is a fall. Rewards: -1 per step, +50 at the goal, -100 for a fall.

The game's own arithmetic: iterative policy evaluation (lecture 3) of each lane's walker on the 4 x 12 grid of pads,
with the boops and without them. Without: edge 39, inland 37. With: edge about 0.41, inland about 30.31. The walker
"without boops" is what Q-learning values (the greedy target), the walker "with boops" is what SARSA values.

Grid: cell k = row * 12 + column. Row 0 is next to the drop (z from -19.5 to -17.5), rows grow inland (+z).
Columns run with +x from x = -12. Start = cell 0, goal = cell 11.
Moves: 0 forward (+x), 1 back (-x), 2 inland (+z), 3 toward the drop (-z).
*/
settings {
    "main": {
        "modeName": "RL course 5: Slippery Boots",
        "description": "Lecture 5 of the RL course: cross beside a drop while Lucio boops you. github.com/CarlKho-Minerva/overwatch-rl-lab"
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

#!define GAME_ID 5
#!define GAME_VERSION 1
#!define GAME_TITLE "RL 5: SLIPPERY BOOTS"
#!define LEARNER_HERO Hero.TRACER
#!define HOME_POS vect(-11, 0, -18.5)
#!define HOME_FACING vect(1, 0, 0)

#!include "common.opy"

macro NC = 12
macro NR = 4
macro NCELL = 48
macro GOAL = 11
macro X0 = -12
macro ZB = -19.5
macro EPS = 0.1
macro CELL_AT(p):
    (min(max(floor((p.z - ZB) / 2), 0), NR - 1) * NC + min(max(floor((p.x - X0) / 2), 0), NC - 1))
macro CENTER(k):
    vect(X0 + 2 * ((k) % NC) + 1, FLOOR_Y, ZB + 2 * floor((k) / NC) + 1)
# The lane walker's own move from cell k: the edge walker goes back to row 0 and forward; the inland walker goes to
# row 1, forward along it, and down to the goal from the last column.
macro POLICY(k, ln):
    ((3 if floor((k) / NC) > 0 else 0) if (ln) == 0 else (3 if (k) % NC == NC - 1 else (2 if floor((k) / NC) < 1 else (3 if floor((k) / NC) > 1 else 0))))
macro HOLD(t):
    wait(0.4 if AUTOPLAY else t)

globalvar evV = []
globalvar evLane
globalvar evEps
globalvar evStep
globalvar evGoal
globalvar evFall
globalvar evOut
globalvar evSweeps
globalvar evSweep
globalvar evK
globalvar evD
globalvar evDelta
globalvar evSum
globalvar evP
globalvar evPol
globalvar evR2
globalvar evC2
globalvar evS2
globalvar evX
globalvar vEdge0
globalvar vIn0
globalvar vEdge
globalvar vIn
globalvar fEdge
globalvar fIn
globalvar fQuick
globalvar crossing = 0
globalvar lane = 0
globalvar laneActive = false
globalvar laneChoice = -1
globalvar laneHead = ""
globalvar boopsOn = false
globalvar curCell = 0
globalvar seenCell = 0
globalvar newCell = 0
globalvar roll = 0
globalvar mv = 0
globalvar r2 = 0
globalvar c2 = 0
globalvar stepR = 0
globalvar ret = 0
globalvar steps = 0
globalvar boops = 0
globalvar outcome = 0
globalvar edgeSteps = 0
globalvar tStart = 0
globalvar tgtPos
globalvar realFall = 0
globalvar lucio = null
globalvar autoLanes = [0, 0, 1, 1]
globalvar dirName = ["forward", "back", "inland", "toward the drop"]
globalvar laneName = ["EDGE", "INLAND"]
globalvar outName = ["", "reached the goal", "fell", "time up"]
globalvar hudRun = ""
globalvar hudRes = ["", "", "", ""]
globalvar hudModel = ""
globalvar db1 = ""
globalvar db2 = ""
globalvar db3 = ""
globalvar db4 = ""
globalvar fxI

subroutine evalLane
subroutine chooseLane
subroutine crossOnce

def evalLane():
    @Name "Game 5: value of one lane's walker by iterative policy evaluation (lecture 3), its own arithmetic"
    # Inputs: evLane (0 edge, 1 inland), evEps (chance a move is replaced by a random one), evStep, evGoal, evFall.
    # Output: evOut, the expected total from the start pad. With step 0, goal 0, fall 1 it is the chance of a fall.
    evV = []
    evV[NCELL - 1] = 0
    evSweeps = 0
    for evSweep in range(200):
        evDelta = 0
        evSweeps += 1
        for evK in range(NCELL - 1, -1, -1):
            if evK != GOAL:
                evPol = POLICY(evK, evLane)
                evSum = 0
                for evD in range(4):
                    evP = (1 - evEps + evEps / 4) if evD == evPol else evEps / 4
                    if evP > 0:
                        evR2 = floor(evK / NC) + [0, 0, 1, -1][evD]
                        evC2 = evK % NC + [1, -1, 0, 0][evD]
                        if evR2 < 0:
                            evX = evStep + evFall
                        else:
                            evS2 = evK if (evC2 < 0 or evC2 > NC - 1 or evR2 > NR - 1) else evR2 * NC + evC2
                            evX = evStep + (evGoal if evS2 == GOAL else evV[evS2])
                        evSum += evP * evX
                evDelta = max(evDelta, abs(evSum - evV[evK]))
                evV[evK] = evSum
            if evK % 8 == 0:
                wait()
        if evDelta < 0.0005:
            break
    evOut = evV[0]

def chooseLane():
    @Name "Game 5: the player picks a lane (left click edge, right click inland)"
    laneChoice = -1
    laneHead = "Choose your lane for crossing {} of 4".format(crossing)
    learner.disallowButton(Button.PRIMARY_FIRE)
    learner.disallowButton(Button.SECONDARY_FIRE)
    wait(0.4)
    laneActive = true
    if AUTOPLAY:
        wait(1)
        laneChoice = autoLanes[crossing - 1]
    else:
        waitUntil(laneChoice >= 0, 90)
    laneActive = false
    if laneChoice < 0:
        laneChoice = 1
    lane = laneChoice
    LOG("RLG,E,{},lane,{},{},{}".format(GAME_ID, crossing, lane, 1 if boopsOn else 0))
    learner.allowButton(Button.PRIMARY_FIRE)
    learner.allowButton(Button.SECONDARY_FIRE)

rule "Game 5: left click picks the edge lane":
    @Event eachPlayer
    @Condition eventPlayer == learner
    @Condition laneActive
    @Condition eventPlayer.isHoldingButton(Button.PRIMARY_FIRE)
    laneChoice = 0

rule "Game 5: right click picks the inland lane":
    @Event eachPlayer
    @Condition eventPlayer == learner
    @Condition laneActive
    @Condition eventPlayer.isHoldingButton(Button.SECONDARY_FIRE)
    laneChoice = 1

def crossOnce():
    @Name "Game 5: one crossing, start ring to goal ring, with or without boops"
    putHome()
    learner.setFacing(vect(1, 0, 0), Relativity.TO_WORLD)
    curCell = 0
    ret = 0
    steps = 0
    boops = 0
    outcome = 0
    edgeSteps = 0
    realFall = 0
    hudRun = "Crossing {}: {} lane. Steps 0, return 0.".format(crossing, laneName[lane])
    coach = "GO. Walk the {} lane to the green ring. Each pad you step onto costs 1.".format(laneName[lane])
    tStart = NOW
    while outcome == 0:
        wait(0.1)
        if AUTOPLAY:
            # The stand-in walks the lane: head for the centre of the pad its lane says comes next.
            tgtPos = CENTER(curCell + [1, -1, NC, 0 - NC][POLICY(curCell, lane)])
            learner.startThrottleInDirection(normalize(vect(tgtPos.x - learner.getPosition().x, 0, tgtPos.z - learner.getPosition().z)), 1, Relativity.TO_WORLD, Throttle.REPLACE_EXISTING, ThrottleReeval.NONE)
        if learner.fell:
            # Walked off the island without a boop.
            outcome = 2
            ret += -100
            realFall = 1
            LOG("RLG,E,{},selffall,{},{},{}".format(GAME_ID, crossing, steps, curCell))
        elif NOW - tStart > (40 if AUTOPLAY else 90) or steps >= 40:
            outcome = 3
        else:
            seenCell = CELL_AT(learner.getPosition())
            if seenCell != curCell:
                # One step. Draw first, log the draw, then use it.
                roll = random.randint(1, 10)
                mv = random.randint(0, 3)
                stepR = -1
                newCell = seenCell
                if floor(curCell / NC) == 0:
                    edgeSteps += 1
                if boopsOn and roll == 1:
                    # The boop: the step is replaced by move mv, taken from the pad she stepped off.
                    boops += 1
                    r2 = floor(curCell / NC) + [0, 0, 1, -1][mv]
                    c2 = curCell % NC + [1, -1, 0, 0][mv]
                    if r2 < 0:
                        newCell = -1
                    elif c2 < 0 or c2 > NC - 1 or r2 > NR - 1:
                        newCell = curCell
                    else:
                        newCell = r2 * NC + c2
                    playEffect(getAllPlayers(), DynamicEffect.RING_EXPLOSION, Color.GREEN, learner.getPosition(), 3)
                    smallMessage(getAllPlayers(), "Boop. Lucio sends you one pad {}.".format(dirName[mv]))
                    if newCell < 0:
                        learner.teleport(vect(X0 + 2 * (curCell % NC) + 1, FLOOR_Y + 0.5, ISLE_MIN - 1.5))
                        learner.applyImpulse(vect(0, 0, -1), 6, Relativity.TO_WORLD, Impulse.CANCEL_CONTRARY_MOTION_XYZ)
                    else:
                        learner.teleport(CENTER(newCell))
                if newCell < 0:
                    stepR += -100
                    outcome = 2
                elif newCell == GOAL:
                    stepR += 50
                    outcome = 1
                steps += 1
                ret += stepR
                # step: crossing, step number, pad left, pad walked onto, roll (1 to 10), move drawn, pad ended on
                #       (-1 = over the drop), reward, boops on
                LOG("RLG,E,{},step,{},{},{},{},{},{},{},{},{}".format(GAME_ID, crossing, steps, curCell, seenCell, roll, mv, newCell, stepR, 1 if boopsOn else 0))
                if newCell >= 0:
                    curCell = newCell
                hudRun = "Crossing {}: {} lane. Steps {}, boops {}, return {}.".format(crossing, laneName[lane], steps, boops, ret)
    learner.stopThrottleInDirection()
    if outcome == 2 and realFall == 0:
        waitUntil(learner.fell == true, 3)
        realFall = 1 if learner.fell else 0
    # cross: crossing, lane, boops on, steps, boops, outcome (1 goal, 2 fell, 3 time up), return, steps from edge pads,
    #        fell for real in the game (1/0)
    LOG("RLG,E,{},cross,{},{},{},{},{},{},{},{},{}".format(GAME_ID, crossing, lane, 1 if boopsOn else 0, steps, boops, outcome, ret, edgeSteps, realFall))
    hudRes[crossing - 1] = "Crossing {}: {} lane, {} steps, {} boops, {}. Return {}.".format(crossing, laneName[lane], steps, boops, outName[outcome], ret)
    hudRun = ""
    if outcome == 2:
        HOLD(2)
        putHome()

rule "Game 5: the screen (lane choice, controls, results)":
    hudText(getAllPlayers() if laneActive else null, laneHead, "LEFT CLICK: EDGE lane (11 steps)      RIGHT CLICK: INLAND lane (13 steps)", null, HudPosition.TOP, 1, Color.YELLOW, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, null, "WASD: walk.  LEFT CLICK / RIGHT CLICK / MELEE: answer and choose.  Abilities are off.", HudPosition.RIGHT, 0, Color.WHITE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, null, hudRun, HudPosition.RIGHT, 1, Color.WHITE, Color.WHITE, Color.YELLOW, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, null, hudRes[0], HudPosition.RIGHT, 2, Color.WHITE, Color.WHITE, Color.SKY_BLUE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, null, hudRes[1], HudPosition.RIGHT, 3, Color.WHITE, Color.WHITE, Color.SKY_BLUE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, null, hudRes[2], HudPosition.RIGHT, 4, Color.WHITE, Color.WHITE, Color.SKY_BLUE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, null, hudRes[3], HudPosition.RIGHT, 5, Color.WHITE, Color.WHITE, Color.SKY_BLUE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, null, hudModel, HudPosition.RIGHT, 6, Color.WHITE, Color.WHITE, Color.ORANGE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, null, db1, HudPosition.LEFT, 3, Color.WHITE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, null, db2, HudPosition.LEFT, 4, Color.WHITE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, null, db3, HudPosition.LEFT, 5, Color.WHITE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, null, db4, HudPosition.LEFT, 6, Color.WHITE, Color.WHITE, Color.SKY_BLUE, HudReeval.VISIBILITY_AND_STRING)

rule "Game 5: run":
    @Condition ready
    learner.disallowButton(Button.ABILITY_1)
    learner.disallowButton(Button.ABILITY_2)
    learner.disallowButton(Button.ULTIMATE)

    # The strip: a red line on the real edge, orange pads for the edge lane, blue pads for the inland lane.
    createBeam(getAllPlayers(), Beam.BAD, vect(X0, FLOOR_Y + 0.1, ISLE_MIN + 0.1), vect(X0 + 2 * NC, FLOOR_Y + 0.1, ISLE_MIN + 0.1), Color.RED, EffectReeval.NONE)
    for fxI in range(1, NC - 1):
        createEffect(getAllPlayers(), Effect.RING, Color.ORANGE, CENTER(fxI), 0.8, EffectReeval.NONE)
    for fxI in range(NC):
        createEffect(getAllPlayers(), Effect.RING, Color.SKY_BLUE, CENTER(NC + fxI), 0.8, EffectReeval.NONE)
    createEffect(getAllPlayers(), Effect.RING, Color.WHITE, CENTER(0), 0.9, EffectReeval.NONE)
    createEffect(getAllPlayers(), Effect.RING, Color.GREEN, CENTER(GOAL), 0.9, EffectReeval.NONE)
    createEffect(getAllPlayers(), Effect.LIGHT_SHAFT, Color.GREEN, CENTER(GOAL), 0.9, EffectReeval.NONE)
    createInWorldText(getAllPlayers(), "EDGE LANE", CENTER(5) + vect(1, 1.6, 0), 1.6, Clip.NONE, WorldTextReeval.NONE, Color.ORANGE)
    createInWorldText(getAllPlayers(), "INLAND LANE", CENTER(NC + 5) + vect(1, 1.6, 0), 1.6, Clip.NONE, WorldTextReeval.NONE, Color.SKY_BLUE)
    createInWorldText(getAllPlayers(), "START", CENTER(0) + vect(0, 1.6, 0), 1.6, Clip.NONE, WorldTextReeval.NONE, Color.WHITE)
    createInWorldText(getAllPlayers(), "GOAL", CENTER(GOAL) + vect(0, 1.6, 0), 1.6, Clip.NONE, WorldTextReeval.NONE, Color.GREEN)

    coach = "Slippery Boots. White ring to green ring. Each pad costs 1, the goal pays 50, a fall costs 100."

    # The game's arithmetic checks itself.
    CHECK("chance a step goes toward the drop", 0.025, EPS / 4)
    fQuick = 1 - (1 - EPS / 4) ** 11
    CHECK("quick fall estimate for 11 edge steps", 0.243, fQuick)
    evStep = -1
    evGoal = 50
    evFall = -100
    evEps = 0
    evLane = 0
    evalLane()
    vEdge0 = evOut
    LOG("RLG,E,{},model,0,0,{},{}".format(GAME_ID, vEdge0, evSweeps))
    CHECK("edge lane no boops", 39, vEdge0)
    evLane = 1
    evalLane()
    vIn0 = evOut
    LOG("RLG,E,{},model,1,0,{},{}".format(GAME_ID, vIn0, evSweeps))
    CHECK("inland lane no boops", 37, vIn0)
    evEps = EPS
    evLane = 0
    evalLane()
    vEdge = evOut
    LOG("RLG,E,{},model,0,1,{},{}".format(GAME_ID, vEdge, evSweeps))
    CHECK("edge lane with boops", 0.41, vEdge)
    evLane = 1
    evalLane()
    vIn = evOut
    LOG("RLG,E,{},model,1,1,{},{}".format(GAME_ID, vIn, evSweeps))
    CHECK("inland lane with boops", 30.31, vIn)
    evStep = 0
    evGoal = 0
    evFall = 1
    evLane = 0
    evalLane()
    fEdge = evOut
    LOG("RLG,E,{},fall,0,{},{}".format(GAME_ID, fEdge, evSweeps))
    CHECK("edge lane fall chance", 0.26, fEdge)
    evLane = 1
    evalLane()
    fIn = evOut
    LOG("RLG,E,{},fall,1,{},{}".format(GAME_ID, fIn, evSweeps))
    CHECK("inland lane fall chance", 0.034, fIn)
    HOLD(3)

    # Crossing 1: calm air.
    crossing = 1
    boopsOn = false
    coach = "Crossing 1. No Lucio yet. The edge lane is 11 steps, the inland lane 13."
    HOLD(3)
    qId = 1
    qText = "No boops. Each step costs 1, the goal pays 50. Which lane pays more?"
    qOpts = ["EDGE", "INLAND", "THE SAME"]
    qCorrect = 0
    qAuto = 0
    qWhy = "Edge: 50 - 11 = {}. Inland: 50 - 13 = {}. With nothing pushing you, short wins.".format(round(vEdge0), round(vIn0))
    ask()
    chooseLane()
    crossOnce()
    coach = "Crossing 1 done. Return {}. That was the player you wish you were: nobody pushing.".format(ret)
    HOLD(4)

    # Lucio arrives.
    createDummy(Hero.LUCIO, Team.2, -1, vect(-11, FLOOR_Y, -11), vect(0, 0, -1))
    wait(1)
    if len([p for p in getPlayers(Team.2) if p.isDummy()]) > 0:
        lucio = [p for p in getPlayers(Team.2) if p.isDummy()][0]
        lucio.setStatusEffect(null, Status.PHASED_OUT, 9999)
        lucio.startForcingPosition(vect(min(max(learner.getPosition().x, -11), 11), FLOOR_Y, -11), true)
        lucio.startFacing(directionTowards(lucio.getEyePosition(), learner.getEyePosition()), 720, Relativity.TO_WORLD, FacingReeval.DIRECTION_AND_TURN_RATE)
    LOG("RLG,E,{},lucio,{},{}".format(GAME_ID, 1 if entityExists(lucio) else 0, NOW))
    boopsOn = true

    # Crossing 2: the boops start.
    crossing = 2
    coach = "Lucio is here. On one step in ten he boops you one pad in a random direction instead."
    HOLD(5)
    qId = 2
    qText = "You step off an edge pad. What is the chance this step ends over the drop?"
    qOpts = ["1 in 10", "1 in 40", "1 in 4"]
    qCorrect = 1
    qAuto = 1
    qWhy = "One step in ten is a boop, and one boop in four points at the drop: 0.1 x 0.25 = 0.025."
    ask()
    chooseLane()
    crossOnce()
    coach = "Return {}. In the lecture the random move is the learner's own: it keeps her trying things.".format(ret)
    HOLD(5)

    # Crossing 3.
    crossing = 3
    qId = 3
    qText = "Walk the whole edge lane with boops. How often do you fall before the goal?"
    qOpts = ["about 2 in 100", "about {} in 100".format(round(fEdge * 100)), "about 60 in 100"]
    qCorrect = 1
    qAuto = 0
    qWhy = "11 steps off edge pads at 2.5%: about {}%. Counting walks back after boops: {}%.".format(round(fQuick * 100), round(fEdge * 100))
    ask()
    chooseLane()
    crossOnce()
    coach = "Return {}. One crossing is luck. The game can work out the long run instead.".format(ret)
    HOLD(4)

    # Crossing 4: the reveal comes before it, so the last choice can use it.
    crossing = 4
    qId = 4
    qText = "With boops, over many crossings, which lane earns more on average?"
    qOpts = ["EDGE", "INLAND"]
    qCorrect = 1
    qAuto = 1
    qWhy = "Edge averages {}, inland {}. A {}% chance of -100 costs more than 2 extra steps.".format(vEdge, vIn, round(fEdge * 100))
    ask()
    hudModel = "Long run, no boops: edge {}, inland {}.  With boops: edge {}, inland {}.".format(round(vEdge0), round(vIn0), vEdge, vIn)
    chooseLane()
    crossOnce()
    coach = "Return {}. Your four crossings are on the right; the long-run averages under them.".format(ret)
    HOLD(4)

    # Naming it.
    coach = "On-policy: learn about the way you really act. Off-policy: learn about the best way, acting another."
    HOLD(6)
    qId = 5
    qText = "TD (lecture 4): move a guess toward the reward plus the NEXT guess. Which learner prefers EDGE?"
    qOpts = ["Q-LEARNING (best next move)", "SARSA (the move you really make)"]
    qCorrect = 0
    qAuto = 0
    qWhy = "The best next move is never a boop: Q-learning rates the edge {}. SARSA counts boops: {}.".format(round(vEdge0), vEdge)
    ask()
    coach = "SARSA learns the lane for the booped player you are: inland. Q-learning, the never-booped one: edge."
    HOLD(6)
    coach = "Honest note: the boop stands in for your own random move. A boop from the world, Q-learning counts too."
    HOLD(6)

    db1 = "What you did: crossed beside a drop under random boops. Long run: edge {}, inland {}.".format(vEdge, vIn)
    db2 = "What it is called: SARSA is on-policy, Q-learning off-policy. Next to a drop they disagree."
    db3 = "In an agent: judge a plan by what the agent will really do, slips included, not by a perfect run."
    db4 = "Your predictions: {} right of {}.".format(predRight, predTotal)
    coach = "Debrief. The game is over."
    LOG("RLG,E,{},debrief,{},{}".format(GAME_ID, predRight, predTotal))
    finish()
