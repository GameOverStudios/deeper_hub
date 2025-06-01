# Migração Elixir: Criar Tabela `bx_market_categories`

Este módulo de migração Elixir é responsável por criar a tabela `bx_market_categories` no banco de dados SQLite. Esta tabela armazena as categorias e subcategorias para as listagens do marketplace.

## Código da Migração (`lib/deeper/core/data/migrations/create_bx_market_categories_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateBxMarketCategoriesTable do
  @moduledoc \"\"\"
  Migração para criar a tabela bx_market_categories.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela bx_market_categories.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela bx_market_categories...\", module: __MODULE__)

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS bx_market_categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      parent_id INTEGER NOT NULL DEFAULT 0,
      name TEXT NOT NULL,
      title TEXT NOT NULL,
      uri TEXT NOT NULL,
      icon TEXT,
      order_index INTEGER NOT NULL DEFAULT 0, -- Renomeado de 'order' para evitar conflito com palavra reservada
      active INTEGER NOT NULL DEFAULT 1 CHECK(active IN (0,1)),
      meta_description TEXT,
      meta_keywords TEXT
    );

    CREATE INDEX IF NOT EXISTS idx_bx_market_categories_parent_id ON bx_market_categories(parent_id);
    CREATE UNIQUE INDEX IF NOT EXISTS idx_bx_market_categories_name ON bx_market_categories(name); -- Nome deve ser único
    CREATE UNIQUE INDEX IF NOT EXISTS idx_bx_market_categories_uri ON bx_market_categories(uri); -- URI deve ser única
    \"\"\"
    # Nota: O nome da coluna 'order' foi mudado para 'order_index' para evitar
    # possível conflito com a palavra reservada ORDER em SQL.

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela bx_market_categories criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela bx_market_categories: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela bx_market_categories.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela bx_market_categories...\", module: __MODULE__)

    sql = \"DROP TABLE IF EXISTS bx_market_categories;\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela bx_market_categories removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela bx_market_categories: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas:

*   A coluna `order` foi renomeada para `order_index` para evitar conflitos com a palavra-chave SQL `ORDER`.
*   Índices `UNIQUE` foram adicionados para `name` e `uri` para garantir unicidade.