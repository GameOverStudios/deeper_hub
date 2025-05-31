# Migração Elixir: Criar Tabela `sys_std_roles_actions`

Este módulo de migração Elixir cria a tabela `sys_std_roles_actions` no SQLite, que define ações específicas que podem ser associadas aos papéis padrão.

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_std_roles_actions_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysStdRolesActionsTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_std_roles_actions.
  \"\"\"
  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_std_roles_actions...\", module: __MODULE__)
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_std_roles_actions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE, -- Nome programático da ação, ex: 'manage_users', 'moderate_content'
      title TEXT NOT NULL, -- Chave de tradução
      description TEXT NOT NULL DEFAULT '' -- Chave de tradução
    );
    -- FULLTEXT KEY searchable (title, description) -- Omitido
    CREATE INDEX IF NOT EXISTS idx_sys_std_roles_actions_name ON sys_std_roles_actions(name);
    \"\"\"
    case Repo.execute(sql) do
      {:ok, _} -> :ok
      err -> err
    end
  end

  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_std_roles_actions...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_std_roles_actions;\"
    case Repo.execute(sql) do
      {:ok, _} -> :ok
      err -> err
    end
  end
end
```