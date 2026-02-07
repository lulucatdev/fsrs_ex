defmodule Fsrs.SchedulerPortTest do
  use ExUnit.Case, async: true

  test "default parameters match latest py-fsrs defaults" do
    parameters = Fsrs.default_parameters()

    assert tuple_size(parameters) == 21
    assert elem(parameters, 0) == 0.212
    assert elem(parameters, 20) == 0.1542
  end

  test "scheduler validates custom parameter count" do
    assert_raise ArgumentError, ~r/Expected 21 parameters/, fn ->
      Fsrs.new_scheduler(parameters: {1.0})
    end
  end

  test "scheduler validates parameter bounds" do
    invalid_parameters =
      Fsrs.default_parameters()
      |> Tuple.to_list()
      |> List.replace_at(20, 0.01)
      |> List.to_tuple()

    assert_raise ArgumentError, ~r/out of bounds/, fn ->
      Fsrs.new_scheduler(parameters: invalid_parameters)
    end
  end

  test "scheduler accepts tuple step units" do
    scheduler =
      Fsrs.new_scheduler(
        learning_steps: [{:minutes, 1}, {:seconds, 95}],
        relearning_steps: [{:seconds, 90}],
        enable_fuzzing: false
      )

    assert scheduler.learning_steps == [60, 95]
    assert scheduler.relearning_steps == [90]
  end

  test "scheduler rejects invalid step tuples" do
    assert_raise ArgumentError, ~r/invalid learning_steps entry/, fn ->
      Fsrs.new_scheduler(learning_steps: [{:hours, 1}], enable_fuzzing: false)
    end
  end

  test "reschedule_card/3 replays logs in chronological order" do
    scheduler = Fsrs.new_scheduler(enable_fuzzing: false)
    base_due = ~U[2024-01-01 00:00:00Z]
    card = Fsrs.new_card(card_id: 42, due: base_due)

    t1 = ~U[2024-01-01 00:00:00Z]
    t2 = ~U[2024-01-01 00:02:00Z]
    t3 = ~U[2024-01-04 12:00:00Z]

    log1 = Fsrs.new_review_log(card_id: 42, rating: :good, review_datetime: t1)
    log2 = Fsrs.new_review_log(card_id: 42, rating: :again, review_datetime: t2)
    log3 = Fsrs.new_review_log(card_id: 42, rating: :good, review_datetime: t3)

    result = Fsrs.reschedule_card(scheduler, card, [log3, log1, log2])

    expected_card =
      [log1, log2, log3]
      |> Enum.sort_by(&DateTime.to_unix(&1.review_datetime, :microsecond))
      |> Enum.reduce(Fsrs.new_card(card_id: 42, due: base_due), fn log, acc_card ->
        {updated_card, _review_log} =
          Fsrs.review_card(scheduler, acc_card, log.rating, log.review_datetime)

        updated_card
      end)

    assert Fsrs.Card.to_map(result) == Fsrs.Card.to_map(expected_card)
  end

  test "reschedule_card/3 rejects review logs from another card" do
    scheduler = Fsrs.new_scheduler(enable_fuzzing: false)
    card = Fsrs.new_card(card_id: 1, due: ~U[2024-01-01 00:00:00Z])

    bad_log =
      Fsrs.new_review_log(card_id: 2, rating: :good, review_datetime: ~U[2024-01-01 00:00:00Z])

    assert_raise ArgumentError, ~r/does not match card card_id/, fn ->
      Fsrs.reschedule_card(scheduler, card, [bad_log])
    end
  end
end
