# ---------------------------------------------------------------------------
# Every global variable of the lab, declared in one place (OverPy needs a
# variable declared before the first file that uses it).
# ---------------------------------------------------------------------------

# environment/calibration.opy
globalvar calStage = 0
globalvar calMsg = "measuring the island"
globalvar floorY
globalvar isleCenter
globalvar edgeXMin
globalvar edgeXMax
globalvar edgeZMin
globalvar edgeZMax
globalvar probeDir
globalvar probeLo
globalvar probeHi
globalvar probeMid
globalvar runSpeed
globalvar coastDist
globalvar calP0
globalvar calP1
globalvar calT0

# environment/arena.opy
globalvar cell
globalvar gridOrigin
globalvar cellPos = []
globalvar startPos
globalvar goalPos
globalvar stripCenter
globalvar widowPos
globalvar hostPos
globalvar camEye
globalvar camLook
globalvar actDuration
globalvar actTimeout
globalvar tracer
globalvar widow
globalvar tracerDied = false
globalvar tracerDiedEnv = false
globalvar spawnTry
globalvar spawnCalls

# environment/cliffwalk.opy
globalvar curS
globalvar curA
globalvar curCell
globalvar nextS
globalvar nextA
globalvar nextCell
globalvar reward
globalvar terminal
globalvar outcome
globalvar stepCol
globalvar stepRow
globalvar tgtCol
globalvar tgtRow
globalvar tgtPos
globalvar actDir
globalvar obsP
globalvar obsCell
globalvar obsS
globalvar useHealthBit
globalvar useBlink
globalvar nAct
globalvar epSteps
globalvar epReturn
globalvar epEdgeSum
globalvar epHits = 0
globalvar stepHits0

# agents/tabular.opy
globalvar Q = []
globalvar polGlyph = []
globalvar selS
globalvar selA
globalvar selExplore
globalvar rowQ
globalvar rowMax
globalvar glyphS
globalvar tdTarget
globalvar qOld
globalvar isTraining = true
globalvar curExplore = false
globalvar nextExplore = false
globalvar demoPlan = [Act.IN, Act.IN, Act.IN, Act.FWD, Act.FWD, Act.FWD, Act.FWD, Act.FWD, Act.FWD, Act.FWD, Act.FWD, Act.FWD, Act.FWD, Act.FWD, Act.EDGE, Act.EDGE, Act.EDGE]

# agents/widowmaker.opy
globalvar nextShotT = 0
globalvar shotsFired = 0
globalvar episodeActive = false

# agents/experiment.opy
globalvar runId = 0
globalvar epCount = 0
globalvar cnt = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]   # [mode * 5 + outcome], mode 0 = training, 1 = evaluation
globalvar recentRet = []
globalvar recentSum = 0
globalvar histReturn = []
globalvar histOutcome = []
globalvar lastReturn = 0
globalvar lastOutcome = 0
globalvar lastSteps = 0
globalvar lastTraining = true
globalvar pendingReset = false
globalvar pendingAlgoSwitch = false
