defmodule Fsrs.Scheduler do
  @moduledoc """
  The FSRS scheduler.
  FSRS 调度器。

  Enables the reviewing and future scheduling of cards according to the FSRS algorithm.
  根据 FSRS 算法启用卡片的复习和未来调度。
  """

  alias Fsrs.Card
  alias Fsrs.Constants
  alias Fsrs.Rating
  alias Fsrs.ReviewLog

  @type t :: %__MODULE__{
          parameters: tuple(),
          desired_retention: float(),
          learning_steps: list(integer()),
          relearning_steps: list(integer()),
          maximum_interval: integer(),
          enable_fuzzing: boolean(),
          decay: float(),
          factor: float()
        }

  defstruct [
    :parameters,
    :desired_retention,
    :learning_steps,
    :relearning_steps,
    :maximum_interval,
    :enable_fuzzing,
    :decay,
    :factor
  ]

  @doc """
  Creates a new scheduler with default or provided parameters.
  使用默认或提供的参数创建一个新的调度器。
  """
  @spec new(Keyword.t()) :: t()
  def new(opts \\ []) do
    parameters =
      opts
      |> Keyword.get(:parameters, Constants.default_parameters())
      |> normalize_parameters()

    validate_parameters!(parameters)

    desired_retention = Keyword.get(opts, :desired_retention, 0.9)

    # Convert learning_steps and relearning_steps from timedeltas to seconds
    # 将 learning_steps 和 relearning_steps 从时间增量转换为秒
    learning_steps =
      opts
      |> Keyword.get(:learning_steps, [60, 600])
      |> normalize_steps(:learning_steps)

    relearning_steps =
      opts
      |> Keyword.get(:relearning_steps, [600])
      |> normalize_steps(:relearning_steps)

    maximum_interval = Keyword.get(opts, :maximum_interval, 36500)
    enable_fuzzing = Keyword.get(opts, :enable_fuzzing, true)

    # Pre-calculate some constants used in the algorithm
    # 预先计算算法中使用的一些常量
    decay = -elem(parameters, 20)
    factor = :math.pow(0.9, 1 / decay) - 1

    %__MODULE__{
      parameters: parameters,
      desired_retention: desired_retention,
      learning_steps: learning_steps,
      relearning_steps: relearning_steps,
      maximum_interval: maximum_interval,
      enable_fuzzing: enable_fuzzing,
      decay: decay,
      factor: factor
    }
  end

  @doc """
  Reschedules a card with this scheduler using historical review logs.
  使用该调度器和历史复习日志重新调度卡片。
  """
  @spec reschedule_card(t(), Card.t(), list(ReviewLog.t())) :: Card.t()
  def reschedule_card(%__MODULE__{} = scheduler, %Card{} = card, review_logs)
      when is_list(review_logs) do
    Enum.each(review_logs, fn
      %ReviewLog{card_id: card_id} when card_id == card.card_id ->
        :ok

      %ReviewLog{card_id: card_id} ->
        raise ArgumentError,
              "review log card_id #{card_id} does not match card card_id #{card.card_id}"

      _ ->
        raise ArgumentError, "review_logs must contain Fsrs.ReviewLog structs"
    end)

    sorted_review_logs =
      Enum.sort_by(review_logs, &DateTime.to_unix(&1.review_datetime, :microsecond))

    rescheduled_card = Card.new(card_id: card.card_id, due: card.due)

    Enum.reduce(sorted_review_logs, rescheduled_card, fn review_log, acc_card ->
      {updated_card, _review_log} =
        review_card(scheduler, acc_card, review_log.rating, review_log.review_datetime)

      updated_card
    end)
  end

  @doc """
  Calculates a Card object's current retrievability for a given date and time.
  计算卡片对象在给定日期和时间的当前可提取性。

  The retrievability of a card is the predicted probability that the card is correctly recalled
  at the provided datetime.
  卡片的可提取性是在提供的日期时间正确回忆起卡片的预测概率。

  This implementation follows py-fsrs day-based elapsed-time behavior.
  该实现遵循 py-fsrs 的按天计算已用时间行为。
  """
  @spec get_card_retrievability(t(), Card.t(), DateTime.t() | nil) :: float()
  def get_card_retrievability(%__MODULE__{} = scheduler, %Card{} = card, current_datetime \\ nil) do
    if is_nil(card.last_review) do
      0.0
    else
      current_datetime = current_datetime || DateTime.utc_now()
      elapsed_days = max(0, DateTime.diff(current_datetime, card.last_review, :day))

      :math.pow(1 + scheduler.factor * elapsed_days / card.stability, scheduler.decay)
    end
  end

  @doc """
  Reviews a card with a given rating at a given time for a specified duration.
  在给定时间以指定持续时间使用给定评分复习卡片。

  Returns a tuple with the updated card and a review log entry.
  返回包含更新后的卡片和复习日志条目的元组。
  """
  @spec review_card(t(), Card.t(), Rating.t(), DateTime.t() | nil, integer() | nil) ::
          {Card.t(), ReviewLog.t()}
  def review_card(
        %__MODULE__{} = scheduler,
        %Card{} = card,
        rating,
        review_datetime \\ nil,
        review_duration \\ nil
      ) do
    review_datetime = review_datetime || DateTime.utc_now()

    # Check if review_datetime is set to UTC
    # 检查 review_datetime 是否设置为 UTC
    unless review_datetime.time_zone == "Etc/UTC" do
      raise ArgumentError, "datetime must be timezone-aware and set to UTC"
    end

    # Create a copy of the card to update
    # 创建卡片的副本进行更新
    card = Map.from_struct(card) |> then(&struct(Card, &1))

    # Calculate days since last review (py-fsrs behavior)
    # 计算自上次复习以来的天数（py-fsrs 行为）
    days_since_last_review =
      if card.last_review do
        DateTime.diff(review_datetime, card.last_review, :day)
      else
        nil
      end

    # Create review log entry
    # 创建复习日志条目
    review_log =
      ReviewLog.new(
        card_id: card.card_id,
        rating: rating,
        review_datetime: review_datetime,
        review_duration: review_duration
      )

    # Update card based on its current state
    # 根据卡片当前状态更新卡片
    {card, next_interval} =
      case card.state do
        :learning ->
          handle_learning_state(scheduler, card, rating, days_since_last_review, review_datetime)

        :review ->
          handle_review_state(scheduler, card, rating, days_since_last_review, review_datetime)

        :relearning ->
          handle_relearning_state(
            scheduler,
            card,
            rating,
            days_since_last_review,
            review_datetime
          )
      end

    # Apply fuzzing if enabled and card is in review state
    # 如果启用模糊处理且卡片处于复习状态，则应用模糊处理
    next_interval =
      if scheduler.enable_fuzzing and card.state == :review do
        get_fuzzed_interval(scheduler, next_interval)
      else
        next_interval
      end

    # Update the card's due date and last review timestamp
    # 更新卡片的到期日期和上次复习时间戳
    card = %{
      card
      | due: DateTime.add(review_datetime, next_interval, :second),
        last_review: review_datetime
    }

    {card, review_log}
  end

  @doc """
  Converts a Scheduler struct to a map for serialization.
  将 Scheduler 结构体转换为用于序列化的映射。
  """
  @spec to_dict(t()) :: map()
  def to_dict(%__MODULE__{} = scheduler), do: to_map(scheduler)

  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = scheduler) do
    %{
      "parameters" => Tuple.to_list(scheduler.parameters),
      "desired_retention" => scheduler.desired_retention,
      "learning_steps" => scheduler.learning_steps,
      "relearning_steps" => scheduler.relearning_steps,
      "maximum_interval" => scheduler.maximum_interval,
      "enable_fuzzing" => scheduler.enable_fuzzing
    }
  end

  @doc """
  Creates a Scheduler struct from a serialized map.
  从序列化的映射创建 Scheduler 结构体。
  """
  @spec from_dict(map()) :: t()
  def from_dict(source_map), do: from_map(source_map)

  @spec from_map(map()) :: t()
  def from_map(source_map) do
    parameters = map_get(source_map, :parameters)

    parameters =
      cond do
        is_tuple(parameters) -> parameters
        is_list(parameters) -> List.to_tuple(parameters)
        true -> raise ArgumentError, "parameters must be a tuple or list of numbers"
      end

    new(
      parameters: parameters,
      desired_retention: map_get(source_map, :desired_retention),
      learning_steps: map_get(source_map, :learning_steps),
      relearning_steps: map_get(source_map, :relearning_steps),
      maximum_interval: map_get(source_map, :maximum_interval),
      enable_fuzzing: map_get(source_map, :enable_fuzzing)
    )
  end

  @doc """
  Serializes a Scheduler to JSON.
  将 Scheduler 序列化为 JSON。
  """
  @spec to_json(t(), keyword()) :: String.t()
  def to_json(%__MODULE__{} = scheduler, opts \\ []) do
    Jason.encode!(to_dict(scheduler), opts)
  end

  @doc """
  Deserializes a Scheduler from JSON.
  从 JSON 反序列化 Scheduler。
  """
  @spec from_json(String.t()) :: t()
  def from_json(source_json) when is_binary(source_json) do
    source_json
    |> Jason.decode!()
    |> from_dict()
  end

  # Private functions for state handling
  # 用于状态处理的私有函数

  defp handle_learning_state(scheduler, card, rating, days_since_last_review, review_datetime) do
    # Update the card's stability and difficulty
    # 更新卡片的稳定性和难度
    {card, next_interval} =
      cond do
        is_nil(card.stability) or is_nil(card.difficulty) ->
          # Initial learning
          # 初始学习
          stability = initial_stability(scheduler, rating)
          difficulty = initial_difficulty(scheduler, rating)
          card = %{card | stability: stability, difficulty: difficulty}

          handle_learning_steps(scheduler, card, rating)

        days_since_last_review != nil and days_since_last_review < 1 ->
          # Short-term learning
          # 短期学习
          stability = short_term_stability(scheduler, card.stability, rating)
          difficulty = next_difficulty(scheduler, card.difficulty, rating)
          card = %{card | stability: stability, difficulty: difficulty}

          handle_learning_steps(scheduler, card, rating)

        true ->
          # Regular learning
          # 常规学习
          retrievability = get_card_retrievability(scheduler, card, review_datetime)

          stability =
            next_stability(scheduler, card.difficulty, card.stability, retrievability, rating)

          difficulty = next_difficulty(scheduler, card.difficulty, rating)
          card = %{card | stability: stability, difficulty: difficulty}

          handle_learning_steps(scheduler, card, rating)
      end

    {card, next_interval}
  end

  defp handle_learning_steps(scheduler, card, rating) do
    cond do
      Enum.empty?(scheduler.learning_steps) or
          (card.step >= length(scheduler.learning_steps) and rating in [:hard, :good, :easy]) ->
        # Graduate to review
        # 晋升到复习状态
        card = %{card | state: :review, step: nil}
        next_interval_days = next_interval(scheduler, card.stability)
        # Convert days to seconds
        next_interval = next_interval_days * 86400

        {card, next_interval}

      true ->
        case rating do
          :again ->
            card = %{card | step: 0}
            {card, Enum.at(scheduler.learning_steps, 0)}

          :hard ->
            # Card step stays the same
            # 卡片步骤保持不变
            next_interval =
              cond do
                card.step == 0 and length(scheduler.learning_steps) == 1 ->
                  Enum.at(scheduler.learning_steps, 0) * 1.5

                card.step == 0 and length(scheduler.learning_steps) >= 2 ->
                  (Enum.at(scheduler.learning_steps, 0) + Enum.at(scheduler.learning_steps, 1)) /
                    2.0

                true ->
                  Enum.at(scheduler.learning_steps, card.step)
              end

            {card, trunc(next_interval)}

          :good ->
            if card.step + 1 == length(scheduler.learning_steps) do
              # Graduate to review on the last step
              # 在最后一步晋升到复习状态
              card = %{card | state: :review, step: nil}
              next_interval_days = next_interval(scheduler, card.stability)
              # Convert days to seconds
              next_interval = next_interval_days * 86400

              {card, next_interval}
            else
              # Move to next step
              # 移至下一步
              card = %{card | step: card.step + 1}
              {card, Enum.at(scheduler.learning_steps, card.step)}
            end

          :easy ->
            # Graduate to review immediately
            # 立即晋升到复习状态
            card = %{card | state: :review, step: nil}
            next_interval_days = next_interval(scheduler, card.stability)
            # Convert days to seconds
            next_interval = next_interval_days * 86400

            {card, next_interval}
        end
    end
  end

  defp handle_review_state(scheduler, card, rating, days_since_last_review, review_datetime) do
    # Update the card's stability and difficulty
    # 更新卡片的稳定性和难度
    card =
      if days_since_last_review != nil and days_since_last_review < 1 do
        # Short-term review
        # 短期复习
        stability = short_term_stability(scheduler, card.stability, rating)
        difficulty = next_difficulty(scheduler, card.difficulty, rating)
        %{card | stability: stability, difficulty: difficulty}
      else
        # Regular review
        # 常规复习
        retrievability = get_card_retrievability(scheduler, card, review_datetime)

        stability =
          next_stability(scheduler, card.difficulty, card.stability, retrievability, rating)

        difficulty = next_difficulty(scheduler, card.difficulty, rating)
        %{card | stability: stability, difficulty: difficulty}
      end

    # Calculate the card's next interval
    # 计算卡片的下一个间隔
    # rating in [:hard, :good, :easy]
    if rating == :again do
      # If there are no relearning steps (they were left blank)
      # 如果没有重新学习步骤（它们被留空）
      if Enum.empty?(scheduler.relearning_steps) do
        next_interval_days = next_interval(scheduler, card.stability)
        # Convert days to seconds
        {card, next_interval_days * 86400}
      else
        card = %{card | state: :relearning, step: 0}
        {card, Enum.at(scheduler.relearning_steps, 0)}
      end
    else
      next_interval_days = next_interval(scheduler, card.stability)
      # Convert days to seconds
      {card, next_interval_days * 86400}
    end
  end

  defp handle_relearning_state(scheduler, card, rating, days_since_last_review, review_datetime) do
    # Update the card's stability and difficulty
    # 更新卡片的稳定性和难度
    card =
      if days_since_last_review != nil and days_since_last_review < 1 do
        # Short-term relearning
        # 短期重新学习
        stability = short_term_stability(scheduler, card.stability, rating)
        difficulty = next_difficulty(scheduler, card.difficulty, rating)
        %{card | stability: stability, difficulty: difficulty}
      else
        # Regular relearning
        # 常规重新学习
        retrievability = get_card_retrievability(scheduler, card, review_datetime)

        stability =
          next_stability(scheduler, card.difficulty, card.stability, retrievability, rating)

        difficulty = next_difficulty(scheduler, card.difficulty, rating)
        %{card | stability: stability, difficulty: difficulty}
      end

    # Calculate the card's next interval
    # 计算卡片的下一个间隔
    cond do
      Enum.empty?(scheduler.relearning_steps) or
          (card.step >= length(scheduler.relearning_steps) and rating in [:hard, :good, :easy]) ->
        # Graduate back to review
        # 回到复习状态
        card = %{card | state: :review, step: nil}
        next_interval_days = next_interval(scheduler, card.stability)
        # Convert days to seconds
        {card, next_interval_days * 86400}

      true ->
        case rating do
          :again ->
            card = %{card | step: 0}
            {card, Enum.at(scheduler.relearning_steps, 0)}

          :hard ->
            # Card step stays the same
            # 卡片步骤保持不变
            next_interval =
              cond do
                card.step == 0 and length(scheduler.relearning_steps) == 1 ->
                  Enum.at(scheduler.relearning_steps, 0) * 1.5

                card.step == 0 and length(scheduler.relearning_steps) >= 2 ->
                  (Enum.at(scheduler.relearning_steps, 0) + Enum.at(scheduler.relearning_steps, 1)) /
                    2.0

                true ->
                  Enum.at(scheduler.relearning_steps, card.step)
              end

            {card, trunc(next_interval)}

          :good ->
            if card.step + 1 == length(scheduler.relearning_steps) do
              # Graduate to review on the last step
              # 在最后一步晋升到复习状态
              card = %{card | state: :review, step: nil}
              next_interval_days = next_interval(scheduler, card.stability)
              # Convert days to seconds
              {card, next_interval_days * 86400}
            else
              # Move to next step
              # 移至下一步
              card = %{card | step: card.step + 1}
              {card, Enum.at(scheduler.relearning_steps, card.step)}
            end

          :easy ->
            # Graduate to review immediately
            # 立即晋升到复习状态
            card = %{card | state: :review, step: nil}
            next_interval_days = next_interval(scheduler, card.stability)
            # Convert days to seconds
            {card, next_interval_days * 86400}
        end
    end
  end

  # Core algorithm helper functions
  # 核心算法辅助函数

  defp clamp_difficulty(difficulty) do
    max(1.0, min(difficulty, 10.0))
  end

  defp clamp_stability(stability) do
    max(stability, Constants.stability_min())
  end

  defp initial_stability(scheduler, rating) do
    stability = elem(scheduler.parameters, Rating.to_int(rating) - 1)
    clamp_stability(stability)
  end

  defp initial_difficulty(scheduler, rating, clamp \\ true) do
    w4 = elem(scheduler.parameters, 4)
    w5 = elem(scheduler.parameters, 5)

    difficulty = w4 - :math.exp(w5 * (Rating.to_int(rating) - 1)) + 1

    if clamp do
      clamp_difficulty(difficulty)
    else
      difficulty
    end
  end

  defp next_interval(scheduler, stability) do
    next_interval =
      stability / scheduler.factor *
        (:math.pow(scheduler.desired_retention, 1 / scheduler.decay) - 1)

    next_interval = round(next_interval)

    # Must be at least 1 day long
    # 必须至少为 1 天
    next_interval = max(next_interval, 1)

    # Cannot be longer than the maximum interval
    # 不能长于最大间隔
    min(next_interval, scheduler.maximum_interval)
  end

  defp short_term_stability(scheduler, stability, rating) do
    w17 = elem(scheduler.parameters, 17)
    w18 = elem(scheduler.parameters, 18)
    w19 = elem(scheduler.parameters, 19)

    short_term_stability_increase =
      :math.exp(w17 * (Rating.to_int(rating) - 3 + w18)) *
        :math.pow(stability, -w19)

    short_term_stability_increase =
      if rating in [:good, :easy] do
        max(short_term_stability_increase, 1.0)
      else
        short_term_stability_increase
      end

    stability = stability * short_term_stability_increase
    clamp_stability(stability)
  end

  defp next_difficulty(scheduler, difficulty, rating) do
    w6 = elem(scheduler.parameters, 6)
    w7 = elem(scheduler.parameters, 7)

    linear_damping = fn delta_difficulty, difficulty ->
      (10.0 - difficulty) * delta_difficulty / 9.0
    end

    mean_reversion = fn arg_1, arg_2 ->
      w7 * arg_1 + (1 - w7) * arg_2
    end

    arg_1 = initial_difficulty(scheduler, :easy, false)
    delta_difficulty = -(w6 * (Rating.to_int(rating) - 3))
    arg_2 = difficulty + linear_damping.(delta_difficulty, difficulty)

    next_difficulty = mean_reversion.(arg_1, arg_2)
    clamp_difficulty(next_difficulty)
  end

  defp next_stability(scheduler, difficulty, stability, retrievability, rating) do
    case rating do
      :again ->
        next_forget_stability(scheduler, difficulty, stability, retrievability)

      _ ->
        next_recall_stability(scheduler, difficulty, stability, retrievability, rating)
    end
    |> clamp_stability()
  end

  defp next_forget_stability(scheduler, difficulty, stability, retrievability) do
    w11 = elem(scheduler.parameters, 11)
    w12 = elem(scheduler.parameters, 12)
    w13 = elem(scheduler.parameters, 13)
    w14 = elem(scheduler.parameters, 14)
    w17 = elem(scheduler.parameters, 17)
    w18 = elem(scheduler.parameters, 18)

    next_forget_stability_long_term_params =
      w11 * :math.pow(difficulty, -w12) *
        (:math.pow(stability + 1, w13) - 1) *
        :math.exp((1 - retrievability) * w14)

    next_forget_stability_short_term_params =
      stability / :math.exp(w17 * w18)

    min(next_forget_stability_long_term_params, next_forget_stability_short_term_params)
  end

  defp next_recall_stability(scheduler, difficulty, stability, retrievability, rating) do
    w8 = elem(scheduler.parameters, 8)
    w9 = elem(scheduler.parameters, 9)
    w10 = elem(scheduler.parameters, 10)
    w15 = elem(scheduler.parameters, 15)
    w16 = elem(scheduler.parameters, 16)

    hard_penalty = if rating == :hard, do: w15, else: 1
    easy_bonus = if rating == :easy, do: w16, else: 1

    stability *
      (1 +
         :math.exp(w8) *
           (11 - difficulty) *
           :math.pow(stability, -w9) *
           (:math.exp((1 - retrievability) * w10) - 1) *
           hard_penalty *
           easy_bonus)
  end

  defp get_fuzzed_interval(scheduler, interval) do
    # Convert seconds to days for interval calculation
    # 将秒转换为天以进行间隔计算
    interval_days = interval / 86400

    # Only apply fuzz to intervals of 2.5 days or more
    # 仅对 2.5 天或更长的间隔应用模糊处理
    if interval_days < 2.5 do
      interval
    else
      {min_ivl, max_ivl} = get_fuzz_range(scheduler, interval_days)

      # Generate a random value between min_ivl and max_ivl
      # 生成 min_ivl 和 max_ivl 之间的随机值
      fuzzed_interval_days = :rand.uniform() * (max_ivl - min_ivl + 1) + min_ivl
      fuzzed_interval_days = min(round(fuzzed_interval_days), scheduler.maximum_interval)

      # Convert back to seconds
      # 转换回秒
      trunc(fuzzed_interval_days * 86400)
    end
  end

  defp get_fuzz_range(scheduler, interval_days) do
    delta = 1.0

    # Calculate delta based on the fuzz ranges
    # 根据模糊范围计算 delta
    delta =
      Enum.reduce(Constants.fuzz_ranges(), delta, fn fuzz_range, acc ->
        factor = fuzz_range.factor
        range_start = fuzz_range.start
        range_end = if fuzz_range.end == :infinity, do: :infinity, else: fuzz_range.end

        range_contribution =
          if range_end == :infinity do
            if interval_days > range_start do
              factor * (interval_days - range_start)
            else
              0.0
            end
          else
            factor * max(min(interval_days, range_end) - range_start, 0.0)
          end

        acc + range_contribution
      end)

    min_ivl = round(interval_days - delta)
    max_ivl = round(interval_days + delta)

    # Make sure the min_ivl and max_ivl fall into a valid range
    # 确保 min_ivl 和 max_ivl 落入有效范围
    min_ivl = max(2, min_ivl)
    max_ivl = min(max_ivl, scheduler.maximum_interval)
    min_ivl = min(min_ivl, max_ivl)

    {min_ivl, max_ivl}
  end

  defp normalize_parameters(parameters) when is_tuple(parameters), do: parameters
  defp normalize_parameters(parameters) when is_list(parameters), do: List.to_tuple(parameters)

  defp normalize_parameters(_parameters) do
    raise ArgumentError, "parameters must be a tuple or list of numbers"
  end

  defp validate_parameters!(parameters) when is_tuple(parameters) do
    lower_bounds = Constants.lower_bounds_parameters()
    upper_bounds = Constants.upper_bounds_parameters()

    if tuple_size(parameters) != tuple_size(lower_bounds) do
      raise ArgumentError,
            "Expected #{tuple_size(lower_bounds)} parameters, got #{tuple_size(parameters)}."
    end

    errors =
      for index <- 0..(tuple_size(parameters) - 1), reduce: [] do
        acc ->
          parameter = elem(parameters, index)
          lower_bound = elem(lower_bounds, index)
          upper_bound = elem(upper_bounds, index)

          if not (parameter >= lower_bound and parameter <= upper_bound) do
            [
              "parameters[#{index}] = #{parameter} is out of bounds: (#{lower_bound}, #{upper_bound})"
              | acc
            ]
          else
            acc
          end
      end

    case Enum.reverse(errors) do
      [] ->
        :ok

      messages ->
        raise ArgumentError,
              "One or more parameters are out of bounds:\n" <> Enum.join(messages, "\n")
    end
  end

  defp map_get(map, key) when is_map(map) do
    case Map.fetch(map, key) do
      {:ok, value} -> value
      :error -> Map.get(map, Atom.to_string(key))
    end
  end

  defp normalize_steps(steps, field_name) when is_list(steps) do
    Enum.map(steps, &normalize_step(&1, field_name))
  end

  defp normalize_steps(_steps, field_name) do
    raise ArgumentError,
          "#{field_name} must be a list of seconds or {:seconds|:minutes, value} tuples"
  end

  defp normalize_step(step, _field_name) when is_integer(step) and step >= 0, do: step
  defp normalize_step(step, _field_name) when is_float(step) and step >= 0, do: trunc(step)

  defp normalize_step({unit, value}, field_name)
       when unit in [:second, :seconds, :minute, :minutes] do
    seconds =
      cond do
        (is_integer(value) or is_float(value)) and value >= 0 ->
          case unit do
            :second -> value
            :seconds -> value
            :minute -> value * 60
            :minutes -> value * 60
          end

        true ->
          raise ArgumentError,
                "#{field_name} tuple values must be non-negative numbers, got: #{inspect(value)}"
      end

    trunc(seconds)
  end

  defp normalize_step(step, field_name) do
    raise ArgumentError,
          "invalid #{field_name} entry: #{inspect(step)}; expected seconds or {:seconds|:minutes, value}"
  end
end
