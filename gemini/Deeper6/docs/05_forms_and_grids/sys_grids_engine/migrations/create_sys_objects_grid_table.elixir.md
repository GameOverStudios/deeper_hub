# Migração Elixir: Criar Tabela `sys_objects_grid`

Este módulo de migração Elixir é responsável por criar a tabela `sys_objects_grid` no banco de dados SQLite. Esta tabela armazena as definições dos objetos de grade (tabelas de dados) usados no sistema.

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_objects_grid_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysObjectsGridTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_objects_grid.
  \"\"\"
  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  def up do
    Logger.info(\"Criando tabela sys_objects_grid...\", module: __MODULE__)
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_objects_grid (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      object TEXT NOT NULL UNIQUE,
      source_type TEXT NOT NULL CHECK(source_type IN ('Sql', 'Array')) DEFAULT 'Sql',
      source TEXT NOT NULL,
      table_name TEXT NOT NULL,
      field_id TEXT NOT NULL,
      field_order TEXT NOT NULL,
      field_active TEXT,
      paginate_per_page INTEGER NOT NULL DEFAULT 10,
      paginate_get_start TEXT DEFAULT 'offset',
      paginate_get_per_page TEXT DEFAULT 'limit',
      filter_fields TEXT,
      filter_mode TEXT NOT NULL DEFAULT 'auto' CHECK(filter_mode IN ('like', 'fulltext', 'auto')),
      filter_get TEXT DEFAULT 'filter',
      sorting_fields TEXT,
      visible_for_levels INTEGER NOT NULL DEFAULT 2147483647,
      responsive INTEGER NOT NULL DEFAULT 1,
      show_total_count INTEGER NOT NULL DEFAULT 1
    );
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