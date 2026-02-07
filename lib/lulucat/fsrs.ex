defmodule Fsrs do
  @moduledoc """
  Public API for `fsrs_ex`.

  This module exposes the core entry points for creating schedulers, cards,
  and review logs, then running reviews and retrievability calculations.

  Port baseline: `open-spaced-repetition/py-fsrs` `v6.3.0` (FSRS-6).

  中文说明：这是 `fsrs_ex` 的公共 API 模块，对齐 `py-fsrs v6.3.0`。

  ## Main modules

  - `Fsrs.Scheduler` for scheduling and review logic
  - `Fsrs.Card` for card state
  - `Fsrs.ReviewLog` for review events
  - `Fsrs.Rating` and `Fsrs.State` enum helpers

  ## Timezone policy

  Scheduler operations that consume datetimes expect UTC datetimes.
  调度相关时间参数要求使用 UTC。
  """

  alias Fsrs.Card
  alias Fsrs.Constants
  alias Fsrs.Rating
  alias Fsrs.ReviewLog
  alias Fsrs.Scheduler

  @doc """
  Creates a scheduler.

  Common options:

  - `:parameters` 21 FSRS-6 weights
  - `:desired_retention` target recall probability (default `0.9`)
  - `:learning_steps` and `:relearning_steps` in seconds or tuple units
  - `:maximum_interval` in days
  - `:enable_fuzzing` boolean

  中文说明：创建调度器，可自定义参数和学习步长。

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
  Creates a card.

  New cards default to `:learning` state and `step: 0`.
  中文说明：新卡默认是学习态（`step: 0`）。

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
  Creates a review log entry.

  Required options are `:card_id`, `:rating`, and `:review_datetime`.
  中文说明：复习日志至少需要卡片 ID、评分和复习时间。

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
  Reviews a card and returns `{updated_card, review_log}`.

  The optional `review_datetime` defaults to `DateTime.utc_now/0`.
  The optional `review_duration` is stored in the review log.

  中文说明：复习后返回更新卡片和日志。

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
  Replays historical logs and returns a rescheduled card state.

  Logs are sorted by `review_datetime` before replay.
  The function validates that every log belongs to the same `card_id`.

  中文说明：按历史日志重放计算卡片状态，内部会先排序并校验卡片 ID。

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
  Calculates retrievability at a given datetime.

  If `current_datetime` is omitted, `DateTime.utc_now/0` is used.
  If `card.last_review` is `nil`, returns `0.0`.

  中文说明：计算在指定时间点的可回忆概率。

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
  Returns the default FSRS-6 parameter tuple.

  中文说明：返回 FSRS-6 的默认 21 参数。
  """
  @spec default_parameters() :: tuple()
  def default_parameters do
    Constants.default_parameters()
  end

  @doc """
  Returns the minimum allowed stability value.

  中文说明：返回稳定性的最小下界。
  """
  @spec stability_min() :: float()
  def stability_min do
    Constants.stability_min()
  end

  @doc """
  Returns fuzzing ranges used when interval fuzzing is enabled.

  中文说明：返回区间模糊处理所用范围。
  """
  @spec fuzz_ranges() :: list(map())
  def fuzz_ranges do
    Constants.fuzz_ranges()
  end
end
