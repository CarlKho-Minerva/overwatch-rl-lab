/*
Game 4: Back From Spawn (lecture 4, model-free prediction).

The learner walks from the spawn ring through four rings to the point, five times. Some legs are mud (slow).
Two predictors of "seconds from this ring to the point" are kept for every ring and shown above it:
    BLUE    (every-visit Monte Carlo, constant step): at the point, each guess moves halfway to the time
            the rest of that walk really took.
    ORANGE  (TD(0), the same step): at each ring, the guess for the ring just left moves halfway to
            the leg's time plus ORANGE's own guess for the ring just reached (0 at the point).
Walk 4 is cut short at ring 2: ORANGE learns from it, BLUE cannot.
Mud: on each full walk the number of mud legs comes from a shuffled list (1, 2, 4, 5), which legs are mud is drawn
at random, and leg 1 of walk 1 is always mud. The cut walk draws each leg with odds 0.4. Every draw is logged.
Log lines: workshop/games/g04.md
*/
settings {
    "main": {
        "modeName": "RL course 4: Back From Spawn",
        "description": "RL course, lecture 4: two predictors guess your walk back from spawn. github.com/CarlKho-Minerva/overwatch-rl-lab"
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

#!define GAME_ID 4
#!define GAME_VERSION 1
#!define GAME_TITLE "RL 4: BACK FROM SPAWN"
#!define LEARNER_HERO Hero.TRACER
#!define HOME_POS vect(-14, 0, -14)
#!define HOME_FACING vect(0, 0, 1)
#!define STOPS 8

#!include "common.opy"

globalvar ringPos = [vect(-14, 0, -14), vect(-14, 0, -2), vect(-2, 0, -2), vect(-2, 0, 10), vect(10, 0, 10), vect(10, 0, -2)]
globalvar ringName = ["SPAWN", "RING 1", "RING 2", "RING 3", "RING 4", "THE POINT"]
globalvar vMc = []
globalvar vTd = []
globalvar rB = []
globalvar rO = []
globalvar tB = []
globalvar tO = []
globalvar legState = [0, 0, 0, 0, 0]
globalvar mud = [0, 0, 0, 0, 0]
globalvar legT = [0, 0, 0, 0, 0]
globalvar ret = [0, 0, 0, 0, 0]
globalvar counts = []
globalvar picks = []
globalvar walk = 0
globalvar leg = 0
globalvar nLegs = 5
globalvar fullIdx = 0
globalvar t0 = 0
globalvar tLeg = 0
globalvar old = 0
globalvar tgt = 0
globalvar gSum = 0
globalvar ii = 0
globalvar histB = []
globalvar histO = []
globalvar swingIn = []
globalvar swingOut = 0
globalvar swingB = 0
globalvar swingO = 0
globalvar board = ["", "", "", "", ""]
globalvar status = ""
# Left rows 4 to 6. Until the debrief: BLUE's rule, ORANGE's rule, and a note that names what he just saw. They hold
# until replaced, so a person reading the lecture's page in another window comes back to them (2026-11-22).
globalvar deb = ["BLUE: at the point, each ring's guess moves halfway to the time the rest of that walk took.", "ORANGE: at each ring, the last ring's guess moves halfway to that leg's time plus ORANGE's guess here.", "Above each ring: two guesses of the seconds from there to the point. Both start at 3 s a leg."]
globalvar showDeb = false

macro ALPHA = 0.5
macro PRIOR_LEG = 3
macro CLEAR_SPEED = 100
macro MUD_SPEED = 30
macro RING_R = 1.5
macro NLEGS = 5
macro NWALKS = 5
macro CUT_WALK = 3
macro CUT_LEGS = 2
# Macro argument names must not match a variable: OverPy read 'old' here as the global old (seen in the game,
# 2026-11-22: the self-test gave 8.50 for 16). So every argument has a name no variable uses, in brackets.
macro STEP(m_from, m_to):
    ((m_from) + ALPHA * ((m_to) - (m_from)))
macro TD_TARGET(m_leg, m_next):
    ((m_leg) + (m_next))
macro AT(m_ring):
    (distance(vect(learner.getPosition().x, 0, learner.getPosition().z), ringPos[(m_ring)]) < RING_R)
macro PAUSE(m_sec):
    wait(0.3 if AUTOPLAY else (m_sec))

subroutine refresh
subroutine computeReturns
subroutine computeSwing
subroutine doWalk

def refresh():
    @Name "Game 4: rebuild the numbers above the rings and the board (only when a guess changes)"
    rB = vMc.map(lambda x: round(x * 10) / 10)
    rO = vTd.map(lambda x: round(x * 10) / 10)
    for ii in range(NLEGS):
        tB[ii] = "BLUE {}".format(rB[ii])
        tO[ii] = "ORANGE {}".format(rO[ii])
        # One right-hand row per ring (a single six-line string made the right block 179 characters, 2026-11-22).
        board[ii] = "{}:  blue {}  orange {}".format(ringName[ii], rB[ii], rO[ii])

def computeReturns():
    @Name "Game 4: the real time left from each ring to the point (sum of this walk's legs from there on)"
    gSum = 0
    for ii in range(NLEGS - 1, -1, -1):
        gSum += legT[ii]
        ret[ii] = gSum

def computeSwing():
    @Name "Game 4: how far a guess moved in total over the walks (sum of the size of each change)"
    swingOut = 0
    for ii in range(1, len(swingIn)):
        swingOut += abs(swingIn[ii] - swingIn[ii - 1])

def doWalk():
    @Name "Game 4: one walk from spawn to the point (or to ring 2 on the cut walk)"
    putHome()
    learner.setMoveSpeed(CLEAR_SPEED)
    nLegs = CUT_LEGS if walk == CUT_WALK else NLEGS
    # Draw the mud first and log it, then walk it.
    mud = [0, 0, 0, 0, 0]
    if walk == CUT_WALK:
        for ii in range(NLEGS):
            mud[ii] = 1 if random.uniform(0, 1) < 0.4 else 0
    else:
        fullIdx = walk if walk < CUT_WALK else walk - 1
        if walk == 0:
            picks = [0].concat(random.shuffle([1, 2, 3, 4]).slice(0, counts[0] - 1))
        else:
            picks = random.shuffle([0, 1, 2, 3, 4]).slice(0, counts[fullIdx])
        for ii in range(NLEGS):
            mud[ii] = 1 if ii in picks else 0
    legState = [0, 0, 0, 0, 0]
    legT = [0, 0, 0, 0, 0]
    # walk: walk (0-4), mud on legs 1-5 (1 mud, 0 clear), legs this walk will have
    LOG("RLG,E,{},walk,{},{},{},{},{},{},{}".format(GAME_ID, walk, mud[0], mud[1], mud[2], mud[3], mud[4], nLegs))
    for leg in range(nLegs):
        legState[leg] = 2 if mud[leg] == 1 else 1
        learner.setMoveSpeed(MUD_SPEED if mud[leg] == 1 else CLEAR_SPEED)
        status = "WALK {} OF 5    LEG {}: {}".format(walk + 1, leg + 1, "MUD (slow)" if mud[leg] == 1 else "clear")
        if walk == 0 and leg == 1:
            STOP(2)
        if AUTOPLAY:
            learner.startThrottleInDirection(directionTowards(vect(learner.getPosition().x, 0, learner.getPosition().z), ringPos[leg + 1]), 1, Relativity.TO_WORLD, Throttle.REPLACE_EXISTING, ThrottleReeval.NONE)
        waitUntil(not AT(leg), 10 if AUTOPLAY else 99999)
        t0 = NOW
        if leg == 0:
            # Set only once he has left the spawn ring: until then the last result and its reason stay on screen.
            coach = "Walk {} of 5. Leg 1 is {}. The clock runs only between rings.".format(walk + 1, "MUD" if mud[0] == 1 else "clear")
        while not AT(leg + 1):
            waitUntil(AT(leg + 1) or learner.fell, 15 if AUTOPLAY else 99999)
            if learner.fell:
                if learner.isDead():
                    learner.resurrect()
                    wait(0.25)
                learner.teleport(ringPos[leg])
                wait(0.2)
                learner.fell = false
            elif AUTOPLAY and not AT(leg + 1):
                learner.teleport(ringPos[leg + 1])
            wait(0.05)
        tLeg = round(100 * (NOW - t0)) / 100
        legT[leg] = tLeg
        if AUTOPLAY:
            learner.stopThrottleInDirection()
        # leg: walk, leg (0-4), mud, seconds
        LOG("RLG,E,{},leg,{},{},{},{}".format(GAME_ID, walk, leg, mud[leg], tLeg))
        if walk == 0 and leg == 0:
            qId = 1
            qText = "Leg 1 was mud and you are at ring 1. Whose guess for the spawn ring has changed already?"
            qOpts = ["BLUE", "ORANGE", "both"]
            qCorrect = 1
            qAuto = 1
            qWhy = "ORANGE updates at each ring. BLUE needs the time to the point, which you do not have yet."
            ask()
            learner.teleport(ringPos[1])
        # TD(0): the guess for the ring just left moves toward this leg's time plus the guess for the ring just reached.
        old = vTd[leg]
        tgt = TD_TARGET(tLeg, 0 if leg == NLEGS - 1 else vTd[leg + 1])
        vTd[leg] = STEP(old, tgt)
        # td: walk, ring updated (0 spawn - 4), old guess, target, new guess
        LOG("RLG,E,{},td,{},{},{},{},{}".format(GAME_ID, walk, leg, old, tgt, vTd[leg]))
        refresh()
        coach = "{} after {} s. ORANGE's guess for {}: {} to {}. BLUE waits.".format(ringName[leg + 1], tLeg, ringName[leg], round(old * 10) / 10, rO[leg])
    learner.stopThrottleInDirection()
    learner.setMoveSpeed(CLEAR_SPEED)
    if nLegs == NLEGS:
        # Every-visit Monte Carlo: now that the walk is over, every guess moves toward the real time left from its ring.
        computeReturns()
        for ii in range(NLEGS):
            old = vMc[ii]
            vMc[ii] = STEP(old, ret[ii])
            # mc: walk, ring (0 spawn - 4), old guess, real time left, new guess
            LOG("RLG,E,{},mc,{},{},{},{},{}".format(GAME_ID, walk, ii, old, ret[ii], vMc[ii]))
        refresh()
        status = "WALK {} OF 5    AT THE POINT".format(walk + 1)
        coach = "At the point: {} s in all. Now BLUE moves every guess halfway to the real time left.".format(ret[0])
    else:
        # cut: walk, legs walked
        LOG("RLG,E,{},cut,{},{}".format(GAME_ID, walk, nLegs))
        status = "WALK {} OF 5    CUT SHORT".format(walk + 1)
        coach = "The round ended on the way. BLUE never got a time to the point, so it learned nothing."
    histB.append(vMc[0])
    histO.append(vTd[0])
    PAUSE(6)

rule "Game 4: the screen":
    hudText(getAllPlayers(), null, null, status, HudPosition.RIGHT, 0, Color.WHITE, Color.WHITE, Color.YELLOW, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, null, "SECONDS FROM EACH RING TO THE POINT", HudPosition.RIGHT, 1, Color.WHITE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, null, board[0], HudPosition.RIGHT, 2, Color.WHITE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, null, board[1], HudPosition.RIGHT, 3, Color.WHITE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, null, board[2], HudPosition.RIGHT, 4, Color.WHITE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, null, board[3], HudPosition.RIGHT, 5, Color.WHITE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, null, board[4], HudPosition.RIGHT, 6, Color.WHITE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, null, "WASD: walk to the next ring. Answer with left click, right click or melee.", HudPosition.LEFT, 3, Color.WHITE, Color.WHITE, Color.SKY_BLUE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, deb[0], null, HudPosition.LEFT, 4, Color.WHITE, Color.WHITE if showDeb else Color.SKY_BLUE, Color.WHITE, HudReeval.VISIBILITY_STRING_AND_COLOR)
    hudText(getAllPlayers(), null, deb[1], null, HudPosition.LEFT, 5, Color.WHITE, Color.WHITE if showDeb else Color.ORANGE, Color.WHITE, HudReeval.VISIBILITY_STRING_AND_COLOR)
    hudText(getAllPlayers(), null, deb[2], null, HudPosition.LEFT, 6, Color.WHITE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)

rule "Game 4: run":
    @Condition ready
    STOP(1)
    # 2026-11-22: the button rule, not the ability switch: the core turns the ability switch back on after each
    # question (it switches Blink off while a question is up, because right click is also Blink).
    learner.disallowButton(Button.ABILITY_1)
    learner.disallowButton(Button.ABILITY_2)
    learner.disallowButton(Button.ULTIMATE)

    # Self-tests: every formula the game uses, on known numbers (the same ones tests/test_game_04.py checks).
    CHECK("guess from spawn at 3 s a leg", 15, PRIOR_LEG * NLEGS)
    CHECK("orange target 5 s leg + 12 s guess", 17, TD_TARGET(5, 12))
    CHECK("halfway step 15 toward 17", 16, STEP(15, 17))
    CHECK("halfway step 15 toward 21", 18, STEP(15, 21))
    legT = [5, 1.5, 1.5, 5, 1.5]
    computeReturns()
    CHECK("time left from spawn", 14.5, ret[0])
    CHECK("time left from ring 3", 6.5, ret[3])
    swingIn = [15, 18, 16, 17]
    computeSwing()
    CHECK("total movement 15 18 16 17", 6, swingOut)

    # Both predictors start from the same guess: 3 seconds a leg.
    for ii in range(NLEGS):
        vMc[ii] = PRIOR_LEG * (NLEGS - ii)
        vTd[ii] = PRIOR_LEG * (NLEGS - ii)
    histB = [vMc[0]]
    histO = [vTd[0]]
    counts = random.shuffle([1, 2, 4, 5])
    # setup: step size, starting guess per leg, clear speed %, mud speed %, legs, walks, cut walk, legs on the cut walk
    LOG("RLG,E,{},setup,{},{},{},{},{},{},{},{}".format(GAME_ID, ALPHA, PRIOR_LEG, CLEAR_SPEED, MUD_SPEED, NLEGS, NWALKS, CUT_WALK, CUT_LEGS))
    # counts: mud legs on full walks 1, 2, 3 and 5 (shuffled from 1, 2, 4, 5)
    LOG("RLG,E,{},counts,{},{},{},{}".format(GAME_ID, counts[0], counts[1], counts[2], counts[3]))
    refresh()

    # The route: rings, the legs between them (white until walked, then green clear or red mud), guesses above.
    for ii in range(NLEGS + 1):
        createEffect(getAllPlayers(), Effect.RING, Color.GREEN if ii == NLEGS else Color.WHITE, ringPos[ii], RING_R, EffectReeval.NONE)
        createInWorldText(getAllPlayers(), ringName[ii], ringPos[ii] + vect(0, 2.6, 0), 1.6, Clip.NONE, WorldTextReeval.NONE, Color.GREEN if ii == NLEGS else Color.WHITE)
    createEffect(getAllPlayers(), Effect.LIGHT_SHAFT, Color.GREEN, ringPos[NLEGS], RING_R, EffectReeval.NONE)
    for ii in range(NLEGS):
        createBeam(getAllPlayers(), Beam.GRAPPLE, ringPos[evalOnce(ii)] + vect(0, 0.1, 0), ringPos[evalOnce(ii) + 1] + vect(0, 0.1, 0), Color.RED if legState[evalOnce(ii)] == 2 else (Color.GREEN if legState[evalOnce(ii)] == 1 else Color.WHITE), EffectReeval.VISIBILITY_POSITION_RADIUS_AND_COLOR)
        createInWorldText(getAllPlayers(), tB[evalOnce(ii)], ringPos[ii] + vect(0, 2.0, 0), 1.6, Clip.NONE, WorldTextReeval.VISIBILITY_AND_STRING, Color.SKY_BLUE)
        createInWorldText(getAllPlayers(), tO[evalOnce(ii)], ringPos[ii] + vect(0, 1.4, 0), 1.6, Clip.NONE, WorldTextReeval.VISIBILITY_AND_STRING, Color.ORANGE)

    status = "BEFORE THE FIRST WALK"
    # Stop 1 opens on the first walk, which waits for him to leave the spawn ring. The two rules stay on the left rows
    # (they were four timed lines, 27 seconds, gone by the time he came back from the page).
    coach = "Back from spawn: walk the rings to the point, five times. Some legs are mud and slow you down."

    walk = 0
    doWalk()
    deb[2] = "BLUE is called Monte Carlo: it waits for the end and learns from the real total. No rules needed."
    STOP(3)
    qId = 2
    qText = "Lecture 2's Bellman rule: time from here = this leg + time from the next ring. Which guess is built so?"
    qOpts = ["BLUE", "ORANGE"]
    qCorrect = 1
    qAuto = 1
    qWhy = "ORANGE: a real leg plus its own next guess, a guess fixing a guess. BLUE uses only real times."
    ask()
    deb[2] = "ORANGE is temporal-difference learning, TD. Fixing a guess with your next guess is bootstrapping."
    STOP(4)
    walk = 1
    doWalk()

    STOP(5)
    qId = 3
    qText = "By the last walk, whose spawn guess will have moved around more in total?"
    qOpts = ["BLUE", "ORANGE", "about the same"]
    qCorrect = 0
    qAuto = 0
    qWhy = "BLUE chases each whole walk, all its mud at once. ORANGE uses one leg plus a steady guess."
    ask()

    walk = 2
    doWalk()

    STOP(6)
    qId = 4
    qText = "On walk 4 the round ends as you reach ring 2, and you go back. Who learns anything from that walk?"
    qOpts = ["BLUE", "ORANGE", "neither"]
    qCorrect = 1
    qAuto = 2
    qWhy = "BLUE needs a time to the point and never gets one. ORANGE already used the two legs walked."
    ask()

    walk = 3
    doWalk()
    deb[2] = "TD learns before the end, and from walks that are cut short. Monte Carlo needs walks that finish."
    STOP(7)
    qId = 5
    qText = "Lecture 3's planner found values without walking at all. What would it need to do that here?"
    qOpts = ["only the map", "each leg's mud odds and speeds", "nothing more"]
    qCorrect = 1
    qAuto = 1
    qWhy = "Planning needs the rules: how likely and how slow mud is per leg. These two learn from walks."
    ask()
    deb[2] = "Neither predictor was told the mud odds. Learning values from walks alone is model-free prediction."

    walk = 4
    doWalk()

    swingIn = histB
    computeSwing()
    swingB = swingOut
    swingIn = histO
    computeSwing()
    swingO = swingOut
    # swing: total movement of the spawn guess over the walks, BLUE then ORANGE
    LOG("RLG,E,{},swing,{},{}".format(GAME_ID, swingB, swingO))
    # final: 0 BLUE or 1 ORANGE, then the guesses for spawn and rings 1 to 4
    LOG("RLG,E,{},final,0,{},{},{},{},{}".format(GAME_ID, vMc[0], vMc[1], vMc[2], vMc[3], vMc[4]))
    LOG("RLG,E,{},final,1,{},{},{},{},{}".format(GAME_ID, vTd[0], vTd[1], vTd[2], vTd[3], vTd[4]))
    status = "ALL FIVE WALKS DONE"
    coach = "Spawn guess, total movement: BLUE {} s, ORANGE {} s. {}".format(round(swingB * 10) / 10, round(swingO * 10) / 10, "BLUE swung more." if swingB > swingO else "This time ORANGE did; usually BLUE does.")
    PAUSE(7)
    deb[2] = "ORANGE is steadier but leans on its own guesses. If they start wrong, it stays wrong a while: bias."
    PAUSE(7)

    STOP(8)

    deb = ["What you did: walked back from spawn 5 times while two guesses of your time were fixed at each ring.", "Its name: BLUE is Monte Carlo (real totals, no bias, noisy). ORANGE is TD (a leg plus a guess, biased).", "In an agent: judge each turn by the final score (Monte Carlo) or by how a value guess moved that turn (TD)."]
    showDeb = true
    coach = "You got {} of {} predictions right. Simplified: fixed half steps, five walks, shuffled mud counts.".format(predRight, predTotal)
    PAUSE(4)
    finish()
