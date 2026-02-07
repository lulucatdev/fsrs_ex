defmodule Fsrs.Card do
  @moduledoc """
  Represents a flashcard in the FSRS system.
  表示 FSRS 系统中的一张抽认卡。
  """

  alias Fsrs.State

  @type t :: %__MODULE__{
          card_id: integer(),
          state: State.t(),
          step: integer() | nil,
          stability: float() | nil,
          difficulty: float() | nil,
          due: DateTime.t(),
          last_review: DateTime.t() | nil
        }

  defstruct [
    :card_id,
    :state,
    :step,
    :stability,
    :difficulty,
    :due,
    :last_review
  ]

  @doc """
  Creates a new card with default values.
  使用默认值创建一张新卡片。
  """
  @spec new(Keyword.t()) :: t()
  def new(opts \\ []) do
    card_id = Keyword.get(opts, :card_id, generate_card_id())
    state = Keyword.get(opts, :state, :learning)
    step = handle_step(Keyword.get(opts, :step), state)
    stability = Keyword.get(opts, :stability)
    difficulty = Keyword.get(opts, :difficulty)
    due = Keyword.get(opts, :due, DateTime.utc_now())
    last_review = Keyword.get(opts, :last_review)

    %__MODULE__{
      card_id: card_id,
      state: state,
      step: step,
      stability: stability,
      difficulty: difficulty,
      due: due,
      last_review: last_review
    }
  end

  @doc """
  Converts a Card struct to a map for serialization.
  将 Card 结构体转换为用于序列化的映射。
  """
  @spec to_dict(t()) :: map()
  def to_dict(%__MODULE__{} = card), do: to_map(card)

  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = card) do
    %{
      "card_id" => card.card_id,
      "state" => State.to_int(card.state),
      "step" => card.step,
      "stability" => card.stability,
      "difficulty" => card.difficulty,
      "due" => datetime_to_python_iso8601(card.due),
      "last_review" =>
        if(card.last_review, do: datetime_to_python_iso8601(card.last_review), else: nil)
    }
  end

  @doc """
  Creates a Card struct from a serialized map.
  从序列化的映射创建 Card 结构体。
  """
  @spec from_dict(map()) :: t()
  def from_dict(source_map), do: from_map(source_map)

  @spec from_map(map()) :: t()
  def from_map(source_map) do
    state = map_get(source_map, :state)

    state =
      cond do
        is_integer(state) -> State.from_int(state)
        is_atom(state) -> state
        true -> raise ArgumentError, "state must be an integer or atom"
      end

    %__MODULE__{
      card_id: map_get(source_map, :card_id),
      state: state,
      step: map_get(source_map, :step),
      stability: map_get(source_map, :stability),
      difficulty: map_get(source_map, :difficulty),
      due: map_get(source_map, :due) |> parse_datetime(),
      last_review:
        if(map_get(source_map, :last_review),
          do: map_get(source_map, :last_review) |> parse_datetime(),
          else: nil
        )
    }
  end

  @doc """
  Serializes a Card to JSON.
  将 Card 序列化为 JSON。
  """
  @spec to_json(t(), keyword()) :: String.t()
  def to_json(%__MODULE__{} = card, opts \\ []) do
    Jason.encode!(to_dict(card), opts)
  end

  @doc """
  Deserializes a Card from JSON.
  从 JSON 反序列化 Card。
  """
  @spec from_json(String.t()) :: t()
  def from_json(source_json) when is_binary(source_json) do
    source_json
    |> Jason.decode!()
    |> from_dict()
  end

  # Private functions

  defp generate_card_id do
    # Epoch milliseconds of when the card was created.
    # 创建卡片时的 epoch 毫秒时间戳。
    card_id = System.system_time(:millisecond)

    # Wait 1 ms to prevent potential card_id collision on next card creation.
    # 等待 1 毫秒，防止下一次创建卡片时发生 card_id 冲突。
    Process.sleep(1)

    card_id
  end

  defp handle_step(step, state) do
    case {step, state} do
      {nil, :learning} -> 0
      {step, _} -> step
    end
  end

  defp parse_datetime(iso_string) do
    {:ok, datetime, _offset} = DateTime.from_iso8601(iso_string)
    datetime
  end

  defp datetime_to_python_iso8601(datetime) do
    datetime
    |> DateTime.to_iso8601()
    |> String.replace_suffix("Z", "+00:00")
  end

  defp map_get(map, key) when is_map(map) do
    case Map.fetch(map, key) do
      {:ok, value} -> value
      :error -> Map.get(map, Atom.to_string(key))
    end
  end
end
