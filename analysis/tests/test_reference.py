"""Hand-worked checks of the tabular update maths."""

import math

import pytest

from rllab import reference as ref


def test_sarsa_target_uses_the_action_actually_taken_next():
    row = [1.0, 5.0, -2.0, 0.0]
    assert ref.sarsa_target(-1.0, 0.9, row, next_action=2) == pytest.approx(-1.0 + 0.9 * -2.0)


def test_q_learning_target_uses_the_best_next_action():
    row = [1.0, 5.0, -2.0, 0.0]
    assert ref.q_learning_target(-1.0, 0.9, row) == pytest.approx(-1.0 + 0.9 * 5.0)


def test_q_learning_ignores_actions_that_are_switched_off():
    # Column 4 is Blink. With Blink off (4 actions) its stale value must not count.
    row = [1.0, 2.0, 0.0, 0.0, 99.0]
    assert ref.q_learning_target(0.0, 1.0, row, n_actions=4) == pytest.approx(2.0)
    assert ref.q_learning_target(0.0, 1.0, row, n_actions=5) == pytest.approx(99.0)


@pytest.mark.parametrize("algo", [ref.SARSA, ref.Q_LEARNING])
def test_terminal_step_does_not_bootstrap(algo):
    row = [100.0, 100.0, 100.0, 100.0]
    assert ref.td_target(algo, -101.0, 1.0, row, next_action=0, terminal=True) == -101.0


def test_the_two_algorithms_agree_when_the_next_action_is_greedy():
    row = [0.5, 3.0, -1.0, 2.0]
    greedy = row.index(max(row))
    sarsa = ref.td_target(ref.SARSA, -1.0, 1.0, row, greedy, terminal=False)
    q_learning = ref.td_target(ref.Q_LEARNING, -1.0, 1.0, row, greedy, terminal=False)
    assert sarsa == pytest.approx(q_learning)


def test_the_two_algorithms_differ_only_when_the_next_action_is_exploratory():
    row = [0.5, 3.0, -1.0, 2.0]
    sarsa = ref.td_target(ref.SARSA, -1.0, 1.0, row, next_action=2, terminal=False)
    q_learning = ref.td_target(ref.Q_LEARNING, -1.0, 1.0, row, next_action=2, terminal=False)
    assert sarsa == pytest.approx(-2.0)
    assert q_learning == pytest.approx(2.0)


def test_td_update_moves_a_fraction_alpha_toward_the_target():
    assert ref.td_update(0.0, 0.5, -1.0) == pytest.approx(-0.5)
    assert ref.td_update(-0.5, 0.5, -1.0) == pytest.approx(-0.75)
    assert ref.td_update(4.0, 1.0, -3.0) == pytest.approx(-3.0)
    assert ref.td_update(4.0, 0.0, -3.0) == pytest.approx(4.0)


def test_the_cliff_edge_update_from_the_first_fall():
    # Step off the edge from a fresh table: reward -1 + -100, terminal.
    target = ref.td_target(ref.SARSA, -101.0, 1.0, [0, 0, 0, 0], 0, terminal=True)
    assert ref.td_update(0.0, 0.5, target) == pytest.approx(-50.5)


def test_greedy_ties_are_all_returned():
    assert ref.greedy_actions([0.0, 0.0, 0.0, 0.0]) == [0, 1, 2, 3]
    assert ref.greedy_actions([0.0, -0.5, 0.0, -1.0]) == [0, 2]
    assert ref.greedy_actions([0.0, -0.5, 0.0, -1.0, 7.0], n_actions=4) == [0, 2]


def test_epsilon_greedy_probabilities_sum_to_one_and_favour_the_greedy_action():
    probabilities = ref.epsilon_greedy_probabilities([0.0, 1.0, 0.0, 0.0], epsilon=0.1)
    assert math.isclose(sum(probabilities), 1.0)
    assert probabilities == pytest.approx([0.025, 0.925, 0.025, 0.025])


def test_epsilon_zero_is_purely_greedy_and_epsilon_one_is_uniform():
    assert ref.epsilon_greedy_probabilities([0.0, 1.0, 0.0, 0.0], 0.0) == pytest.approx([0, 1, 0, 0])
    assert ref.epsilon_greedy_probabilities([0.0, 1.0, 0.0, 0.0], 1.0) == pytest.approx([0.25] * 4)


def test_unknown_algorithm_is_an_error():
    with pytest.raises(ValueError):
        ref.td_target(7, 0.0, 1.0, [0.0], 0, terminal=False)
