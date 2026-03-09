defmodule Fsrs.Ecto.CardType do
  @moduledoc """
  Ecto type for Fsrs.Card serialization.

  This module implements the `Ecto.Type` behaviour to allow storing
  Fsrs.Card structs in database fields (typically as JSON/BSON).

  ## Usage

      schema "cards" do
        field :fsrs_data, Fsrs.Ecto.CardType
      end

  The card is stored as a JSON object with all fields serialized.

  中文说明：为 Fsrs.Card 实现的 Ecto 类型，支持数据库存储。
  """

  use Ecto.Type

  alias Fsrs.Card

  @impl true
  def type, do: :map

  @impl true
  def cast(%Card{} = card) do
    {:ok, Card.to_dict(card)}
  end

  def cast(%{} = map) do
    try do
      {:ok, Card.from_dict(map)}
    rescue
      _ -> :error
    end
  end

  def cast(_), do: :error

  @impl true
  def load(data) when is_map(data) do
    try do
      {:ok, Card.from_dict(data)}
    rescue
      _ -> :error
    end
  end

  def load(_), do: :error

  @impl true
  def dump(%Card{} = card) do
    {:ok, Card.to_dict(card)}
  end

  def dump(_), do: :error

  @impl true
  def embed_as(_format), do: :self

  @impl true
  def equal?(term1, term2) do
    term1 == term2
  end
end
