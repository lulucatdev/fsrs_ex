defmodule Fsrs do
  @moduledoc """
  Free Spaced Repetition Scheduler (FSRS) implementation in Elixir.
  Elixir 实现的免费间隔重复调度器 (FSRS)。

  This module brings together all FSRS components and provides the main interface
  for creating and working with cards, scheduling reviews, and tracking review logs.
  该模块整合了所有 FSRS 组件，并提供了用于创建和操作卡片、安排复习以及跟踪复习日志的主要接口。
  """

  alias Fsrs.Card
  alias Fsrs.Constants
  alias Fsrs.Rating
  alias Fsrs.ReviewLog
  alias Fsrs.Scheduler

  @doc """
  Creates a new scheduler with the given options.
  使用给定选项创建一个新的调度器。

  ## Examples

      iex> scheduler = Fsrs.new_scheduler()
      iex> is_struct(scheduler, Fsrs.Scheduler)
      true
  """
  @spec new_scheduler(Keyword.t()) :: Scheduler.t()
  def new_scheduler(opts \\ []) do
    Scheduler.new(opts)
  end

  @doc """
  Creates a new card with the given options.
  使用给定选项创建一个新的卡片。

  ## Examples

      iex> card = Fsrs.new_card()
      iex> is_struct(card, Fsrs.Card)
      true
  """
  @spec new_card(Keyword.t()) :: Card.t()
  def new_card(opts \\ []) do
    Card.new(opts)
  end

  @doc """
  Creates a new review log with the given options.
  使用给定选项创建一个新的复习日志。

  ## Examples

      iex> {:ok, dt} = DateTime.new(~D[2023-01-01], ~T[12:00:00], "Etc/UTC")
      iex> review_log = Fsrs.new_review_log(card_id: 123, rating: :good, review_datetime: dt)
      iex> is_struct(review_log, Fsrs.ReviewLog)
      true
  """
  @spec new_review_log(Keyword.t()) :: ReviewLog.t()
  def new_review_log(opts) do
    ReviewLog.new(opts)
  end

  @doc """
  Reviews a card with the given scheduler, rating, and other options.
  使用给定的调度器、评分和其他选项复习卡片。

  ## Examples

      iex> scheduler = Fsrs.new_scheduler()
      iex> card = Fsrs.new_card()
      iex> {updated_card, review_log} = Fsrs.review_card(scheduler, card, :good)
      iex> is_struct(updated_card, Fsrs.Card)
      true
      iex> is_struct(review_log, Fsrs.ReviewLog)
      true
  """
  @spec review_card(Scheduler.t(), Card.t(), Rating.t(), DateTime.t() | nil, integer() | nil) ::
          {Card.t(), ReviewLog.t()}
  def review_card(scheduler, card, rating, review_datetime \\ nil, review_duration \\ nil) do
    Scheduler.review_card(scheduler, card, rating, review_datetime, review_duration)
  end

  @doc """
  Reschedules a card from historical review logs with the given scheduler.
  使用给定调度器和历史复习日志重新调度卡片。

  ## Examples

      iex> scheduler = Fsrs.new_scheduler(enable_fuzzing: false)
      iex> card = Fsrs.new_card(card_id: 1)
      iex> now = DateTime.utc_now()
      iex> log = Fsrs.new_review_log(card_id: 1, rating: :good, review_datetime: now)
      iex> updated_card = Fsrs.reschedule_card(scheduler, card, [log])
      iex> updated_card.last_review == now
      true
  """
  @spec reschedule_card(Scheduler.t(), Card.t(), list(ReviewLog.t())) :: Card.t()
  def reschedule_card(scheduler, card, review_logs) do
    Scheduler.reschedule_card(scheduler, card, review_logs)
  end

  @doc """
  Calculates a card's retrievability with the given scheduler and datetime.
  计算卡片在给定调度器和日期时间下的可提取性。

  ## Examples

      iex> scheduler = Fsrs.new_scheduler()
      iex> card = Fsrs.new_card(stability: 2.5, last_review: DateTime.utc_now())
      iex> retrievability = Fsrs.get_card_retrievability(scheduler, card)
      iex> is_float(retrievability)
      true
  """
  @spec get_card_retrievability(Scheduler.t(), Card.t(), DateTime.t() | nil) :: float()
  def get_card_retrievability(scheduler, card, current_datetime \\ nil) do
    Scheduler.get_card_retrievability(scheduler, card, current_datetime)
  end

  @doc """
  Returns the default FSRS parameters.
  返回默认的 FSRS 参数。
  """
  @spec default_parameters() :: tuple()
  def default_parameters do
    Constants.default_parameters()
  end

  @doc """
  Returns the minimum stability value allowed.
  返回允许的最小稳定性值。
  """
  @spec stability_min() :: float()
  def stability_min do
    Constants.stability_min()
  end

  @doc """
  Returns the fuzz ranges used in interval calculation.
  返回用于间隔计算的模糊范围。
  """
  @spec fuzz_ranges() :: list(map())
  def fuzz_ranges do
    Constants.fuzz_ranges()
  end
end
