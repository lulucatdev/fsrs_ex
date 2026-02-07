defmodule FsrsTest do
  use ExUnit.Case
  doctest Fsrs

  test "review_card/3 returns updated card and review log" do
    scheduler = Fsrs.new_scheduler(enable_fuzzing: false)
    card = Fsrs.new_card()

    {updated_card, review_log} = Fsrs.review_card(scheduler, card, :good)

    assert updated_card.last_review != nil
    assert DateTime.compare(updated_card.due, updated_card.last_review) == :gt
    assert review_log.card_id == card.card_id
    assert review_log.rating == :good
  end
end
