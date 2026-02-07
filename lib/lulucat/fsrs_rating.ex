defmodule Fsrs.Rating do
  @moduledoc """
  Enum representing the four possible ratings when reviewing a card.
  表示复习卡片时四种可能评分的枚举。
  """

  @type t :: :again | :hard | :good | :easy

  @doc """
  Returns all possible card ratings
  返回所有可能的卡片评分
  """
  def all, do: [:again, :hard, :good, :easy]

  @doc """
  Converts an atom rating to its integer representation
  将原子评分转换为其整数表示
  """
  @spec to_int(t()) :: integer()
  def to_int(:again), do: 1
  def to_int(:hard), do: 2
  def to_int(:good), do: 3
  def to_int(:easy), do: 4

  @doc """
  Converts an integer to its atom rating representation
  将整数转换为其原子评分表示
  """
  @spec from_int(integer()) :: t()
  def from_int(1), do: :again
  def from_int(2), do: :hard
  def from_int(3), do: :good
  def from_int(4), do: :easy
end
