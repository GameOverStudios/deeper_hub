# Migração Elixir: Criar Tabela `deeper_forum_categories`

Este módulo de migração Elixir é responsável por criar a tabela `deeper_forum_categories` no banco de dados SQLite. Esta tabela é opcional e serve para agrupar os fóruns principais em categorias maiores.

## Código da Migração (`lib/deeper/core/data/migrations/create_deeper_forum_categories_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateDeeperForumCategoriesTable do
  @moduledoc \"\"\"
  Migração para criar a tabela deeper_forum_categories.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela deeper_forum_categories.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela deeper_forum_categories...\", module: __MODULE__)

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS deeper_forum_categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL UNIQUE,
      slug TEXT NOT NULL UNIQUE,
      description TEXT,
      order_index INTEGER NOT NULL DEFAULT 0
    );

    CREATE INDEX IF NOT EXISTS idx_dfc_slug ON deeper_forum_categories(slug);
    CREATE INDEX IF NOT EXISTS idx_dfc_order_index ON deeper_forum_categories(order_index);
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela deeper_forum_categories criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela deeper_forum_categories: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela deeper_forum_categories.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela deeper_forum_categories...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS deeper_forum_categories;\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela deeper_forum_categories removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela deeper_forum_categories: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas:

*   Esta tabela é simples e usada para organizar os fóruns principais.
*   `order_index` permite uma ordenação manual das categorias.