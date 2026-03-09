defmodule Fsrs.Ecto.CardTypeTest do
  @moduledoc """
  Tests for Fsrs.Ecto.CardType.
  These tests are only run if Ecto is available.
  """

  use ExUnit.Case, async: true

  # Check if Ecto is available
  @ecto_available Code.ensure_loaded?(Ecto.Type)

  if @ecto_available do
    alias Fsrs.Ecto.CardType

    describe "CardType Ecto type" do
      test "type returns :map" do
        assert CardType.type() == :map
      end

      test "cast accepts Card structs" do
        card = Fsrs.new_card()
        assert {:ok, _} = CardType.cast(card)
      end

      test "cast accepts valid maps" do
        card = Fsrs.new_card()
        map = Fsrs.Card.to_dict(card)
        assert {:ok, _} = CardType.cast(map)
      end

      test "cast rejects invalid data" do
        assert :error = CardType.cast("invalid")
        assert :error = CardType.cast(123)
      end

      test "load converts map to Card" do
        card = Fsrs.new_card()
        map = Fsrs.Card.to_dict(card)
        assert {:ok, loaded_card} = CardType.load(map)
        assert %Fsrs.Card{} = loaded_card
        assert loaded_card.card_id == card.card_id
      end

      test "load returns error for invalid data" do
        assert :error = CardType.load("invalid")
        assert :error = CardType.load(%{invalid: "data"})
      end

      test "dump converts Card to map" do
        card = Fsrs.new_card()
        assert {:ok, map} = CardType.dump(card)
        assert is_map(map)
        assert map["card_id"] == card.card_id
      end

      test "dump returns error for non-Card" do
        assert :error = CardType.dump("invalid")
        assert :error = CardType.dump(%{card_id: 123})
      end

      test "embed_as returns :self" do
        assert CardType.embed_as(nil) == :self
      end

      test "equal? compares Cards correctly" do
        card1 = Fsrs.new_card(card_id: 1)
        card2 = Fsrs.new_card(card_id: 1)
        card3 = Fsrs.new_card(card_id: 2)

        assert CardType.equal?(card1, card2)
        refute CardType.equal?(card1, card3)
      end
    end
  else
    IO.puts("Skipping Ecto tests - Ecto not available")
  end
end
