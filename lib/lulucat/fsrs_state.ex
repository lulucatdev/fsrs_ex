defmodule Fsrs.State do
  @moduledoc """
  Enum representing the learning state of a Card object.
  表示卡片对象学习状态的枚举。
  """

  @type t :: :learning | :review | :relearning

  @doc """
  Returns all possible card states
  返回所有可能的卡片状态
  """
  def all, do: [:learning, :review, :relearning]

  @doc """
  Converts an atom state to its integer representation
  将原子状态转换为其整数表示
  """
  @spec to_int(t()) :: integer()
  def to_int(:learning), do: 1
  def to_int(:review), do: 2
  def to_int(:relearning), do: 3

  @doc """
  Converts an integer to its atom state representation
  将整数转换为其原子状态表示
  """
  @spec from_int(integer()) :: t()
  def from_int(1), do: :learning
  def from_int(2), do: :review
  def from_int(3), do: :relearning
end
