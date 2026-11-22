/*
The shared core of the course games (one Workshop mode per lecture, played by a person).

A game file defines, BEFORE including this file:
    #!define GAME_ID 5                       the lecture number
    #!define GAME_VERSION 1
    #!define GAME_TITLE "RL 5: SLIPPERY BOOTS"
    #!define LEARNER_HERO Hero.TRACER        the hero the player is given
    #!define HOME_POS vect(-12, 0, -17)      where the player starts and is put back after a fall
and AUTOPLAY (true or false) comes from the two-line wrapper files gNN.opy and gNN_auto.opy.

What this file gives every game:
    learner            the player being taught: the human host, or (AUTOPLAY) a bot that stands in for him so the
                       whole game can be run and checked in the real game with nobody at the keyboard
    ready              true once the learner exists and stands at HOME_POS
    LOG(text)          a log line (queued, written once a second: the game's recorder stops if lines are written freely)
    CHECK(name, expected, got)   a self-test line; the game's arithmetic checks itself when it starts
    ASK                a prediction question: set qId, qText, qOpts, qCorrect, qWhy (and qAuto, the stand-in's answer),
                       then call ask(). The player answers with left click, right click or melee. The answer is logged.
    coach              one line of plain words on screen; set it whenever something worth saying happens
    finish()           ends the game and writes the closing log line

Workshop Island, measured in the game on 2026-11-21: a flat square platform, x and z from -20 to 20, floor at y = 0,
a deadly drop on every side.

Log lines (docs/games.md):
    RLG,M,<game>,<version>,<autoplay>
    RLG,T,<game>,<name>,<expected>,<got>,<ok>
    RLG,A,<game>,<question id>,<answer>,<correct answer>,<right>
    RLG,E,<game>,<event name>,<numbers...>          (each game's own events)
    RLG,X,<game>,<seconds>,<predictions right>,<predictions made>,<self-tests ok>,<self-tests failed>
*/

macro ISLE_MIN = -20
macro ISLE_MAX = 20
macro FLOOR_Y = 0
macro NOW = getTotalTimeElapsed()
macro BELOW(p):
    (p.getPosition().y < FLOOR_Y - 1.5)

globalvar logQ = []
globalvar flushN
globalvar flushI
globalvar learner = null
globalvar ready = false
globalvar gameOver = false
globalvar coach = ""
globalvar qActive = false
globalvar qId = 0
globalvar qText = ""
globalvar qOpts = []
globalvar qLine = ""
globalvar qCorrect = 0
globalvar qAuto = 0
globalvar qAnswer = -1
globalvar qRight = false
globalvar qWhy = ""
globalvar predRight = 0
globalvar predTotal = 0
globalvar chkName = ""
globalvar chkExp = 0
globalvar chkGot = 0
globalvar selfOk = 0
globalvar selfBad = 0
playervar fellCount = 0
playervar fell = false

subroutine ask
subroutine check
subroutine finish
subroutine putHome

macro LOG(s):
    logQ.append(s)

macro CHECK(name, expected, got):
    chkName = name
    chkExp = expected
    chkGot = got
    check()

rule "Core: write the queued log lines in one frame, once a second":
    wait(1)
    if len(logQ) > 0:
        flushN = min(len(logQ), 120)
        enableInspector()
        for flushI in range(flushN):
            logToInspector(logQ[flushI])
        disableInspector()
        logQ = logQ.slice(flushN, 1000)
    loop()

rule "Core: every human player gets the game's hero":
    @Event eachPlayer
    @Condition eventPlayer.isDummy() == false
    eventPlayer.startForcingHero(LEARNER_HERO)

rule "Core: hide the match clock, which sits under the question line":
    @Event eachPlayer
    @Condition eventPlayer.isDummy() == false
    @Condition eventPlayer.hasSpawned()
    eventPlayer.disableGamemodeHud()

rule "Core: set up the learner":
    disableInspector()
    pauseMatchTime()
    wait(1.5)
    waitUntil(hostPlayer.hasSpawned() and hostPlayer.isAlive(), 60)
    if AUTOPLAY:
        # The automatic check: a bot plays the learner's part. The host stands aside, out of the way and unseen.
        createDummy(LEARNER_HERO, Team.1, -1, HOME_POS, vect(1, 0, 0))
        wait(1)
        learner = [p for p in getPlayers(Team.1) if p.isDummy()][0]
        hostPlayer.setStatusEffect(null, Status.PHASED_OUT, 99999)
        hostPlayer.setInvisibility(Invis.ALL)
        hostPlayer.teleport(vect(0, FLOOR_Y, 0))
    else:
        learner = hostPlayer
        learner.teleport(HOME_POS)
    wait(0.5)
    LOG("RLG,M,{},{},{}".format(GAME_ID, GAME_VERSION, 1 if AUTOPLAY else 0))
    ready = true

def putHome():
    @Name "Core: put the learner back at the start (after a fall, or between rounds)"
    if learner.isDead():
        learner.resurrect()
        wait(0.25)
        if learner.isDead():
            learner.respawn()
            waitUntil(learner.isAlive(), 4)
    learner.teleport(HOME_POS)
    wait(0.2)
    learner.fell = false

rule "Core: the learner fell off the island":
    @Event eachPlayer
    @Condition eventPlayer == learner
    @Condition ready
    @Condition BELOW(eventPlayer) or eventPlayer.isDead()
    eventPlayer.fell = true
    eventPlayer.fellCount += 1

def check():
    @Name "Core: one self-test line"
    if abs(chkExp - chkGot) < 0.011:
        selfOk += 1
        LOG("RLG,T,{},{},{},{},1".format(GAME_ID, chkName, chkExp, chkGot))
    else:
        selfBad += 1
        coach = "SELF-TEST FAILED: {} (expected {}, got {})".format(chkName, chkExp, chkGot)
        LOG("RLG,T,{},{},{},{},0".format(GAME_ID, chkName, chkExp, chkGot))

def ask():
    @Name "Core: ask the learner to predict, wait for the answer, say why, log it"
    qAnswer = -1
    qLine = "LEFT CLICK: {}      RIGHT CLICK: {}".format(qOpts[0], qOpts[1])
    if len(qOpts) > 2:
        qLine = "LEFT CLICK: {}      RIGHT CLICK: {}      MELEE: {}".format(qOpts[0], qOpts[1], qOpts[2])
    learner.disallowButton(Button.PRIMARY_FIRE)
    learner.disallowButton(Button.SECONDARY_FIRE)
    learner.disallowButton(Button.MELEE)
    wait(0.4)
    qActive = true
    if AUTOPLAY:
        wait(1.2)
        qAnswer = qAuto
    else:
        waitUntil(qAnswer >= 0 or gameOver, 90)
    qActive = false
    qRight = qAnswer == qCorrect
    predTotal += 1
    if qRight:
        predRight += 1
    LOG("RLG,A,{},{},{},{},{}".format(GAME_ID, qId, qAnswer, qCorrect, 1 if qRight else 0))
    coach = "{} {}".format("RIGHT." if qRight else ("NO ANSWER." if qAnswer < 0 else "NOT THIS TIME."), qWhy)
    wait(0.6 if AUTOPLAY else 5)
    learner.allowButton(Button.PRIMARY_FIRE)
    learner.allowButton(Button.SECONDARY_FIRE)
    learner.allowButton(Button.MELEE)

rule "Core: left click answers the first option":
    @Event eachPlayer
    @Condition eventPlayer == learner
    @Condition qActive
    @Condition eventPlayer.isHoldingButton(Button.PRIMARY_FIRE)
    qAnswer = 0

rule "Core: right click answers the second option":
    @Event eachPlayer
    @Condition eventPlayer == learner
    @Condition qActive
    @Condition eventPlayer.isHoldingButton(Button.SECONDARY_FIRE)
    qAnswer = 1

rule "Core: melee answers the third option":
    @Event eachPlayer
    @Condition eventPlayer == learner
    @Condition qActive
    @Condition len(qOpts) > 2
    @Condition eventPlayer.isHoldingButton(Button.MELEE)
    qAnswer = 2

def finish():
    @Name "Core: end the game and write the closing line"
    gameOver = true
    LOG("RLG,X,{},{},{},{},{},{}".format(GAME_ID, NOW, predRight, predTotal, selfOk, selfBad))

rule "Core: the screen":
    hudText(getAllPlayers(), GAME_TITLE, null, null, HudPosition.LEFT, 0, Color.ORANGE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, coach, null, HudPosition.LEFT, 1, Color.WHITE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, null, "predictions right: {} of {}".format(predRight, predTotal), HudPosition.LEFT, 2, Color.WHITE, Color.WHITE, Color.SKY_BLUE, HudReeval.VISIBILITY_AND_STRING)
    # The question floats in the middle of the view, a few metres in front of the learner's eyes, and its options under
    # it. At the top of the screen it ran into whatever a game had put on the left and right (seen in the game,
    # 2026-11-22: three placements tried). In the world it is clear of every HUD line.
    createInWorldText(getAllPlayers() if qActive else null, qText, learner.getEyePosition() + learner.getFacingDirection() * 5 + vect(0, 1.0, 0), 1.9, Clip.NONE, WorldTextReeval.VISIBILITY_POSITION_AND_STRING, Color.YELLOW)
    createInWorldText(getAllPlayers() if qActive else null, qLine, learner.getEyePosition() + learner.getFacingDirection() * 5 + vect(0, 0.45, 0), 1.5, Clip.NONE, WorldTextReeval.VISIBILITY_POSITION_AND_STRING, Color.WHITE)
