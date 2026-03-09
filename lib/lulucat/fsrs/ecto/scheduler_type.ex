defmodule Fsrs.Ecto.SchedulerType do
  @moduledoc """
  Ecto type for Fsrs.Scheduler serialization.

  This module implements the `Ecto.Type` behaviour to allow storing
  Fsrs.Scheduler configurations in database fields.

  ## Usage

      schema "users" do
        field :scheduler_config, Fsrs.Ecto.SchedulerType
      end

  中文说明：为 Fsrs.Scheduler 实现的 Ecto 类型，支持数据库存储。
  """

  use Ecto.Type

  alias Fsrs.Scheduler

  @impl true
  def type, do: :map

  @impl true
  def cast(%Scheduler{} = scheduler) do
    {:ok, Scheduler.to_dict(scheduler)}
  end

  def cast(%{} = map) do
    try do
      {:ok, Scheduler.from_dict(map)}
    rescue
      _ -> :error
    end
  end

  def cast(_), do: :error

  @impl true
  def load(data) when is_map(data) do
    try do
      {:ok, Scheduler.from_dict(data)}
    rescue
      _ -> :error
    end
  end

  def load(_), do: :error

  @impl true
  def dump(%Scheduler{} = scheduler) do
    {:ok, Scheduler.to_dict(scheduler)}
  end

  def dump(_), do: :error

  @impl true
  def embed_as(_format), do: :self

  @impl true
  def equal?(term1, term2) do
    term1 == term2
  end
end
