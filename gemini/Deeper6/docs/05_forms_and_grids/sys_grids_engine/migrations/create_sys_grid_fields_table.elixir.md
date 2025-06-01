# Migração Elixir: Criar Tabela `sys_grid_fields`

Este módulo de migração Elixir é responsável por criar a tabela `sys_grid_fields` no banco de dados SQLite. Esta tabela define as colunas (campos) que serão exibidas em cada objeto de grade.

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_grid_fields_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysGridFieldsTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_grid_fields.
  \"\"\"
  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  def up do
    Logger.info(\"Criando tabela sys_grid_fields...\", module: __MODULE__)
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_grid_fields (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      object TEXT NOT NULL, -- FK para sys_objects_grid.object
      name TEXT NOT NULL,
      title TEXT NOT NULL,
      width TEXT NOT NULL DEFAULT 'auto',
      translatable INTEGER NOT NULL DEFAULT 0,
      chars_limit INTEGER NOT NULL DEFAULT 0,
      params TEXT,
      hidden_on TEXT,
      \"order\" INTEGER NOT NULL,
      FOREIGN KEY (object) REFERENCES sys_objects_grid(object) ON UPDATE CASCADE ON DELETE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_sys_grid_fields_object_order ON sys_grid_fields(object, \"order\");
    CREATE UNIQUE INDEX IF NOT EXISTS idx_sys_grid_fields_object_name ON sys_grid_fields(object, name);
    \"\"\"
    # Repo.execute(\"PRAGMA foreign_keys = ON;\") # Se necessário

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_grid_fields criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela sys_grid_fields: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  def down do
    Logger.info(\"Removendo tabela sys_grid_fields...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_grid_fields;\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_grid_fields removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela sys_grid_fields: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```