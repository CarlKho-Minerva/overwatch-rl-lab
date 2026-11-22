# ---------------------------------------------------------------------------
# Arena layout, bots, reset.
# The grid is 12 columns along the island's -z edge and 4 rows going inland.
#   column index grows with +x (toward the goal)
#   row 0 is the row next to the edge; row 3 is furthest inland
#   cell index = row * 12 + column
# Start = row 0, column 0.  Goal = row 0, column 11.
# ---------------------------------------------------------------------------

macro TRACER_BELOW = (tracer.getPosition().y < floorY - 1.2)

def layoutArena():
    @Name "Arena: place the grid from the measured edges"
    cell = min(cfgCell, (edgeXMax - edgeXMin - 4) / NCOLS)
    gridOrigin = vect((edgeXMin + edgeXMax) / 2 - NCOLS * cell / 2, floorY, edgeZMin + cfgMargin)
    for i in range(NCELLS):
        cellPos[i] = gridOrigin + vect((i % NCOLS + 0.5) * cell, 0, (floor(i / NCOLS) + 0.5) * cell)
    startPos = cellPos[START_CELL]
    goalPos = cellPos[GOAL_CELL]
    stripCenter = gridOrigin + vect(NCOLS * cell / 2, 0, NROWS * cell / 2)
    widowPos = vect(stripCenter.x, floorY, min(gridOrigin.z + NROWS * cell + cfgWidowStandoff, edgeZMax - 2))
    hostPos = vect(stripCenter.x + 3, floorY, min(widowPos.z + 3, edgeZMax - 1))
    camEye = stripCenter + vect(0, 21, 15)
    camLook = stripCenter + vect(0, 0, 1.5)

rule "Arena: spawn Tracer and Widowmaker, then measure Tracer's run speed":
    @Condition calStage == 1
    # Spawn each bot, then look it up by team and hero instead of trusting "last created entity".
    # Up to five tries each, a second apart: on 2026-11-21 Tracer failed to appear in two matches in a row
    # (Widowmaker did appear) and then spawned first time in the next seven. The cause was not found; game
    # speed, cell size and a restart after slow motion were each ruled out in the game.
    spawnCalls = 0
    for spawnTry in range(5):
        tracer = getPlayersOnHero(Hero.TRACER, Team.1).filter(lambda p: p.isDummy())[0]
        if not entityExists(tracer):
            createDummy(Hero.TRACER, Team.1, -1, startPos, vect(1, 0, 0))
            spawnCalls += 1
            wait(1)
    for spawnTry in range(5):
        widow = getPlayersOnHero(Hero.WIDOWMAKER, Team.2).filter(lambda p: p.isDummy())[0]
        if not entityExists(widow):
            createDummy(Hero.WIDOWMAKER, Team.2, -1, widowPos, vect(0, 0, -1))
            spawnCalls += 10
            wait(1)
    tracer = getPlayersOnHero(Hero.TRACER, Team.1).filter(lambda p: p.isDummy())[0]
    widow = getPlayersOnHero(Hero.WIDOWMAKER, Team.2).filter(lambda p: p.isDummy())[0]
    if not entityExists(tracer) or not entityExists(widow):
        calStage = -1
        calMsg = "the bots did not spawn. Leave a free slot on Team 1 and Team 2, then Esc > Show Lobby > Restart Match"
        logToInspector("RLLAB,FAIL,spawn,{},{},{},{},{},{}".format(len(getPlayers(Team.1)), len(getPlayers(Team.2)), len(getPlayersOnHero(Hero.TRACER, Team.1)), len(getPlayersOnHero(Hero.WIDOWMAKER, Team.2)), startPos, widowPos))
        return
    # spawnCalls = Tracer creations + 10 x Widowmaker creations; 11 means each bot appeared on the first try.
    logToInspector("RLLAB,SPAWN,{}".format(spawnCalls))
    if cfgSlowMo < 100:
        setSlowMotion(cfgSlowMo)
        wait(0.25)
    tracer.setMoveSpeed(cfgMoveSpeed)
    widow.setDamageDealt(cfgWidowDamage if cfgExperiment == Exp.WIDOW else 0)
    widow.startFacing(directionTowards(widow.getEyePosition(), tracer.getPosition() + vect(0, 1, 0)), 720, Relativity.TO_WORLD, FacingReeval.DIRECTION_AND_TURN_RATE)

    # Speed run: from the middle row, along +x.
    calMsg = "measuring Tracer's run speed"
    tracer.startForcingPosition(cellPos[2 * NCOLS], false)
    wait(0.25)
    tracer.stopForcingPosition()
    tracer.setFacing(vect(1, 0, 0), Relativity.TO_WORLD)
    if DBG_ROOT_TRACER:
        tracer.setStatusEffect(null, Status.ROOTED, 5)
    wait(0.4)
    tracer.startThrottleInDirection(vect(1, 0, 0), 1, Relativity.TO_WORLD, Throttle.REPLACE_EXISTING, ThrottleReeval.NONE)
    wait(0.4)
    calP0 = tracer.getPosition()
    calT0 = getTotalTimeElapsed()
    wait(0.8)
    calP1 = tracer.getPosition()
    runSpeed = distance(calP0, calP1) / (getTotalTimeElapsed() - calT0)
    tracer.stopThrottleInDirection()
    wait(0.5)
    coastDist = distance(calP1, tracer.getPosition())
    if runSpeed < 1:
        calStage = -1
        calMsg = "Tracer did not move under throttle control"
        logToInspector("RLLAB,FAIL,throttle,{},{},{}".format(runSpeed, calP0, calP1))
        return
    actDuration = cell / runSpeed * cfgDurationScale / 100
    actTimeout = 2.5 * cell / runSpeed + 0.25
    calStage = 2
    calMsg = "ready"

def resetTracer():
    @Name "Arena: put Tracer back on the start cell"
    tracer.stopThrottleInDirection()
    if tracer.isDead():
        tracer.resurrect()
        wait(0.25)
        if tracer.isDead():
            tracer.respawn()
            waitUntil(tracer.isAlive(), 3)
    tracer.startForcingPosition(startPos, false)
    wait(0.15)
    tracer.stopForcingPosition()
    tracer.setFacing(vect(1, 0, 0), Relativity.TO_WORLD)
    heal(tracer, null, 9999)
    if cfgBlink:
        tracer.setAbilityCharge(Button.ABILITY_1, 3)
    waitUntil(tracer.isOnGround(), 1)
    tracerDied = false
    tracerDiedEnv = false

rule "Arena: Tracer died":
    @Event playerDied
    @Condition eventPlayer == tracer
    tracerDiedEnv = eventWasEnvironment
    tracerDied = true

rule "Arena: Tracer took damage from Widowmaker":
    @Event playerTookDamage
    @Condition eventPlayer == tracer
    @Condition attacker == widow
    epHits += 1
