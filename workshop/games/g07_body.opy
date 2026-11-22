/*
Game 7: Counter-Pick (Lecture 7, policy gradient).

The player picks Tracer, Widowmaker or Pharah each round (left click, right click, melee). In this game Tracer beats
Widowmaker, Widowmaker beats Pharah, Pharah beats Tracer: the game's own rule, a rock-paper-scissors triangle.
The bot keeps no scores for moves. It keeps three preferences, turns them into odds with a softmax, draws its pick
from those odds (before he picks), and after the round nudges the preferences by REINFORCE with a baseline:
    h[j] += alpha * (reward - baseline) * ((1 if j == pick else 0) - p[j])
    baseline += 0.25 * (reward - baseline)
Phase A: 6 rounds of the same hero. Phase B: a fresh bot, free play, 5 rounds at nudge size 0.6, then 4 at 2.5.
Design note: gNN.md. Reference maths and log check: analysis/tests/test_game_07.py.
*/
settings {
    "main": {
        "modeName": "RL course 7: Counter-Pick",
        "description": "Lecture 7, policy gradient: a bot learns to counter-pick you by nudging its odds. github.com/CarlKho-Minerva/overwatch-rl-lab"
    },
    "lobby": {
        "team1Slots": 6,
        "team2Slots": 6
    },
    "gamemodes": {
        "skirmish": {
            "enabledMaps": [
                "workshopIsland"
            ]
        },
        "general": {
            "heroLimit": "off",
            "enableKillCam": false,
            "spawnHealthPacks": "disabled"
        }
    }
}

#!define GAME_ID 7
#!define GAME_VERSION 1
#!define GAME_TITLE "RL 7: COUNTER-PICK"
#!define LEARNER_HERO Hero.SOLDIER
#!define HOME_POS vect(0, 0, -8)
#!define HOME_FACING vect(0, 0, 1)
#!define STOPS 8

#!include "common.opy"

macro ALPHA_SMALL = 0.6
macro ALPHA_BIG = 2.5
macro BETA = 0.25
macro N_A = 6
macro N_B1 = 5
macro N_B2 = 4
macro HIDE_POS = vect(0, -60, 0)
# The bot's reward for its pick b against the player's pick y: Tracer 0 beats Widowmaker 1, Widowmaker 1 beats
# Pharah 2, Pharah 2 beats Tracer 0. So b beats y when y == (b + 1) % 3.
macro REWARD(b, y):
    (1 if (y) == ((b) + 1) % 3 else (-1 if (b) == ((y) + 1) % 3 else 0))
# How much a perfect counter-picker wins (wins minus losses, per round) against a mix f of Tracer, Widow, Pharah.
# Its best answer is Tracer (f[1] - f[2]), Widowmaker (f[2] - f[0]) or Pharah (f[0] - f[1]).
macro EXPLOIT(f):
    max((f)[1] - (f)[2], max((f)[2] - (f)[0], (f)[0] - (f)[1]))

globalvar heroName = ["TRACER", "WIDOWMAKER", "PHARAH"]
globalvar botPos = [vect(-5, 0, 4), vect(0, 0, 4), vect(5, 0, 4)]
globalvar youPos = [vect(-5, 0, -4), vect(0, 0, -4), vect(5, 0, -4)]
globalvar autoPicks = [0, 0, 0, 0, 0, 0, 1, 2, 0, 2, 1, 0, 1, 2, 0]
globalvar botH = [0, 0, 0]
globalvar botP = [0.3333333, 0.3333333, 0.3333333]
globalvar smMax
globalvar smE = []
globalvar smS
globalvar base = 0
globalvar alpha = ALPHA_SMALL
globalvar adv
globalvar dPick
globalvar li
globalvar bPick = 0
globalvar bR = 0
globalvar drawK
globalvar drawU
globalvar youPick = -1
globalvar habit = -1
globalvar pickOpen = false
globalvar timedOut = 0
globalvar rnd = 0
globalvar phase = 0
globalvar roundsLeft
globalvar pBefore = [0, 0, 0]
globalvar cntB = [0, 0, 0]
globalvar nB = 0
globalvar youF = [0, 0, 0]
globalvar exYou = 0
globalvar exBot = 0
globalvar exF = [0, 0, 0]
globalvar winsYou = 0
globalvar winsBot = 0
globalvar draws = 0
globalvar botFx = vect(0, -60, 0)
globalvar youFx = vect(0, -60, 0)
globalvar worldTxt = ["", "", ""]
globalvar barTxt = ["", "", ""]
globalvar info = ["", "", "", ""]
globalvar nDummies = 0
globalvar holdT

subroutine softmax
subroutine learn
subroutine getPick
subroutine playRound
subroutine buildTexts
subroutine resetBot

def softmax():
    @Name "Game 7: the bot's odds from its preferences (softmax)"
    smMax = max(botH[0], max(botH[1], botH[2]))
    smE = botH.map(lambda x: 2.718281828 ** (x - smMax))
    smS = smE[0] + smE[1] + smE[2]
    botP = smE.map(lambda x: x / smS)

def learn():
    @Name "Game 7: REINFORCE with a baseline: push the pick by (reward minus usual) times its surprise"
    # botP holds the odds the pick was drawn from.
    adv = bR - base
    dPick = alpha * adv * (1 - botP[bPick])
    for li in range(3):
        botH[li] += alpha * adv * ((1 if li == bPick else 0) - botP[li])
    base += BETA * (bR - base)
    softmax()

def resetBot():
    @Name "Game 7: a fresh bot, even odds"
    botH = [0, 0, 0]
    base = 0
    softmax()

def buildTexts():
    @Name "Game 7: rebuild the screen strings once, when something changes"
    worldTxt = ["{}: {}%".format(heroName[0], round(botP[0] * 100)), "{}: {}%".format(heroName[1], round(botP[1] * 100)), "{}: {}%".format(heroName[2], round(botP[2] * 100))]
    barTxt = ["bot picks TRACER {}%".format(round(botP[0] * 100)), "bot picks WIDOWMAKER {}%".format(round(botP[1] * 100)), "bot picks PHARAH {}%".format(round(botP[2] * 100))]
    exF = botP
    exBot = EXPLOIT(exF)

def getPick():
    @Name "Game 7: wait for the player's pick (left click, right click, melee), outside of questions"
    learner.disallowButton(Button.PRIMARY_FIRE)
    learner.disallowButton(Button.SECONDARY_FIRE)
    learner.disallowButton(Button.MELEE)
    youPick = -1
    # A button still held from the last answer must not count as a pick.
    waitUntil(not (learner.isHoldingButton(Button.PRIMARY_FIRE) or learner.isHoldingButton(Button.SECONDARY_FIRE) or learner.isHoldingButton(Button.MELEE)), 5)
    wait(0.25)
    pickOpen = true
    if AUTOPLAY:
        wait(0.4)
        youPick = autoPicks[rnd]
    else:
        # No time limit for a person: the game is played beside its lecture's page, and he may be reading it.
        waitUntil(youPick >= 0 or gameOver, 99999)
    pickOpen = false
    if youPick < 0:
        # 2026-11-22: in the same-hero rounds a random pick had a 2 in 3 chance of not matching, and the round then
        # asked again, two minutes at a time. A timed-out pick there is the hero already chosen.
        youPick = habit if (phase == 0 and habit >= 0) else random.randint(0, 2)
        timedOut += 1
        coach = "No pick came, so one was made for you."

def playRound():
    @Name "Game 7: one round: the bot locks in from its odds, the player picks, reveal, the bot learns"
    softmax()
    pBefore = botP
    # The bot draws first, from its odds only (it never sees his pick). Logged so the test can redo it.
    drawK = random.randint(0, 999)
    drawU = (drawK + 0.5) / 1000
    bPick = 0 if drawU < botP[0] else (1 if drawU < botP[0] + botP[1] else 2)
    botFx = HIDE_POS
    youFx = HIDE_POS
    # The last result stays in the coach line while he picks again; the round number lives in the controls row.
    info[0] = "Round {}: LEFT CLICK Tracer, RIGHT CLICK Widowmaker, MELEE Pharah.".format(rnd + 1)
    getPick()
    if phase == 0:
        if habit < 0:
            habit = youPick
        while youPick != habit:
            coach = "Same hero for these rounds: keep picking {}.".format(heroName[habit])
            getPick()
    youFx = youPos[youPick]
    botFx = botPos[bPick]
    bR = REWARD(bPick, youPick)
    if bR > 0:
        winsBot += 1
    elif bR < 0:
        winsYou += 1
    else:
        draws += 1
    LOG("RLG,E,{},pick,{},{},{},{},{},{}".format(GAME_ID, rnd + 1, phase, youPick, drawK, bPick, bR))
    LOG("RLG,E,{},odds,{},{},{},{},{},{}".format(GAME_ID, rnd + 1, pBefore[0], pBefore[1], pBefore[2], alpha, base))
    info[1] = "Round {}: you {}, bot {}: {}. You {}, bot {}, draws {}.".format(rnd + 1, heroName[youPick], heroName[bPick], "Bot wins" if bR > 0 else ("You win" if bR < 0 else "Draw"), winsYou, winsBot, draws)
    coach = "{} had {}%, scored {} vs its usual {}: preference moves {} x {} x {} = {}.".format(heroName[bPick], round(pBefore[bPick] * 100), bR, base, alpha, bR - base, 1 - pBefore[bPick], alpha * (bR - base) * (1 - pBefore[bPick]))
    learn()
    LOG("RLG,E,{},pref,{},{},{},{},{}".format(GAME_ID, rnd + 1, botH[0], botH[1], botH[2], base))
    if phase > 0:
        cntB[youPick] += 1
        nB += 1
        youF = [cntB[0] / nB, cntB[1] / nB, cntB[2] / nB]
        exF = youF
        exYou = EXPLOIT(exF)
        exF = botP
        exBot = EXPLOIT(exF)
        LOG("RLG,E,{},mix,{},{},{},{},{},{}".format(GAME_ID, rnd + 1, youF[0], youF[1], youF[2], exYou, exBot))
        info[2] = "Your mix: TRACER {}%, WIDOWMAKER {}%, PHARAH {}%.".format(round(youF[0] * 100), round(youF[1] * 100), round(youF[2] * 100))
        info[3] = "A perfect counter-picker would net {} wins minus losses per 100 rounds vs it.".format(round(exYou * 100))
    buildTexts()
    rnd += 1
    wait(0.5 if AUTOPLAY else 2)

rule "Game 7: pick Tracer (left click)":
    @Event eachPlayer
    @Condition eventPlayer == learner
    @Condition pickOpen
    @Condition qActive == false
    @Condition eventPlayer.isHoldingButton(Button.PRIMARY_FIRE)
    youPick = 0

rule "Game 7: pick Widowmaker (right click)":
    @Event eachPlayer
    @Condition eventPlayer == learner
    @Condition pickOpen
    @Condition qActive == false
    @Condition eventPlayer.isHoldingButton(Button.SECONDARY_FIRE)
    youPick = 1

rule "Game 7: pick Pharah (melee)":
    @Event eachPlayer
    @Condition eventPlayer == learner
    @Condition pickOpen
    @Condition qActive == false
    @Condition eventPlayer.isHoldingButton(Button.MELEE)
    youPick = 2

rule "Game 7: back home after a fall":
    @Condition ready
    @Condition learner.fell
    putHome()
    learner.setFacing(vect(0, 0, 1), Relativity.TO_WORLD)

rule "Game 7: the screen":
    @Condition ready
    hudText(getAllPlayers(), null, null, info[0], HudPosition.LEFT, 3, Color.WHITE, Color.WHITE, Color.YELLOW, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, null, info[1], HudPosition.LEFT, 4, Color.WHITE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, null, info[2], HudPosition.LEFT, 5, Color.WHITE, Color.WHITE, Color.SKY_BLUE, HudReeval.VISIBILITY_AND_STRING)
    hudText(getAllPlayers(), null, null, info[3], HudPosition.LEFT, 6, Color.WHITE, Color.WHITE, Color.SKY_BLUE, HudReeval.VISIBILITY_AND_STRING)
    # Right block: one slot per row, every row at most 36% of the screen wide (slots on one row sit side by side).
    hudText(getAllPlayers(), "THIS GAME'S RULE", null, null, HudPosition.RIGHT, 0, Color.ORANGE, Color.WHITE, Color.WHITE, HudReeval.NONE)
    hudText(getAllPlayers(), null, null, "Tracer beats Widowmaker beats Pharah beats Tracer", HudPosition.RIGHT, 1, Color.WHITE, Color.WHITE, Color.WHITE, HudReeval.NONE)
    hudText(getAllPlayers(), null, null, "(made for this game, not real Overwatch)", HudPosition.RIGHT, 2, Color.WHITE, Color.WHITE, Color.WHITE, HudReeval.NONE)
    hudText(getAllPlayers(), "BOT'S ODDS FOR ITS NEXT PICK", null, null, HudPosition.RIGHT, 3, Color.YELLOW, Color.WHITE, Color.WHITE, HudReeval.NONE)
    progressBarHud(getAllPlayers(), botP[0] * 100, barTxt[0], HudPosition.RIGHT, 4, Color.ORANGE, Color.WHITE, ProgressHudReeval.VISIBILITY_AND_VALUES)
    progressBarHud(getAllPlayers(), botP[1] * 100, barTxt[1], HudPosition.RIGHT, 5, Color.LIGHT_PURPLE, Color.WHITE, ProgressHudReeval.VISIBILITY_AND_VALUES)
    progressBarHud(getAllPlayers(), botP[2] * 100, barTxt[2], HudPosition.RIGHT, 6, Color.BLUE, Color.WHITE, ProgressHudReeval.VISIBILITY_AND_VALUES)

rule "Game 7: run":
    @Condition ready
    # The arena: the bot's three heroes in a row ahead, the player's three picks on the floor in front of him.
    for li in range(3):
        createDummy([Hero.TRACER, Hero.WIDOWMAKER, Hero.PHARAH][li], learner.getTeam(), -1, botPos[li], vect(0, 0, -1))
        wait(0.3)
        createEffect(getAllPlayers(), Effect.RING, Color.WHITE, youPos[li], 1.2, EffectReeval.NONE)
    nDummies = len([p for p in getPlayers(learner.getTeam()) if p.isDummy() and p != learner])
    createInWorldText(getAllPlayers(), worldTxt[0], botPos[0] + vect(0, 2.8, 0), 2.5, Clip.NONE, WorldTextReeval.VISIBILITY_AND_STRING, Color.ORANGE)
    createInWorldText(getAllPlayers(), worldTxt[1], botPos[1] + vect(0, 2.8, 0), 2.5, Clip.NONE, WorldTextReeval.VISIBILITY_AND_STRING, Color.LIGHT_PURPLE)
    createInWorldText(getAllPlayers(), worldTxt[2], botPos[2] + vect(0, 2.8, 0), 2.5, Clip.NONE, WorldTextReeval.VISIBILITY_AND_STRING, Color.BLUE)
    createInWorldText(getAllPlayers(), "you: TRACER (left click)", youPos[0] + vect(0, 0.4, 0), 1.6, Clip.NONE, WorldTextReeval.NONE, Color.ORANGE)
    createInWorldText(getAllPlayers(), "you: WIDOWMAKER (right click)", youPos[1] + vect(0, 0.4, 0), 1.6, Clip.NONE, WorldTextReeval.NONE, Color.LIGHT_PURPLE)
    createInWorldText(getAllPlayers(), "you: PHARAH (melee)", youPos[2] + vect(0, 0.4, 0), 1.6, Clip.NONE, WorldTextReeval.NONE, Color.BLUE)
    createEffect(getAllPlayers(), Effect.LIGHT_SHAFT, Color.YELLOW, botFx, 1.2, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
    createEffect(getAllPlayers(), Effect.RING, Color.YELLOW, botFx, 1.6, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
    createEffect(getAllPlayers(), Effect.LIGHT_SHAFT, Color.GREEN, youFx, 1.0, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
    putHome()
    learner.setFacing(vect(0, 0, 1), Relativity.TO_WORLD)
    LOG("RLG,E,{},arena,{},{}".format(GAME_ID, nDummies, learner.getTeam() == Team.1))

    # Self-tests: every formula the game uses, through the same subroutines and macros.
    botH = [0, 0, 0]
    softmax()
    CHECK("softmax even odds", 0.333, botP[0])
    botH = [1, 0, 0]
    softmax()
    CHECK("softmax one preference ahead", 0.576, botP[0])
    botH = [0, 0, 0]
    softmax()
    base = 0
    alpha = ALPHA_SMALL
    bPick = 2
    bR = 1
    learn()
    CHECK("reinforce win pushes the pick up", 0.4, botH[2])
    CHECK("reinforce win pushes the others down", -0.2, botH[0])
    CHECK("baseline moves a quarter of the way", 0.25, base)
    CHECK("pharah beats tracer", 1, REWARD(2, 0))
    CHECK("tracer beats widowmaker", -1, REWARD(1, 0))
    CHECK("same hero is a draw", 0, REWARD(1, 1))
    exF = [1, 0, 0]
    CHECK("all tracer is fully exploitable", 1, EXPLOIT(exF))
    exF = [0.3333333, 0.3333333, 0.3333333]
    CHECK("a third each cannot be exploited", 0, EXPLOIT(exF))
    exF = [0.5, 0.5, 0]
    CHECK("half tracer half widow", 0.5, EXPLOIT(exF))
    CHECK("epsilon greedy picks its best", 0.933, 0.9 + 0.1 / 3)
    resetBot()
    alpha = ALPHA_SMALL
    buildTexts()

    info[0] = "PICK: LEFT CLICK Tracer, RIGHT CLICK Widowmaker, MELEE Pharah."
    # Stop 1: the first prediction. Each stop opens on something that waits for him (a question or a pick), since
    # he may still be reading the page; the intro lines stay on screen while the question waits.
    STOP(1)
    coach = "Counter-picking: the bot keeps only three odds (bars on the right) and learns to beat the hero you repeat."
    if AUTOPLAY:
        wait(2)

    # Phase A: one hero, again and again.
    qId = 1
    qText = "You will pick the same hero 6 rounds in a row. What will the bot's three bars do?"
    qOpts = ["stay near a third", "your counter climbs", "your hero climbs"]
    qCorrect = 1
    qAuto = 1
    qWhy = "It nudges up whatever won. Against one hero, only that hero's counter keeps winning."
    ask()
    phase = 0
    STOP(2)
    info[2] = "The push: nudge size x (reward minus its usual) x (1 minus the pick's odds)."
    coach = "The bot locks in a hidden pick first. Pick any hero, then keep picking it. Watch the bars."
    if AUTOPLAY:
        wait(1)
    for roundsLeft in range(N_A):
        playRound()
    coach = "It moved odds, not scores. Odds per move are a policy; learning them directly is a policy gradient."
    wait(1 if AUTOPLAY else 8)
    coach = "Its rule, REINFORCE: push up what beat its usual reward, more if the pick was a surprise."
    wait(1 if AUTOPLAY else 8)

    # Lecture 5 reach-back: randomness sprayed against randomness aimed.
    STOP(3)
    qId = 2
    qText = "Lecture 5's bot took its best-scored hero, and a random hero one time in ten. Where did its randomness go?"
    qOpts = ["evenly onto all three", "onto heroes that did well", "nowhere"]
    qCorrect = 0
    qAuto = 0
    qWhy = "Evenly: best hero 93%, others 3% each, whatever they earned. This bot aims its odds."
    ask()

    # Why the best policy can need randomness.
    STOP(4)
    qId = 3
    qText = "A bot that must pick by a fixed rule (always Pharah, or Tracer, Widow, Pharah in turn). What beats it?"
    qOpts = ["nothing, if the rule is clever", "anyone who spots the rule", "only luck"]
    qCorrect = 1
    qAuto = 1
    qWhy = "Any fixed rule can be read and countered every round. Random odds cannot be read."
    ask()
    coach = "Silver's other case: two squares look alike, so one fixed move fails in one. A coin flip escapes."
    wait(1 if AUTOPLAY else 8)

    STOP(5)
    qId = 4
    qText = "Which mix of your own picks can no counter-picker beat on average?"
    qOpts = ["a third each", "mostly the hero that wins", "the same hero, always"]
    qCorrect = 0
    qAuto = 0
    qWhy = "A third each: every counter wins as often as it loses (Silver's rock-paper-scissors)."
    ask()

    # Phase B: free play against a fresh bot; his own mix is measured.
    STOP(6)
    resetBot()
    alpha = ALPHA_SMALL
    phase = 1
    buildTexts()
    LOG("RLG,E,{},reset,{},{}".format(GAME_ID, rnd, alpha))
    info[2] = "Your mix appears here after each round of free play."
    coach = "Free play against a fresh bot, odds back to a third each. Try to leave it nothing to learn."
    if AUTOPLAY:
        wait(1)
    for roundsLeft in range(N_B1):
        playRound()

    STOP(7)
    qId = 5
    qText = "For the last 4 rounds the nudge size goes from 0.6 to 2.5. What will the bars do?"
    qOpts = ["swing hard", "settle near a third", "move as before"]
    qCorrect = 0
    qAuto = 1
    qWhy = "Big steps overreact to one lucky round; near 100% the surprise is tiny, so it sticks."
    ask()
    alpha = ALPHA_BIG
    phase = 2
    buildTexts()
    coach = "Nudge size 2.5 now. Keep playing your mix."
    if AUTOPLAY:
        wait(1)
    for roundsLeft in range(N_B2):
        playRound()
    LOG("RLG,E,{},score,{},{},{},{}".format(GAME_ID, winsYou, winsBot, draws, timedOut))

    # Debrief.
    STOP(8)
    pickOpen = false
    botFx = HIDE_POS
    youFx = HIDE_POS
    info[0] = "What you did: played habits; a bot that keeps only odds learned to counter them."
    info[1] = "What it is called: policy gradient, REINFORCE with a baseline, softmax policy."
    info[2] = "In a language model: temperature spreads its odds over words,"
    info[3] = "and training nudges up the outputs that scored well."
    coach = "You got {} of {} predictions right. Simplified: one situation, one-round episodes, no critic.".format(predRight, predTotal)
    wait(1 if AUTOPLAY else 3)
    finish()
