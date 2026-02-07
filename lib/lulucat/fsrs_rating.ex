defmodule Fsrs.Rating do
  @moduledoc """
  Rating enum used in FSRS review events.

  Mapping:

  - `:again` => `1`
  - `:hard` => `2`
  - `:good` => `3`
  - `:easy` => `4`

  中文说明：复习评分枚举，支持原子与整数映射。
  """

  @type t :: :again | :hard | :good | :easy

  @doc """
  Returns all possible ratings.

  中文说明：返回全部评分值。
  """
  def all, do: [:again, :hard, :good, :easy]

  @doc """
  Converts atom rating to integer representation.

  中文说明：原子评分转整数。
  """
  @spec to_int(t()) :: integer()
  def to_int(:again), do: 1
  def to_int(:hard), do: 2
  def to_int(:good), do: 3
  def to_int(:easy), do: 4

  @doc """
  Converts integer rating to atom representation.

  中文说明：整数评分转原子。
  """
  @spec from_int(integer()) :: t()
  def from_int(1), do: :again
  def from_int(2), do: :hard
  def from_int(3), do: :good
  def from_int(4), do: :easy
end
