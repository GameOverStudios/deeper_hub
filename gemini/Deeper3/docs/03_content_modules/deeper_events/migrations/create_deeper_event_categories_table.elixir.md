# Migração Elixir: Criar Tabela `deeper_event_categories`

Este módulo de migração Elixir é responsável por criar a tabela `deeper_event_categories` no banco de dados SQLite. Esta tabela define as categorias que podem ser associadas aos eventos.

## Código da Migração (`lib/deeper/core/data/migrations/create_deeper_event_categories_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateDeeperEventCategoriesTable do
  @moduledoc \"\"\"
  Migração para criar a tabela deeper_event_categories.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela deeper_event_categories.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela deeper_event_categories...\", module: __MODULE__)

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS deeper_event_categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE,
      slug TEXT NOT NULL UNIQUE,
      description TEXT,
      parent_id INTEGER,
      FOREIGN KEY (parent_id) REFERENCES deeper_event_categories(id) ON DELETE SET NULL
    );

    CREATE INDEX IF NOT EXISTS idx_deeper_event_categories_slug ON deeper_event_categories(slug);
    CREATE INDEX IF NOT EXISTS idx_deeper_event_categories_parent_id ON deeper_event_categories(parent_id);
    \"\"\"

    # Repo.execute(\"PRAGMA foreign_keys = ON;\") -- Se necessário

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela deeper_event_categories criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela deeper_event_categories: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela deeper_event_categories.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela deeper_event_categories...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS deeper_event_categories;\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela deeper_event_categories removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela deeper_event_categories: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas:

*   Similar à tabela de categorias de artigos, `name` e `slug` são `UNIQUE`.
*   `parent_id` permite categorias hierárquicas.