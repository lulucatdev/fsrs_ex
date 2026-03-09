defmodule FsrsTest do
  use ExUnit.Case
  doctest Fsrs

  describe "review_card/3" do
    test "returns updated card and review log" do
      scheduler = Fsrs.new_scheduler(enable_fuzzing: false)
      card = Fsrs.new_card()

      {updated_card, review_log} = Fsrs.review_card(scheduler, card, :good)

      assert updated_card.last_review != nil
      assert DateTime.compare(updated_card.due, updated_card.last_review) == :gt
      assert review_log.card_id == card.card_id
      assert review_log.rating == :good
    end

    test "all rating transitions work correctly" do
      scheduler = Fsrs.new_scheduler(enable_fuzzing: false)

      for rating <- Fsrs.Rating.all() do
        card = Fsrs.new_card()
        {updated_card, review_log} = Fsrs.review_card(scheduler, card, rating)

        assert updated_card.last_review != nil
        assert review_log.rating == rating
        assert is_number(updated_card.stability)
        assert is_number(updated_card.difficulty)
      end
    end

    test "learning to review state transition" do
      scheduler = Fsrs.new_scheduler(enable_fuzzing: false)
      card = Fsrs.new_card()

      # First review with :good should graduate card to review state
      {card, _} = Fsrs.review_card(scheduler, card, :good)
      assert card.state == :review
      assert card.step == nil
    end

    test "again rating moves card to relearning" do
      scheduler = Fsrs.new_scheduler(
        enable_fuzzing: false,
        relearning_steps: [600]
      )
      
      card = Fsrs.new_card(
        state: :review,
        stability: 5.0,
        difficulty: 5.0,
        last_review: DateTime.add(DateTime.utc_now(), -1, :day)
      )

      {card, _} = Fsrs.review_card(scheduler, card, :again)
      assert card.state == :relearning
      assert card.step == 0
    end
  end

  describe "scheduler options" do
    test "custom desired_retention" do
      scheduler = Fsrs.new_scheduler(desired_retention: 0.85, enable_fuzzing: false)
      assert scheduler.desired_retention == 0.85
    end

    test "custom learning steps" do
      scheduler = Fsrs.new_scheduler(
        learning_steps: [{:minutes, 1}, {:seconds, 300}],
        enable_fuzzing: false
      )
      assert scheduler.learning_steps == [60, 300]
    end

    test "custom maximum_interval" do
      scheduler = Fsrs.new_scheduler(maximum_interval: 1000, enable_fuzzing: false)
      assert scheduler.maximum_interval == 1000
    end

    test "invalid desired_retention raises error" do
      assert_raise ArgumentError, fn ->
        Fsrs.new_scheduler(desired_retention: 1.5)
      end

      assert_raise ArgumentError, fn ->
        Fsrs.new_scheduler(desired_retention: -0.1)
      end
    end

    test "invalid maximum_interval raises error" do
      assert_raise ArgumentError, fn ->
        Fsrs.new_scheduler(maximum_interval: 0)
      end

      assert_raise ArgumentError, fn ->
        Fsrs.new_scheduler(maximum_interval: -100)
      end
    end
  end

  describe "card creation" do
    test "new card defaults" do
      card = Fsrs.new_card()
      assert card.state == :learning
      assert card.step == 0
      assert card.stability == nil
      assert card.difficulty == nil
    end

    test "new card with custom values" do
      card = Fsrs.new_card(
        card_id: 12345,
        state: :review,
        stability: 10.0,
        difficulty: 7.5
      )
      assert card.card_id == 12345
      assert card.state == :review
      assert card.stability == 10.0
      assert card.difficulty == 7.5
    end

    test "card IDs are unique" do
      cards = for _ <- 1..100, do: Fsrs.new_card()
      ids = Enum.map(cards, &&1.card_id)
      assert length(Enum.uniq(ids)) == 100
    end
  end

  describe "serialization" do
    test "card round-trip serialization" do
      card = Fsrs.new_card(
        card_id: 12345,
        state: :review,
        stability: 10.0,
        difficulty: 7.5
      )

      json = Fsrs.Card.to_json(card)
      restored = Fsrs.Card.from_json(json)

      assert restored.card_id == card.card_id
      assert restored.state == card.state
      assert restored.stability == card.stability
      assert restored.difficulty == card.difficulty
    end

    test "scheduler round-trip serialization" do
      scheduler = Fsrs.new_scheduler(
        desired_retention: 0.85,
        enable_fuzzing: false,
        maximum_interval: 5000
      )

      json = Fsrs.Scheduler.to_json(scheduler)
      restored = Fsrs.Scheduler.from_json(json)

      assert restored.desired_retention == scheduler.desired_retention
      assert restored.enable_fuzzing == scheduler.enable_fuzzing
      assert restored.maximum_interval == scheduler.maximum_interval
    end

    test "review log round-trip serialization" do
      log = Fsrs.new_review_log(
        card_id: 123,
        rating: :good,
        review_datetime: ~U[2024-01-01 12:00:00Z],
        review_duration: 5000
      )

      json = Fsrs.ReviewLog.to_json(log)
      restored = Fsrs.ReviewLog.from_json(json)

      assert restored.card_id == log.card_id
      assert restored.rating == log.rating
      assert restored.review_duration == log.review_duration
    end
  end

  describe "retrievability calculation" do
    test "retrievability decreases over time" do
      scheduler = Fsrs.new_scheduler(enable_fuzzing: false)
      
      card = Fsrs.new_card(
        state: :review,
        stability: 5.0,
        last_review: ~U[2024-06-01 00:00:00Z]
      )

      r1 = Fsrs.get_card_retrievability(scheduler, card, ~U[2024-06-01 12:00:00Z])
      r2 = Fsrs.get_card_retrievability(scheduler, card, ~U[2024-06-02 00:00:00Z])
      r3 = Fsrs.get_card_retrievability(scheduler, card, ~U[2024-06-03 00:00:00Z])

      assert r1 > r2
      assert r2 > r3
      assert r1 <= 1.0
      assert r3 >= 0.0
    end

    test "retrievability is 0.0 for card without last_review" do
      scheduler = Fsrs.new_scheduler(enable_fuzzing: false)
      card = Fsrs.new_card()
      
      assert Fsrs.get_card_retrievability(scheduler, card) == 0.0
    end
  end

  describe "reschedule_card/3" do
    test "replaying logs restores correct card state" do
      scheduler = Fsrs.new_scheduler(enable_fuzzing: false)
      
      now = DateTime.utc_now()
      logs = [
        Fsrs.new_review_log(card_id: 1, rating: :good, review_datetime: DateTime.add(now, -2, :day)),
        Fsrs.new_review_log(card_id: 1, rating: :good, review_datetime: DateTime.add(now, -1, :day)),
        Fsrs.new_review_log(card_id: 1, rating: :hard, review_datetime: now)
      ]

      card = Fsrs.new_card(card_id: 1)
      result = Fsrs.reschedule_card(scheduler, card, logs)

      assert result.state == :review
      assert is_number(result.stability)
      assert is_number(result.difficulty)
    end

    test "reschedule_card validates card_id consistency" do
      scheduler = Fsrs.new_scheduler(enable_fuzzing: false)
      
      logs = [
        Fsrs.new_review_log(card_id: 2, rating: :good, review_datetime: DateTime.utc_now())
      ]

      card = Fsrs.new_card(card_id: 1)

      assert_raise ArgumentError, fn ->
        Fsrs.reschedule_card(scheduler, card, logs)
      end
    end
  end

  describe "enum helpers" do
    test "Rating conversions" do
      assert Fsrs.Rating.to_int(:again) == 1
      assert Fsrs.Rating.to_int(:easy) == 4
      assert Fsrs.Rating.from_int!(1) == :again
      assert Fsrs.Rating.from_int!(4) == :easy
      
      assert {:ok, :good} == Fsrs.Rating.from_int(3)
      assert :error == Fsrs.Rating.from_int(5)
      
      assert Fsrs.Rating.valid?(:good)
      assert not Fsrs.Rating.valid?(5)
    end

    test "State conversions" do
      assert Fsrs.State.to_int(:learning) == 1
      assert Fsrs.State.to_int(:relearning) == 3
      assert Fsrs.State.from_int!(1) == :learning
      assert Fsrs.State.from_int!(3) == :relearning
      
      assert {:ok, :review} == Fsrs.State.from_int(2)
      assert :error == Fsrs.State.from_int(0)
      
      assert Fsrs.State.valid?(:review)
      assert not Fsrs.State.valid?(:invalid)
    end
  end

  describe "performance" do
    @tag timeout: 5000
    test "handles batch card creation efficiently" do
      scheduler = Fsrs.new_scheduler(enable_fuzzing: false)
      
      cards = for _ <- 1..1000, do: Fsrs.new_card()
      
      results = Enum.map(cards, fn card ->
        {updated_card, _} = Fsrs.review_card(scheduler, card, :good)
        updated_card
      end)
      
      assert length(results) == 1000
      assert Enum.all?(results, &&(&1.state == :review))
    end
  end
end
