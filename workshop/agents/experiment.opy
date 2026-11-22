# ---------------------------------------------------------------------------
# The experiment loop: episodes, learning updates, counters.
# ---------------------------------------------------------------------------

macro RECENT_N = 20

def botLost():
    @Name "Experiment: a bot has left the match - stop and say so"
    # Bot slots look empty in the lobby, so a player moved onto one removes the bot. Seen 2026-11-21:
    # the lab kept logging episodes for a Tracer that no longer existed. Never run on a missing bot.
    episodeActive = false
    calStage = -1
    calMsg = "a bot left the match (was a player moved onto its slot?). Esc > Show Lobby > Restart Match"
    logToInspector("RLLAB,FAIL,botlost,{},{},{},{}".format(runId, epCount + 1, entityExists(tracer), entityExists(widow)))
    bigMessage(getAllPlayers(), "RL Lab stopped: a bot left the match")

def runEpisode():
    @Name "Experiment: one episode"
    if not entityExists(tracer) or not entityExists(widow):
        botLost()
        return
    isTraining = wantTraining and cfgExperiment != Exp.DEMO
    if isTraining != lastTraining:
        recentRet = []
        recentSum = 0
        lastTraining = isTraining
    resetTracer()
    epSteps = 0
    epReturn = 0
    epEdgeSum = 0
    epHits = 0
    observeState()
    curS = obsS
    curCell = obsCell
    selS = curS
    chooseAction()
    curA = selA
    curExplore = selExplore
    terminal = false
    nextShotT = getTotalTimeElapsed() + cfgWidowInterval
    episodeActive = true
    while not terminal:
        stepEnv()
        if not entityExists(tracer) or not entityExists(widow):
            # The step just taken cannot be trusted. Drop the episode: no update, no EP line.
            botLost()
            return
        epSteps += 1
        epReturn += reward
        if terminal:
            # Terminal step: the target is the reward alone.
            tdTarget = reward
        else:
            # Choose a' now, with the behaviour policy, for both algorithms.
            selS = nextS
            chooseAction()
            nextA = selA
            nextExplore = selExplore
            if algo == Algo.SARSA:
                tdTarget = reward + gamma * Q[nextS * NA + nextA]
            else:
                tdTarget = reward + gamma * sorted(Q.slice(nextS * NA, nAct)).last()
        qOld = Q[curS * NA + curA]
        if isTraining:
            Q[curS * NA + curA] = qOld + alpha * (tdTarget - qOld)
            if curS < NCELLS and curS != GOAL_CELL:
                glyphS = curS
                updateGlyph()
        if cfgLogSteps:
            logStep()
        curS = nextS
        curCell = nextCell
        curA = nextA
        curExplore = nextExplore
        if paused and not terminal:
            waitUntil(not paused, 99999)
    episodeActive = false
    tracer.stopThrottleInDirection()

    epCount += 1
    cnt[(0 if isTraining else 1) * 5 + outcome] += 1
    lastReturn = epReturn
    lastOutcome = outcome
    lastSteps = epSteps
    recentRet.append(epReturn)
    recentSum += epReturn
    if len(recentRet) > RECENT_N:
        recentSum -= recentRet[0]
        del recentRet[0]
    if len(histReturn) < 990:
        histReturn.append(epReturn)
        histOutcome.append(outcome)
    logEpisode()
    if cfgLogQEvery > 0 and epCount % cfgLogQEvery == 0:
        logQTable()

rule "Experiment: main loop":
    @Condition calStage == 2
    resetLearning()
    logRunHeader()
    if WARM_START:
        # Carry over a Q-table exported from the Workshop Inspector in an earlier match.
        Q = WARM_Q
        for glyphS in range(NCELLS):
            if glyphS != GOAL_CELL:
                updateGlyph()
        logToInspector("RLLAB,WARM,{},{}".format(runId, len(Q)))
        logQTable()
    while calStage == 2:
        if pendingReset:
            pendingReset = false
            if pendingAlgoSwitch:
                pendingAlgoSwitch = false
                algo = 1 - algo
            # A new run starts in training: evaluating an empty table teaches nothing.
            wantTraining = true
            resetLearning()
            logRunHeader()
            smallMessage(getAllPlayers(), "New run: Q-table cleared, training")
        if paused:
            waitUntil(not paused or pendingReset, 99999)
        else:
            runEpisode()
            wait(0.2)
