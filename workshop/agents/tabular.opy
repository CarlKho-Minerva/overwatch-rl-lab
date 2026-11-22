# ---------------------------------------------------------------------------
# Tabular agent: one Q-table, epsilon-greedy behaviour, two learning targets.
#
# Q is a flat array: Q[s * NA + a].
# SARSA      target = r + gamma * Q(s', a')          a' = the action actually chosen next
# Q-learning target = r + gamma * max_a Q(s', a)
# Terminal   target = r                              (no bootstrapping)
#
# Both algorithms pick a' the same way and before the update, so the only
# difference between them is the target line in experiment.opy.
# ---------------------------------------------------------------------------

macro ACTION_GLYPHS = ["→", "←", "↓", "↑", "»"]
macro ACTION_NAMES = ["FORWARD", "BACK", "INLAND", "EDGE", "BLINK"]

def chooseAction():
    @Name "Agent: epsilon-greedy action for state selS (random tie-break)"
    if cfgExperiment == Exp.DEMO:
        selA = demoPlan[min(epSteps, len(demoPlan) - 1)]
        selExplore = false
        return
    rowQ = Q.slice(selS * NA, nAct)
    rowMax = sorted(rowQ).last()
    selA = random.choice([0, 1, 2, 3, 4].slice(0, nAct).filter(lambda a: rowQ[a] >= rowMax - 0.0001))
    selExplore = false
    if isTraining and random.uniform(0, 1) < epsilon:
        selA = random.randint(0, nAct - 1)
        selExplore = true

def updateGlyph():
    @Name "Agent: refresh the policy arrow for cell glyphS"
    rowQ = Q.slice(glyphS * NA, nAct)
    rowMax = sorted(rowQ).last()
    if sorted(rowQ)[0] == rowMax:
        polGlyph[glyphS] = "·"
    else:
        polGlyph[glyphS] = ACTION_GLYPHS[rowQ.index(rowMax)]

def resetLearning():
    @Name "Agent: new run (clear the Q-table and the counters)"
    useHealthBit = cfgExperiment == Exp.WIDOW and cfgObserveHealth
    useBlink = cfgBlink and cfgExperiment != Exp.DEMO
    nAct = 5 if useBlink else 4
    Q = []
    Q[NSTATES * NA - 1] = 0
    if cfgQInit != 0:
        Q = Q.map(lambda q: cfgQInit)
    for i in range(NCELLS):
        polGlyph[i] = "·"
    polGlyph[GOAL_CELL] = "G"
    runId += 1
    epCount = 0
    cnt = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    recentRet = []
    recentSum = 0
    histReturn = []
    histOutcome = []
    lastReturn = 0
    lastOutcome = Outcome.RUNNING
    lastSteps = 0
