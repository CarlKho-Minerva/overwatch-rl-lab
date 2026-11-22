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
    if cfgSlowMo < 100:
        setSlowMotion(cfgSlowMo)
    createDummy(Hero.TRACER, Team.1, -1, startPos, vect(1, 0, 0))
    tracer = getLastCreatedEntity()
    createDummy(Hero.WIDOWMAKER, Team.2, -1, widowPos, vect(0, 0, -1))
    widow = getLastCreatedEntity()
    wait(1.5)
    if not entityExists(tracer) or not entityExists(widow) or tracer == widow:
        calStage = -1
        calMsg = "the dummy bots did not spawn: leave a free slot on Team 1 and on Team 2"
        return
    tracer.setMoveSpeed(cfgMoveSpeed)
    widow.setDamageDealt(cfgWidowDamage if cfgExperiment == Exp.WIDOW else 0)
    widow.startFacing(directionTowards(widow.getEyePosition(), tracer.getPosition() + vect(0, 1, 0)), 720, Relativity.TO_WORLD, FacingReeval.DIRECTION_AND_TURN_RATE)

    # Speed run: from the middle row, along +x.
    calMsg = "measuring Tracer's run speed"
    tracer.startForcingPosition(cellPos[2 * NCOLS], false)
    wait(0.25)
    tracer.stopForcingPosition()
    tracer.setFacing(vect(1, 0, 0), Relativity.TO_WORLD)
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
