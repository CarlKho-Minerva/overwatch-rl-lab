/*
Game 1: No Coach. Lecture 1, Introduction to Reinforcement Learning.

The player stands in the middle of five identical white rings, all 13 m away. Nobody says what to do. The screen
shows only the last reward and the running total. Hidden rules: every second of a round costs 1; one ring pays +50
and ends the round; one ring sends a -20 bill that arrives only when the round ends (late feedback); the other three
pay 0. Round 1 he finds out. Round 2 has the same hidden layout, so his total should go up; both totals are shown
side by side. Round 3 the rings vanish before the clock starts, so he acts on what he remembers (his state). Round 4
looks the same but the hidden payouts were redrawn: same view, different hidden state.

Design note: workshop/games/g01.md. Test: analysis/tests/test_game_01.py.
*/
settings {
    "main": {
        "modeName": "RL course 1: No Coach",
        "description": "Five rings, no callouts, only the score. Lecture 1 of an RL course. github.com/CarlKho-Minerva/overwatch-rl-lab"
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

#!define GAME_ID 1
#!define GAME_VERSION 1
#!define GAME_TITLE "RL 1: NO COACH"
#!define LEARNER_HERO Hero.TRACER
#!define HOME_POS vect(0, 0, -3)
#!define HOME_FACING vect(0, 0, 1)

#!include "common.opy"

macro NRINGS = 5
macro RING_DIST = 13
macro RING_R = 1.6
macro PAY_GOAL = 50
macro BILL = 20
macro ROUND_TOTAL(f, s, t):
    (PAY_GOAL * (f) - (s) - BILL * (t))
macro BEAT(s):
    wait(0.4 if AUTOPLAY else s)

globalvar ringPos = []
globalvar goalRing = -1
globalvar trapRing = -1
globalvar oldGoal = -1
globalvar rnd = 0
globalvar roundOn = false
globalvar touched = []
globalvar found = 0
globalvar trapHit = 0
globalvar secs = 0
globalvar total = 0
globalvar last = 0
globalvar lastSrc = "nothing yet"
globalvar totals = ["?", "?", "?", "?"]
globalvar r1Total = 0
globalvar r2Total = 0
globalvar r1Found = 0
globalvar ri
globalvar ki
globalvar autoTgt
globalvar autoRoute = []
globalvar hudScore = "last reward: 0      total: 0"
globalvar hudRounds = ""
globalvar hudGap = ""
globalvar debrief = false
globalvar db = ["", "", "", ""]

subroutine drawRings
subroutine playRound
subroutine settleRound
subroutine autoGo
subroutine refreshScore

def refreshScore():
    @Name "Game 1: rebuild the score line (only when it changes)"
    hudScore = "last reward: {}{} ({})      total: {}".format("+" if last > 0 else "", last, lastSrc, total)

def drawRings():
    @Name "Game 1: five identical rings"
    for ki in range(NRINGS):
        createEffect(getAllPlayers(), Effect.RING, Color.WHITE, ringPos[ki], RING_R, EffectReeval.NONE)

def autoGo():
    @Name "Game 1: the stand-in walks to a ring (automatic check only)"
    learner.startThrottleInDirection(directionTowards(learner.getPosition(), autoTgt), 1, Relativity.TO_WORLD, Throttle.REPLACE_EXISTING, ThrottleReeval.DIRECTION_AND_MAGNITUDE)
    waitUntil(distance(learner.getPosition(), autoTgt) < 0.8 or not roundOn, 8)
    learner.stopThrottleInDirection()
    if roundOn and distance(learner.getPosition(), autoTgt) > RING_R - 0.4:
        learner.teleport(autoTgt)
    wait(0.5)

def playRound():
    @Name "Game 1: one round, from the start until the +50 ring or the time limit"
    putHome()
    learner.setFacing(vect(0, 0, 1), Relativity.TO_WORLD)
    touched = [false, false, false, false, false]
    found = 0
    trapHit = 0
    secs = 0
    total = 0
    last = 0
    lastSrc = "round {} starts".format(rnd)
    refreshScore()
    coach = "Round {}. Go.".format(rnd)
    roundOn = true
    if AUTOPLAY:
        for ki in range(len(autoRoute)):
            if roundOn:
                autoTgt = ringPos[autoRoute[ki]]
                autoGo()
        waitUntil(not roundOn, 20)
    else:
        waitUntil(not roundOn, 120 if rnd == 1 else 60)
    if roundOn:
        roundOn = false
        coach = "Time is up for round {}.".format(rnd)
    if AUTOPLAY:
        learner.stopThrottleInDirection()
    wait(0.3)

def settleRound():
    @Name "Game 1: the late bill, the round's total, its self-test and its log line"
    if trapHit:
        total -= BILL
        last = 0 - BILL
        lastSrc = "a late bill"
        refreshScore()
        smallMessage(learner, "-20, a late bill for a ring you touched")
    CHECK("round {} total adds up".format(rnd), ROUND_TOTAL(found, secs, trapHit), total)
    LOG("RLG,E,{},round,{},{},{},{},{}".format(GAME_ID, rnd, found, secs, trapHit, total))
    totals[rnd - 1] = total
    hudRounds = "round totals   1: {}   2: {}   3: {}   4: {}".format(totals[0], totals[1], totals[2], totals[3])

rule "Game 1: every second of a round costs 1":
    @Condition roundOn
    while roundOn:
        wait(1)
        if roundOn:
            secs += 1
            total -= 1
            last = -1
            lastSrc = "a second passed"
            refreshScore()

rule "Game 1: touching a ring":
    @Condition roundOn
    while roundOn:
        for ri in range(NRINGS):
            if roundOn and not touched[ri] and distance(learner.getPosition(), ringPos[ri]) < RING_R:
                touched[ri] = true
                lastSrc = "a ring"
                if ri == goalRing:
                    total += PAY_GOAL
                    last = PAY_GOAL
                    found = 1
                    roundOn = false
                    smallMessage(learner, "+50")
                else:
                    if ri == trapRing:
                        trapHit = 1
                    last = 0
                    smallMessage(learner, "0")
                refreshScore()
                LOG("RLG,E,{},touch,{},{},{},{}".format(GAME_ID, rnd, ri, last, secs))
        wait(0.1)

rule "Game 1: a fall sends you back to the middle":
    @Condition ready
    @Condition learner.fell
    putHome()

rule "Game 1: the screen":
    hudText(getAllPlayers(), hudScore, null, null, HudPosition.LEFT, 3, Color.YELLOW, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers() if not debrief else null, null, "WASD walk. Answer questions with left click, right click or melee.", null, HudPosition.LEFT, 4, Color.WHITE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers() if hudRounds != "" else null, null, null, hudRounds, HudPosition.RIGHT, 0, Color.WHITE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers() if hudGap != "" else null, null, null, hudGap, HudPosition.RIGHT, 1, Color.WHITE, Color.WHITE, Color.GREEN, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers() if debrief else null, null, null, db[0], HudPosition.LEFT, 5, Color.WHITE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers() if debrief else null, null, null, db[1], HudPosition.LEFT, 6, Color.WHITE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers() if debrief else null, null, null, db[2], HudPosition.LEFT, 7, Color.WHITE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers() if debrief else null, null, null, db[3], HudPosition.LEFT, 8, Color.WHITE, Color.WHITE, Color.SKY_BLUE, HudReeval.VISIBILITY_AND_STRING)

rule "Game 1: run":
    @Condition ready
    # The five rings sit on a circle of 13 m around the start, so no ring is closer than another.
    for ki in range(NRINGS):
        ringPos.append(HOME_POS + vect(RING_DIST * cosDeg(90 + 72 * ki), 0, RING_DIST * sinDeg(90 + 72 * ki)))
    CHECK("ring 0 is 13 m from the start", 13, distance(ringPos[0], HOME_POS))
    CHECK("ring 3 is 13 m from the start", 13, distance(ringPos[3], HOME_POS))
    CHECK("quick round: +50 in 3 s, no bill", 47, ROUND_TOTAL(1, 3, 0))
    CHECK("slow round: +50 in 12 s, with the bill", 18, ROUND_TOTAL(1, 12, 1))
    CHECK("no +50 in 120 s, no bill", -120, ROUND_TOTAL(0, 120, 0))
    CHECK("gap between those two rounds", 29, ROUND_TOTAL(1, 3, 0) - ROUND_TOTAL(1, 12, 1))
    drawRings()

    # The hidden layout: drawn first, logged, then used.
    goalRing = random.randint(0, NRINGS - 1)
    trapRing = random.choice([0, 1, 2, 3, 4].filter(lambda x: x != goalRing))
    LOG("RLG,E,{},layout,1,{},{}".format(GAME_ID, goalRing, trapRing))

    coach = "Like your first minutes on a new map: no callouts, no coach, only the scoreboard."
    BEAT(6)
    coach = "Five rings, all alike. The yellow number is all you get."
    BEAT(4)

    qId = 1
    qText = "The round starts after you answer. If you stand still, what will the number do?"
    qOpts = ["stay at 0", "go down", "go up"]
    qCorrect = 1
    qAuto = 1
    qWhy = "It drops 1 every second. The score says hurry, but never where to go."
    ask()

    # Round 1: find out what the score rewards.
    rnd = 1
    autoRoute = [trapRing, [0, 1, 2, 3, 4].filter(lambda x: x != goalRing and x != trapRing)[0], goalRing]
    playRound()
    r1Found = found
    coach = "Round 1 is over."
    BEAT(2)
    qId = 2
    qText = "The round is over. Will your total change before round 2 starts?"
    qOpts = ["no, it is final", "yes, it can still change"]
    qCorrect = 1 if trapHit else 0
    qAuto = 0
    if trapHit:
        qWhy = "One ring you touched sends a -20 bill, late. Which one? The score does not say."
    else:
        qWhy = "No bill this time. One ring you have not touched sends a -20 bill when the round ends."
    ask()
    settleRound()
    r1Total = total
    BEAT(3)
    coach = "You acted, then read the number, then acted again: action, observation, reward, in a loop."
    BEAT(6)
    coach = "No one showed you the right move. Learning from that number alone is reinforcement learning."
    BEAT(6)

    qId = 3
    if r1Found:
        qText = "Round 2 has the same hidden layout. Go straight to the ring that paid: your total will be..."
    else:
        qText = "Round 2, same hidden layout. Go straight to a ring you have not tried. If it pays, your total is..."
    qOpts = ["exactly +50", "a little under +50", "about round 1's"]
    qCorrect = 1
    qAuto = 1
    qWhy = "+50 minus the seconds it takes. Same map, fewer tries: you should beat round 1."
    ask()

    # Round 2: same layout, use what you know.
    rnd = 2
    autoRoute = [goalRing]
    playRound()
    settleRound()
    r2Total = total
    hudGap = "round 2 minus round 1: {}, what the score taught".format(r2Total - r1Total)
    LOG("RLG,E,{},gap,{},{},{}".format(GAME_ID, r1Total, r2Total, r2Total - r1Total))
    if r2Total > r1Total:
        coach = "Round 2 beat round 1 by {}. Same map, more score: that is learning from reward.".format(r2Total - r1Total)
    else:
        coach = "Round 2 did not beat round 1 this time. The score only teaches if you use what it showed."
    BEAT(7)

    qId = 4
    qText = "Round 3: if you go straight to the ring that paid, what will you learn about the other rings?"
    qOpts = ["nothing new", "which one is best"]
    qCorrect = 0
    qAuto = 0
    qWhy = "Using what you know earns now but tests nothing. Trying things costs seconds but finds more."
    ask()

    # Round 3: the rings vanish before the clock starts, so he acts on what he remembers.
    rnd = 3
    putHome()
    learner.setFacing(vect(0, 0, 1), Relativity.TO_WORLD)
    learner.setStatusEffect(null, Status.ROOTED, 9999)
    learner.disallowButton(Button.ABILITY_1)
    coach = "Round 3. Look around now: the rings vanish in 2 seconds."
    wait(2)
    destroyAllEffects()
    LOG("RLG,E,{},vanish,{}".format(GAME_ID, rnd))
    qId = 5
    qText = "The rings are gone. What are you steering by now?"
    qOpts = ["what the screen shows", "what I remember", "the score"]
    qCorrect = 1
    qAuto = 1
    qWhy = "Memory. History is every second, ring and bill so far. What you kept of it is your state."
    ask()
    learner.clearStatusEffect(Status.ROOTED)
    learner.allowButton(Button.ABILITY_1)
    autoRoute = [goalRing]
    playRound()
    settleRound()
    coach = "Round 3: {}, with nothing on screen to steer by. Your state came from your history.".format(total)
    BEAT(7)

    # Round 4: the island looks the same, but the hidden payouts are redrawn and the +50 ring moves.
    drawRings()
    oldGoal = goalRing
    goalRing = random.choice([0, 1, 2, 3, 4].filter(lambda x: x != oldGoal))
    trapRing = random.choice([0, 1, 2, 3, 4].filter(lambda x: x != goalRing))
    LOG("RLG,E,{},layout,4,{},{}".format(GAME_ID, goalRing, trapRing))
    coach = "Round 4. The rings are back."
    BEAT(3)
    qId = 6
    qText = "Round 4 looks the same, but something hidden may have changed. Will your old ring pay +50?"
    qOpts = ["yes, the island looks the same", "I cannot tell from what I see"]
    qCorrect = 1
    qAuto = 1
    qWhy = "The payouts were redrawn. Same view, different hidden state: what you see is not everything."
    ask()
    rnd = 4
    autoRoute = [oldGoal, goalRing]
    playRound()
    settleRound()
    coach = "Round 4: {}. It looked like round 2, but it was not: that is partial observability.".format(total)
    BEAT(7)

    # Debrief.
    db[0] = "What you did: found the paying ring from a number alone, then ran to it blind."
    db[1] = "What it is called: learning from reward, with late feedback. Your memory was your state."
    db[2] = "In a language-model agent: a task scored only at the end; the transcript is its history."
    db[3] = "Your predictions: {} of {} right.".format(predRight, predTotal)
    debrief = true
    coach = "Simplified: you always knew where you stood, and the rules held still. Real agents see less."
    BEAT(10)
    finish()
    coach = "Done. Game 1 finished."
