/*
Game 9: Loot Boxes (lecture 9, exploration and exploitation).

Four loot boxes on pads in a row, each with its own hidden chance of paying 1 (0.2, 0.4, 0.55 and 0.7, shuffled).
The player has 30 opens: stand on a pad, press Interact. Every box has a fixed stack of 30 results drawn at the
start, and whoever opens a box for the k-th time gets its k-th result. So three fixed strategies, played by
arithmetic in step with him (greedy, greedy with one random open in ten, and UCB1 "optimism"), see the same luck.
In the background the script also replays each strategy 20 times for 300 opens, to show whose regret keeps
climbing in a straight line.

Regret here is the lecture's: for each open, how much less the chosen box pays on average than the best box,
added up (sum over boxes of opens times gap). It leaves out luck, so it says how good the choices were.
The upper confidence bound of a box after t opens in all is mean + sqrt(2 ln t / n). The game has no natural log,
so ln is computed as 1024 * (u - u^2/2 + u^3/3) with u = x^(1/1024) - 1, checked at the start.
*/
settings {
    "main": {
        "modeName": "RL course 9: Loot Boxes",
        "description": "Four loot boxes, hidden odds, 30 opens: explore or exploit. Lecture 9 of the RL course. github.com/CarlKho-Minerva/overwatch-rl-lab"
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

#!define GAME_ID 9
#!define GAME_VERSION 1
#!define GAME_TITLE "RL 9: LOOT BOXES"
#!define LEARNER_HERO Hero.TRACER
#!define HOME_POS vect(0, 0, -8)
#!define HOME_FACING vect(0, 0, 1)

#!include "common.opy"

macro NBOX = 4
macro BUDGET = 30
macro PMAX = 0.7
macro PAD_X0 = -9
macro PAD_GAP = 6
macro PAD_Z = 0
macro RP_GAMES = 20
macro RP_OPENS = 300

globalvar odds = []           # the hidden chance of each pad, shuffled
globalvar padPos = [vect(-9, 0, 0), vect(-3, 0, 0), vect(3, 0, 0), vect(9, 0, 0)]
globalvar label = ["A", "B", "C", "D"]
globalvar payTab = []         # box b, its k-th open: payTab[b * 30 + k] (1 pays, 0 not)
globalvar coinTab = []        # the coin's draw for open t: 0 to 39; under 4 means "open box <draw> at random"
globalvar lnTab = []          # ln(t) for t = 0 .. 300 (ln 0 stored as 0, never used)
globalvar gI
globalvar gU
globalvar gV
globalvar setupDone = false
# the player
globalvar myN = [0, 0, 0, 0]
globalvar myS = [0, 0, 0, 0]
globalvar myT = 0
globalvar myTot = 0
globalvar myReg = 0
globalvar myUb = [9, 9, 9, 9]
globalvar wantOpen = -1
globalvar canOpen = false
globalvar roundEnd = 0
globalvar roundNo = 0
globalvar autoBox = 0
globalvar oBox
globalvar oK
globalvar oPay
# the three strategies, played in step with him: strategy k, box i at index k * 4 + i (0 greedy, 1 coin, 2 optimist)
globalvar sN = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
globalvar sS = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
globalvar sTot = [0, 0, 0]
globalvar sReg = [0, 0, 0]
globalvar sA = [0, 0, 0]
globalvar sPay = [0, 0, 0]
globalvar sK
globalvar sTn
globalvar sX
globalvar sV
# (renamed from a name the game's text filter refused as a variable name, 2026-11-22)
globalvar armPick
# the background replays
globalvar rpK
globalvar rpR
globalvar rpT
globalvar rpA
globalvar rpN = [0, 0, 0, 0]
globalvar rpS = [0, 0, 0, 0]
globalvar rpV
globalvar rpX
globalvar rpI
globalvar rpC
globalvar rpSum = []          # strategy k, checkpoint c (100, 200, 300 opens), box i: (k * 3 + c) * 4 + i, summed over games
globalvar rpReg = []          # average regret, strategy k at checkpoint c: k * 3 + c
globalvar replayDone = false
globalvar replayT0
# what the screen shows (rebuilt when something changes)
globalvar beamsOn = false
globalvar beamEnd = [vect(-9, 0.3, 2), vect(-3, 0.3, 2), vect(3, 0.3, 2), vect(9, 0.3, 2)]
globalvar padTxt = ["", "", "", ""]
globalvar ubTxt = ["", "", "", ""]
globalvar hudMine = ""
globalvar hudStrat = ""
globalvar hudReg = ""
globalvar hudRp = ["", "", ""]
globalvar showRp = false
globalvar showEnd = false
globalvar endLine = ["", "", "", ""]

subroutine openRound
subroutine doOpen
subroutine stratChoose
subroutine refreshView
subroutine roundSummary
subroutine pickAuto

playervar nearPad

# ---------------------------------------------------------------------------
# Setup: draw the odds and the boxes' stacks of results, build the log table, check the arithmetic
# ---------------------------------------------------------------------------
rule "Game 9: run":
    @Condition ready
    odds = random.shuffle([0.2, 0.4, 0.55, 0.7])
    for gI in range(NBOX * BUDGET):
        payTab[gI] = 1 if random.uniform(0, 1) < odds[floor(gI / BUDGET)] else 0
    for gI in range(BUDGET):
        coinTab[gI] = random.randint(0, 39)
    for gI in range(RP_OPENS + 1):
        gU = max(gI, 1) ** (1 / 1024) - 1
        lnTab[gI] = 1024 * (gU - gU * gU / 2 + gU * gU * gU / 3)
        if gI % 25 == 24:
            wait()
    LOG("RLG,E,{},odds,{},{},{},{}".format(GAME_ID, odds[0], odds[1], odds[2], odds[3]))
    for gI in range(8):
        # draws: box, half (opens 0-14 or 15-29), then the 15 results
        LOG("RLG,E,{},draws,{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{}".format(GAME_ID, floor(gI / 2), gI % 2, payTab[gI * 15], payTab[gI * 15 + 1], payTab[gI * 15 + 2], payTab[gI * 15 + 3], payTab[gI * 15 + 4], payTab[gI * 15 + 5], payTab[gI * 15 + 6], payTab[gI * 15 + 7], payTab[gI * 15 + 8], payTab[gI * 15 + 9], payTab[gI * 15 + 10], payTab[gI * 15 + 11], payTab[gI * 15 + 12], payTab[gI * 15 + 13], payTab[gI * 15 + 14]))
    for gI in range(2):
        LOG("RLG,E,{},coin,{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{}".format(GAME_ID, gI, coinTab[gI * 15], coinTab[gI * 15 + 1], coinTab[gI * 15 + 2], coinTab[gI * 15 + 3], coinTab[gI * 15 + 4], coinTab[gI * 15 + 5], coinTab[gI * 15 + 6], coinTab[gI * 15 + 7], coinTab[gI * 15 + 8], coinTab[gI * 15 + 9], coinTab[gI * 15 + 10], coinTab[gI * 15 + 11], coinTab[gI * 15 + 12], coinTab[gI * 15 + 13], coinTab[gI * 15 + 14]))
    # Self-tests, one per formula the game uses
    CHECK("ln 8", 2.079, lnTab[8])
    CHECK("ln 300", 5.704, lnTab[300])
    CHECK("3 or more of 4 from a 0.4 box", 0.179, 4 * 0.4 * 0.4 * 0.4 * 0.6 + 0.4 * 0.4 * 0.4 * 0.4)
    CHECK("3 or more of 4 from a 0.55 box", 0.391, 4 * 0.55 * 0.55 * 0.55 * 0.45 + 0.55 * 0.55 * 0.55 * 0.55)
    CHECK("greedy locks out the 0.7 box", 0.235, 0.3 * (1 - 0.8 * 0.6 * 0.45))
    CHECK("bonus of a box opened once after 8 opens in all", 2.039, 0 + sqrt(2 * lnTab[8] / 1))
    CHECK("best case of a box at 4 of 6 after 8 opens in all", 1.499, 4 / 6 + sqrt(2 * lnTab[8] / 6))
    CHECK("coin's lowest regret per 100 opens", 2.375, 100 * 0.1 * ((0.7 - 0.2) + (0.7 - 0.4) + (0.7 - 0.55) + (0.7 - 0.7)) / 4)
    CHECK("regret of opens 1 2 3 4 on odds .2 .4 .55 .7", 1.55, 1 * (PMAX - 0.2) + 2 * (PMAX - 0.4) + 3 * (PMAX - 0.55) + 4 * (PMAX - 0.7))
    setupDone = true

    # Round 1: feel the boxes
    createEffect(getAllPlayers(), Effect.RING, Color.YELLOW, padPos[0], 1.4, EffectReeval.NONE)
    createEffect(getAllPlayers(), Effect.RING, Color.YELLOW, padPos[1], 1.4, EffectReeval.NONE)
    createEffect(getAllPlayers(), Effect.RING, Color.YELLOW, padPos[2], 1.4, EffectReeval.NONE)
    createEffect(getAllPlayers(), Effect.RING, Color.YELLOW, padPos[3], 1.4, EffectReeval.NONE)
    refreshView()
    coach = "Four loot boxes. Each pays 1 with its own hidden chance. You get 30 opens: make them pay."
    wait(1 if AUTOPLAY else 6)
    coach = "Stand on a yellow pad and press Interact to open that box. Opens 1 to 8."
    roundNo = 1
    roundEnd = 8
    openRound()
    roundSummary()

    qId = 1
    qText = "A box paid 3 of its first 4 opens. Is it the best box, for sure?"
    qOpts = ["yes", "no, too few opens"]
    qCorrect = 1
    qAuto = 1
    qWhy = "A 0.4 box pays 3 or 4 of 4 about {}% of the time, a 0.55 box {}%. Four opens prove little.".format(round(100 * (4 * 0.4 * 0.4 * 0.4 * 0.6 + 0.4 * 0.4 * 0.4 * 0.4)), round(100 * (4 * 0.55 * 0.55 * 0.55 * 0.45 + 0.55 * 0.55 * 0.55 * 0.55)))
    ask()

    qId = 2
    qText = "GREEDY opens the best average so far. COIN does too, but 1 open in 10 is random (lecture 5). Stuck forever?"
    qOpts = ["greedy", "the coin", "neither"]
    qCorrect = 0
    qAuto = 0
    qWhy = "If the 0.7 box loses its first open, greedy never opens it again: at least {} games in 100.".format(floor(100 * 0.3 * (1 - 0.8 * 0.6 * 0.45)))
    ask()
    coach = "That is the dilemma: use the box you know (exploit) or find out more (explore). Lecture 5's coin explores."
    wait(1 if AUTOPLAY else 6)

    # Round 2: the optimist's beams appear
    beamsOn = true
    createBeam(getAllPlayers() if beamsOn else null, Beam.GOOD, padPos[0] + vect(0, 0, 2), beamEnd[0], Color.SKY_BLUE, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
    createBeam(getAllPlayers() if beamsOn else null, Beam.GOOD, padPos[1] + vect(0, 0, 2), beamEnd[1], Color.SKY_BLUE, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
    createBeam(getAllPlayers() if beamsOn else null, Beam.GOOD, padPos[2] + vect(0, 0, 2), beamEnd[2], Color.SKY_BLUE, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
    createBeam(getAllPlayers() if beamsOn else null, Beam.GOOD, padPos[3] + vect(0, 0, 2), beamEnd[3], Color.SKY_BLUE, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
    createInWorldText(getAllPlayers() if beamsOn else null, ubTxt[0], beamEnd[0] + vect(0, 0.4, 0), 1.4, Clip.NONE, WorldTextReeval.VISIBILITY_POSITION_AND_STRING, Color.SKY_BLUE)
    createInWorldText(getAllPlayers() if beamsOn else null, ubTxt[1], beamEnd[1] + vect(0, 0.4, 0), 1.4, Clip.NONE, WorldTextReeval.VISIBILITY_POSITION_AND_STRING, Color.SKY_BLUE)
    createInWorldText(getAllPlayers() if beamsOn else null, ubTxt[2], beamEnd[2] + vect(0, 0.4, 0), 1.4, Clip.NONE, WorldTextReeval.VISIBILITY_POSITION_AND_STRING, Color.SKY_BLUE)
    createInWorldText(getAllPlayers() if beamsOn else null, ubTxt[3], beamEnd[3] + vect(0, 0.4, 0), 1.4, Clip.NONE, WorldTextReeval.VISIBILITY_POSITION_AND_STRING, Color.SKY_BLUE)
    refreshView()
    coach = "Blue beams: each box's best plausible case from YOUR opens. Average plus a bonus that shrinks as you open it."
    wait(1 if AUTOPLAY else 7)
    coach = "That is optimism, the rule called UCB1: open the tallest beam. Opens 9 to 16, your choice."
    roundNo = 2
    roundEnd = 16
    openRound()
    roundSummary()

    qId = 3
    qText = "OPTIMIST opened a box once and it paid 0. What does it do with that box?"
    qOpts = ["never again", "opens it again later", "opens it every time"]
    qCorrect = 1
    qAuto = 1
    qWhy = "Its bonus grows with all opens: after 8, a once-lost box scores {} against {} for one at 4 of 6.".format(round(100 * sqrt(2 * lnTab[8])) / 100, round(100 * (4 / 6 + sqrt(2 * lnTab[8] / 6))) / 100)
    ask()
    coach = "Optimism in the face of uncertainty: what you barely know might be the best, so you look."
    wait(1 if AUTOPLAY else 5)
    coach = "Opens 17 to 24."
    roundNo = 3
    roundEnd = 24
    openRound()
    roundSummary()

    # Question 4 is answered by the replays, which have been running since the start
    waitUntil(replayDone == true, 100)
    qId = 4
    qText = "Each strategy plays 20 games of 300 opens. Whose regret keeps climbing in a straight line?"
    qOpts = ["only greedy", "greedy and the coin", "all three"]
    qCorrect = 1
    qAuto = 1
    qWhy = "Greedy can stick on a worse box; the coin pays {} per 100 forever. The optimist's bill shrinks.".format(round(10 * 100 * 0.1 * ((0.7 - 0.2) + (0.7 - 0.4) + (0.7 - 0.55)) / 4) / 10)
    ask()
    showRp = true
    coach = "Right side: regret added per 100 opens. Short games favour the coin; the optimist's line bends."
    wait(1 if AUTOPLAY else 9)
    coach = "Opens 25 to 29."
    roundNo = 4
    roundEnd = 29
    openRound()

    qId = 5
    qText = "One open left. The box you know best, or a box you opened once that lost?"
    qOpts = ["the box I know", "the barely known box"]
    qCorrect = 0
    qAuto = 0
    qWhy = "Nothing you learn now can change a later open. Information is worth most when many opens remain."
    ask()
    coach = "That is the value of information: an open is worth more when it could change what you do next."
    wait(1 if AUTOPLAY else 4)
    coach = "Your last open."
    roundEnd = 30
    openRound()
    roundSummary()

    # Debrief
    endLine[0] = "The odds were A {}, B {}, C {}, D {}. You opened A {}, B {}, C {}, D {} times.".format(odds[0], odds[1], odds[2], odds[3], myN[0], myN[1], myN[2], myN[3])
    endLine[1] = "You did: {} from 30 opens, regret {}. Greedy {}, coin {}, optimist {} on the same luck.".format(myTot, myReg, sTot[0], sTot[1], sTot[2])
    endLine[2] = "It is called: the explore-exploit dilemma, scored by regret; optimism (UCB1) explores where unsure."
    endLine[3] = "In an agent: the tool call it knows, or one that might be better. What it does not know is part of its state."
    showEnd = true
    LOG("RLG,E,{},end,{},{},{},{},{},{},{},{},{}".format(GAME_ID, myTot, myReg, sTot[0], sReg[0], sTot[1], sReg[1], sTot[2], sReg[2], predRight))
    coach = "Predictions right: {} of {}. Debrief on the left.".format(predRight, predTotal)
    wait(1 if AUTOPLAY else 8)
    finish()
    coach = "Simplified: 4 boxes, 30 opens. On these odds the optimist passes the coin only after thousands of opens."

# ---------------------------------------------------------------------------
# Opening boxes
# ---------------------------------------------------------------------------
def openRound():
    @Name "Game 9: let the learner open boxes until the round's last open"
    while myT < roundEnd:
        wantOpen = -1
        if learner.fell:
            putHome()
        if AUTOPLAY:
            pickAuto()
            learner.teleport(padPos[autoBox])
            wait(0.3)
            wantOpen = autoBox
        else:
            canOpen = true
            waitUntil(wantOpen >= 0 or learner.fell, 99999)
            canOpen = false
        if wantOpen >= 0:
            oBox = wantOpen
            doOpen()
            wait(0.2 if AUTOPLAY else 0.6)

def pickAuto():
    @Name "Game 9: the stand-in's choice (each box twice, then the tallest beam from its own opens)"
    if myT < 8:
        autoBox = myT % NBOX
    elif myT == 29:
        # the last open: the box it knows best (most opens), as question 5 recommends
        autoBox = myN.index(sorted(myN).last())
    else:
        autoBox = myUb.index(sorted(myUb).last())

def doOpen():
    @Name "Game 9: open box oBox for the learner, and one open for each strategy"
    oK = myN[oBox]
    oPay = payTab[oBox * BUDGET + oK]
    myN[oBox] += 1
    myS[oBox] += oPay
    myT += 1
    myTot += oPay
    myReg += PMAX - odds[oBox]
    smallMessage(getAllPlayers(), "BOX {} PAID {}".format(label[oBox], oPay))
    # the three strategies take their open number myT
    sTn = myT - 1
    sX = coinTab[sTn]
    for sK in range(3):
        stratChoose()
        sA[sK] = armPick
        sPay[sK] = payTab[armPick * BUDGET + sN[sK * 4 + armPick]]
        sN[sK * 4 + armPick] += 1
        sS[sK * 4 + armPick] += sPay[sK]
        sTot[sK] += sPay[sK]
        sReg[sK] += PMAX - odds[armPick]
    refreshView()
    # open: t, box, which open of that box, paid, his total, his regret
    LOG("RLG,E,{},open,{},{},{},{},{},{}".format(GAME_ID, myT, oBox, oK, oPay, myTot, myReg))
    # step: t, coin draw, then box and pay for greedy, coin, optimist
    LOG("RLG,E,{},step,{},{},{},{},{},{},{},{}".format(GAME_ID, myT, sX, sA[0], sPay[0], sA[1], sPay[1], sA[2], sPay[2]))
    # ub: t, his best case for each box after this open (9 = untried)
    LOG("RLG,E,{},ub,{},{},{},{},{}".format(GAME_ID, myT, myUb[0], myUb[1], myUb[2], myUb[3]))

def stratChoose():
    @Name "Game 9: strategy sK's next box (sTn opens so far, coin draw sX)"
    if sTn < NBOX:
        # every strategy first opens each box once, in order
        armPick = sTn
        return
    sV = sN.slice(sK * 4, 4).map(lambda x, i: sS[sK * 4 + i] / x + (sqrt(2 * lnTab[sTn] / x) if sK == 2 else 0))
    armPick = sV.index(sorted(sV).last())
    if sK == 1 and sX < NBOX:
        armPick = sX

def refreshView():
    @Name "Game 9: rebuild the pad labels, the optimist's beams and the HUD lines"
    for gI in range(NBOX):
        padTxt[gI] = "BOX {}\nopened {}, paid {}".format(label[gI], myN[gI], myS[gI])
        if myN[gI] == 0:
            myUb[gI] = 9
            ubTxt[gI] = "untried: no limit yet"
            gV = 3.2
        else:
            myUb[gI] = myS[gI] / myN[gI] + sqrt(2 * lnTab[myT] / myN[gI])
            ubTxt[gI] = "best case {}".format(round(100 * myUb[gI]) / 100)
            gV = min(myUb[gI], 3)
        beamEnd[gI] = padPos[gI] + vect(0, 0.3 + 1.3 * gV, 2)
    hudMine = "opens left: {}    your total: {}".format(BUDGET - myT, myTot)
    hudStrat = "same boxes, same luck, {} opens:  greedy {}   coin {}   optimist {}".format(myT, sTot[0], sTot[1], sTot[2])

def roundSummary():
    @Name "Game 9: regret so far, and where each strategy has been opening"
    hudReg = "regret so far:  you {}   greedy {}   coin {}   optimist {}\ngreedy opened A {} B {} C {} D {}".format(myReg, sReg[0], sReg[1], sReg[2], sN[0], sN[1], sN[2], sN[3])
    # round: number, t, his total, his regret, then total and regret for greedy, coin, optimist
    LOG("RLG,E,{},round,{},{},{},{},{},{},{},{},{},{}".format(GAME_ID, roundNo, myT, myTot, myReg, sTot[0], sReg[0], sTot[1], sReg[1], sTot[2], sReg[2]))
    coach = "Regret: per open, how much less your box pays on average than the best box. Added up. Lower is better."
    wait(1 if AUTOPLAY else 6)

rule "Game 9: Interact on a pad opens that box":
    @Event eachPlayer
    @Condition eventPlayer == learner
    @Condition canOpen
    @Condition eventPlayer.isHoldingButton(Button.INTERACT)
    eventPlayer.nearPad = min(NBOX - 1, max(0, round((eventPlayer.getPosition().x - PAD_X0) / PAD_GAP)))
    if distance(eventPlayer.getPosition(), padPos[eventPlayer.nearPad]) < 1.8:
        wantOpen = eventPlayer.nearPad
    else:
        smallMessage(eventPlayer, "Stand on a yellow pad first")

# ---------------------------------------------------------------------------
# Background: replay each strategy 20 games of 300 opens, with fresh draws
# ---------------------------------------------------------------------------
rule "Game 9: replays":
    @Condition setupDone
    replayT0 = NOW
    rpSum = []
    rpSum[35] = 0
    rpSum = rpSum.map(lambda x: 0)
    for rpK in range(3):
        for rpR in range(RP_GAMES):
            rpN = [0, 0, 0, 0]
            rpS = [0, 0, 0, 0]
            for rpT in range(RP_OPENS):
                # rpT opens so far
                if rpT < NBOX:
                    rpA = rpT
                else:
                    rpV = rpN.map(lambda x, i: rpS[i] / x + (sqrt(2 * lnTab[rpT] / x) if rpK == 2 else 0))
                    rpA = rpV.index(sorted(rpV).last())
                    if rpK == 1:
                        rpX = random.randint(0, 39)
                        if rpX < NBOX:
                            rpA = rpX
                rpN[rpA] += 1
                rpS[rpA] += 1 if random.uniform(0, 1) < odds[rpA] else 0
                if rpT % 100 == 99:
                    for rpI in range(NBOX):
                        rpSum[(rpK * 3 + floor(rpT / 100)) * 4 + rpI] += rpN[rpI]
                if rpT % 15 == 14:
                    wait()
    for rpC in range(9):
        rpReg[rpC] = (rpSum[rpC * 4] * (PMAX - odds[0]) + rpSum[rpC * 4 + 1] * (PMAX - odds[1]) + rpSum[rpC * 4 + 2] * (PMAX - odds[2]) + rpSum[rpC * 4 + 3] * (PMAX - odds[3])) / RP_GAMES
        # replay: strategy, checkpoint (0 = 100 opens, 1 = 200, 2 = 300), opens of each box summed over the games, average regret
        LOG("RLG,E,{},replay,{},{},{},{},{},{},{}".format(GAME_ID, floor(rpC / 3), rpC % 3, rpSum[rpC * 4], rpSum[rpC * 4 + 1], rpSum[rpC * 4 + 2], rpSum[rpC * 4 + 3], rpReg[rpC]))
    hudRp[0] = "20 replays of 300 opens. Regret added in opens 1-100, 101-200, 201-300:"
    hudRp[1] = "greedy {}, {}, {}      coin {}, {}, {}".format(round(rpReg[0] * 10) / 10, round((rpReg[1] - rpReg[0]) * 10) / 10, round((rpReg[2] - rpReg[1]) * 10) / 10, round(rpReg[3] * 10) / 10, round((rpReg[4] - rpReg[3]) * 10) / 10, round((rpReg[5] - rpReg[4]) * 10) / 10)
    hudRp[2] = "optimist {}, {}, {}      the coin can never go under {} per 100".format(round(rpReg[6] * 10) / 10, round((rpReg[7] - rpReg[6]) * 10) / 10, round((rpReg[8] - rpReg[7]) * 10) / 10, round(10 * 100 * 0.1 * ((PMAX - 0.2) + (PMAX - 0.4) + (PMAX - 0.55)) / 4) / 10)
    LOG("RLG,E,{},replaytime,{}".format(GAME_ID, NOW - replayT0))
    replayDone = true

# ---------------------------------------------------------------------------
# The screen
# ---------------------------------------------------------------------------
rule "Game 9: the screen":
    @Condition setupDone
    hudText(getAllPlayers(), null, null, hudMine, HudPosition.LEFT, 3, Color.WHITE, Color.WHITE, Color.YELLOW, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, null, hudStrat, HudPosition.LEFT, 4, Color.WHITE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, null, hudReg, HudPosition.LEFT, 5, Color.WHITE, Color.WHITE, Color.ORANGE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers() if showEnd else null, null, null, endLine[0], HudPosition.LEFT, 6, Color.WHITE, Color.WHITE, Color.GREEN, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers() if showEnd else null, null, null, endLine[1], HudPosition.LEFT, 7, Color.WHITE, Color.WHITE, Color.GREEN, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers() if showEnd else null, null, null, endLine[2], HudPosition.LEFT, 8, Color.WHITE, Color.WHITE, Color.GREEN, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers() if showEnd else null, null, null, endLine[3], HudPosition.LEFT, 9, Color.WHITE, Color.WHITE, Color.GREEN, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, null, "WASD: walk.  Interact (F) on a yellow pad: open that box.\nAnswer: left click, right click, melee.", HudPosition.RIGHT, 0, Color.WHITE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers() if showRp else null, null, null, hudRp[0], HudPosition.RIGHT, 1, Color.WHITE, Color.WHITE, Color.SKY_BLUE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers() if showRp else null, null, null, hudRp[1], HudPosition.RIGHT, 2, Color.WHITE, Color.WHITE, Color.SKY_BLUE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers() if showRp else null, null, null, hudRp[2], HudPosition.RIGHT, 3, Color.WHITE, Color.WHITE, Color.SKY_BLUE, HudReeval.VISIBILITY_AND_STRING)
    createInWorldText(getAllPlayers(), padTxt[0], padPos[0] + vect(0, 1.2, 1.2), 1.6, Clip.NONE, WorldTextReeval.VISIBILITY_POSITION_AND_STRING, Color.WHITE)
    createInWorldText(getAllPlayers(), padTxt[1], padPos[1] + vect(0, 1.2, 1.2), 1.6, Clip.NONE, WorldTextReeval.VISIBILITY_POSITION_AND_STRING, Color.WHITE)
    createInWorldText(getAllPlayers(), padTxt[2], padPos[2] + vect(0, 1.2, 1.2), 1.6, Clip.NONE, WorldTextReeval.VISIBILITY_POSITION_AND_STRING, Color.WHITE)
    createInWorldText(getAllPlayers(), padTxt[3], padPos[3] + vect(0, 1.2, 1.2), 1.6, Clip.NONE, WorldTextReeval.VISIBILITY_POSITION_AND_STRING, Color.WHITE)
