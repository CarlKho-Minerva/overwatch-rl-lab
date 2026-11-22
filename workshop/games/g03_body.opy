/*
Game 3: The Whiteboard (Lecture 3, planning by dynamic programming).

A 5 by 5 board of pads on Workshop Island, one goal pad and two pit pads. The rules are known and fixed:
each step costs 1, stepping onto the goal pays 10, stepping into a pit costs 10, and both end the dive.
A step off the board leaves you where you were (and still costs 1). Every pad shows a number, starting at 0.
Each Interact (F) runs ONE synchronous sweep of value iteration:
    new number of a pad = best over its 4 moves of (step reward + old number of the pad that move lands on)
When a sweep changes nothing, lines appear on the pads (the plan) and the player walks it himself.
Then he moves one pit (the board marks which) to a pad of his choice and the board is planned again.

Pads: index p = row * 5 + column, row along +z, column along +x, centre (-14 + 4 column, 0, -14 + 4 row).
Moves: 0 = +x, 1 = +z, 2 = -x, 3 = -z. A tie between moves goes to the lowest number.
Log lines: workshop/games/g03.md.
*/
settings {
    "main": {
        "modeName": "RL course 3: The Whiteboard",
        "description": "Plan the dive before the round: value iteration on a 5 by 5 board, one sweep per press. github.com/CarlKho-Minerva/overwatch-rl-lab"
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

#!define GAME_ID 3
#!define GAME_VERSION 1
#!define GAME_TITLE "RL 3: THE WHITEBOARD"
#!define LEARNER_HERO Hero.TRACER
#!define HOME_POS vect(-6, 0, -14)
#!define HOME_FACING vect(0, 0, 1)

#!include "common.opy"

macro START = 2
macro GOAL = 23
macro PIT_A = 11
macro PIT_B = 13
macro AUTO_PIT = 7
macro HOLD(t):
    wait(0.4 if AUTOPLAY else t)

globalvar padPos = []
globalvar dirv = [vect(1, 0, 0), vect(0, 0, 1), vect(-1, 0, 0), vect(0, 0, -1)]
globalvar goal = GOAL
globalvar pits = [PIT_A, PIT_B]
globalvar V = []
globalvar Vnew = []
globalvar Vsave = []
globalvar chg = []
globalvar newPos = []
globalvar lastCh = []
globalvar arrow = []
globalvar arrowOld = []
globalvar flip = []
globalvar qs = [0, 0, 0, 0]
globalvar qBest = 0
globalvar sweepN = 0
globalvar nChg = 0
globalvar maxChg = 0
globalvar looks = 0
globalvar looks0 = 0
globalvar keepOld = false
globalvar wrongN = 0
globalvar showArrows = false
globalvar runId = 0
globalvar nSweeps = 0
globalvar dStart = 0
globalvar dMax = 0
globalvar vStart = 0
globalvar walkSim = 0
globalvar wantF = false
globalvar gotF = false
globalvar wantR = false
globalvar markPit = false
globalvar gotR = false
globalvar walking = false
globalvar walkRet = 0
globalvar walkSteps = 0
globalvar walkEnd = 0
globalvar walkRestarts = 0
globalvar walkT0 = 0
globalvar lastMove = 0
globalvar curP = 0
globalvar prevP = 0
globalvar pitFrom = 0
globalvar pitTo = 0
globalvar pitOk = false
globalvar pitTries = 0
globalvar ctrl = ""
globalvar boardTxt = ""
globalvar boardTxt2 = ""
globalvar padTxt = []
globalvar showDebrief = false
globalvar deb = ["", "", ""]
globalvar npP
globalvar npA
globalvar npS
globalvar npR
globalvar npRow
globalvar npCol
globalvar lp
globalvar la
globalvar wp
globalvar mp
globalvar sp
globalvar dp
globalvar rp
globalvar wk

subroutine nextPad
subroutine lookAhead
subroutine sweepOnce
subroutine clearBoard
subroutine settle
subroutine makeArrows
subroutine simWalk
subroutine drawBoard
subroutine logBoard
subroutine logArrows
subroutine waitF

macro PAD_OF(pos):
    (min(max(floor((pos.x + 16) / 4), 0), 4) + 5 * min(max(floor((pos.z + 16) / 4), 0), 4))

def nextPad():
    @Name "Game 3: the rules (the model). Pad npP, move npA -> landing pad npS, reward npR"
    npRow = floor(npP / 5) + [0, 1, 0, -1][npA]
    npCol = npP % 5 + [1, 0, -1, 0][npA]
    npS = npP if (npRow < 0 or npRow > 4 or npCol < 0 or npCol > 4) else npRow * 5 + npCol
    npR = -1 + (10 if npS == goal else 0) - (10 if npS in pits else 0)

def lookAhead():
    @Name "Game 3: one-step look ahead from pad lp: qs[move] = reward + old number of the landing pad"
    for la in range(4):
        npP = lp
        npA = la
        nextPad()
        qs[la] = npR + V[npS]
    qBest = sorted(qs).last()

def sweepOnce():
    @Name "Game 3: one synchronous sweep of value iteration (the new table is built from the old one)"
    Vnew = V
    nChg = 0
    maxChg = 0
    for wp in range(25):
        chg[wp] = false
        newPos[wp] = false
        if wp != goal and not (wp in pits):
            lp = wp
            lookAhead()
            Vnew[wp] = qBest
            looks += 4
            if abs(qBest - V[wp]) > 0.001:
                chg[wp] = true
                nChg += 1
                maxChg = max(maxChg, abs(qBest - V[wp]))
            newPos[wp] = qBest > 0 and V[wp] <= 0
        if wp % 5 == 4:
            wait()
    V = Vnew
    sweepN += 1

def clearBoard():
    @Name "Game 3: wipe the whiteboard (every number back to 0)"
    for sp in range(25):
        V[sp] = 0
        chg[sp] = false
        newPos[sp] = false
        lastCh[sp] = 0
        flip[sp] = false
    sweepN = 0
    nChg = 1

def settle():
    @Name "Game 3: plan silently from a clean board until a sweep changes nothing (for the answer key)"
    clearBoard()
    while nChg > 0 and sweepN < 30:
        sweepOnce()
        for sp in range(25):
            if chg[sp]:
                lastCh[sp] = sweepN

def makeArrows():
    @Name "Game 3: the plan: on each pad, the move with the best look ahead (keep the old line if it is still best)"
    wrongN = 0
    for mp in range(25):
        flip[mp] = false
        if mp == goal or mp in pits:
            arrow[mp] = -1
        else:
            lp = mp
            lookAhead()
            if keepOld and arrowOld[mp] >= 0 and qs[arrowOld[mp]] >= qBest - 0.001:
                arrow[mp] = arrowOld[mp]
            else:
                arrow[mp] = qs.index(qBest)
            if keepOld and arrowOld[mp] >= 0 and qs[arrowOld[mp]] < qBest - 0.001:
                wrongN += 1
                flip[mp] = true
        if mp % 5 == 4:
            wait()

def simWalk():
    @Name "Game 3: what following the lines from the start earns, by the rules"
    curP = START
    walkSim = 0
    for wk in range(40):
        if curP == goal or curP in pits:
            break
        npP = curP
        npA = arrow[curP]
        nextPad()
        walkSim += npR
        curP = npS

def drawBoard():
    @Name "Game 3: redraw the whiteboard: rings, one number per pad, and the plan's lines"
    # Only this board's own texts: the core's floating question is an in-world text too, and destroying every text
    # would remove it for the rest of the game.
    for dp in range(len(padTxt)):
        destroyInWorldText(padTxt[dp])
    padTxt = []
    destroyAllEffects()
    wait()
    createEffect(getAllPlayers(), Effect.RING, Color.SKY_BLUE, padPos[START], 1, EffectReeval.NONE)
    createEffect(getAllPlayers(), Effect.RING, Color.GREEN, padPos[goal], 1.8, EffectReeval.NONE)
    createEffect(getAllPlayers(), Effect.RING, Color.RED, padPos[pits[0]], 1.8, EffectReeval.NONE)
    createEffect(getAllPlayers(), Effect.RING, Color.RED, padPos[pits[1]], 1.8, EffectReeval.NONE)
    for dp in range(25):
        createInWorldText(getAllPlayers(), "GOAL +10" if dp == goal else (("THIS PIT MOVES" if markPit and dp == pits[1] else "PIT -10") if dp in pits else "{}".format(round(V[dp]))), padPos[dp] + vect(0, 1, 0), 2.5, Clip.NONE, WorldTextReeval.NONE, Color.GREEN if dp == goal else (Color.LIGHT_RED if dp in pits else (Color.YELLOW if newPos[dp] else (Color.LIME_GREEN if V[dp] > 0 else Color.WHITE))))
        padTxt.append(getLastCreatedText())
        if showArrows and arrow[dp] >= 0:
            createBeam(getAllPlayers(), Beam.GRAPPLE, padPos[dp] + vect(0, 0.3, 0), padPos[dp] + dirv[arrow[dp]] * 2 + vect(0, 0.3, 0), Color.YELLOW if flip[dp] else Color.GREEN, EffectReeval.NONE)
        if dp % 5 == 4:
            wait()
    boardTxt = "sweep {}   pads changed {}   biggest change {}".format(sweepN, nChg if sweepN > 0 else 0, round(maxChg) if sweepN > 0 else 0)
    boardTxt2 = "look-aheads so far: {}".format(looks - looks0)

def logBoard():
    @Name "Game 3: log the whole board after a visible sweep"
    # sweep: run (1 first plan, 2 after the pit moved), sweep, pads changed, biggest change, start pad's number
    LOG("RLG,E,{},sweep,{},{},{},{},{}".format(GAME_ID, runId, sweepN, nChg, maxChg, V[START]))
    for rp in range(5):
        # row: run, sweep, row, the five numbers of that row (column 0 to 4)
        LOG("RLG,E,{},row,{},{},{},{},{},{},{},{}".format(GAME_ID, runId, sweepN, rp, V[rp * 5], V[rp * 5 + 1], V[rp * 5 + 2], V[rp * 5 + 3], V[rp * 5 + 4]))

def logArrows():
    @Name "Game 3: log the plan (-1 on the goal and the pits)"
    for rp in range(5):
        # arrows: run, row, the five moves of that row
        LOG("RLG,E,{},arrows,{},{},{},{},{},{},{}".format(GAME_ID, runId, rp, arrow[rp * 5], arrow[rp * 5 + 1], arrow[rp * 5 + 2], arrow[rp * 5 + 3], arrow[rp * 5 + 4]))

def waitF():
    @Name "Game 3: wait for the player to press Interact (the stand-in presses it after a moment)"
    gotF = false
    wait(0.3)
    wantF = true
    if AUTOPLAY:
        wait(0.6)
        gotF = true
    waitUntil(gotF == true, 90)
    wantF = false

rule "Game 3: Interact runs a sweep":
    @Event eachPlayer
    @Condition eventPlayer == learner
    @Condition wantF
    @Condition eventPlayer.isHoldingButton(Button.INTERACT)
    gotF = true

rule "Game 3: Reload moves the pit to this pad":
    @Event eachPlayer
    @Condition eventPlayer == learner
    @Condition wantR
    @Condition eventPlayer.isHoldingButton(Button.RELOAD)
    gotR = true

rule "Game 3: a fall outside the walk puts him back on the start pad":
    @Event eachPlayer
    @Condition eventPlayer == learner
    @Condition ready
    @Condition eventPlayer.fell
    @Condition walking == false
    wait(0.5)
    putHome()

rule "Game 3: the screen":
    @Condition ready
    hudText(getAllPlayers(), null, null, ctrl, HudPosition.LEFT, 3, Color.WHITE, Color.WHITE, Color.ORANGE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, null, boardTxt, HudPosition.RIGHT, 0, Color.WHITE, Color.WHITE, Color.SKY_BLUE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, null, boardTxt2, HudPosition.RIGHT, 1, Color.WHITE, Color.WHITE, Color.SKY_BLUE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers() if showDebrief else null, null, null, deb[0], HudPosition.LEFT, 4, Color.WHITE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers() if showDebrief else null, null, null, deb[1], HudPosition.LEFT, 5, Color.WHITE, Color.WHITE, Color.YELLOW, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers() if showDebrief else null, null, null, deb[2], HudPosition.LEFT, 6, Color.WHITE, Color.WHITE, Color.LIME_GREEN, HudReeval.VISIBILITY_AND_STRING)

rule "Game 3: run":
    @Condition ready
    learner.disallowButton(Button.ABILITY_1)
    learner.disallowButton(Button.ABILITY_2)
    learner.disallowButton(Button.ULTIMATE)
    for sp in range(25):
        padPos[sp] = vect(-14 + 4 * (sp % 5), 0, -14 + 4 * floor(sp / 5))
        arrow[sp] = -1
        arrowOld[sp] = -1
    learner.setFacing(vect(0, 0, 1), Relativity.TO_WORLD)
    # map: start, goal, the fixed pit, the pit that will move
    LOG("RLG,E,{},map,{},{},{},{}".format(GAME_ID, START, goal, pits[0], pits[1]))

    # ---- Self-tests: the planner checks its own arithmetic on this map, silently, before the round ----
    clearBoard()
    looks = 0
    sweepOnce()
    CHECK("one sweep: pad beside the goal", 9, V[22])
    CHECK("one sweep: start pad", -1, V[START])
    CHECK("look-aheads in one sweep (22 pads x 4 moves)", 88, looks)
    settle()
    nSweeps = sweepN
    dStart = lastCh[START]
    dMax = sorted(lastCh).last()
    vStart = V[START]
    CHECK("sweeps until a sweep changes nothing", 8, nSweeps)
    CHECK("start pad's settled number", 5, vStart)
    keepOld = false
    makeArrows()
    simWalk()
    CHECK("walking the lines earns the start pad's number", vStart, walkSim)
    arrowOld = arrow
    pits[1] = AUTO_PIT
    settle()
    keepOld = true
    makeArrows()
    CHECK("old lines made wrong by moving the pit to pad 7", 5, wrongN)
    # pre: sweeps until nothing changes, sweeps until the start pad hears the goal, the same for the farthest pad,
    #      the start pad's settled number, what walking the lines earns by the rules
    LOG("RLG,E,{},pre,{},{},{},{},{}".format(GAME_ID, nSweeps, dStart, dMax, vStart, walkSim))
    pits[1] = PIT_B
    keepOld = false
    for sp in range(25):
        arrow[sp] = -1
        arrowOld[sp] = -1
    clearBoard()
    looks = 0
    looks0 = 0
    showArrows = false
    drawBoard()

    # ---- Round 1: the rules, and the first sweep ----
    ctrl = "Answer: LEFT CLICK / RIGHT CLICK / MELEE.   F: one sweep.   WASD: walk."
    coach = "Whiteboard before the round: you know this map's rules, so plan the dive instead of dying to find out."
    HOLD(7)
    coach = "Each step costs 1. The goal pays 10. A red pit costs 10 and ends the dive. Every pad starts at 0."
    HOLD(7)
    qId = 1
    qText = "After ONE sweep, the pad next to the goal shows?"
    qOpts = ["9", "10", "-1"]
    qCorrect = 0
    qAuto = 0
    qWhy = "-1 for the step, +10 for the goal, plus the goal's 0: lecture 2's one-step rule."
    ask()
    runId = 1
    coach = "Press F: each pad looks at its 4 moves (step reward + the number it lands on) and keeps the best."
    while sweepN < 30:
        waitF()
        sweepOnce()
        drawBoard()
        logBoard()
        coach = "Sweep {}: {} pads changed. Yellow pads just heard about the goal. Press F again.".format(sweepN, nChg)
        if nChg == 0:
            break
        if sweepN == 1:
            HOLD(3)
            qId = 2
            qText = "Your start pad shows -1. Which sweep turns it positive?"
            qOpts = ["sweep 2", "sweep {}".format(dStart), "sweep {}".format(2 * dStart)]
            qCorrect = 1
            qAuto = 1
            qWhy = "Good news moves one pad per sweep, and your pad is {} steps from the goal.".format(dStart)
            ask()
            coach = "Press F for sweep 2."
        elif sweepN == 2:
            HOLD(3)
            qId = 3
            qText = "Does ONE plan score exactly these numbers?"
            qOpts = ["the best plan", "a worse plan", "no plan"]
            qCorrect = 2
            qAuto = 0
            qWhy = "A -2 pad ringed by -2 pads scores -3 under any plan. Midway numbers are half-done sums."
            ask()
            coach = "Press F for sweep 3."
        elif sweepN == 3:
            HOLD(3)
            qId = 4
            qText = "Which sweep is the first to change nothing?"
            qOpts = ["sweep {}".format(dMax), "sweep {}".format(dMax + 1), "never"]
            qCorrect = 1
            qAuto = 1
            qWhy = "The farthest pad settles on sweep {}. Sweep {} changes nothing: that is how you know.".format(dMax, dMax + 1)
            ask()
            coach = "Keep pressing F until a sweep changes nothing."

    # ---- Round 2: the plan appears ----
    nSweeps = sweepN
    keepOld = false
    makeArrows()
    showArrows = true
    drawBoard()
    logArrows()
    # looks: sweeps, pads that get a number, look-aheads in all
    LOG("RLG,E,{},looks,{},{},{}".format(GAME_ID, nSweeps, 25 - 1 - len(pits), looks))
    coach = "Nothing changed: plan done. Green line = the step to the best number next door (policy improvement)."
    HOLD(7)
    coach = "{} sweeps x {} pads x 4 moves = {} look-aheads. A real match has far too many states to sweep.".format(nSweeps, 25 - 1 - len(pits), looks)
    HOLD(7)
    qId = 5
    qText = "Start pad says {}. Walk the lines. Your score?".format(round(V[START]))
    qOpts = ["10", "{}".format(round(V[START])), "luck decides"]
    qCorrect = 1
    qAuto = 1
    qWhy = "Walk it and see."
    ask()

    # ---- Round 3: walk the plan ----
    putHome()
    ctrl = "WASD: walk the green lines from the blue ring to the goal. Each pad costs 1."
    coach = "Walk the plan. You can leave it if you like; the board counts every pad you step on."
    walkRet = 0
    walkSteps = 0
    walkEnd = 0
    walkRestarts = 0
    prevP = START
    walkT0 = NOW
    lastMove = NOW
    walking = true
    while walking:
        if learner.fell:
            putHome()
            walkRet = 0
            walkSteps = 0
            prevP = START
            walkRestarts += 1
            coach = "Off the island. Back to the start; the walk starts over."
        if AUTOPLAY and NOW - lastMove > 0.6:
            npP = prevP
            npA = arrow[prevP]
            nextPad()
            learner.teleport(padPos[npS])
            lastMove = NOW
        curP = PAD_OF(learner.getPosition())
        if curP != prevP:
            walkSteps += abs(floor(curP / 5) - floor(prevP / 5)) + abs(curP % 5 - prevP % 5)
            walkRet += 0 - (abs(floor(curP / 5) - floor(prevP / 5)) + abs(curP % 5 - prevP % 5)) + (10 if curP == goal else 0) - (10 if curP in pits else 0)
            prevP = curP
            if curP == goal:
                walkEnd = 1
                walking = false
            elif curP in pits:
                walkEnd = 2
                walking = false
        if NOW - walkT0 > 90:
            walking = false
        wait(0.05)
    # walk: pads entered, what he scored, the start pad's number, end (1 goal, 2 pit, 0 time ran out), restarts after a fall
    LOG("RLG,E,{},walk,{},{},{},{},{}".format(GAME_ID, walkSteps, walkRet, V[START], walkEnd, walkRestarts))
    if walkEnd == 1:
        coach = "You scored {}. The start pad said {}. Its number is what this plan earns: policy evaluation.".format(round(walkRet), round(V[START]))
    elif walkEnd == 2:
        coach = "A pit: you scored {}. Following the lines would have earned {}, the start pad's number.".format(round(walkRet), round(V[START]))
    else:
        coach = "Time ran out. Following the lines earns {}, the start pad's number.".format(round(V[START]))
    HOLD(7)

    # ---- Round 4: the map changes ----
    arrowOld = arrow
    Vsave = V
    pitFrom = pits[1]
    pitOk = false
    pitTries = 0
    # 2026-11-22: this used to say "the right-hand pit", which was the left-hand one from the start pad and
    # neither from where the walk ends. The board now labels the pit that moves.
    markPit = true
    drawBoard()
    ctrl = "WASD: go to a pad.   R: move the pit marked THIS PIT MOVES to that pad."
    coach = "The enemy moved. Stand on any pad and press R: the pit marked THIS PIT MOVES jumps there."
    while not pitOk:
        gotR = false
        wantR = true
        if AUTOPLAY:
            learner.teleport(padPos[AUTO_PIT])
            wait(0.6)
            gotR = true
        waitUntil(gotR == true, 60)
        wantR = false
        pitTries += 1
        pitTo = PAD_OF(learner.getPosition())
        if pitTries >= 4 and (pitTo == START or pitTo == goal or pitTo in pits):
            pitTo = AUTO_PIT
        if pitTo == START or pitTo == goal or pitTo in pits:
            coach = "Pick a pad that is not the blue start, the goal or a pit, then press R."
        else:
            pits[1] = pitTo
            settle()
            # Refuse a pad that would wall another pad in (a pad that could never reach the goal).
            pitOk = true
            for sp in range(25):
                if sp != goal and not (sp in pits) and V[sp] <= 0:
                    pitOk = false
            if not pitOk:
                pits[1] = pitFrom
                coach = "That would wall a pad in with no way to the goal. Pick another pad."
    markPit = false
    keepOld = true
    makeArrows()
    # pit: the pad it left, the pad it moved to, old lines now wrong (answer key), presses of R
    LOG("RLG,E,{},pit,{},{},{},{}".format(GAME_ID, pitFrom, pitTo, wrongN, pitTries))
    V = Vsave
    arrow = arrowOld
    for sp in range(25):
        flip[sp] = false
        newPos[sp] = false
    drawBoard()
    qId = 6
    qText = "The pit moved. How many old lines are now wrong?"
    qOpts = ["none", "1 to 3", "4 or more"]
    qCorrect = 0 if wrongN == 0 else (1 if wrongN <= 3 else 2)
    qAuto = qCorrect
    qWhy = "Press F and watch: lines that change turn yellow."
    ask()

    # ---- Round 5: plan again ----
    ctrl = "F: wipe the board and plan again (the sweeps run by themselves)."
    coach = "Press F: wipe the whiteboard and sweep the new map until nothing changes."
    waitF()
    runId = 2
    clearBoard()
    showArrows = false
    looks0 = looks
    while nChg > 0 and sweepN < 30:
        sweepOnce()
        drawBoard()
        logBoard()
        coach = "Sweep {}: {} pads changed.".format(sweepN, nChg)
        wait(0.3 if AUTOPLAY else 1.2)
    keepOld = true
    makeArrows()
    showArrows = true
    drawBoard()
    logArrows()
    # replan: sweeps, old lines that flipped
    LOG("RLG,E,{},replan,{},{}".format(GAME_ID, sweepN, wrongN))
    coach = "{} old lines flipped (yellow). Only pads whose best route ran past the new pit change their minds.".format(wrongN)
    ctrl = ""
    HOLD(8)

    # ---- Debrief ----
    deb = ["You did: planned the dive one sweep per F, walked the plan, then moved a pit.", "Called: dynamic programming, here value iteration: look one step ahead, repeat.", "In an LLM agent: it can plan tool calls only if it knows what each tool does."]
    showDebrief = true
    coach = "Predictions right: {} of {}. Simplified: moves never slip, and 25 pads is tiny next to a real game.".format(predRight, predTotal)
    HOLD(12)
    finish()
