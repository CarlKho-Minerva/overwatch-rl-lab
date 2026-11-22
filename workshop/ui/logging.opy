# ---------------------------------------------------------------------------
# Logging through the Workshop Inspector ("Log To Inspector").
# Every line starts with RLLAB so the analysis script can find it in the log
# file that Overwatch writes when "Enable Workshop Inspector Log File" is on.
# The Workshop prints numbers with two decimals, so alpha, gamma and epsilon
# are logged times 1000 as whole numbers. Column lists: docs/logging.md.
# ---------------------------------------------------------------------------

def logRunHeader():
    @Name "Log: run header"
    logToInspector("RLLAB,CAL,{},{},{},{},{},{},{},{},{}".format(floorY, edgeXMin, edgeXMax, edgeZMin, edgeZMax, cell, runSpeed, coastDist, actDuration))
    logToInspector("RLLAB,RUN,{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{}".format(runId, cfgExperiment, algo, cfgQInit, rStep, rGoal, rFall, rTimeout, rKilled, rHit, cfgMaxSteps, cfgClosedLoop, useHealthBit, useBlink, nAct, cfgMoveSpeed, cfgSlowMo))

def logEpisode():
    @Name "Log: one line per episode"
    logToInspector("RLLAB,EP,{},{},{},{},{},{},{},{},{},{},{},{},{}".format(runId, epCount, algo, 0 if isTraining else 1, round(epsilon * 1000), round(alpha * 1000), round(gamma * 1000), epReturn, epSteps, outcome, epEdgeSum / max(1, epSteps), epHits, getTotalTimeElapsed()))

def logStep():
    @Name "Log: one line per step (verification)"
    logToInspector("RLLAB,STEP,{},{},{},{},{},{},{},{},{},{},{},{},{}".format(runId, epCount + 1, epSteps, curS, curA, reward, nextS, nextA, terminal, curExplore, qOld, Q[curS * NA + curA], tdTarget))

def logQTable():
    @Name "Log: the Q-table rows that have been updated"
    for i in range(NSTATES):
        if sorted(Q.slice(i * NA, NA))[0] != cfgQInit or sorted(Q.slice(i * NA, NA)).last() != cfgQInit:
            logToInspector("RLLAB,Q,{},{},{},{},{},{},{},{}".format(runId, epCount, i, Q[i * NA], Q[i * NA + 1], Q[i * NA + 2], Q[i * NA + 3], Q[i * NA + 4]))
        if i % 8 == 7:
            wait()
