defmodule Fsrs.State do
  @moduledoc """
  Card state enum used by FSRS.

  Mapping:

  - `:learning` => `1`
  - `:review` => `2`
  - `:relearning` => `3`

  中文说明：卡片状态枚举，支持原子与整数映射。
  """

  @type t :: :learning | :review | :relearning

  @doc """
  Returns all possible states.

  中文说明：返回全部状态值。
  """
  def all, do: [:learning, :review, :relearning]

  @doc """
  Converts atom state to integer representation.

  中文说明：原子状态转整数。
  """
  @spec to_int(t()) :: integer()
  def to_int(:learning), do: 1
  def to_int(:review), do: 2
  def to_int(:relearning), do: 3

  @doc """
  Converts integer state to atom representation.
  Returns `{:ok, state}` on success, `:error` on invalid input.

  中文说明：整数状态转原子，成功返回 `{:ok, state}`，无效输入返回 `:error`。

  ## Examples

      iex> Fsrs.State.from_int(1)
      {:ok, :learning}
      
      iex> Fsrs.State.from_int(5)
      :error
  """
  @spec from_int(integer()) :: {:ok, t()} | :error
  def from_int(1), do: {:ok, :learning}
  def from_int(2), do: {:ok, :review}
  def from_int(3), do: {:ok, :relearning}
  def from_int(_), do: :error

  @doc """
  Converts integer state to atom representation.
  Raises `ArgumentError` on invalid input.

  中文说明：整数状态转原子，无效输入抛出 `ArgumentError`。

  ## Examples

      iex> Fsrs.State.from_int!(1)
      :learning
      
      iex> Fsrs.State.from_int!(5)
      ** (ArgumentError) invalid state: 5, expected 1-3
  """
  @spec from_int!(integer()) :: t()
  def from_int!(n) do
    case from_int(n) do
      {:ok, state} -> state
      :error -> raise ArgumentError, "invalid state: #{n}, expected 1-3"
    end
  end

  @doc """
  Checks if the given value is a valid state.

  中文说明：检查给定值是否为有效状态。

  ## Examples

      iex> Fsrs.State.valid?(:learning)
      true
      
      iex> Fsrs.State.valid?(5)
      false
  """
  @spec valid?(t() | integer()) :: boolean()
  def valid?(:learning), do: true
  def valid?(:review), do: true
  def valid?(:relearning), do: true
  def valid?(n) when is_integer(n) and n in 1..3, do: true
  def valid?(_), do: false
end
