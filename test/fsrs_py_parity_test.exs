defmodule Fsrs.PyParityTest do
  use ExUnit.Case, async: true

  @fixture_path Path.expand("fixtures/py_fsrs_v6_3_0_fixture.json", __DIR__)
  @float_delta 1.0e-12

  test "default scheduler dict matches py-fsrs fixture" do
    fixture = fixture_data()

    scheduler = Fsrs.new_scheduler(enable_fuzzing: false)

    assert Fsrs.Scheduler.to_dict(scheduler) == fixture["scheduler_default_dict"]
  end

  test "step tuple normalization matches py-fsrs scheduler dict" do
    fixture = fixture_data()

    scheduler =
      Fsrs.new_scheduler(
        desired_retention: 0.87,
        learning_steps: [{:minutes, 1}, {:seconds, 95}, {:minutes, 5}],
        relearning_steps: [{:seconds, 90}, {:minutes, 15}],
        maximum_interval: 4000,
        enable_fuzzing: false
      )

    assert Fsrs.Scheduler.to_dict(scheduler) == fixture["scheduler_custom_dict"]
  end

  test "from_json and from_dict interoperate with py-fsrs payloads" do
    fixture = fixture_data()

    scheduler = Fsrs.Scheduler.from_json(fixture["scheduler_custom_json"])
    assert Fsrs.Scheduler.to_dict(scheduler) == fixture["scheduler_custom_dict"]

    card = Fsrs.Card.from_json(fixture["card_sample_json"])
    assert Fsrs.Card.to_dict(card) == fixture["card_sample_dict"]

    review_log = Fsrs.ReviewLog.from_json(fixture["review_log_sample_json"])
    assert Fsrs.ReviewLog.to_dict(review_log) == fixture["review_log_sample_dict"]
  end

  test "review trace matches py-fsrs card and log outputs" do
    fixture = fixture_data()

    scheduler = Fsrs.new_scheduler(enable_fuzzing: false)
    review_trace = fixture["review_trace"]

    initial_card = Fsrs.new_card(card_id: 4242, due: parse_datetime!("2024-01-01T08:00:00+00:00"))

    _final_card =
      Enum.reduce(review_trace, initial_card, fn entry, card ->
        rating = int_rating_to_atom(entry["rating"])
        review_datetime = parse_datetime!(entry["review_datetime"])
        review_duration = entry["review_duration"]

        {updated_card, review_log} =
          Fsrs.review_card(scheduler, card, rating, review_datetime, review_duration)

        assert_card_matches(updated_card, entry["card"])
        assert_review_log_matches(review_log, entry["review_log"])

        updated_card
      end)
  end

  test "reschedule_card matches py-fsrs fixture output" do
    fixture = fixture_data()
    reschedule = fixture["reschedule"]

    scheduler = Fsrs.new_scheduler(enable_fuzzing: false)
    card = Fsrs.Card.from_dict(reschedule["input_card"])
    review_logs = Enum.map(reschedule["input_logs_unsorted"], &Fsrs.ReviewLog.from_dict/1)

    result_card = Fsrs.reschedule_card(scheduler, card, review_logs)

    assert_card_matches(result_card, reschedule["result_card"])
  end

  test "retrievability points match py-fsrs day-based behavior" do
    fixture = fixture_data()

    scheduler = Fsrs.new_scheduler(enable_fuzzing: false)

    card =
      Fsrs.new_card(
        card_id: 888,
        state: :review,
        step: nil,
        stability: 2.5,
        difficulty: 5.0,
        due: parse_datetime!("2024-06-01T00:00:00+00:00"),
        last_review: parse_datetime!("2024-06-01T00:00:00+00:00")
      )

    retrievability = fixture["retrievability"]

    Enum.each(retrievability, fn point ->
      current_datetime = parse_datetime!(point["current_datetime"])
      expected = point["value"]

      actual = Fsrs.get_card_retrievability(scheduler, card, current_datetime)

      assert_in_delta actual, expected, @float_delta
    end)
  end

  defp fixture_data do
    @fixture_path
    |> File.read!()
    |> Jason.decode!()
  end

  defp parse_datetime!(iso8601) do
    {:ok, dt, _offset} = DateTime.from_iso8601(iso8601)
    dt
  end

  defp int_rating_to_atom(1), do: :again
  defp int_rating_to_atom(2), do: :hard
  defp int_rating_to_atom(3), do: :good
  defp int_rating_to_atom(4), do: :easy

  defp assert_card_matches(card, expected_map) do
    assert card.card_id == expected_map["card_id"]
    assert Fsrs.State.to_int(card.state) == expected_map["state"]
    assert card.step == expected_map["step"]
    assert_optional_float(card.stability, expected_map["stability"])
    assert_optional_float(card.difficulty, expected_map["difficulty"])

    assert DateTime.compare(card.due, parse_datetime!(expected_map["due"])) == :eq

    if expected_map["last_review"] do
      assert DateTime.compare(card.last_review, parse_datetime!(expected_map["last_review"])) ==
               :eq
    else
      assert card.last_review == nil
    end
  end

  defp assert_review_log_matches(review_log, expected_map) do
    assert review_log.card_id == expected_map["card_id"]
    assert Fsrs.Rating.to_int(review_log.rating) == expected_map["rating"]

    assert DateTime.compare(
             review_log.review_datetime,
             parse_datetime!(expected_map["review_datetime"])
           ) == :eq

    assert review_log.review_duration == expected_map["review_duration"]
  end

  defp assert_optional_float(nil, nil), do: :ok

  defp assert_optional_float(actual, expected) do
    assert_in_delta actual, expected, @float_delta
  end
end
