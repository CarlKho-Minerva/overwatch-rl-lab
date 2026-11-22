# ---------------------------------------------------------------------------
# The in-game dashboard: HUD text, policy arrows on the floor, arena markers.
# The arrows are drawn for the overhead camera: up = toward the edge.
# ---------------------------------------------------------------------------

macro EXP_NAMES = ["CLIFF WALK", "CLIFF WALK + WIDOWMAKER", "ARENA DEMO"]
macro ALGO_NAMES = ["SARSA", "Q-LEARNING"]
macro OUTCOME_NAMES = ["-", "GOAL", "FELL", "TIMEOUT", "KILLED"]

rule "UI: dashboard":
    # Left: what is running.
    hudText(getAllPlayers(), "Overwatch RL Lab", null, null, HudPosition.LEFT, 0, Color.ORANGE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, "{} | {}".format(EXP_NAMES[cfgExperiment], "SCRIPTED" if cfgExperiment == Exp.DEMO else ALGO_NAMES[algo]), null, HudPosition.LEFT, 1, Color.WHITE, Color.SKY_BLUE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, "PAUSED" if paused else ("TRAINING" if isTraining else "GREEDY EVALUATION"), null, HudPosition.LEFT, 2, Color.WHITE, Color.LIGHT_RED if paused else (Color.GREEN if isTraining else Color.YELLOW), Color.WHITE, HudReeval.VISIBILITY_SORT_ORDER_STRING_AND_COLOR)
    hudText(getAllPlayers(), null, null, "alpha {}   gamma {}   epsilon {}\nrewards: step {}  goal {}  fall {}".format(alpha, gamma, epsilon, rStep, rGoal, rFall), HudPosition.LEFT, 3, Color.WHITE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, null, "status: {}".format(calMsg), HudPosition.LEFT, 4, Color.WHITE, Color.WHITE, Color.LIGHT_RED if calStage == -1 else Color.WHITE, HudReeval.VISIBILITY_SORT_ORDER_STRING_AND_COLOR)

    # Top: the current episode.
    hudText(getAllPlayers(), null, "run {}  episode {}  step {}  return {}".format(runId, epCount + 1, epSteps, epReturn), null, HudPosition.TOP, 0, Color.WHITE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, null, "last episode: {} in {} steps, return {}   |   mean return of last {}: {}".format(OUTCOME_NAMES[lastOutcome], lastSteps, lastReturn, len(recentRet), recentSum / max(1, len(recentRet))), HudPosition.TOP, 1, Color.WHITE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, null, "action: {}{}".format(ACTION_NAMES[curA], " (exploring)" if curExplore else ""), HudPosition.TOP, 2, Color.WHITE, Color.WHITE, Color.ORANGE if curExplore else Color.WHITE, HudReeval.VISIBILITY_SORT_ORDER_STRING_AND_COLOR)

    # Right: counts and controls.
    hudText(getAllPlayers(), null, "Training episodes", "goal {}   fell {}   timeout {}   killed {}".format(cnt[Outcome.GOAL], cnt[Outcome.FELL], cnt[Outcome.TIMEOUT], cnt[Outcome.KILLED]), HudPosition.RIGHT, 0, Color.WHITE, Color.GREEN, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, "Evaluation episodes", "goal {}   fell {}   timeout {}   killed {}".format(cnt[5 + Outcome.GOAL], cnt[5 + Outcome.FELL], cnt[5 + Outcome.TIMEOUT], cnt[5 + Outcome.KILLED]), HudPosition.RIGHT, 1, Color.WHITE, Color.YELLOW, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, null, "{} pause   {} train/eval   {} switch algorithm\nhold {} new run   {} camera\n{}+{} / {}+{} epsilon -/+".format(buttonToString(Button.INTERACT), buttonToString(Button.RELOAD), buttonToString(Button.ABILITY_2), buttonToString(Button.ULTIMATE), buttonToString(Button.MELEE), buttonToString(Button.CROUCH), buttonToString(Button.PRIMARY_FIRE), buttonToString(Button.CROUCH), buttonToString(Button.SECONDARY_FIRE)), HudPosition.RIGHT, 2, Color.WHITE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)

rule "UI: calibration HUD":
    @Condition cfgShowCal
    hudText(getAllPlayers(), null, null, "island x {} to {}, z {} to {}, floor y {}\ncell {} m, run speed {} m/s, coast {} m\nhost at {}".format(edgeXMin, edgeXMax, edgeZMin, edgeZMax, floorY, cell, runSpeed, coastDist, hostPlayer.getPosition()), HudPosition.LEFT, 10, Color.WHITE, Color.WHITE, Color.GRAY, HudReeval.VISIBILITY_AND_STRING)

rule "UI: arena markers and policy arrows":
    @Condition calStage >= 1
    # Grid outline. The red side is the real island edge.
    createBeam(getAllPlayers(), Beam.BAD, gridOrigin + vect(0, 0.1, 0), gridOrigin + vect(NCOLS * cell, 0.1, 0), Color.RED, EffectReeval.NONE)
    createBeam(getAllPlayers(), Beam.GRAPPLE, gridOrigin + vect(0, 0.1, NROWS * cell), gridOrigin + vect(NCOLS * cell, 0.1, NROWS * cell), Color.WHITE, EffectReeval.NONE)
    createBeam(getAllPlayers(), Beam.GRAPPLE, gridOrigin + vect(0, 0.1, 0), gridOrigin + vect(0, 0.1, NROWS * cell), Color.WHITE, EffectReeval.NONE)
    createBeam(getAllPlayers(), Beam.GRAPPLE, gridOrigin + vect(NCOLS * cell, 0.1, 0), gridOrigin + vect(NCOLS * cell, 0.1, NROWS * cell), Color.WHITE, EffectReeval.NONE)
    createEffect(getAllPlayers(), Effect.RING, Color.SKY_BLUE, startPos, cell / 2, EffectReeval.NONE)
    createEffect(getAllPlayers(), Effect.RING, Color.GREEN, goalPos, cell / 2, EffectReeval.NONE)
    createEffect(getAllPlayers(), Effect.LIGHT_SHAFT, Color.GREEN, goalPos, cell / 2, EffectReeval.NONE)
    if cfgExperiment == Exp.WIDOW:
        createEffect(getAllPlayers(), Effect.RING, Color.RED, widowPos, cfgWidowRange, EffectReeval.NONE)
    for j in range(NCELLS):
        polGlyph[j] = "·"
        createInWorldText(getAllPlayers(), polGlyph[evalOnce(j)], cellPos[j] + vect(0, 0.4, 0), 2, Clip.NONE, WorldTextReeval.VISIBILITY_AND_STRING, Color.GREEN if j == GOAL_CELL else Color.WHITE)
        if j % 12 == 11:
            wait()
    polGlyph[GOAL_CELL] = "G"
