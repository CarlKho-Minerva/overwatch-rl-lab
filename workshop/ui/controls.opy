# ---------------------------------------------------------------------------
# Live controls for the host (the human who created the lobby).
#   Interact            pause / resume
#   Reload              switch between training and greedy evaluation (from the next episode)
#   Ability 2           switch SARSA <-> Q-learning and start a new run (clears the Q-table)
#   Ultimate (hold 1 s) start a new run with the same algorithm (clears the Q-table)
#   Melee               overhead camera on / off
#   Crouch + Primary    epsilon - 0.05
#   Crouch + Secondary  epsilon + 0.05
# The host is phased out, so the bots cannot hit or block them.
# ---------------------------------------------------------------------------

rule "Host: place the observer":
    @Event eachPlayer
    @Condition eventPlayer.isDummy() == false
    @Condition eventPlayer.hasSpawned()
    @Condition eventPlayer.isAlive()
    @Condition calStage >= 1
    wait(0.25)
    eventPlayer.setStatusEffect(null, Status.PHASED_OUT, 9999)
    eventPlayer.teleport(hostPos)
    eventPlayer.setFacing(directionTowards(hostPos + vect(0, 1.5, 0), stripCenter), Relativity.TO_WORLD)
    if camOn:
        eventPlayer.startCamera(camEye, camLook, 0)

rule "Host: Interact = pause / resume":
    @Event eachPlayer
    @Condition eventPlayer == hostPlayer
    @Condition eventPlayer.isHoldingButton(Button.INTERACT)
    paused = not paused

rule "Host: Reload = training / greedy evaluation":
    @Event eachPlayer
    @Condition eventPlayer == hostPlayer
    @Condition eventPlayer.isHoldingButton(Button.RELOAD)
    @Condition cfgExperiment != Exp.DEMO
    wantTraining = not wantTraining
    smallMessage(getAllPlayers(), "Next episode: {}".format("training" if wantTraining else "greedy evaluation"))

rule "Host: Ability 2 = switch algorithm (new run)":
    @Event eachPlayer
    @Condition eventPlayer == hostPlayer
    @Condition eventPlayer.isHoldingButton(Button.ABILITY_2)
    @Condition cfgExperiment != Exp.DEMO
    pendingAlgoSwitch = not pendingAlgoSwitch
    pendingReset = true

rule "Host: hold Ultimate 1 s = new run":
    @Event eachPlayer
    @Condition eventPlayer == hostPlayer
    @Condition eventPlayer.isHoldingButton(Button.ULTIMATE)
    wait(1, Wait.ABORT_WHEN_FALSE)
    pendingReset = true

rule "Host: Melee = overhead camera":
    @Event eachPlayer
    @Condition eventPlayer == hostPlayer
    @Condition eventPlayer.isHoldingButton(Button.MELEE)
    @Condition calStage >= 1
    camOn = not camOn
    if camOn:
        eventPlayer.startCamera(camEye, camLook, 0)
    else:
        eventPlayer.stopCamera()

rule "Host: Crouch + Primary = less exploration":
    @Event eachPlayer
    @Condition eventPlayer == hostPlayer
    @Condition eventPlayer.isHoldingButton(Button.CROUCH)
    @Condition eventPlayer.isHoldingButton(Button.PRIMARY_FIRE)
    epsilon = max(0, epsilon - 0.05)

rule "Host: Crouch + Secondary = more exploration":
    @Event eachPlayer
    @Condition eventPlayer == hostPlayer
    @Condition eventPlayer.isHoldingButton(Button.CROUCH)
    @Condition eventPlayer.isHoldingButton(Button.SECONDARY_FIRE)
    epsilon = min(1, epsilon + 0.05)
