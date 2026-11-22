# Defaults of the Night School build. A variant redefines the few it wants to change, then includes night.opy.
#!define BUILD_VERSION 205
#!define DEF_BOTS_PER_TEAM 5
#!define DEF_MOVE_SPEED 200
#!define DEF_EVAL_EPS 10
# No bot starts a new run after this many minutes of a block; runs in progress finish.
#!define DEF_SOFT_MIN 14
#!define DEF_RUN_MAX_MIN 18
#!define DEF_AUTO_RESTART true
# Per-step lines (for checking the update arithmetic) are logged for this many steps at the start of each run.
#!define STEP_LOG_STEPS 30
#!define CAM_HEIGHT 38
#!define CAM_BACK 16
#!define CAM_LOOK_Z 1

# The conditions, one column each. Lecture numbers refer to David Silver's 2015 UCL course.
#   SARSA, Q-learning, Expected SARSA            Lecture 5 (model-free control)
#   Q-learning with decaying exploration         Lecture 5 (GLIE) and Lecture 9
#   Q-learning from optimistic starting values   Lecture 9 (optimism in the face of uncertainty)
#   Dyna-Q, 20 imagined updates per real step    Lecture 8 (learning and planning)
#   Monte Carlo control                          Lectures 4 and 5
#   SARSA(lambda)                                Lectures 4 and 5 (eligibility traces)
#   Q-learning with a count bonus                Lecture 9
#   Random walk + TD(0) and Monte Carlo values   Lectures 1, 2 and 4 (prediction)
#   Planner: value iteration on the rules        Lecture 3 (dynamic programming)
#   REINFORCE with a baseline                    Lecture 7 (policy gradient)
#   One-step actor-critic                        Lecture 7
#   Monte Carlo control from optimistic values   Lectures 5 and 9 (added after plain Monte Carlo learned to jump)
#!define CONDITION_COUNT 14
#!define CONDITION_NAMES ["SARSA", "Q-LEARNING", "EXPECTED SARSA", "Q + FADING EXPLORATION", "Q + OPTIMISM", "DYNA-Q", "MONTE CARLO", "SARSA LAMBDA", "Q + COUNT BONUS", "RANDOM WALK", "PLANNER", "POLICY GRADIENT", "ACTOR-CRITIC", "MONTE CARLO + OPTIMISM"]
#!define CONDITION_ALGOS [0, 1, 2, 1, 1, 3, 4, 5, 1, 6, 7, 8, 9, 4]
#!define CONDITION_EPS [0.1, 0.1, 0.1, -1, 0, 0.1, 0.1, 0.1, 0, 1, 0, 0, 0, 0.1]
#!define CONDITION_ALPHAS [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.2, 0.3, 0.5, 0.1, 0, 0.02, 0.1, 0.2]
#!define CONDITION_QINITS [0, 0, 0, 0, 40, 0, 0, 0, 0, 0, 0, 0, 0, 40]
#!define CONDITION_PLANS [0, 0, 0, 0, 0, 20, 0, 0, 0, 0, 0, 0, 0, 0]
#!define CONDITION_LAMBDAS [0, 0, 0, 0, 0, 0, 0, 0.8, 0, 0, 0, 0, 0, 0]
#!define CONDITION_BONUSES [0, 0, 0, 0, 0, 0, 0, 0, 10, 0, 0, 0, 0, 0]
#!define CONDITION_TRAIN_EPS [150, 150, 150, 150, 150, 150, 150, 150, 150, 300, 40, 150, 150, 150]

# Golden test only (night_golden.opy): a scripted walk and a fixed condition offset.
#!define SCRIPTED false
#!define SCRIPT_PLAN [0]
#!define FORCE_OFFSET (-1)
