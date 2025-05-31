# Migração Elixir: Criar Tabela de Junção `deeper_events_to_categories`

Este módulo de migração Elixir é responsável por criar a tabela de junção `deeper_events_to_categories` no banco de dados SQLite. Esta tabela estabelece uma relação muitos-para-muitos entre eventos (`deeper_events`) e suas categorias (`deeper_event_categories`).

## Código da Migração (`lib/deeper/core/data/migrations/create_deeper_events_to_categories_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateDeeperEventsToCategoriesTable do
  @moduledoc \"\"\"
  Migração para criar a tabela de junção deeper_events_to_categories.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela deeper_events_to_categories.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela de junção deeper_events_to_categories...\", module: __MODULE__)

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS deeper_events_to_categories (
      event_id INTEGER NOT NULL,
      category_id INTEGER NOT NULL,
      PRIMARY KEY (event_id, category_id),
      FOREIGN KEY (event_id) REFERENCES deeper_events(id) ON DELETE CASCADE,
      FOREIGN KEY (category_id) REFERENCES deeper_event_categories(id) ON DELETE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_detc_category_id_event_id ON deeper_events_to_categories(category_id, event_id);
    \"\"\"

    # Repo.execute(\"PRAGMA foreign_keys = ON;\") -- Se necessário

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela de junção deeper_events_to_categories criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela de junção deeper_events_to_categories: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela de junção deeper_events_to_categories.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela de junção deeper_events_to_categories...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS deeper_events_to_categories;\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela de junção deeper_events_to_categories removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela de junção deeper_events_to_categories: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas:

*   Esta tabela depende da existência de `deeper_events` e `deeper_event_categories`.
*   `ON DELETE CASCADE` em ambas as chaves estrangeiras garante que as associações sejam limpas se um evento ou uma categoria for excluída.