# Migração Elixir: Criar Tabela `sys_grid_actions`

Este módulo de migração Elixir é responsável por criar a tabela `sys_grid_actions` no banco de dados SQLite. Esta tabela define as ações (botões, links) disponíveis para as grades de dados.

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_grid_actions_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysGridActionsTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_grid_actions.
  \"\"\"
  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  def up do
    Logger.info(\"Criando tabela sys_grid_actions...\", module: __MODULE__)
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_grid_actions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      object TEXT NOT NULL, -- FK para sys_objects_grid.object
      type TEXT NOT NULL CHECK(type IN ('bulk', 'single', 'independent')),
      name TEXT NOT NULL,
      title TEXT NOT NULL,
      icon TEXT,
      icon_only INTEGER NOT NULL DEFAULT 0,
      confirm INTEGER NOT NULL DEFAULT 1,
      active INTEGER NOT NULL DEFAULT 1,
      \"order\" INTEGER NOT NULL,
      api_endpoint TEXT,
      api_method TEXT,
      id_placeholder_field TEXT DEFAULT 'id',
      FOREIGN KEY (object) REFERENCES sys_objects_grid(object) ON UPDATE CASCADE ON DELETE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_sys_grid_actions_object_order ON sys_grid_actions(object, \"order\");
    CREATE UNIQUE INDEX IF NOT EXISTS idx_sys_grid_actions_object_name_type ON sys_grid_actions(object, name, type);
    \"\"\"
    # Repo.execute(\"PRAGMA foreign_keys = ON;\") # Se necessário

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_grid_actions criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela sys_grid_actions: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  def down do
    Logger.info(\"Removendo tabela sys_grid_actions...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_grid_actions;\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_grid_actions removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela sys_grid_actions: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```