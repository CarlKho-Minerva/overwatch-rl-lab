"""Reference implementation of the tabular updates used in the Workshop script.

These functions are the specification. The Workshop code in
workshop/agents/experiment.opy is checked against them in two ways:
unit tests on hand-worked numbers, and a replay of real in-game step logs
(see replay.py).

This module is not a simulator. It never produces a transition.
"""

from __future__ import annotations

from typing import Sequence

SARSA = 0
Q_LEARNING = 1


def sarsa_target(reward: float, gamma: float, q_next_row: Sequence[float], next_action: int) -> float:
    """r + gamma * Q(s', a'), where a' is the action the agent will really take next."""
    return reward + gamma * q_next_row[next_action]


def q_learning_target(reward: float, gamma: float, q_next_row: Sequence[float], n_actions: int | None = None) -> float:
    """r + gamma * max_a Q(s', a), over the actions that are switched on."""
    row = q_next_row if n_actions is None else q_next_row[:n_actions]
    return reward + gamma * max(row)


def td_target(
    algo: int,
    reward: float,
    gamma: float,
    q_next_row: Sequence[float],
    next_action: int,
    terminal: bool,
    n_actions: int | None = None,
) -> float:
    """The learning target for one step. A terminal step never bootstraps."""
    if terminal:
        return reward
    if algo == SARSA:
        return sarsa_target(reward, gamma, q_next_row, next_action)
    if algo == Q_LEARNING:
        return q_learning_target(reward, gamma, q_next_row, n_actions)
    raise ValueError(f"unknown algorithm {algo!r}")


def td_update(q_old: float, alpha: float, target: float) -> float:
    """Q <- Q + alpha * (target - Q)."""
    return q_old + alpha * (target - q_old)


def greedy_actions(q_row: Sequence[float], n_actions: int | None = None, tol: float = 1e-4) -> list[int]:
    """Every action within tol of the best value. The game picks one of these at random."""
    row = list(q_row if n_actions is None else q_row[:n_actions])
    best = max(row)
    return [a for a, q in enumerate(row) if q >= best - tol]


def epsilon_greedy_probabilities(q_row: Sequence[float], epsilon: float, n_actions: int | None = None) -> list[float]:
    """Probability of each action under the behaviour policy used in the game.

    With probability epsilon the game draws uniformly over all actions (which can
    land on a greedy action too); otherwise it draws uniformly over the greedy set.
    """
    row = list(q_row if n_actions is None else q_row[:n_actions])
    n = len(row)
    best = greedy_actions(row)
    return [epsilon / n + ((1 - epsilon) / len(best) if a in best else 0.0) for a in range(n)]
