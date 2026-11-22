settings {
    "main": {
        "modeName": "Overwatch RL Lab",
        "description": "Tabular SARSA and Q-learning on Workshop Island. A Tracer dummy bot learns a cliff walk on the real island edge. github.com/CarlKho-Minerva/overwatch-rl-lab"
    },
    "gamemodes": {
        "skirmish": {
            "enabledMaps": [
                DEF_MAP
            ]
        },
        "general": {
            "heroLimit": "off",
            "enableKillCam": false,
            "spawnHealthPacks": "disabled"
        }
    }
}

#!include "environment/config.opy"
#!include "environment/state.opy"
#!include "environment/calibration.opy"
#!include "environment/arena.opy"
#!include "environment/cliffwalk.opy"
#!include "agents/tabular.opy"
#!include "agents/widowmaker.opy"
#!include "agents/experiment.opy"
#!include "ui/controls.opy"
#!include "ui/hud.opy"
#!include "ui/logging.opy"
