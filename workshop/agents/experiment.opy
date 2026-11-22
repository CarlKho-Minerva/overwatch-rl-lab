# ---------------------------------------------------------------------------
# The experiment loop: episodes, learning updates, counters.
# ---------------------------------------------------------------------------

macro RECENT_N = 20

def runEpisode():
    @Name "Experiment: one episode"
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
    while true:
        if pendingReset:
            pendingReset = false
            if pendingAlgoSwitch:
                pendingAlgoSwitch = false
                algo = 1 - algo
            resetLearning()
            logRunHeader()
            smallMessage(getAllPlayers(), "New run: Q-table cleared")
        if paused:
            waitUntil(not paused or pendingReset, 99999)
        else:
            runEpisode()
            wait(0.2)
