defmodule Fsrs.ReviewLog do
  @moduledoc """
  Represents the log entry of a Card object that has been reviewed.
  表示已被复习的卡片对象的日志条目。
  """

  alias Fsrs.Rating

  @type t :: %__MODULE__{
          card_id: integer(),
          rating: Rating.t(),
          review_datetime: DateTime.t(),
          review_duration: integer() | nil
        }

  defstruct [
    :card_id,
    :rating,
    :review_datetime,
    :review_duration
  ]

  @doc """
  Creates a new review log entry.
  创建一个新的复习日志条目。
  """
  @spec new(Keyword.t()) :: t()
  def new(opts) do
    card_id = Keyword.fetch!(opts, :card_id)
    rating = Keyword.fetch!(opts, :rating)
    review_datetime = Keyword.fetch!(opts, :review_datetime)
    review_duration = Keyword.get(opts, :review_duration)

    %__MODULE__{
      card_id: card_id,
      rating: rating,
      review_datetime: review_datetime,
      review_duration: review_duration
    }
  end

  @doc """
  Converts a ReviewLog struct to a map for serialization.
  将 ReviewLog 结构体转换为用于序列化的映射。
  """
  @spec to_dict(t()) :: map()
  def to_dict(%__MODULE__{} = review_log), do: to_map(review_log)

  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = review_log) do
    %{
      "card_id" => review_log.card_id,
      "rating" => Rating.to_int(review_log.rating),
      "review_datetime" => datetime_to_python_iso8601(review_log.review_datetime),
      "review_duration" => review_log.review_duration
    }
  end

  @doc """
  Creates a ReviewLog struct from a serialized map.
  从序列化的映射创建 ReviewLog 结构体。
  """
  @spec from_dict(map()) :: t()
  def from_dict(source_map), do: from_map(source_map)

  @spec from_map(map()) :: t()
  def from_map(source_map) do
    rating = map_get(source_map, :rating)

    rating =
      cond do
        is_integer(rating) -> Rating.from_int(rating)
        is_atom(rating) -> rating
        true -> raise ArgumentError, "rating must be an integer or atom"
      end

    %__MODULE__{
      card_id: map_get(source_map, :card_id),
      rating: rating,
      review_datetime: map_get(source_map, :review_datetime) |> parse_datetime(),
      review_duration: map_get(source_map, :review_duration)
    }
  end

  @doc """
  Serializes a ReviewLog to JSON.
  将 ReviewLog 序列化为 JSON。
  """
  @spec to_json(t(), keyword()) :: String.t()
  def to_json(%__MODULE__{} = review_log, opts \\ []) do
    Jason.encode!(to_dict(review_log), opts)
  end

  @doc """
  Deserializes a ReviewLog from JSON.
  从 JSON 反序列化 ReviewLog。
  """
  @spec from_json(String.t()) :: t()
  def from_json(source_json) when is_binary(source_json) do
    source_json
    |> Jason.decode!()
    |> from_dict()
  end

  # Private functions

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
