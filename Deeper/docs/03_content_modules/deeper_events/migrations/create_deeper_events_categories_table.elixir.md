# Migração Elixir: Criar Tabela `deeper_events_categories`

Este módulo de migração Elixir é responsável por criar a tabela `deeper_events_categories` no banco de dados SQLite. Esta tabela armazena as categorias que podem ser associadas aos eventos.

## Código da Migração (`lib/deeper/core/data/migrations/create_deeper_events_categories_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateDeeperEventsCategoriesTable do
  @moduledoc \"\"\"
  Migração para criar a tabela deeper_events_categories.
  \"\"\"
  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  def up do
    Logger.info(\"Criando tabela deeper_events_categories...\", module: __MODULE__)
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS deeper_events_categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      parent_id INTEGER DEFAULT 0,
      name TEXT NOT NULL UNIQUE,
      title_lang_key TEXT,
      \"order\" INTEGER DEFAULT 0
    );

    CREATE INDEX IF NOT EXISTS idx_deeper_events_categories_parent_id ON deeper_events_categories(parent_id);
    \"\"\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela deeper_events_categories criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela deeper_events_categories: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  def down do
    Logger.info(\"Removendo tabela deeper_events_categories...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS deeper_events_categories;\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela deeper_events_categories removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela deeper_events_categories: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```