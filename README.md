# Overwatch RL Lab

Reinforcement learning experiments that run inside the real Overwatch 2, on Workshop Island.
A Tracer bot learns to cross a strip along the island's edge by trial and error. A wrong step
sends her off the island for real, and the game's own physics decide what each move does.
You watch the policy form as arrows on the floor, switch between SARSA and Q-learning, and take
the logs out for analysis.

There is no simulator in this repository. All movement, falling, shooting and dying happen in the
game, driven by an official Workshop script. Python is used only to read the game's log files.

![SARSA training on Workshop Island, episode 9](docs/img/2026-11-21_sarsa_training_episode9.jpg)

*A real screenshot (Overwatch 2.25.1.0, 2026-11-21). The red line is the island's edge. Arrows are
the action Tracer currently rates best in each cell; dots are cells she has not learned about.*

## Run it in five minutes

1. In Overwatch: Options > Gameplay > General, turn on **Enable Workshop Inspector** and
   **Enable Workshop Inspector Log File**.
2. Copy all of [`workshop/compiled/overwatch-rl-lab.txt`](workshop/compiled/overwatch-rl-lab.txt).
3. Play > More > Custom Games > Create. Set the lobby to **Invite Only**.
4. Settings > the orange paste button in the Summary panel > Confirm.
   (Parameters live in the Workshop Settings tile that appears on the same screen.)
5. Esc > Start. Pick any hero.

Six seconds later Tracer starts her first episode. Full steps, controls and troubleshooting:
[`docs/setup.md`](docs/setup.md).

## What you can change

In the lobby under Settings > Workshop Settings (the orange hammer tile): algorithm (SARSA or Q-learning), learning rate
alpha, discount gamma, exploration epsilon, every reward, the step limit, cell size, Tracer's
speed, closed-loop or fixed-duration moves, Widowmaker's shot interval, range and damage, whether
Tracer can see her own health, Blink as a fifth action, and what gets logged.

While it runs (default keys): F pause, R training / greedy evaluation, E switch algorithm,
hold Q new run, V overhead camera, Crouch + mouse buttons epsilon down / up.

## The first experiment

> Does an agent trained with SARSA learn to stay farther from the edge of Workshop Island than one
> trained with Q-learning, when both keep exploring?

Both explore the same way and both learn from every step, falls included. They differ in one line
of the script: SARSA scores a move by the action Tracer will really take next, Q-learning by the
best action available next. [`labs/lab02.md`](labs/lab02.md) walks through it.

### First run of it (2026-11-21, one run per algorithm)

![Learning curves from the two recorded runs](analysis/figures/learning_curves.png)

| Last 40 training episodes | SARSA | Q-learning |
|---|---|---|
| Mean return | +18.2 | -1.3 |
| Episodes ending in a fall | 4 of 40 | 10 of 40 |
| Mean distance from the edge | 3.88 m | 2.40 m |

While both were still exploring, the SARSA Tracer kept about a cell and a half further from the
drop and fell less than half as often. With exploration switched off afterwards, the Q-learning
table gave 12 clean crossings out of 12 in 13 steps; the SARSA table sent her pacing between two
cells until the step limit. Each algorithm was run once and the Workshop has no random seed, so
this is a lead to repeat, not a finding (a 4-against-10 gap in 40 can come from chance: Fisher
exact p = 0.14). Logs: [`data/logs/`](data/logs). Full table:
[`docs/verification.md`](docs/verification.md).

| SARSA after 62 episodes | Q-learning after 118 episodes |
|---|---|
| ![SARSA policy](docs/img/2026-11-21_sarsa_learned_policy_episode62.jpg) | ![Q-learning policy](docs/img/2026-11-21_qlearning_learned_policy_episode118.jpg) |

*Left: SARSA's arrows lead inland from the start and back out at the goal. Right: Q-learning's
arrows run straight along the edge row.*

## Labs

| Lab | Question |
|---|---|
| [01](labs/lab01.md) | How much does exploration cost on a route with a drop beside it? |
| [02](labs/lab02.md) | SARSA against Q-learning on the edge |
| [03](labs/lab03.md) | What the learning rate does to speed and stability |
| [04](labs/lab04.md) | Reward changes that produce behaviour you did not ask for |
| [05](labs/lab05.md) | Widowmaker, and what happens when Tracer cannot see her own health |

Each lab has a prediction to write down first, one setting to change, what to watch in the game,
a graph to make from your log, a reflection question and a 3 to 5 line coding exercise.

## How it works

- The script measures the island with ray casts every match; no coordinates are hard-coded
  ([`docs/calibration.md`](docs/calibration.md)).
- State = which of 48 cells (4 rows by 12 columns, 2 m each) Tracer stands in. Actions = forward,
  back, inland, toward the edge. One action = one real run of about a third of a second
  ([`docs/architecture.md`](docs/architecture.md)).
- The Q-table, the epsilon-greedy choice and both learning targets are Workshop code:
  [`workshop/agents/`](workshop/agents).
- Logs: [`docs/logging.md`](docs/logging.md). Platform limits: [`docs/limitations.md`](docs/limitations.md).

## What has been checked, and how

[`docs/verification.md`](docs/verification.md) lists every claim with its evidence, split into
"run in Overwatch", "compiled and unit-tested only" and "not checked".

The strongest check: with per-step logging on, the game writes each transition and the Q-value
before and after its own update. `analysis/rllab/replay.py` applies the textbook update to the
same transitions and compares every number.

```powershell
npm install; npm run build                 # compile the OverPy source
python -m venv .venv
.venv\Scripts\python -m pip install numpy pandas matplotlib pytest nbclient nbformat ipykernel
.venv\Scripts\python -m pytest -q          # reference maths + replay of the real logs in data/logs
```

## Repository

```
workshop/      OverPy source (main.opy, environment/, agents/, ui/), test variants, compiled Workshop text
analysis/      rllab (log parser, reference maths, replay check, plots), tests, notebook, figures
data/logs/     Log files written by Overwatch during the verification sessions
labs/          Five guided labs
docs/          Setup, calibration, architecture, logging, limitations, verification
tools/         Build script, notebook generator
```

## Rules this project keeps

Private custom games only. No injection into the game process, no memory reading, no automated
input into gameplay, nothing that touches matchmaking. The bots are moved by Workshop actions on
Blizzard's servers. Not affiliated with Blizzard Entertainment.

Built with [OverPy](https://github.com/Zezombye/overpy) 9.7.21. MIT licence.
