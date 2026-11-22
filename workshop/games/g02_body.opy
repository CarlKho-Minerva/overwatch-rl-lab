/*
Game 2: Mini or Mega (Lecture 2, Markov decision processes).

A row of 14 pads runs along x. Pad 3 is the start. A mini pack worth 15 sits on pad 0 (3 pads behind the start), a
mega pack worth 50 on pad 13 (10 pads ahead). Part 1: the player turns a discount dial (0.5, 0.8, 0.9, 1), predicts
which pack a Tracer with that discount walks to, sees both discounted values (worth x discount ^ pads), and a bot
Tracer walks to the larger. Part 2: each step costs 1 and the discount is 0.9. The pads fill with values under
"always walk to the mega", by the one-step rule "this pad = -1 + 0.9 x the pad ahead"; he predicts one, then walks
the row while the screen checks the rule on every pad. Then the same pads under "always walk to the mini".
Design note: gNN.md. Log lines: listed there.
*/
settings {
    "main": {
        "modeName": "RL course 2: Mini or Mega",
        "description": "Lecture 2, Markov decision processes: discounting and the Bellman equation with a mini and a mega health pack. github.com/CarlKho-Minerva/overwatch-rl-lab"
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

#!define GAME_ID 2
#!define GAME_VERSION 1
#!define GAME_TITLE "RL 2: MINI OR MEGA"
#!define LEARNER_HERO Hero.TRACER
#!define HOME_POS vect(-8, 0, -4)
#!define HOME_FACING vect(1, 0, 0)

#!include "common.opy"

# The row: pad i stands at x = PAD_X0 + PAD_SP * (i - START_I). Pad 0 holds the mini, pad 13 the mega.
macro PAD_X0 = -8
macro PAD_SP = 2.2
macro PAD_Z = -4
macro START_I = 3
macro MEGA_I = 13
macro NPADS = 14
macro BOT_DZ = 1.8
macro MINI_R = 15
macro MEGA_R = 50
macro MINI_D = 3
macro MEGA_D = 10
macro STEP_COST = -1
macro G2 = 0.9
macro PADPOS(i):
    vect(PAD_X0 + PAD_SP * ((i) - START_I), FLOOR_Y, PAD_Z)

globalvar dialVals = [0.5, 0.8, 0.9, 1]
globalvar autoOrder = [2, 0, 3, 1]
globalvar tried = [false, false, false, false]
globalvar dialIdx = 0
globalvar dialJ
globalvar dialOpen = false
globalvar dialLocked = false
globalvar dialName = "PATIENCE DIAL"
globalvar dialLine = ""
globalvar ctrlLine = ""
globalvar checkLine = ""
globalvar debrief1 = ""
globalvar debrief2 = ""
globalvar debrief3 = ""
globalvar rnd
globalvar g
globalvar vMini
globalvar vMega
globalvar best
globalvar bot = null
globalvar walkDir
globalvar tgtPos
globalvar miniLbl = ""
globalvar megaLbl = ""
globalvar padOn = []
globalvar padV = []
globalvar vToMega = []
globalvar vToMini = []
globalvar loopI
globalvar txtI
globalvar padNow
globalvar padLast
globalvar walkN
globalvar walkOk
globalvar walkT0
globalvar ruleV

subroutine drawTexts
subroutine buildDial
subroutine botWalk

def buildDial():
    @Name "Game 2: rebuild the dial line"
    dialLine = "{}: {}".format(dialName, dialVals[dialIdx])

def drawTexts():
    @Name "Game 2: redraw the pack labels and the numbers on the pads"
    destroyAllInWorldText()
    createInWorldText(getAllPlayers(), miniLbl, PADPOS(0) + vect(0, 1.7, 0), 1.6, Clip.NONE, WorldTextReeval.NONE, Color.YELLOW)
    createInWorldText(getAllPlayers(), megaLbl, PADPOS(MEGA_I) + vect(0, 2.4, 0), 2, Clip.NONE, WorldTextReeval.NONE, Color.YELLOW)
    for txtI in range(NPADS):
        if padOn[txtI] > 0:
            createInWorldText(getAllPlayers(), "?" if padOn[txtI] == 2 else "{}".format(padV[txtI]), PADPOS(txtI) + vect(0, 0.6, 0), 1.5, Clip.NONE, WorldTextReeval.NONE, Color.ORANGE if padOn[txtI] == 2 else Color.WHITE)
        if txtI % 7 == 6:
            wait()

def botWalk():
    @Name "Game 2: the bot Tracer walks to the pack worth more under this discount"
    if not entityExists(bot):
        LOG("RLG,E,{},walked,{},{},{},{}".format(GAME_ID, rnd, g, best, -1))
        return
    walkDir = vect(1, 0, 0) if best == 1 else vect(-1, 0, 0)
    tgtPos = (PADPOS(MEGA_I) if best == 1 else PADPOS(0)) + vect(0, 0, BOT_DZ)
    bot.teleport(PADPOS(START_I) + vect(0, 0, BOT_DZ))
    wait(0.3)
    bot.setFacing(walkDir, Relativity.TO_WORLD)
    bot.startThrottleInDirection(walkDir, 1, Relativity.TO_WORLD, Throttle.REPLACE_EXISTING, ThrottleReeval.NONE)
    waitUntil(dotProduct(tgtPos - bot.getPosition(), walkDir) <= 0.3, 10)
    bot.stopThrottleInDirection()
    wait(0.4)
    LOG("RLG,E,{},walked,{},{},{},{}".format(GAME_ID, rnd, g, best, distance(bot.getPosition(), tgtPos) < 1.5))

rule "Game 2: F turns the dial to the next setting not tried yet":
    @Event eachPlayer
    @Condition eventPlayer == learner
    @Condition dialOpen
    @Condition eventPlayer.isHoldingButton(Button.INTERACT)
    for dialJ in range(4):
        dialIdx = (dialIdx + 1) % 4
        if not tried[dialIdx]:
            break
    buildDial()

rule "Game 2: R locks the dial":
    @Event eachPlayer
    @Condition eventPlayer == learner
    @Condition dialOpen
    @Condition eventPlayer.isHoldingButton(Button.RELOAD)
    dialLocked = true

rule "Game 2: the screen":
    @Condition ready
    hudText(getAllPlayers(), null, null, ctrlLine, HudPosition.LEFT, 3, Color.WHITE, Color.WHITE, Color.LIME_GREEN, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, null, debrief1, HudPosition.LEFT, 4, Color.WHITE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, null, debrief2, HudPosition.LEFT, 5, Color.WHITE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, null, debrief3, HudPosition.LEFT, 6, Color.WHITE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), dialLine, null, null, HudPosition.RIGHT, 0, Color.YELLOW, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, checkLine, null, HudPosition.RIGHT, 1, Color.WHITE, Color.SKY_BLUE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)

rule "Game 2: run":
    @Condition ready
    learner.disallowButton(Button.INTERACT)
    learner.disallowButton(Button.RELOAD)
    learner.setFacing(vect(1, 0, 0), Relativity.TO_WORLD)

    # The values of the row at discount 0.9 with a step cost of 1, by the one-step rule, both ways of walking.
    vToMega[MEGA_I] = MEGA_R
    for loopI in range(MEGA_I - 1, 0, -1):
        vToMega[loopI] = STEP_COST + G2 * vToMega[loopI + 1]
    vToMini[0] = MINI_R
    for loopI in range(1, MEGA_I):
        vToMini[loopI] = STEP_COST + G2 * vToMini[loopI - 1]
    for loopI in range(NPADS):
        padOn[loopI] = 0
        padV[loopI] = 0

    # Self-tests: every formula the game uses.
    CHECK("mini at 0.5", 1.875, MINI_R * (0.5 ** MINI_D))
    CHECK("mega at 0.8", 5.369, MEGA_R * (0.8 ** MEGA_D))
    CHECK("mini at 0.9", 10.935, MINI_R * (0.9 ** MINI_D))
    CHECK("mega at 0.9", 17.434, MEGA_R * (0.9 ** MEGA_D))
    CHECK("switch point", 0.842, 0.3 ** (1 / 7))
    CHECK("pad three behind the mega", 33.74, vToMega[MEGA_I - 3])
    CHECK("start pad, walk to the mega", 10.921, vToMega[START_I])
    CHECK("start pad, walk to the mini", 8.225, vToMini[START_I])
    CHECK("loop equals closed form", 60 * (0.9 ** 10) - 10, vToMega[START_I])

    # The row, the start, the two packs.
    for loopI in range(NPADS):
        createEffect(getAllPlayers(), Effect.RING, Color.SKY_BLUE if loopI == START_I else Color.WHITE, PADPOS(loopI), 0.9, EffectReeval.NONE)
    createEffect(getAllPlayers(), Effect.SPHERE, Color.YELLOW, PADPOS(0) + vect(0, 0.7, 0), 0.35, EffectReeval.NONE)
    createEffect(getAllPlayers(), Effect.SPHERE, Color.YELLOW, PADPOS(MEGA_I) + vect(0, 0.9, 0), 0.75, EffectReeval.NONE)
    createEffect(getAllPlayers(), Effect.LIGHT_SHAFT, Color.YELLOW, PADPOS(MEGA_I), 1, EffectReeval.NONE)
    miniLbl = "MINI 15, 3 pads behind you"
    megaLbl = "MEGA 50, 10 pads ahead"
    drawTexts()

    # The bot Tracer that walks beside the row.
    createDummy(LEARNER_HERO, learner.getTeam(), -1, PADPOS(START_I) + vect(0, 0, BOT_DZ), vect(1, 0, 0))
    wait(1)
    bot = [p for p in getPlayers(learner.getTeam()) if p.isDummy() and p != learner]
    bot = bot[0] if len(bot) > 0 else null
    LOG("RLG,E,{},bot,{}".format(GAME_ID, 1 if entityExists(bot) else 0))

    coach = "A mini pack 3 pads behind you, a mega 10 pads ahead. Take the small thing now, or walk for the big one?"
    wait(1 if AUTOPLAY else 7)

    # ---------------- Part 1: the dial ----------------
    for rnd in range(4):
        if learner.fell:
            putHome()
        dialOpen = true
        dialLocked = false
        for dialJ in range(4):
            if not tried[dialIdx]:
                break
            dialIdx = (dialIdx + 1) % 4
        buildDial()
        ctrlLine = "F: turn the dial to a setting not tried yet    R: lock it in    then answer with a click"
        coach = "The dial says how much a pack shrinks for every pad she must walk. Set it, then lock it." if rnd == 0 else "Next setting: {} of 4. F to turn, R to lock.".format(rnd + 1)
        if AUTOPLAY:
            wait(0.5)
            dialIdx = autoOrder[rnd]
            buildDial()
            wait(0.5)
            dialLocked = true
        else:
            waitUntil(dialLocked == true, 90)
        dialOpen = false
        g = dialVals[dialIdx]
        tried[dialIdx] = true
        buildDial()
        vMini = MINI_R * (g ** MINI_D)
        vMega = MEGA_R * (g ** MEGA_D)
        best = 1 if vMega > vMini else 0
        LOG("RLG,E,{},dial,{},{},{},{},{}".format(GAME_ID, rnd, g, vMini, vMega, best))
        qId = 1 + rnd
        qText = "Dial at {}: every pad walked multiplies a pack's worth by {}. Which pack does she walk to?".format(g, g)
        qOpts = ["the MINI (15, 3 pads)", "the MEGA (50, 10 pads)"]
        qCorrect = best
        qAuto = best
        qWhy = "Mini 15 x {}^3 = {}. Mega 50 x {}^10 = {}. She takes the larger.".format(g, vMini, g, vMega)
        ask()
        miniLbl = "MINI worth {} to her".format(vMini)
        megaLbl = "MEGA worth {} to her".format(vMega)
        drawTexts()
        coach = "Discount {}: she walks to the {}.".format(g, "MEGA" if best == 1 else "MINI")
        botWalk()
        if rnd == 0:
            dialName = "DISCOUNT (gamma)"
            buildDial()
            coach = "That dial is the discount factor, gamma: what one step later is worth compared with now."
        elif rnd == 1:
            coach = "What she collects, shrunk by gamma once per step of delay and added up, is her return."
        elif rnd == 2:
            coach = "Same packs, same pads. Only gamma changed, and the best way to act can change with it."
        else:
            coach = "The switch sits near gamma 0.84, where 15 x g^3 equals 50 x g^10."
            wait(1 if AUTOPLAY else 6)
            coach = "Why discount: later is less certain, endless sums stay finite, and sooner is usually worth more."
        wait(1 if AUTOPLAY else 6)
        miniLbl = "MINI 15, 3 pads behind you"
        megaLbl = "MEGA 50, 10 pads ahead"
        drawTexts()

    # Interleaving: lecture 1's state and the Markov property.
    ctrlLine = "Answer with a click or melee"
    qId = 5
    qText = "Lecture 1 idea: is the pad she stands on enough to predict what happens next?"
    qOpts = ["yes, here and in a match", "here yes, in a match no", "no, not even here"]
    qCorrect = 1
    qAuto = 1
    qWhy = "Here only her pad changes. In a match a taken pack returns on a timer: add the timer to the state."
    ask()
    wait(0.5 if AUTOPLAY else 2)

    # ---------------- Part 2: the one-step rule ----------------
    if learner.fell:
        putHome()
    dialLine = "DISCOUNT 0.9, EACH STEP COSTS 1"
    miniLbl = "MINI 15"
    megaLbl = "MEGA 50"
    coach = "New rule: each step costs 1, time out of the fight. Pads show their worth if she always walks to the mega."
    padOn[MEGA_I] = 1
    padV[MEGA_I] = vToMega[MEGA_I]
    drawTexts()
    wait(1 if AUTOPLAY else 5)
    coach = "Each pad: minus 1 for the step, plus 0.9 times the pad ahead of it."
    for loopI in range(MEGA_I - 1, MEGA_I - 3, -1):
        padOn[loopI] = 1
        padV[loopI] = vToMega[loopI]
        drawTexts()
        wait(0.3 if AUTOPLAY else 2.5)
    padOn[MEGA_I - 3] = 2
    drawTexts()
    qId = 6
    qText = "The pad ahead of the ? shows {}. This pad = -1 + 0.9 x the pad ahead. What goes on the ?".format(vToMega[MEGA_I - 2])
    qOpts = ["37.60", "33.74", "34.74"]
    qCorrect = 1
    qAuto = 1
    qWhy = "-1 + 0.9 x 38.6 = 33.74. 37.60 forgets the discount; 34.74 forgets the step cost."
    ask()
    for loopI in range(MEGA_I - 3, 0, -1):
        padOn[loopI] = 1
        padV[loopI] = vToMega[loopI]
        drawTexts()
        wait(0.1 if AUTOPLAY else 0.6)
    for loopI in range(1, NPADS):
        LOG("RLG,E,{},pad,0,{},{}".format(GAME_ID, loopI, vToMega[loopI]))

    # He walks the row; the screen checks the rule on the pad he stands on.
    putHome()
    learner.setFacing(vect(1, 0, 0), Relativity.TO_WORLD)
    ctrlLine = "WASD: walk along the row to the mega. Watch the line on the right."
    coach = "Walk the row to the mega. On every pad, check: this pad = -1 + 0.9 x the pad ahead."
    walkN = 0
    walkOk = 0
    padLast = -1
    walkT0 = NOW
    if AUTOPLAY:
        wait(0.5)
        learner.startThrottleInDirection(vect(1, 0, 0), 1, Relativity.TO_WORLD, Throttle.REPLACE_EXISTING, ThrottleReeval.NONE)
    while padLast != MEGA_I and NOW - walkT0 < (25 if AUTOPLAY else 120):
        if learner.fell:
            putHome()
            padLast = -1
        padNow = round((learner.getPosition().x - PAD_X0) / PAD_SP) + START_I
        if abs(learner.getPosition().z - PAD_Z) < 1.3 and padNow >= 1 and padNow <= MEGA_I and padNow != padLast:
            padLast = padNow
            walkN += 1
            if padNow == MEGA_I:
                checkLine = "MEGA PAD: worth 50. She picks it up."
                LOG("RLG,E,{},walk,{},{},{}".format(GAME_ID, padNow, vToMega[padNow], 0))
            else:
                ruleV = STEP_COST + G2 * vToMega[padNow + 1]
                if abs(ruleV - vToMega[padNow]) < 0.011:
                    walkOk += 1
                checkLine = "THIS PAD {}  =  -1 + 0.9 x {} (the pad ahead)  =  {}".format(vToMega[padNow], vToMega[padNow + 1], ruleV)
                LOG("RLG,E,{},walk,{},{},{}".format(GAME_ID, padNow, vToMega[padNow], vToMega[padNow + 1]))
        wait(0.1)
    learner.stopThrottleInDirection()
    LOG("RLG,E,{},walkdone,{},{},{}".format(GAME_ID, walkN, walkOk, 1 if padLast == MEGA_I else 0))
    coach = "That one-step rule is the Bellman equation: value here = reward now + discount x value next."
    wait(1 if AUTOPLAY else 7)
    checkLine = ""

    # A value belongs to a pad and a way of walking.
    putHome()
    ctrlLine = "Answer with a click"
    qId = 7
    qText = "Same pad, same 0.9, but now she always walks to the MINI. Start pad: more or less than {}?".format(vToMega[START_I])
    qOpts = ["more", "less"]
    qCorrect = 1
    qAuto = 1
    qWhy = "Less: {}. The same pad has another value under another way of walking.".format(vToMini[START_I])
    ask()
    padOn[MEGA_I] = 0
    for loopI in range(1, MEGA_I):
        padOn[loopI] = 1
        padV[loopI] = vToMini[loopI]
    drawTexts()
    for loopI in range(0, MEGA_I):
        LOG("RLG,E,{},pad,1,{},{}".format(GAME_ID, loopI, vToMini[loopI]))
    coach = "One pad behind the start, the mini is the better walk: {} against {}.".format(vToMini[START_I - 1], vToMega[START_I - 1])
    wait(1 if AUTOPLAY else 7)

    # Debrief.
    ctrlLine = ""
    debrief1 = "You did: turned the discount, called her pick, and walked a row of values checked one step at a time."
    debrief2 = "Called: the discount gamma, the return (a discounted sum), value under a policy, the Bellman equation."
    debrief3 = "In an agent: low gamma takes the quick answer now; high gamma pays for more tool calls to get a better one."
    coach = "Your predictions: {} of {} right.".format(predRight, predTotal)
    LOG("RLG,E,{},end,{},{}".format(GAME_ID, predRight, predTotal))
    wait(1 if AUTOPLAY else 12)
    coach = "Simplified: one straight row and no dice. The lecture averages over chance; here every step is certain."
    finish()
