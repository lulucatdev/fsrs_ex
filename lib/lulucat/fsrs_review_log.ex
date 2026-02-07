defmodule Fsrs.ReviewLog do
  @moduledoc """
  Review event model.

  Each review log stores card identity, user rating, review timestamp,
  and optional review duration.

  中文说明：表示单次复习事件，记录评分、时间和可选耗时。
  """

  alias Fsrs.Rating

  @typedoc """
  Review log struct.
  """

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
  Creates a review log entry.

  Required fields:

  - `card_id`
  - `rating`
  - `review_datetime`

  中文说明：创建日志时必须传入 card_id、rating、review_datetime。

  ## Examples

      iex> log = Fsrs.ReviewLog.new(card_id: 1, rating: :good, review_datetime: ~U[2024-01-01 00:00:00Z])
      iex> {log.card_id, log.rating}
      {1, :good}
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
  Converts a review log to a Python-compatible map.

  中文说明：导出 map，字段与 Python 版本兼容。
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
  Restores a review log from a serialized map.

  Supports atom-key and string-key maps.
  `rating` may be provided as integer or atom.

  中文说明：支持字符串键/原子键，rating 支持整数或原子。
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
  Serializes a review log to JSON.

  中文说明：序列化为 JSON。
  """
  @spec to_json(t(), keyword()) :: String.t()
  def to_json(%__MODULE__{} = review_log, opts \\ []) do
    Jason.encode!(to_dict(review_log), opts)
  end

  @doc """
  Deserializes a review log from JSON.

  中文说明：从 JSON 恢复日志结构。
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
