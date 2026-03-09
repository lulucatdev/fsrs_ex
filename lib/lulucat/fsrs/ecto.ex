defmodule Fsrs.Ecto do
  @moduledoc """
  Ecto integration for FSRS types.

  This module provides Ecto.Type implementations for Fsrs structs,
  allowing them to be stored in database fields (typically as JSON).

  ## Available Types

  - `Fsrs.Ecto.CardType` - For storing Fsrs.Card structs
  - `Fsrs.Ecto.SchedulerType` - For storing Fsrs.Scheduler configurations

  ## Installation

  To use Ecto types, add `:ecto` to your dependencies:

      def deps do
        [
          {:fsrs_ex, "~> 0.1.2"},
          {:ecto, "~> 3.0"}  # Optional, for database integration
        ]
      end

  ## Example Schema

      defmodule MyApp.Card do
        use Ecto.Schema

        schema "cards" do
          field :content, :string
          field :fsrs_data, Fsrs.Ecto.CardType
          timestamps()
        end
      end

  ## Migration Example

      defmodule MyApp.Repo.Migrations.CreateCards do
        use Ecto.Migration

        def change do
          create table(:cards) do
            add :content, :text
            add :fsrs_data, :map  # JSON/JSONB column
            timestamps()
          end
        end
      end

  中文说明：为 FSRS 类型提供 Ecto 集成，支持数据库存储。
  """
end
