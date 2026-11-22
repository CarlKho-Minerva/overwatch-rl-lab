# ---------------------------------------------------------------------------
# The environment: one step = one real movement of the Tracer bot.
#
# State   = cell index (0..47)
#           + 48 if Tracer is at or below half health (Widowmaker experiment, when observed)
#           + 96 if Blink has no charge (only when Blink is enabled)
# Actions = FWD (+x), BACK (-x), IN (+z, away from the edge), EDGE (-z), BLINK
# Reward  = "reward per action" on every step, plus the terminal reward when the
#           step ends the episode, plus "reward per hit" for each Widowmaker hit.
#
# A move toward a side of the grid that is still island (left end, right end,
# inland side) is blocked: Tracer stays put and the step still costs its reward.
# A move toward the edge from row 0 is not blocked. She runs off the island and
# the fall is detected from her real height.
# ---------------------------------------------------------------------------

def observeState():
    @Name "Environment: read the state from Tracer's real position"
    obsP = tracer.getPosition()
    obsCell = min(max(floor((obsP.z - gridOrigin.z) / cell), 0), NROWS - 1) * NCOLS + min(max(floor((obsP.x - gridOrigin.x) / cell), 0), NCOLS - 1)
    obsS = obsCell
    if useHealthBit and tracer.getNormalizedHealth() <= 0.5:
        obsS += NCELLS
    if useBlink and tracer.getAbilityCharge(Button.ABILITY_1) < 1:
        obsS += 2 * NCELLS

def stepEnv():
    @Name "Environment: carry out action curA and observe the result"
    stepCol = curCell % NCOLS
    stepRow = floor(curCell / NCOLS)
    actDir = [vect(1, 0, 0), vect(-1, 0, 0), vect(0, 0, 1), vect(0, 0, -1), vect(1, 0, 0)][curA]
    tgtCol = stepCol + [1, -1, 0, 0, 0][curA]
    tgtRow = stepRow + [0, 0, 1, -1, 0][curA]
    reward = rStep
    terminal = false
    outcome = Outcome.RUNNING
    stepHits0 = epHits

    if curA == Act.BLINK:
        tracer.setFacing(actDir, Relativity.TO_WORLD)
        tracer.startThrottleInDirection(actDir, 1, Relativity.TO_WORLD, Throttle.REPLACE_EXISTING, ThrottleReeval.NONE)
        wait(0.064)
        tracer.forceButtonPress(Button.ABILITY_1)
        wait(0.1)
        tracer.stopThrottleInDirection()
        waitUntil(tracer.getHorizontalSpeed() < 0.2 or TRACER_BELOW or tracerDied, 0.4)
    elif tgtCol < 0 or tgtCol >= NCOLS or tgtRow >= NROWS:
        # Blocked: no movement, the step still counts.
        wait(0.064)
    else:
        tgtPos = gridOrigin + vect((tgtCol + 0.5) * cell, 0, (tgtRow + 0.5) * cell)
        tracer.setFacing(actDir, Relativity.TO_WORLD)
        tracer.startThrottleInDirection(actDir, 1, Relativity.TO_WORLD, Throttle.REPLACE_EXISTING, ThrottleReeval.NONE)
        if not cfgClosedLoop:
            # Open loop: run for a fixed time, wherever that leaves her.
            waitUntil(TRACER_BELOW or tracerDied, actDuration)
        elif tgtRow < 0:
            # Closed loop, off the edge: keep running until she is actually falling.
            waitUntil(TRACER_BELOW or tracerDied, actTimeout)
        else:
            # Closed loop: cut the throttle so she coasts to a stop on the cell centre.
            waitUntil(dotProduct(tgtPos - tracer.getPosition(), actDir) <= coastDist or TRACER_BELOW or tracerDied, actTimeout)
        tracer.stopThrottleInDirection()
        if tgtRow < 0:
            waitUntil(TRACER_BELOW or tracerDied, 1)
        else:
            waitUntil(tracer.getHorizontalSpeed() < 0.2 or TRACER_BELOW or tracerDied, 0.4)

    observeState()
    nextCell = obsCell
    nextS = obsS
    if tracerDied and not tracerDiedEnv and not TRACER_BELOW:
        terminal = true
        outcome = Outcome.KILLED
        reward += rKilled
    elif TRACER_BELOW or tracerDied:
        terminal = true
        outcome = Outcome.FELL
        reward += rFall
    elif nextCell == GOAL_CELL:
        terminal = true
        outcome = Outcome.GOAL
        reward += rGoal
        epEdgeSum += obsP.z - edgeZMin
    else:
        epEdgeSum += obsP.z - edgeZMin
        if epSteps + 1 >= cfgMaxSteps:
            terminal = true
            outcome = Outcome.TIMEOUT
            reward += rTimeout
    reward += rHit * (epHits - stepHits0)
