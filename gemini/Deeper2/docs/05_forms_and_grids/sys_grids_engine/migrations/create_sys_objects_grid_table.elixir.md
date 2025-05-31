# Migração Elixir: Criar Tabela `sys_objects_grid`

Este módulo de migração Elixir é responsável por criar a tabela `sys_objects_grid` no banco de dados SQLite. Esta tabela é a principal definição para cada instância de grid de dados no sistema UNA, especificando sua fonte de dados, opções de paginação, filtros, ordenação, e outras configurações.

## Código da Migração (`lib/deeper/grids/migrations/create_sys_objects_grid_table.ex`)

```elixir
defmodule Deeper.Grids.Migrations.CreateSysObjectsGridTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_objects_grid.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela sys_objects_grid.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_objects_grid...\", module: __MODULE__)

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_objects_grid (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      object TEXT NOT NULL UNIQUE,
      source_type TEXT NOT NULL CHECK(source_type IN ('Sql', 'Array')),
      source TEXT NOT NULL,
      \"table\" TEXT NOT NULL,
      field_id TEXT NOT NULL,
      field_order TEXT NOT NULL,
      field_active TEXT,
      order_get_field TEXT NOT NULL DEFAULT 'order_field',
      order_get_dir TEXT NOT NULL DEFAULT 'order_dir',
      paginate_url TEXT,
      paginate_per_page INTEGER NOT NULL DEFAULT 10,
      paginate_simple TEXT,
      paginate_get_start TEXT NOT NULL,
      paginate_get_per_page TEXT NOT NULL,
      filter_fields TEXT,
      filter_fields_translatable TEXT,
      filter_mode TEXT NOT NULL DEFAULT 'auto' CHECK(filter_mode IN ('like', 'fulltext', 'auto')),
      filter_get TEXT NOT NULL DEFAULT 'filter',
      sorting_fields TEXT,
      sorting_fields_translatable TEXT,
      visible_for_levels INTEGER NOT NULL DEFAULT 2147483647,
      responsive INTEGER NOT NULL DEFAULT 1, -- 0 ou 1
      show_total_count INTEGER NOT NULL DEFAULT 1, -- 0 ou 1
      override_class_name TEXT,
      override_class_file TEXT
    );

    CREATE INDEX IF NOT EXISTS idx_sys_objects_grid_object ON sys_objects_grid(object);
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_objects_grid criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela sys_objects_grid: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela sys_objects_grid.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_objects_grid...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_objects_grid;\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_objects_grid removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela sys_objects_grid: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas de Adaptação SQLite:

*   `id`: `INT(11)` (MySQL) -> `INTEGER PRIMARY KEY AUTOINCREMENT`.
*   Colunas `VARCHAR`/`TEXT` do MySQL -> `TEXT`. `object` é `UNIQUE`.
*   Colunas `ENUM` do MySQL (`source_type`, `filter_mode`) -> `TEXT` com `CHECK` constraint.
*   Colunas `INT`/`TINYINT` (para booleanos) do MySQL -> `INTEGER`.
*   `\"table\"` está entre aspas.