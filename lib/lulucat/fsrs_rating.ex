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
  Returns `{:ok, rating}` on success, `:error` on invalid input.

  中文说明：整数评分转原子，成功返回 `{:ok, rating}`，无效输入返回 `:error`。

  ## Examples

      iex> Fsrs.Rating.from_int(1)
      {:ok, :again}
      
      iex> Fsrs.Rating.from_int(5)
      :error
  """
  @spec from_int(integer()) :: {:ok, t()} | :error
  def from_int(1), do: {:ok, :again}
  def from_int(2), do: {:ok, :hard}
  def from_int(3), do: {:ok, :good}
  def from_int(4), do: {:ok, :easy}
  def from_int(_), do: :error

  @doc """
  Converts integer rating to atom representation.
  Raises `ArgumentError` on invalid input.

  中文说明：整数评分转原子，无效输入抛出 `ArgumentError`。

  ## Examples

      iex> Fsrs.Rating.from_int!(1)
      :again
      
      iex> Fsrs.Rating.from_int!(5)
      ** (ArgumentError) invalid rating: 5, expected 1-4
  """
  @spec from_int!(integer()) :: t()
  def from_int!(n) do
    case from_int(n) do
      {:ok, rating} -> rating
      :error -> raise ArgumentError, "invalid rating: #{n}, expected 1-4"
    end
  end

  @doc """
  Checks if the given value is a valid rating.

  中文说明：检查给定值是否为有效评分。

  ## Examples

      iex> Fsrs.Rating.valid?(:good)
      true
      
      iex> Fsrs.Rating.valid?(5)
      false
  """
  @spec valid?(t() | integer()) :: boolean()
  def valid?(:again), do: true
  def valid?(:hard), do: true
  def valid?(:good), do: true
  def valid?(:easy), do: true
  def valid?(n) when is_integer(n) and n in 1..4, do: true
  def valid?(_), do: false
end
