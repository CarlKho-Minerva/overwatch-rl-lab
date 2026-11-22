/*
Game 10: The Peek. Lecture 10, classic games.

Tracer peeks a Widowmaker. Each peek both choose at once: he picks the LEFT or the RIGHT corner, she picks the corner
she holds her scope on. Whatever he wins she loses (zero-sum). The payoffs are not symmetric:
    he peeks LEFT:   +3 if she holds right, -2 if she holds left     (the fast flank: worth more, costs more)
    he peeks RIGHT:  +1 if she holds left,  -1 if she holds right
The safe mix (minimax) peeks LEFT 2 times in 7 and wins 1/7 a peek whatever she does; hers holds LEFT 4 times in 7.

Phases: 4 peeks against a fixed Widowmaker who always holds right (best response), 5 against one who learns his habits
(she answers his peek counts, the fictitious-play idea, mixed with her own past aims as in Smooth UCT), 5 with a
2-in-7 die beside him (the safe mix), then 300 peeks of two learners playing each other (self-play), shown as bars.
One matrix game played again and again: there is no search tree here.
*/
settings {
    "main": {
        "modeName": "RL course 10: The Peek",
        "description": "Lecture 10, classic games: peek a Widowmaker who learns your habits. github.com/CarlKho-Minerva/overwatch-rl-lab"
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

#!define GAME_ID 10
#!define GAME_VERSION 1
#!define GAME_TITLE "RL 10: THE PEEK"
#!define LEARNER_HERO Hero.TRACER
#!define HOME_POS vect(0, 0, -12)
#!define HOME_FACING vect(0, 0, 1)

#!include "common.opy"

# His points for (pick, aim), index pick * 2 + aim, with 1 = left and 0 = right. Hers are the same, negated.
globalvar payTab = [-1, 1, 3, -2]

macro N_PEEKS = 14
macro PAY(pk, am):
    (payTab[(pk) * 2 + (am)])
macro PAUSE(t):
    wait(0.3 if AUTOPLAY else t)

# Vector.LEFT is (1, 0, 0): the left corner is on his left hand when he faces +z from home.
globalvar leftPos = vect(7, 0, -2)
globalvar rightPos = vect(-7, 0, -2)
globalvar widowPos = vect(0, 0, 12)
globalvar widow = null
globalvar spawnTry
globalvar phase = 0
globalvar peekN = 0
globalvar phasePeeks = 0
globalvar pick = -1
globalvar pickOpen = false
globalvar pickTxt = ""
# The stand-in's peeks in phases 1 and 2 (in phase 3 it follows the die).
globalvar autoPicks = [1, 1, 1, 1, 1, 0, 0, 1, 0]
globalvar nL = 0          # his left peeks so far (she sees them all, the fixed Widowmaker's phase included)
globalvar nN = 0          # his peeks so far
globalvar aL = 1          # her left aims so far, starting from one left and one right (half and half)
globalvar aA = 2
globalvar herBR = 0       # her best answer to his counts: 1 = aim left
globalvar herQ = 0        # her odds of aiming left this peek
globalvar drawU = -1      # her draw, 0 to 99
globalvar aim = 0
globalvar pay = 0
globalvar score = 0
globalvar ev = 0
globalvar evSum = 0
globalvar phasePay = 0
globalvar dieRoll = -1
globalvar dieSays = -1
globalvar followed = 0
globalvar tmo = 0
globalvar beam = null
globalvar barHer = 0
globalvar barHim = 0
globalvar barHerTxt = ""
globalvar barHimTxt = ""
globalvar scoreTxt = ""
globalvar infoTxt = ""
globalvar mA
globalvar mB
globalvar mC
globalvar mD
globalvar mDen
globalvar gVal
globalvar gP
globalvar gQ
globalvar spT
globalvar spNL
globalvar spN
globalvar spML
globalvar spM
globalvar spTr
globalvar spWi
globalvar spLast
globalvar spFlips
globalvar spPay
globalvar spSnap = []
globalvar spI

subroutine oddsNow
subroutine peek
subroutine redraw
subroutine selfPlay

def oddsNow():
    @Name "Game 10: her odds of aiming left this peek"
    if phase == 1:
        # The fixed Widowmaker: she always holds right.
        herBR = 0
        herQ = 0
    else:
        # Half the time she answers his habit (aim left once he peeks left more than 2 times in 7), half the time she
        # repeats her own habit (her share of left aims so far). Integer test, so the log can recompute it exactly.
        herBR = 1 if 7 * nL > 2 * nN else 0
        herQ = (herBR * aA + aL) / (2 * aA)

def redraw():
    @Name "Game 10: rebuild the HUD strings (only when something changes)"
    barHer = 100 * herQ
    barHim = 100 * nL / max(nN, 1)
    # Bar labels stay under 44 characters, or the game wraps them under the bar onto the next row.
    barHerTxt = "her LEFT odds now: {}%{}".format(round(100 * herQ), "  (safe mix 57%)" if phase >= 3 else "")
    barHimTxt = "you went LEFT {}/{}: {}%{}".format(nL, nN, round(barHim), "  (safe mix 29%)" if phase >= 3 else "")
    scoreTxt = "your points {}    hers {}    peek {} of {}".format(score, 0 - score, peekN, N_PEEKS)
    if phase == 1:
        infoTxt = "This Widowmaker never changes: she always holds RIGHT."
    elif phase == 2:
        infoTxt = "She aims at your habit half the time, else at her own."
    else:
        infoTxt = "The die says {}. It says LEFT 2 times in 7.".format("LEFT" if dieSays == 1 else "RIGHT")

def peek():
    @Name "Game 10: one peek. Both choose at once, then the result shows in the world"
    putHome()
    learner.setFacing(Vector.FORWARD, Relativity.TO_WORLD)
    widow.setFacing(directionTowards(widowPos, vect(0, 0, -2)), Relativity.TO_WORLD)
    peekN += 1
    phasePeeks += 1
    oddsNow()
    dieRoll = -1
    dieSays = -1
    if phase == 3:
        dieRoll = random.randint(0, 6)
        dieSays = 1 if dieRoll < 2 else 0
    redraw()
    learner.disallowButton(Button.PRIMARY_FIRE)
    learner.disallowButton(Button.SECONDARY_FIRE)
    waitUntil(not learner.isHoldingButton(Button.PRIMARY_FIRE) and not learner.isHoldingButton(Button.SECONDARY_FIRE), 3)
    pick = -1
    tmo = 0
    pickTxt = "PEEK {} OF {}: LEFT CLICK left, RIGHT CLICK right".format(peekN, N_PEEKS)
    pickOpen = true
    if AUTOPLAY:
        wait(0.4)
        pick = dieSays if phase == 3 else autoPicks[peekN - 1]
    else:
        waitUntil(pick >= 0 or gameOver, 120)
    pickOpen = false
    if pick < 0:
        pick = 0
        tmo = 1
    if phase == 1:
        drawU = -1
        aim = 0
    else:
        drawU = random.randint(0, 99)
        aim = 1 if drawU * 2 * aA < 100 * (herBR * aA + aL) else 0
    pay = PAY(pick, aim)
    ev = herQ * PAY(pick, 1) + (1 - herQ) * PAY(pick, 0)
    # peek: n, phase, pick, his lefts so far, his peeks so far, her best answer, her lefts, her aims, her odds, draw,
    #       aim, his points, his expected points against her odds, die roll, what the die said, timed out
    LOG("RLG,E,{},peek,{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{}".format(GAME_ID, peekN, phase, pick, nL, nN, herBR, aL, aA, herQ, drawU, aim, pay, ev, dieRoll, dieSays, tmo))
    score += pay
    evSum += ev
    phasePay += pay
    if phase == 3 and pick == dieSays:
        followed += 1
    nL += pick
    nN += 1
    if phase >= 2:
        aL += aim
        aA += 1
    # The result, in the world: he steps out at his corner, she turns her scope to hers.
    learner.teleport(leftPos if pick == 1 else rightPos)
    wait(0.15)
    learner.setFacing(directionTowards(learner.getEyePosition(), widow.getEyePosition()), Relativity.TO_WORLD)
    widow.setFacing(directionTowards(widow.getEyePosition(), (leftPos if aim == 1 else rightPos) + vect(0, 1.4, 0)), Relativity.TO_WORLD)
    widow.startForcingButton(Button.SECONDARY_FIRE)
    if pick == aim:
        createBeam(getAllPlayers(), Beam.BAD, widow.getEyePosition(), learner.getEyePosition(), Color.RED, EffectReeval.NONE)
        beam = getLastCreatedEntity()
        playEffect(getAllPlayers(), DynamicEffect.BAD_EXPLOSION, Color.RED, learner.getPosition(), 1.5)
        bigMessage(getAllPlayers(), "CAUGHT. She was holding {}: {} for you".format("LEFT" if aim == 1 else "RIGHT", pay))
    else:
        playEffect(getAllPlayers(), DynamicEffect.GOOD_EXPLOSION, Color.GREEN, learner.getPosition(), 1.5)
        bigMessage(getAllPlayers(), "CLEAN PEEK. She was holding {}: +{} for you".format("LEFT" if aim == 1 else "RIGHT", pay))
    coach = "Peek {}: you went {}, she held {}. {} points, total {}.".format(peekN, "LEFT" if pick == 1 else "RIGHT", "LEFT" if aim == 1 else "RIGHT", pay, score)
    if phase == 2:
        coach = "Peek {}: {} points. Against her odds, that peek was worth {} on average.".format(peekN, pay, ev)
    redraw()
    wait(0.9 if AUTOPLAY else 3)
    widow.stopForcingButton(Button.SECONDARY_FIRE)
    if beam != null:
        destroyEffect(beam)
        beam = null

def selfPlay():
    @Name "Game 10: two learners play 300 peeks (fictitious play: each answers the other's habit counts)"
    spNL = 1
    spN = 2
    spML = 1
    spM = 2
    spLast = -1
    spFlips = 0
    spPay = 0
    spSnap = []
    for spT in range(1, 301):
        # Tracer: peek left when her left share is under 4 in 7. Widowmaker: aim left when his is over 2 in 7.
        spTr = 1 if 7 * spML < 4 * spM else 0
        spWi = 1 if 7 * spNL > 2 * spN else 0
        if spLast >= 0 and spTr != spLast:
            spFlips += 1
        spLast = spTr
        spPay += PAY(spTr, spWi)
        spNL += spTr
        spN += 1
        spML += spWi
        spM += 1
        if spT % 20 == 0:
            spSnap.append(spT)
            spSnap.append(spNL)
            spSnap.append(spN)
            spSnap.append(spML)
            spSnap.append(spM)
            spSnap.append(spTr)
            spSnap.append(spWi)
        if spT % 10 == 0:
            wait()

rule "Game 10: left click and right click choose the corner (outside questions)":
    @Event eachPlayer
    @Condition eventPlayer == learner
    @Condition pickOpen
    @Condition not qActive
    @Condition eventPlayer.isHoldingButton(Button.PRIMARY_FIRE) or eventPlayer.isHoldingButton(Button.SECONDARY_FIRE)
    pick = 1 if eventPlayer.isHoldingButton(Button.PRIMARY_FIRE) else 0

rule "Game 10: back to the start after a fall":
    @Event eachPlayer
    @Condition eventPlayer == learner
    @Condition ready
    @Condition eventPlayer.fell
    @Condition not gameOver
    wait(0.5)
    putHome()
    learner.setFacing(Vector.FORWARD, Relativity.TO_WORLD)

rule "Game 10: the screen":
    @Condition ready
    hudText(getAllPlayers() if phase >= 1 else null, null, null, scoreTxt, HudPosition.RIGHT, 0, Color.WHITE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)
    progressBarHud(getAllPlayers() if phase >= 1 else null, barHer, barHerTxt, HudPosition.RIGHT, 1, Color.LIGHT_RED, Color.WHITE, ProgressHudReeval.VISIBILITY_VALUES_AND_COLOR)
    progressBarHud(getAllPlayers() if phase >= 1 else null, barHim, barHimTxt, HudPosition.RIGHT, 2, Color.YELLOW, Color.WHITE, ProgressHudReeval.VISIBILITY_VALUES_AND_COLOR)
    hudText(getAllPlayers() if phase >= 1 else null, null, null, infoTxt, HudPosition.RIGHT, 3, Color.WHITE, Color.WHITE, Color.SKY_BLUE, HudReeval.VISIBILITY_AND_STRING)
    # The peek prompt is a row of the left block: a row at the top centre ran over the title and the right panel.
    hudText(getAllPlayers() if pickOpen else null, pickTxt, null, null, HudPosition.LEFT, 3, Color.ORANGE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers() if phase == 5 else null, null, null, "1. You peeked a fixed Widowmaker, then a learning one, then by a 2-in-7 die.", HudPosition.LEFT, 3, Color.WHITE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY)
    hudText(getAllPlayers() if phase == 5 else null, null, null, "2. Answering a habit is a best response. The die is the minimax mix nobody can exploit.", HudPosition.LEFT, 4, Color.WHITE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY)
    hudText(getAllPlayers() if phase == 5 else null, null, null, "3. An agent trained against one fixed simulated user learns that user, not the task.", HudPosition.LEFT, 5, Color.WHITE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY)

rule "Game 10: run":
    @Condition ready
    # 2026-11-22: right click picks the right corner, and on Tracer right click is also Blink. Nothing here needs
    # Blink or Recall (the game moves him to his corner), so both are off for the whole game.
    learner.disallowButton(Button.ABILITY_1)
    learner.disallowButton(Button.ABILITY_2)
    # The world: two corners, labelled, and the Widowmaker's spot.
    createEffect(getAllPlayers(), Effect.RING, Color.ORANGE, leftPos, 1.5, EffectReeval.NONE)
    createEffect(getAllPlayers(), Effect.RING, Color.SKY_BLUE, rightPos, 1.5, EffectReeval.NONE)
    createEffect(getAllPlayers(), Effect.RING, Color.RED, widowPos, 1, EffectReeval.NONE)
    createInWorldText(getAllPlayers(), "LEFT CORNER: clean +3, caught -2", leftPos + vect(0, 2.6, 0), 1.6, Clip.NONE, WorldTextReeval.NONE, Color.ORANGE)
    createInWorldText(getAllPlayers(), "RIGHT CORNER: clean +1, caught -1", rightPos + vect(0, 2.6, 0), 1.6, Clip.NONE, WorldTextReeval.NONE, Color.SKY_BLUE)
    for spawnTry in range(3):
        if len([p for p in getPlayers(Team.2) if p.isDummy()]) == 0:
            createDummy(Hero.WIDOWMAKER, Team.2, -1, widowPos, vect(0, 0, -1))
            wait(1)
    widow = [p for p in getPlayers(Team.2) if p.isDummy()][0]
    if len([p for p in getPlayers(Team.2) if p.isDummy()]) == 0:
        coach = "The Widowmaker bot did not appear. Leave a free slot on team 2, then restart the match."
        LOG("RLG,E,{},nowidow,{},{}".format(GAME_ID, len(getPlayers(Team.2)), NOW))
        finish()
        return
    widow.setStatusEffect(null, Status.INVINCIBLE, 9999)
    widow.teleport(widowPos)

    # Self-tests: the safe mix and the value from the payoff table, the mix's safety against both aims, her odds rule,
    # and the self-play run (deterministic, so its result is known in advance).
    mA = PAY(1, 1)
    mB = PAY(1, 0)
    mC = PAY(0, 1)
    mD = PAY(0, 0)
    mDen = mA + mD - mB - mC
    gVal = (mA * mD - mB * mC) / mDen
    gP = (mD - mC) / mDen
    gQ = (mD - mB) / mDen
    CHECK("value of the game", 0.143, gVal)
    CHECK("safe mix peeks left", 0.286, gP)
    CHECK("her safe mix aims left", 0.571, gQ)
    CHECK("mix against her aiming left", 0.143, gP * mA + (1 - gP) * mC)
    CHECK("mix against her aiming right", 0.143, gP * mB + (1 - gP) * mD)
    phase = 2
    nL = 4
    nN = 4
    oddsNow()
    CHECK("her odds after four left peeks", 0.75, herQ)
    nL = 1
    nN = 7
    oddsNow()
    CHECK("her odds after 1 left in 7", 0.25, herQ)
    nL = 0
    nN = 0
    herQ = 0
    herBR = 0
    phase = 0
    selfPlay()
    CHECK("self-play his left share after 300", 0.285, spNL / spN)
    CHECK("self-play her left share after 300", 0.55, spML / spM)
    CHECK("self-play his switches", 12, spFlips)
    LOG("RLG,E,{},setup,{},{},{},{},{},{},{}".format(GAME_ID, mA, mB, mC, mD, gVal, gP, gQ))

    putHome()
    learner.setFacing(Vector.FORWARD, Relativity.TO_WORLD)
    coach = "You are Tracer peeking a Widowmaker. You pick a corner, she picks one to hold. Both at once."
    PAUSE(5)
    coach = "LEFT: +3 if she is not there, -2 if she is. RIGHT: +1 or -1. Whatever you win, she loses."
    PAUSE(6)
    coach = "LEFT CLICK peeks left, RIGHT CLICK peeks right. Questions use the same buttons, at the top."
    PAUSE(5)

    # Phase 1: a fixed opponent. She always holds right.
    phase = 1
    redraw()
    qId = 1
    qText = "This Widowmaker ALWAYS holds the right corner. Which peek wins you the most?"
    qOpts = ["always left", "always right", "half and half"]
    qCorrect = 0
    qAuto = 0
    qWhy = "Left: she never looks there, so it pays 3 each time. Try it."
    ask()
    phasePay = 0
    phasePeeks = 0
    while peekN < 4:
        peek()
    LOG("RLG,E,{},phase,{},{},{}".format(GAME_ID, phase, phasePay, phasePeeks))
    putHome()
    coach = "A fixed opponent is part of the map: one best answer, no dice needed. That is a best response."
    PAUSE(6)

    # Phase 2: a Widowmaker who learns his habits.
    qId = 2
    qText = "A new Widowmaker studies your habits. If you peeked LEFT every time, what is her best answer?"
    qOpts = ["aim left every time", "aim right", "half and half"]
    qCorrect = 0
    qAuto = 0
    qWhy = "Aim left: you would lose 2 a peek. A habit she can see is a habit she can punish."
    ask()
    phase = 2
    oddsNow()
    redraw()
    coach = "She has watched your 4 peeks. She counts them and aims where you usually go."
    PAUSE(5)
    phasePay = 0
    phasePeeks = 0
    while peekN < 9:
        peek()
    LOG("RLG,E,{},phase,{},{},{}".format(GAME_ID, phase, phasePay, phasePeeks))
    putHome()
    coach = "When you changed, her answer changed. Against a learner the target moves."
    PAUSE(6)

    # Back to lecture 7, then the safe mix and its value.
    qId = 3
    qText = "Lecture 7, rock paper scissors: is there a FIXED peek pattern she cannot learn and punish?"
    qOpts = ["yes, the better corner", "no, it must be random"]
    qCorrect = 1
    qAuto = 1
    qWhy = "No. Anything fixed gets read. Like lecture 7's policies, safe play is random on purpose."
    ask()
    qId = 4
    qText = "The safe mix keeps her guessing. Does it peek LEFT, the corner worth 3, more or less than half?"
    qOpts = ["more than half", "less than half", "exactly half"]
    qCorrect = 1
    qAuto = 0
    qWhy = "Less: 2 in 7. Then both her aims pay her the same, so reading you gains her nothing."
    ask()
    qId = 5
    qText = "Against a PERFECT Widowmaker, what is the most you can expect to win per peek?"
    qOpts = ["nothing, 0", "1 point per 7 peeks", "1 point a peek"]
    qCorrect = 1
    qAuto = 1
    qWhy = "1/7 a peek: the most you can guarantee, and the least she can hold you to."
    ask()

    # Phase 3: the safe mix, on a die beside him. He still chooses.
    phase = 3
    coach = "Neither of you sees the other's choice before the peek. When choices are hidden, safe play mixes."
    PAUSE(5)
    coach = "A die now says LEFT 2 times in 7. Follow it or not: you choose every peek."
    PAUSE(5)
    phasePay = 0
    phasePeeks = 0
    while peekN < N_PEEKS:
        peek()
    LOG("RLG,E,{},phase,{},{},{}".format(GAME_ID, phase, phasePay, phasePeeks))
    putHome()
    coach = "You followed the die {} of 5 times and scored {}. Five peeks are too few to see 1/7 a peek.".format(followed, phasePay)
    PAUSE(6)
    coach = "Over many peeks the mix earns 1/7 each whatever she does: the minimax value of the game."
    PAUSE(6)

    # Phase 4: self-play. Two learners, each answering the other's habit counts.
    qId = 6
    qText = "Two learners now play 300 peeks, each answering the other's habits. What do they settle into?"
    qOpts = ["one corner forever", "averages near the safe mix", "nothing settles"]
    qCorrect = 1
    qAuto = 2
    qWhy = "Their choices keep flipping, but their averages settle near 29% and 57%. Watch the bars."
    ask()
    phase = 4
    coach = "Self-play: a learning Tracer against a learning Widowmaker, 300 peeks, shown every 20."
    infoTxt = "Each answers the other's average, so the averages settle."
    for spI in range(15):
        barHim = 100 * spSnap[spI * 7 + 1] / spSnap[spI * 7 + 2]
        barHer = 100 * spSnap[spI * 7 + 3] / spSnap[spI * 7 + 4]
        barHimTxt = "bot Tracer LEFT share: {}%  (safe mix 29%)".format(round(barHim))
        barHerTxt = "bot Widow LEFT share: {}%  (safe mix 57%)".format(round(barHer))
        scoreTxt = "self-play: peek {} of 300".format(spSnap[spI * 7])
        widow.setFacing(directionTowards(widow.getEyePosition(), (leftPos if spSnap[spI * 7 + 6] == 1 else rightPos) + vect(0, 1.4, 0)), Relativity.TO_WORLD)
        LOG("RLG,E,{},sp,{},{},{},{},{},{},{}".format(GAME_ID, spSnap[spI * 7], spSnap[spI * 7 + 1], spSnap[spI * 7 + 2], spSnap[spI * 7 + 3], spSnap[spI * 7 + 4], spSnap[spI * 7 + 5], spSnap[spI * 7 + 6]))
        wait(0.2 if AUTOPLAY else 0.7)
    LOG("RLG,E,{},spend,{},{},{},{}".format(GAME_ID, spFlips, spPay, spNL / spN, spML / spM))
    coach = "His choice switched {} times, yet both averages ended near the safe mix.".format(spFlips)
    PAUSE(6)
    coach = "That pair of mixes is a Nash equilibrium: neither side gains by changing alone."
    PAUSE(6)

    # Debrief.
    phase = 5
    LOG("RLG,E,{},end,{},{},{},{},{}".format(GAME_ID, score, evSum, followed, nL, nN))
    coach = "Predictions right: {} of {}. Your points: {} in {} peeks.".format(predRight, predTotal, score, N_PEEKS)
    PAUSE(9)
    finish()
    coach = "Honest note: one matrix game, replayed. No search tree; real games chain many such choices."
