# ---------------------------------------------------------------------------
# Widowmaker: a predictable threat, driven only by Workshop hero controls.
# She always faces Tracer (set up in arena.opy). In the Widowmaker experiment
# she stays scoped and presses primary fire once every "seconds between shots",
# but only while Tracer is inside her firing range. The shot clock restarts at
# the beginning of every episode. In the other experiments she deals no damage
# and never fires.
# ---------------------------------------------------------------------------

rule "Widowmaker: scripted fire":
    @Condition calStage == 2
    @Condition cfgExperiment == Exp.WIDOW
    widow.startForcingButton(Button.SECONDARY_FIRE)
    while true:
        wait(0.048)
        if episodeActive and not paused and getTotalTimeElapsed() >= nextShotT:
            nextShotT = getTotalTimeElapsed() + cfgWidowInterval
            if tracer.isAlive() and distance(widow, tracer) <= cfgWidowRange:
                widow.setAmmo(0, 35)
                widow.forceButtonPress(Button.PRIMARY_FIRE)
                shotsFired += 1
