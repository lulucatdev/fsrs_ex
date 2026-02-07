defmodule Fsrs.SerializationTest do
  use ExUnit.Case, async: true

  test "Card JSON round-trip" do
    card =
      Fsrs.new_card(
        card_id: 100,
        state: :review,
        step: nil,
        stability: 12.34,
        difficulty: 6.78,
        due: ~U[2024-05-01 12:00:00Z],
        last_review: ~U[2024-04-30 12:00:00Z]
      )

    json = Fsrs.Card.to_json(card)
    decoded = Fsrs.Card.from_json(json)

    assert Fsrs.Card.to_map(decoded) == Fsrs.Card.to_map(card)
  end

  test "ReviewLog JSON round-trip" do
    review_log =
      Fsrs.new_review_log(
        card_id: 200,
        rating: :hard,
        review_datetime: ~U[2024-05-01 12:00:00Z],
        review_duration: 1234
      )

    json = Fsrs.ReviewLog.to_json(review_log)
    decoded = Fsrs.ReviewLog.from_json(json)

    assert Fsrs.ReviewLog.to_map(decoded) == Fsrs.ReviewLog.to_map(review_log)
  end

  test "Scheduler JSON round-trip" do
    scheduler =
      Fsrs.new_scheduler(
        desired_retention: 0.87,
        learning_steps: [30, 120],
        relearning_steps: [90],
        maximum_interval: 1000,
        enable_fuzzing: false
      )

    json = Fsrs.Scheduler.to_json(scheduler)
    decoded = Fsrs.Scheduler.from_json(json)

    assert Fsrs.Scheduler.to_map(decoded) == Fsrs.Scheduler.to_map(scheduler)
  end
end
