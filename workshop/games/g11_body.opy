/*
Game 11: Sombra's Room. Lesson 11, "The wall she cannot see": partial observability.

An invisible Sombra hides in one of two rooms (a pad on the left, a pad on the right). The player walks through the
room she is NOT in (+10) or walks into hers (-30, and she hacks him). He cannot see her. He can ping (Interact, F):
a sonic arrow that names her room and is right 8 times in 10, and costs 1. A bar shows the belief that she is in the
left room, moved by Bayes' rule after every ping. The script also solves the whole problem (value iteration over the
beliefs a ping can reach) and, after each of his choices, says whether one more ping was worth its cost.

Five rounds: 1 and 2 are guided (the bar stays hidden until he predicts it), 3 and 4 are free, and in round 5 the
ping is always right. Six predictions.
*/
settings {
    "main": {
        "modeName": "RL course 11: Sombra's Room",
        "description": "Partial observability: a ping that is right 8 times in 10, and a belief that moves. github.com/CarlKho-Minerva/overwatch-rl-lab"
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

#!define GAME_ID 11
#!define GAME_VERSION 1
#!define GAME_TITLE "RL 11: SOMBRA'S ROOM"
#!define LEARNER_HERO Hero.TRACER
#!define HOME_POS vect(0, 0, -10)

#!include "common.opy"

macro W_EMPTY = 10        # walking through the empty room
macro L_HERS = 30         # walking into Sombra's room costs this
macro PING_COST = 1
macro ACC = 0.8           # the ping names the right room this often (rounds 1 to 4)
macro KL = 10             # the belief ladder: n = (pings that said LEFT) - (pings that said RIGHT), from -KL to KL
macro SWEEPS = 40
macro MAXPINGS = 8
macro NROUNDS = 5
macro PAD_R = 2

# The belief that she is in the LEFT room after a reading r (0 = LEFT, 1 = RIGHT) from a ping right a of the time.
macro POST(p, r, a):
    (((p) * (a) / ((p) * (a) + (1 - (p)) * (1 - (a)))) if (r) == 0 else ((p) * (1 - (a)) / ((p) * (1 - (a)) + (1 - (p)) * (a))))
# What walking into a room is worth on average (room 0 = LEFT, 1 = RIGHT), when p is the belief she is LEFT.
macro ROOM_EV(room, p):
    ((W_EMPTY * (1 - (p)) - L_HERS * (p)) if (room) == 0 else (W_EMPTY * (p) - L_HERS * (1 - (p))))
macro ENTER_EV(p):
    max(ROOM_EV(0, p), ROOM_EV(1, p))
# With a ping right 8 times in 10, n more LEFTs than RIGHTs puts the belief at 4^n / (1 + 4^n).
macro LAT_P(n):
    (1 / (1 + 4 ** (0 - (n))))

# Seen in the game on 2026-11-22: a player facing +z has +x on his LEFT. The two pads were the wrong way round.
globalvar padL = vect(9, 0, 6)
globalvar padR = vect(-9, 0, 6)
globalvar Vt = []
globalvar gi
globalvar gsweep
globalvar gp
globalvar pl
globalvar nStar = -1
globalvar pStar
globalvar planText = ""
globalvar acc = 0.8
globalvar belief = 0.5
globalvar nLat = 0
globalvar hidden = 0
globalvar roundN = 0
globalvar score = 0
globalvar pingCount = 0
globalvar nSaidL = 0
globalvar nSaidR = 0
globalvar lastSaid = ""
globalvar pingReq = false
globalvar fArmed = true
globalvar deciding = false
globalvar roomsOpen = false
globalvar barShown = false
globalvar barText = ""
globalvar hudRound = ""
globalvar hudPings = ""
globalvar hudKeys = ""
globalvar enterNow = 0
globalvar pingQ = 0
globalvar pBefore = 0
globalvar reading = 0
globalvar firstReading = 0
globalvar roundDone = false
globalvar room = 0
globalvar roomEv = 0
globalvar reward = 0
globalvar autoStyle = 0
globalvar autoRoom = 0
globalvar onPad = false
globalvar fx = null
globalvar sombraFx = null
globalvar sombraTx = null
globalvar gain50 = 0
globalvar gain94 = 0
globalvar perfectV = 0
globalvar nGood = 0
globalvar debrief = ["", "", ""]

subroutine solvePlan
subroutine judge
subroutine doPing
subroutine playRound

def solvePlan():
    @Name "Game 11: the best plan, by value iteration over the beliefs a ping can reach"
    # Every rung starts at "enter now". Then, sweep after sweep, each rung takes the better of entering now and
    # paying for one more ping and continuing with the best plan from wherever the reading lands.
    for gi in range(2 * KL + 1):
        Vt[gi] = ENTER_EV(LAT_P(gi - KL))
    for gsweep in range(SWEEPS):
        for gi in range(1, 2 * KL):
            gp = LAT_P(gi - KL)
            pl = gp * ACC + (1 - gp) * (1 - ACC)
            Vt[gi] = max(ENTER_EV(gp), 0 - PING_COST + pl * Vt[gi + 1] + (1 - pl) * Vt[gi - 1])
        wait()
    # The plan's threshold: the first rung (counting up from 50/50) where entering is at least as good as pinging.
    nStar = -1
    for gi in range(KL, 2 * KL + 1):
        if nStar < 0 and ENTER_EV(LAT_P(gi - KL)) >= Vt[gi] - 0.0001:
            nStar = gi - KL
    pStar = LAT_P(nStar)

def judge():
    @Name "Game 11: at the current belief, what entering now and pinging once more are worth"
    enterNow = ENTER_EV(belief)
    if acc > 0.99:
        # A perfect ping: after it the belief is 1 or 0, and you enter the empty room.
        pingQ = 0 - PING_COST + belief * ENTER_EV(1) + (1 - belief) * ENTER_EV(0)
    else:
        pl = belief * acc + (1 - belief) * (1 - acc)
        pingQ = 0 - PING_COST + pl * Vt[nLat + KL + 1] + (1 - pl) * Vt[nLat + KL - 1]

def doPing():
    @Name "Game 11: one ping: draw the reading, log it, move the belief by Bayes' rule"
    judge()
    if (roundN == 1 and pingCount < 2) or (roundN == 2 and pingCount < 1):
        barShown = false
    pBefore = belief
    reading = hidden if random.uniform(0, 1) < acc else 1 - hidden
    belief = POST(belief, reading, acc)
    nLat += 1 if reading == 0 else -1
    pingCount += 1
    score -= PING_COST
    if reading == 0:
        nSaidL += 1
    else:
        nSaidR += 1
    lastSaid = "LEFT" if reading == 0 else "RIGHT"
    if pingCount == 1:
        firstReading = reading
    # ping: round, ping number, reading (0 LEFT, 1 RIGHT), belief before, belief after, entering-now value, ping value
    LOG("RLG,E,{},ping,{},{},{},{},{},{},{}".format(GAME_ID, roundN, pingCount, reading, pBefore, belief, enterNow, pingQ))
    barText = "chance Sombra is in the LEFT room: {}%".format(round(belief * 100))
    hudPings = "pings this round: {} said LEFT, {} said RIGHT. Latest: {}".format(nSaidL, nSaidR, lastSaid)
    hudRound = "round {} of {}   score {}   the ping is right {}% of the time".format(roundN, NROUNDS, score, round(acc * 100))
    smallMessage(getAllPlayers(), "PING: {}".format(lastSaid))
    createEffect(getAllPlayers(), Effect.SPHERE, Color.YELLOW, (padL if reading == 0 else padR) + vect(0, 1, 0), 1.4, EffectReeval.NONE)
    fx = getLastCreatedEntity()
    wait(0.4 if AUTOPLAY else 1)
    destroyEffect(fx)

def playRound():
    @Name "Game 11: one round: hide Sombra, let him ping or enter, reveal, judge his choice"
    roundN += 1
    acc = 1 if roundN == NROUNDS else ACC
    hidden = random.randint(0, 1)
    # hide: round, her room (0 LEFT, 1 RIGHT), the ping's accuracy this round
    LOG("RLG,E,{},hide,{},{},{}".format(GAME_ID, roundN, hidden, acc))
    belief = 0.5
    nLat = 0
    pingCount = 0
    nSaidL = 0
    nSaidR = 0
    lastSaid = "none yet"
    roundDone = false
    roomsOpen = roundN >= 3
    barShown = roundN >= 3
    barText = "chance Sombra is in the LEFT room: 50%"
    hudPings = "pings this round: none yet"
    hudRound = "round {} of {}   score {}   the ping is right {}% of the time".format(roundN, NROUNDS, score, round(acc * 100))
    if roundN == 1:
        coach = "Round 1. Press F to ping. The rooms open after two pings."
    elif roundN == 2:
        coach = "Round 2. She has moved. Press F to ping. The rooms open after one ping."
    elif roundN == NROUNDS:
        coach = "Last round. The ping is now always right. Ping, or walk into a room."
    else:
        coach = "Round {}. Your call: ping with F, or walk onto the pad of the room you think is empty.".format(roundN)
    # The stand-in's plan for each round: 0 follow the best plan, 1 enter after one ping (the gamble at 80%).
    autoStyle = 1 if roundN == 3 or roundN == NROUNDS else 0
    while not roundDone:
        if AUTOPLAY:
            wait(0.3)
            if roomsOpen and ((autoStyle == 1 and pingCount >= 1) or (autoStyle == 0 and (abs(nLat) >= nStar or pingCount >= MAXPINGS))):
                autoRoom = 1 if belief >= 0.5 else 0
                learner.startThrottleInDirection(directionTowards(learner.getPosition(), padR if autoRoom == 1 else padL), 1, Relativity.TO_WORLD, Throttle.REPLACE_EXISTING, ThrottleReeval.NONE)
            else:
                pingReq = true
        deciding = true
        waitUntil(pingReq or (roomsOpen and (distance(learner.getPosition(), padL) < PAD_R or distance(learner.getPosition(), padR) < PAD_R)), 12 if AUTOPLAY else 900)
        deciding = false
        learner.stopThrottleInDirection()
        onPad = roomsOpen and (distance(learner.getPosition(), padL) < PAD_R or distance(learner.getPosition(), padR) < PAD_R)
        if AUTOPLAY and not pingReq and not onPad and roomsOpen:
            # The stand-in did not arrive in time: put it on the pad it was walking to, and say so in the log.
            LOG("RLG,E,{},stuck,{},{}".format(GAME_ID, roundN, autoRoom))
            learner.teleport(padR if autoRoom == 1 else padL)
            wait(0.3)
            onPad = true
        if pingReq:
            pingReq = false
            if pingCount >= MAXPINGS:
                coach = "That is the most pings for one round. Walk into a room."
                roomsOpen = true
            else:
                doPing()
                if roundN == 1 and pingCount == 1:
                    qId = 1
                    qText = "The ping said {}. It is right 8 times in 10. How sure should you be she is there?".format(lastSaid)
                    qOpts = ["50%", "80%", "94%"]
                    qCorrect = 1
                    qAuto = 1
                    qWhy = "Before it you were 50/50, so the ping's own accuracy is the answer: 80%."
                    ask()
                    barShown = true
                    coach = "The bar is your belief: one number, moved by one rule after each ping. Press F again."
                elif roundN == 1 and pingCount == 2:
                    qId = 2
                    qText = "The second ping said {}. How sure should you be she is in the {} room now?".format(lastSaid, lastSaid)
                    qOpts = ["50%", "80%", "94%"]
                    qCorrect = 2 if reading == firstReading else 0
                    qAuto = 2
                    qWhy = "Two that agree: 0.8 x 0.8 against 0.2 x 0.2, about 94%." if reading == firstReading else "One each way cancels out: back to 50%, as if you had not pinged at all."
                    ask()
                    barShown = true
                    roomsOpen = true
                    coach = "Rooms open. Ping more with F, or walk onto the pad of the room you think is EMPTY."
                elif roundN == 2 and pingCount == 1:
                    qId = 3
                    qText = "She is 80% likely in the {} room. Walk into the other now, or ping again: which pays more?".format(lastSaid)
                    qOpts = ["enter now", "ping again"]
                    judge()
                    qCorrect = 1 if pingQ > enterNow else 0
                    qAuto = 1
                    qWhy = "Entering pays 0.8 x 10 - 0.2 x 30 = {} on average. Pinging on (then the best plan): {}.".format(enterNow, pingQ)
                    ask()
                    barShown = true
                    roomsOpen = true
                    coach = "At these prices 80% is not sure enough: one wrong room costs three right ones. Your call."
                else:
                    coach = "That ping was worth {} on average; entering instead, {}. {}".format(pingQ, enterNow, "Worth its cost." if pingQ > enterNow + 0.0001 else "Entering was the better bet.")
        elif onPad:
            judge()
            room = 0 if distance(learner.getPosition(), padL) < PAD_R else 1
            roomEv = ROOM_EV(room, belief)
            reward = W_EMPTY if room != hidden else 0 - L_HERS
            score += reward
            if room != hidden:
                nGood += 1
            # enter: round, room entered, her room, belief, that room's value, best entering value, one-more-ping value, reward, pings
            LOG("RLG,E,{},enter,{},{},{},{},{},{},{},{},{}".format(GAME_ID, roundN, room, hidden, belief, roomEv, enterNow, pingQ, reward, pingCount))
            createEffect(getAllPlayers(), Effect.SPHERE, Color.LIGHT_PURPLE, (padL if hidden == 0 else padR) + vect(0, 1, 0), 1.2, EffectReeval.NONE)
            sombraFx = getLastCreatedEntity()
            createInWorldText(getAllPlayers(), "SOMBRA WAS HERE", (padL if hidden == 0 else padR) + vect(0, 2.8, 0), 2, Clip.NONE, WorldTextReeval.NONE, Color.LIGHT_PURPLE)
            sombraTx = getLastCreatedText()
            if room == hidden:
                learner.setStatusEffect(null, Status.HACKED, 2)
            hudRound = "round {} of {}   score {}   the ping is right {}% of the time".format(roundN, NROUNDS, score, round(acc * 100))
            coach = "She was in the {} room. You walked into the {}: {}.".format("LEFT" if hidden == 0 else "RIGHT", "LEFT" if room == 0 else "RIGHT", "+10, empty" if reward > 0 else "-30, hacked")
            barShown = true
            wait(1 if AUTOPLAY else 4)
            coach = "That room was empty with chance {}%: worth {} on average. Pinging on: {}. {}".format(round(100 * (1 - belief if room == 0 else belief)), roomEv, pingQ, "One more ping was worth it." if pingQ > roomEv + 0.0001 else "Entering was the better bet.")
            wait(1 if AUTOPLAY else 6)
            destroyEffect(sombraFx)
            destroyInWorldText(sombraTx)
            putHome()
            learner.setFacing(vect(0, 0, 1), Relativity.TO_WORLD)
            roundDone = true

rule "Game 11: F pings (once per press)":
    @Event eachPlayer
    @Condition eventPlayer == learner
    @Condition deciding
    @Condition fArmed
    @Condition eventPlayer.isHoldingButton(Button.INTERACT)
    fArmed = false
    pingReq = true

rule "Game 11: letting go of F arms the next ping":
    @Event eachPlayer
    @Condition eventPlayer == learner
    @Condition eventPlayer.isHoldingButton(Button.INTERACT) == false
    fArmed = true

rule "Game 11: a fall puts him back at home":
    @Condition ready
    @Condition learner.fell
    wait(1)
    putHome()
    learner.setFacing(vect(0, 0, 1), Relativity.TO_WORLD)

rule "Game 11: the screen (strings are rebuilt only when something changes)":
    @Condition ready
    hudText(getAllPlayers(), null, null, hudRound, HudPosition.LEFT, 3, Color.WHITE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, null, hudPings, HudPosition.LEFT, 4, Color.WHITE, Color.WHITE, Color.YELLOW, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, null, debrief[0], HudPosition.LEFT, 5, Color.WHITE, Color.WHITE, Color.GREEN, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, null, debrief[1], HudPosition.LEFT, 6, Color.WHITE, Color.WHITE, Color.GREEN, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, null, debrief[2], HudPosition.LEFT, 7, Color.WHITE, Color.WHITE, Color.GREEN, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, null, hudKeys, HudPosition.RIGHT, 0, Color.WHITE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, null, planText, HudPosition.RIGHT, 1, Color.WHITE, Color.WHITE, Color.SKY_BLUE, HudReeval.VISIBILITY_AND_STRING)
    progressBarHud(getAllPlayers() if barShown else null, belief * 100, barText, HudPosition.TOP, 1, Color.LIGHT_PURPLE, Color.WHITE, ProgressHudReeval.VISIBILITY_AND_VALUES)

rule "Game 11: run":
    @Condition ready
    hudKeys = "F: ping (costs 1)   walk onto a pad: enter that room   empty room +10, hers -30"
    createEffect(getAllPlayers(), Effect.RING, Color.WHITE, padL, PAD_R, EffectReeval.NONE)
    createEffect(getAllPlayers(), Effect.RING, Color.WHITE, padR, PAD_R, EffectReeval.NONE)
    createInWorldText(getAllPlayers(), "LEFT ROOM", padL + vect(0, 1.6, 0), 2, Clip.NONE, WorldTextReeval.NONE, Color.WHITE)
    createInWorldText(getAllPlayers(), "RIGHT ROOM", padR + vect(0, 1.6, 0), 2, Clip.NONE, WorldTextReeval.NONE, Color.WHITE)

    # The game's arithmetic checks itself before anything is shown.
    CHECK("one ping, belief", 0.8, POST(0.5, 0, 0.8))
    CHECK("two pings that agree", 0.9412, POST(POST(0.5, 0, 0.8), 0, 0.8))
    CHECK("one ping each way", 0.5, POST(POST(0.5, 0, 0.8), 1, 0.8))
    CHECK("a RIGHT reading from 50%", 0.2, POST(0.5, 1, 0.8))
    CHECK("ladder rung 2", 0.9412, LAT_P(2))
    CHECK("ladder rung -1", 0.2, LAT_P(-1))
    CHECK("enter at 80%", 2, ENTER_EV(0.8))
    CHECK("enter at 50%", -10, ENTER_EV(0.5))
    CHECK("perfect ping, belief", 1, POST(0.5, 0, 1))
    solvePlan()
    CHECK("best plan at 50%", 4.7059, Vt[KL])
    CHECK("best plan at 80%", 5.7059, Vt[KL + 1])
    CHECK("best plan at 94% is to enter", 7.6471, Vt[KL + 2])
    CHECK("plan threshold rung", 2, nStar)
    perfectV = 0 - PING_COST + 0.5 * ENTER_EV(1) + 0.5 * ENTER_EV(0)
    CHECK("perfect ping at 50%", 9, perfectV)
    # plan: threshold rung, its belief, best-plan value at 50%, 80%, 94%, and with a perfect ping at 50%
    LOG("RLG,E,{},plan,{},{},{},{},{},{}".format(GAME_ID, nStar, pStar, Vt[KL], Vt[KL + 1], Vt[KL + 2], perfectV))
    planText = "Best plan at these prices: ping while the bar is between {}% and {}%, else enter.".format(round(100 * (1 - pStar)), round(100 * pStar))

    coach = "Sombra hides, invisible, in one of two rooms. Walk through the EMPTY one: +10. Hers costs 30."
    wait(1 if AUTOPLAY else 6)
    coach = "Your ping (F) is a sonic arrow, like Hanzo's: it names her room, right 8 times in 10. Each costs 1."
    wait(1 if AUTOPLAY else 6)

    playRound()
    playRound()

    # Two situations that look the same (lesson 11's hidden wall, lecture 7's look-alike squares).
    qId = 4
    qText = "Two players' latest ping both said LEFT. One heard RIGHT before it, one heard LEFT. Same bar?"
    qOpts = ["same bar", "different bars"]
    qCorrect = 1
    qAuto = 1
    qWhy = "Different: {}% and {}%. The latest reading is not a state, like the blind runner's square.".format(round(100 * POST(POST(0.5, 1, ACC), 0, ACC)), round(100 * POST(POST(0.5, 0, ACC), 0, ACC)))
    ask()
    playRound()

    # The value of information (lecture 9): a ping is worth most where it can change what you do.
    # gain50: how much the best plan at 50% (which pings) beats entering now.
    # gain94: how much entering at 94% beats one more ping followed by the best plan.
    gain50 = Vt[KL] - ENTER_EV(0.5)
    gp = LAT_P(2)
    pl = gp * ACC + (1 - gp) * (1 - ACC)
    gain94 = Vt[KL + 2] - (0 - PING_COST + pl * Vt[KL + 3] + (1 - pl) * Vt[KL + 1])
    LOG("RLG,E,{},voi,{},{}".format(GAME_ID, gain50, gain94))
    qId = 5
    qText = "When is one more ping worth most: at 50%, or at 94%?"
    qOpts = ["at 50%", "at 94%", "the same"]
    qCorrect = 0
    qAuto = 0
    qWhy = "At 50% pinging gains {} over entering; at 94% it loses {}. It pays if it can change your move.".format(gain50, gain94)
    ask()
    playRound()

    # A sensor that is always right: the island's single bump.
    qId = 6
    qText = "Last round the ping is always right, like Widowmaker's infra-sight. How many pings do you need?"
    qOpts = ["one", "two", "three or more"]
    qCorrect = 0
    qAuto = 0
    qWhy = "One. A reading that cannot be wrong turns the belief into a fact: 100% or 0%."
    ask()
    playRound()

    # debrief: rounds won, score, predictions right, predictions asked
    LOG("RLG,E,{},score,{},{},{},{}".format(GAME_ID, nGood, score, predRight, predTotal))
    hudKeys = ""
    planText = ""
    barShown = false
    debrief[0] = "You pinged to find out, then walked into a room you could not see into."
    wait(0.5 if AUTOPLAY else 3)
    debrief[1] = "Its name: partial observability. The bar is a belief state; a ping is an action taken for information."
    wait(0.5 if AUTOPLAY else 3)
    debrief[2] = "In an agent: a question or a lookup is a ping, a cancellation is a room. Check what it was shown first."
    coach = "Score {}, empty room {} of {} times. Predictions right: {} of {}.".format(score, nGood, NROUNDS, predRight, predTotal)
    wait(1 if AUTOPLAY else 8)
    coach = "Simplified: two rooms, a ping of known accuracy, Sombra never moves. Real hidden states are too many to list."
    finish()
