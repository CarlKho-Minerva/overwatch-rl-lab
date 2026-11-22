/*
Game 6: Callouts. Lecture 6, Value Function Approximation.

Twelve pads in a row, each with a hidden danger number. The player is the scout (Tracer): standing in a ring and
pressing Interact reads that pad, a little off (truth plus -1, 0 or +1), and costs a small hit. He has 6 steps.
From the SAME calls the team keeps three maps:
    EXACT     one number per pad (12 numbers): a table, one feature per pad
    THIRDS    one number per third of the strip (3 numbers): a coarse callout, "mid is hot"
    ONE WORD  one number for the whole strip (1 number)
Each map's number for a pad is the plain average of the calls that fall in that pad's group (0 when it has none):
for one-hot group features that average is the least-squares fit, the mildest linear approximation there is.
Then the script adds 54 calls (every pad 4 or 5 times), then shows the limit of endless scouting, then the player
gives one pad its own number on top of THIRDS and sees what one well-placed feature does.

Log lines (docs in g06.md):
    RLG,E,6,truth,<12 dangers>
    RLG,E,6,see,<call number>,<pad 0-11>,<noise>,<reading>
    RLG,E,6,miss,<stage>,<EXACT>,<THIRDS>,<ONE WORD>         stage 6, 60, or 0 (endless scouting)
    RLG,E,6,est,<stage>,<map 0 EXACT 1 THIRDS 2 ONE WORD 3 YOURS>,<12 numbers>
    RLG,E,6,pick,<pad 0-11>,<YOURS after 6>,<after 60>,<endless>
*/
settings {
    "main": {
        "modeName": "RL course 6: Callouts",
        "description": "Scout 12 pads, then see three maps learn from the same callouts: exact, thirds, one word. github.com/CarlKho-Minerva/overwatch-rl-lab"
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

#!define GAME_ID 6
#!define GAME_VERSION 1
#!define GAME_TITLE "RL 6: CALLOUTS"
#!define LEARNER_HERO Hero.TRACER
#!define HOME_POS vect(0, 0, -5)
#!define HOME_FACING vect(0, 0, 1)

#!include "common.opy"

macro NPADS = 12
macro PAD_X0 = -16.5
macro PAD_SP = 3
macro PAD_Z = 2
macro PAD_R = 1.2
macro BUDGET = 6
macro EXTRA = 54

macro PAUSE(t):
    wait(0.4 if AUTOPLAY else t)

# The hidden danger of each pad. Thirds: pads 1-4 low, 5-8 high, 9-12 low except pad 10, the trap.
globalvar padTxt = []
globalvar truth = [2, 1, 2, 1, 8, 9, 7, 8, 1, 9, 2, 1]
globalvar descE = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
globalvar descT = [0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2]
globalvar descW = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
globalvar descS = []
globalvar allPads = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
globalvar autoPads = [0, 2, 4, 6, 8, 10]
globalvar padPos = []
globalvar padCnt = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
globalvar padLast = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
globalvar padTop = []
globalvar padLow = []
globalvar sPad = []
globalvar sVal = []
globalvar uPad = []
globalvar uVal = []
globalvar desc = []
globalvar fit = []
globalvar fitErr = 0
globalvar fitSq = 0
globalvar fitD = 0
globalvar gSum = []
globalvar gCnt = []
globalvar fi
globalvar pi
globalvar estE = []
globalvar estT = []
globalvar estW = []
globalvar estS = []
globalvar missE = 0
globalvar missT = 0
globalvar missW = 0
globalvar m6 = []
globalvar m60 = []
globalvar mInf = []
globalvar mS = []
globalvar bestMap = 0
globalvar bestV = 0
globalvar stageNo = 0
globalvar callPad = 0
globalvar callNoise = 0
globalvar callVal = 0
globalvar scoutOpen = false
globalvar scoutReq = false
globalvar scoutN = 0
globalvar herePad = -1
globalvar pickPad = -1
globalvar ringMode = 0
globalvar lowMode = 0
globalvar topMode = 0
globalvar kk
globalvar q5Pads = [4, 9, 11]
globalvar wrongMax = 0
globalvar stepsLine = ""
globalvar legendLine = ""
globalvar legend2 = ""
globalvar missHead = ""
globalvar rowE = ""
globalvar rowT = ""
globalvar rowW = ""
globalvar rowS = ""
globalvar deb1 = ""
globalvar deb2 = ""
globalvar deb3 = ""

subroutine fitMap
subroutine fitThree
subroutine drawCall
subroutine padAt
subroutine drawPads
subroutine drawRings
subroutine logEst

def fitMap():
    @Name "Game 6: one map from the calls in uPad/uVal: average per group (0 when a group has no call), then its miss"
    gSum = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    gCnt = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    for fi in range(len(uPad)):
        gSum[desc[uPad[fi]]] += uVal[fi]
        gCnt[desc[uPad[fi]]] += 1
        if fi % 20 == 19:
            wait()
    fitSq = 0
    for fi in range(NPADS):
        fit[fi] = gSum[desc[fi]] / max(1, gCnt[desc[fi]])
        fitD = fit[fi] - truth[fi]
        fitSq += fitD * fitD
    # Typical miss: the square root of the mean squared difference from the truth, over the 12 pads.
    fitErr = sqrt(fitSq / NPADS)

def fitThree():
    @Name "Game 6: the three maps from the same calls, and which one misses least"
    desc = descE
    fitMap()
    estE = fit
    missE = fitErr
    desc = descT
    fitMap()
    estT = fit
    missT = fitErr
    desc = descW
    fitMap()
    estW = fit
    missW = fitErr
    bestMap = 0
    bestV = missE
    if missT < bestV:
        bestMap = 1
        bestV = missT
    if missW < bestV:
        bestMap = 2
        bestV = missW
    LOG("RLG,E,{},miss,{},{},{},{}".format(GAME_ID, stageNo, missE, missT, missW))
    logEst()

def logEst():
    @Name "Game 6: log the three maps' numbers for every pad"
    LOG("RLG,E,{},est,{},0,{},{},{},{},{},{},{},{},{},{},{},{}".format(GAME_ID, stageNo, estE[0], estE[1], estE[2], estE[3], estE[4], estE[5], estE[6], estE[7], estE[8], estE[9], estE[10], estE[11]))
    LOG("RLG,E,{},est,{},1,{},{},{},{},{},{},{},{},{},{},{},{}".format(GAME_ID, stageNo, estT[0], estT[1], estT[2], estT[3], estT[4], estT[5], estT[6], estT[7], estT[8], estT[9], estT[10], estT[11]))
    LOG("RLG,E,{},est,{},2,{},{},{},{},{},{},{},{},{},{},{},{}".format(GAME_ID, stageNo, estW[0], estW[1], estW[2], estW[3], estW[4], estW[5], estW[6], estW[7], estW[8], estW[9], estW[10], estW[11]))

def drawCall():
    @Name "Game 6: one call on pad callPad: the truth plus a random -1, 0 or +1, drawn and logged before use"
    callNoise = random.randint(-1, 1)
    callVal = truth[callPad] + callNoise
    sPad.append(callPad)
    sVal.append(callVal)
    padCnt[callPad] += 1
    padLast[callPad] = callVal
    LOG("RLG,E,{},see,{},{},{},{}".format(GAME_ID, len(sPad) - 1, callPad, callNoise, callVal))

def padAt():
    @Name "Game 6: which pad the learner stands in (-1 for none)"
    herePad = min(NPADS - 1, max(0, round((learner.getPosition().x - PAD_X0) / PAD_SP)))
    if distance(vect(learner.getPosition().x, 0, learner.getPosition().z), padPos[herePad]) > PAD_R + 0.3:
        herePad = -1

def drawPads():
    @Name "Game 6: rebuild the pad labels (two texts per pad, made once per change, never re-read per frame)"
    for pi in range(NPADS):
        if topMode == 0:
            padTop[pi] = "PAD {}".format(pi + 1)
            if padCnt[pi] == 1:
                padTop[pi] = "PAD {}: read {}".format(pi + 1, padLast[pi])
            elif padCnt[pi] > 1:
                padTop[pi] = "PAD {}: read {} ({} reads)".format(pi + 1, padLast[pi], padCnt[pi])
        else:
            padTop[pi] = "PAD {}  truth {}".format(pi + 1, truth[pi])
        padLow[pi] = ""
        if lowMode == 1:
            padLow[pi] = "{} | {} | {}".format(estE[pi], estT[pi], estW[pi])
        elif lowMode == 2:
            padLow[pi] = "{} | {} | {} | {}".format(estE[pi], estT[pi], estW[pi], estS[pi])
    # 2026-11-22: only this game's own labels are removed. destroyAllInWorldText also removed the core's floating
    # question, so a person saw no question after the first redraw.
    for pi in range(len(padTxt)):
        destroyInWorldText(padTxt[pi])
    padTxt = []
    for pi in range(NPADS):
        createInWorldText(getAllPlayers(), padTop[pi], padPos[pi] + vect(0, 2.3, 0), 1.3, Clip.NONE, WorldTextReeval.NONE, Color.WHITE)
        padTxt.append(getLastCreatedText())
        createInWorldText(getAllPlayers(), padLow[pi], padPos[pi] + vect(0, 1.5, 0), 1.2, Clip.NONE, WorldTextReeval.NONE, Color.SKY_BLUE)
        padTxt.append(getLastCreatedText())
        if pi % 4 == 3:
            wait()

def drawRings():
    @Name "Game 6: the pad rings (white while hidden, red or green once the truth is shown, yellow for his pick)"
    destroyAllEffects()
    for pi in range(NPADS):
        if pi == pickPad:
            createEffect(getAllPlayers(), Effect.RING, Color.YELLOW, padPos[pi], PAD_R, EffectReeval.NONE)
        elif ringMode == 0:
            createEffect(getAllPlayers(), Effect.RING, Color.WHITE, padPos[pi], PAD_R, EffectReeval.NONE)
        elif truth[pi] >= 5:
            createEffect(getAllPlayers(), Effect.RING, Color.RED, padPos[pi], PAD_R, EffectReeval.NONE)
        else:
            createEffect(getAllPlayers(), Effect.RING, Color.GREEN, padPos[pi], PAD_R, EffectReeval.NONE)
        if pi % 6 == 5:
            wait()

rule "Game 6: Interact scouts (or picks) the pad you stand in":
    @Event eachPlayer
    @Condition eventPlayer == learner
    @Condition scoutOpen
    @Condition eventPlayer.isHoldingButton(Button.INTERACT)
    scoutReq = true

rule "Game 6: back to the start after a fall":
    @Condition ready
    @Condition learner.fell
    @Condition gameOver == false
    putHome()

rule "Game 6: the screen":
    @Condition ready
    hudText(getAllPlayers(), null, null, "WASD walk. F (Interact): scout your pad. Answer: left click, right click, melee.", HudPosition.LEFT, 3, Color.WHITE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, null, stepsLine, HudPosition.LEFT, 4, Color.WHITE, Color.WHITE, Color.YELLOW, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, null, deb1, HudPosition.LEFT, 5, Color.WHITE, Color.WHITE, Color.ORANGE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, null, deb2, HudPosition.LEFT, 6, Color.WHITE, Color.WHITE, Color.ORANGE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, null, deb3, HudPosition.LEFT, 7, Color.WHITE, Color.WHITE, Color.ORANGE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, null, missHead, HudPosition.RIGHT, 0, Color.WHITE, Color.WHITE, Color.SKY_BLUE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, null, rowE, HudPosition.RIGHT, 1, Color.WHITE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, null, rowT, HudPosition.RIGHT, 2, Color.WHITE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, null, rowW, HudPosition.RIGHT, 3, Color.WHITE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, null, rowS, HudPosition.RIGHT, 4, Color.WHITE, Color.WHITE, Color.YELLOW, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, null, legendLine, HudPosition.RIGHT, 5, Color.WHITE, Color.WHITE, Color.SKY_BLUE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, null, legend2, HudPosition.RIGHT, 6, Color.WHITE, Color.WHITE, Color.SKY_BLUE, HudReeval.VISIBILITY_AND_STRING)

rule "Game 6: run":
    @Condition ready
    for pi in range(NPADS):
        padPos[pi] = vect(PAD_X0 + PAD_SP * pi, 0, PAD_Z)
    descS = descT

    # Self-tests: every formula the game uses, run through the same subroutine the game uses.
    uPad = [0]
    uVal = [5]
    desc = descE
    fitMap()
    CHECK("table: a pad never called stays at 0", 0, fit[1])
    desc = descT
    fitMap()
    CHECK("thirds: one call fills its whole third", 5, fit[3])
    uPad = [2, 2]
    uVal = [6, 8]
    desc = descE
    fitMap()
    CHECK("Monte Carlo: two reads of 6 and 8 average to 7", 7, fit[2])
    uPad = allPads
    uVal = truth
    desc = descE
    fitMap()
    CHECK("exact map, endless scouting: miss 0", 0, fitErr)
    desc = descT
    fitMap()
    CHECK("thirds map, pads 9 to 12 average 3.25", 3.25, fit[9])
    CHECK("thirds map, endless scouting: miss 1.995", 1.995, fitErr)
    desc = descW
    fitMap()
    CHECK("one word map, endless scouting: miss 3.394", 3.394, fitErr)
    descS = descT
    descS[9] = 3
    desc = descS
    fitMap()
    CHECK("thirds plus pad 10 alone, endless scouting: miss 0.553", 0.553, fitErr)
    descS = descT
    LOG("RLG,E,{},truth,{},{},{},{},{},{},{},{},{},{},{},{}".format(GAME_ID, truth[0], truth[1], truth[2], truth[3], truth[4], truth[5], truth[6], truth[7], truth[8], truth[9], truth[10], truth[11]))

    ringMode = 0
    topMode = 0
    lowMode = 0
    drawRings()
    drawPads()

    # ---------------- Round 1: he scouts 6 pads ----------------
    coach = "Twelve pads, each with a hidden danger. You scout: 6 steps. Stand in a ring, press F to read it."
    PAUSE(5)
    scoutN = 0
    while scoutN < BUDGET:
        stepsLine = "Scouting steps left: {} of {}".format(BUDGET - scoutN, BUDGET)
        scoutReq = false
        # 2026-11-22: F held past the end of one scout used to read the same pad a second time.
        waitUntil(not learner.isHoldingButton(Button.INTERACT), 3)
        scoutOpen = true
        if AUTOPLAY:
            learner.teleport(padPos[autoPads[scoutN]])
            wait(0.5)
            scoutReq = true
        waitUntil(scoutReq == true, 99999)
        scoutOpen = false
        scoutReq = false
        padAt()
        if herePad < 0:
            coach = "Stand inside a ring first, then press F."
            wait(0.5)
        else:
            callPad = herePad
            drawCall()
            scoutN += 1
            learner.setHealth(max(20, learner.getHealth() - 12 * callVal))
            playEffect(getAllPlayers(), DynamicEffect.BAD_EXPLOSION, Color.RED if callVal >= 5 else Color.WHITE, padPos[callPad], 0.4 + callVal / 8)
            smallMessage(getAllPlayers(), "Pad {} reads {}".format(callPad + 1, callVal))
            coach = "Pad {} reads {}. A read can be off by 1. Your call goes to all three maps.".format(callPad + 1, callVal)
            drawPads()
            PAUSE(1.2)
            learner.setHealth(learner.getMaxHealth())
    stepsLine = "Scouting done: {} calls.".format(BUDGET)

    # ---------------- Prediction 1: which map is closest after 6 calls ----------------
    uPad = sPad
    uVal = sVal
    stageNo = 6
    fitThree()
    m6 = [missE, missT, missW]
    coach = "A callout like 'mid is hot' covers four pads at once. Your team kept three maps from your 6 calls."
    PAUSE(5)
    qId = 1
    qText = "Your 6 calls fed three maps. Which is closest to the truth on all 12 pads now?"
    qOpts = ["EXACT, 12 numbers", "THIRDS, 3 numbers", "ONE WORD, 1 number"]
    qCorrect = bestMap
    qAuto = bestMap
    qWhy = "THIRDS: one call filled its whole third. EXACT left every pad you skipped at 0." if bestMap == 1 else ("EXACT: the pads you skipped were near 0 anyway, so guessing 0 cost little." if bestMap == 0 else "ONE WORD: your calls were bunched, so one average guessed the rest best.")
    ask()
    topMode = 1
    ringMode = 1
    lowMode = 1
    drawRings()
    drawPads()
    legendLine = "Under each pad: EXACT | THIRDS | ONE WORD"
    legend2 = "Numbers after 6 calls. Red ring: danger 5 or more."
    missHead = "Typical miss (0 = all right): 6 calls / 60 / forever"
    rowE = "EXACT, 12 numbers:   {}".format(m6[0])
    rowT = "THIRDS, 3 numbers:   {}".format(m6[1])
    rowW = "ONE WORD, 1 number:   {}".format(m6[2])
    coach = "Truth shown. EXACT is a table: a pad it never saw stays at 0. It cannot guess where it has not been."
    PAUSE(7)
    coach = "THIRDS shares: one call moves the number for 4 pads. Learning spread to similar pads is generalisation."
    PAUSE(7)

    # ---------------- Round 2: 54 more calls; draw them first, log them, then ask ----------------
    for kk in range(EXTRA):
        callPad = kk % NPADS
        drawCall()
        if kk % 9 == 8:
            wait()
    uPad = sPad
    uVal = sVal
    stageNo = 60
    fitThree()
    m60 = [missE, missT, missW]
    coach = "Now the team keeps scouting: 54 more calls, every pad read 4 or 5 times, each read off by up to 1."
    PAUSE(5)
    qId = 2
    qText = "After all 60 calls, which map will be closest to the truth?"
    qOpts = ["EXACT", "THIRDS", "ONE WORD"]
    qCorrect = bestMap
    qAuto = bestMap
    qWhy = "EXACT: every pad was visited several times, and a table wins once it has seen everything." if bestMap == 0 else "A coarse map won this time: some pad still had too few calls."
    ask()
    qId = 3
    qText = "Lecture 4: value is the average of what you saw. EXACT averages each pad's reads. After 60, its miss is:"
    qOpts = ["exactly zero", "small, not zero", "bigger than THIRDS"]
    qCorrect = 0 if m60[0] < 0.005 else (1 if m60[0] < m60[1] else 2)
    qAuto = 1
    qWhy = "Small, not zero: 4 or 5 reads off by up to 1 average near the truth, not onto it. The Monte Carlo way."
    ask()
    coach = "Watch the 54 calls come in."
    for kk in range(EXTRA):
        playEffect(getAllPlayers(), DynamicEffect.GOOD_EXPLOSION, Color.SKY_BLUE, padPos[sPad[BUDGET + kk]], 0.6)
        wait(0.05 if AUTOPLAY else 0.12)
    drawPads()
    legend2 = "Numbers after 60 calls. Red ring: danger 5 or more."
    rowE = "EXACT, 12 numbers:   {}  /  {}".format(m6[0], m60[0])
    rowT = "THIRDS, 3 numbers:   {}  /  {}".format(m6[1], m60[1])
    rowW = "ONE WORD, 1 number:   {}  /  {}".format(m6[2], m60[2])
    coach = "With every pad visited the table won. THIRDS and ONE WORD learned fast, then stopped getting better."
    PAUSE(7)
    coach = "Same method, three descriptions: average per group. EXACT has one group per pad: a table is the special case."
    PAUSE(7)

    # ---------------- Prediction 4 and 5: the floor of a coarse description ----------------
    qId = 4
    qText = "Scout forever, every pad read endlessly. Which maps can never get every pad right?"
    qOpts = ["EXACT", "THIRDS and ONE WORD", "none, all get there"]
    qCorrect = 1
    qAuto = 1
    qWhy = "A coarse map writes one number per group. Pads in a group that differ can never all be matched."
    ask()
    uPad = allPads
    uVal = truth
    stageNo = 0
    fitThree()
    mInf = [missE, missT, missW]
    wrongMax = 0
    qCorrect = 0
    for kk in range(3):
        if abs(estT[q5Pads[kk]] - truth[q5Pads[kk]]) > wrongMax + 0.001:
            wrongMax = abs(estT[q5Pads[kk]] - truth[q5Pads[kk]])
            qCorrect = kk
    qId = 5
    qText = "Scouting forever, on which pad does THIRDS stay most wrong?"
    qOpts = ["pad 5", "pad 10", "pad 12"]
    qAuto = 1
    qWhy = "Pad 10: a 9 in a third of 1s and 2s. THIRDS calls it 3.25 forever, and pulls pad 12 up too."
    ask()
    drawPads()
    legend2 = "Numbers if scouting forever. Red ring: danger 5 or more."
    rowE = "EXACT, 12 numbers:   {}  /  {}  /  {}".format(m6[0], m60[0], mInf[0])
    rowT = "THIRDS, 3 numbers:   {}  /  {}  /  {}".format(m6[1], m60[1], mInf[1])
    rowW = "ONE WORD, 1 number:   {}  /  {}  /  {}".format(m6[2], m60[2], mInf[2])
    coach = "Forever: EXACT {}, THIRDS {}, ONE WORD {}. A coarser map learns faster and has a floor.".format(mInf[0], mInf[1], mInf[2])
    PAUSE(8)

    # ---------------- Round 3: he chooses the description ----------------
    coach = "Your call now: give ONE pad its own number on top of THIRDS. Stand in its ring and press F."
    stepsLine = "Pick one pad for its own number."
    pickPad = -1
    while pickPad < 0:
        scoutReq = false
        # 2026-11-22: F held past the end of one scout used to read the same pad a second time.
        waitUntil(not learner.isHoldingButton(Button.INTERACT), 3)
        scoutOpen = true
        if AUTOPLAY:
            learner.teleport(padPos[9])
            wait(0.5)
            scoutReq = true
        waitUntil(scoutReq == true, 99999)
        scoutOpen = false
        scoutReq = false
        padAt()
        if herePad < 0:
            coach = "Stand inside a ring first, then press F."
            wait(0.5)
        else:
            pickPad = herePad
    stepsLine = "Your map: THIRDS, with pad {} on its own. 4 numbers.".format(pickPad + 1)
    descS = descT
    descS[pickPad] = 3
    desc = descS
    uPad = sPad.slice(0, BUDGET)
    uVal = sVal.slice(0, BUDGET)
    fitMap()
    mS[0] = fitErr
    uPad = sPad
    uVal = sVal
    fitMap()
    mS[1] = fitErr
    uPad = allPads
    uVal = truth
    fitMap()
    mS[2] = fitErr
    estS = fit
    LOG("RLG,E,{},pick,{},{},{},{}".format(GAME_ID, pickPad, mS[0], mS[1], mS[2]))
    LOG("RLG,E,{},est,0,3,{},{},{},{},{},{},{},{},{},{},{},{}".format(GAME_ID, estS[0], estS[1], estS[2], estS[3], estS[4], estS[5], estS[6], estS[7], estS[8], estS[9], estS[10], estS[11]))
    qId = 6
    qText = "THIRDS stays at {} forever. With pad {} on its own number, the forever miss lands:".format(mInf[1], pickPad + 1)
    qOpts = ["about the same", "far lower", "at zero"]
    qCorrect = 1 if mS[2] < mInf[1] / 2 else 0
    qAuto = 1
    qWhy = "Far lower: you split off the pad that did not fit its group. 4 numbers, close to EXACT." if qCorrect == 1 else "About the same: that pad already fit its third. The misfit is pad 10, the trap."
    ask()
    ringMode = 1
    drawRings()
    lowMode = 2
    drawPads()
    legendLine = "Under each pad: EXACT | THIRDS | ONE WORD | YOURS"
    rowS = "YOURS, 4 numbers:   {}  /  {}  /  {}".format(mS[0], mS[1], mS[2])
    coach = "Choosing the description is most of the work. Here you chose it by hand; a network learns its own."
    PAUSE(8)
    coach = "Honest note: the mildest form, fixed hand-made groups and plain averages, not a learned network."
    PAUSE(7)

    # ---------------- Debrief ----------------
    stepsLine = ""
    deb1 = "You scouted 6 pads; three maps learned from the same calls: 12 numbers, 3, and 1."
    deb2 = "Called value function approximation: features share a sighting across similar states."
    deb3 = "A language model: sensible on new prompts, sure but wrong when look-alikes differ."
    coach = "Predictions right: {} of {}. Game over.".format(predRight, predTotal)
    finish()
