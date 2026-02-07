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

  中文说明：整数状态转原子。
  """
  @spec from_int(integer()) :: t()
  def from_int(1), do: :learning
  def from_int(2), do: :review
  def from_int(3), do: :relearning
end
