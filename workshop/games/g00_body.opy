/*
Game 0: the smallest game that uses every part of the shared core. It exists to prove the core in the real game.
The learner stands at home. One self-test, one event, one question, then the game ends.
*/
settings {
    "main": {
        "modeName": "RL course: core check",
        "description": "A test of the shared core of the RL course games. github.com/CarlKho-Minerva/overwatch-rl-lab"
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

#!define GAME_ID 0
#!define GAME_VERSION 1
#!define GAME_TITLE "RL 0: CORE CHECK"
#!define LEARNER_HERO Hero.TRACER
#!define HOME_POS vect(-12, 0, -15)

#!include "common.opy"

globalvar pad = vect(-6, 0, -15)

rule "Game 0: run":
    @Condition ready
    createEffect(getAllPlayers(), Effect.RING, Color.GREEN, pad, 1.5, EffectReeval.NONE)
    CHECK("two plus two", 4, 2 + 2)
    CHECK("bayes two readings", 0.941, 0.8 * 0.8 / (0.8 * 0.8 + 0.2 * 0.2))
    coach = "Walk onto the green ring."
    if AUTOPLAY:
        learner.startThrottleInDirection(vect(1, 0, 0), 1, Relativity.TO_WORLD, Throttle.REPLACE_EXISTING, ThrottleReeval.NONE)
    waitUntil(distance(learner.getPosition(), pad) < 1.5, 20)
    learner.stopThrottleInDirection()
    LOG("RLG,E,{},pad,{},{}".format(GAME_ID, distance(learner.getPosition(), pad) < 1.5, NOW))
    qId = 1
    qText = "A sensor that is right 8 times in 10 says WALL twice. How sure should she be?"
    qOpts = ["about 80%", "about 94%", "certain"]
    qCorrect = 1
    qAuto = 1
    qWhy = "0.8 x 0.8 against 0.2 x 0.2: about 94%."
    ask()
    putHome()
    LOG("RLG,E,{},home,{},{}".format(GAME_ID, distance(learner.getPosition(), HOME_POS) < 1.5, learner.fellCount))
    finish()
    coach = "Done. Core check finished."
