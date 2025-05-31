# Migração Elixir: Criar Tabela `sys_grid_actions`

Este módulo de migração Elixir cria a tabela `sys_grid_actions` no SQLite, que define as ações disponíveis para os itens de uma grid ou para a grid como um todo.

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_grid_actions_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysGridActionsTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_grid_actions.
  \"\"\"
  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_grid_actions...\", module: __MODULE__)
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_grid_actions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      object TEXT NOT NULL, -- FK para sys_objects_grid.object
      type TEXT NOT NULL CHECK(type IN ('bulk', 'single', 'independent')),
      name TEXT NOT NULL, -- Nome programático da ação, ex: 'delete', 'edit', 'activate'
      title TEXT NOT NULL, -- Chave de tradução para o rótulo da ação/botão
      icon TEXT NOT NULL DEFAULT '', -- Classe de ícone FontAwesome ou caminho
      icon_only INTEGER NOT NULL DEFAULT 0, -- 0 ou 1
      confirm INTEGER NOT NULL DEFAULT 1, -- 0 ou 1 (se requer confirmação JS no frontend)
      active INTEGER NOT NULL DEFAULT 1, -- 0 ou 1
      \"order\" INTEGER NOT NULL DEFAULT 0,
      UNIQUE(object, type, name)
      -- FOREIGN KEY (object) REFERENCES sys_objects_grid(object) ON DELETE CASCADE -- Opcional
    );
    CREATE INDEX IF NOT EXISTS idx_sys_grid_actions_object_order ON sys_grid_actions(object, \"order\");
    \"\"\"
    case Repo.execute(sql) do
      {:ok, _} -> :ok
      err -> err
    end
  end

  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_grid_actions...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_grid_actions;\"
    case Repo.execute(sql) do
      {:ok, _} -> :ok
      err -> err
    end
  end
end
```