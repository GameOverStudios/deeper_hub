# Migração Elixir: Criar Tabela `sys_std_roles_actions2roles`

Este módulo de migração Elixir cria a tabela `sys_std_roles_actions2roles` no SQLite, uma tabela de junção que associa ações (`sys_std_roles_actions`) a papéis (`sys_std_roles`).

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_std_roles_actions2roles_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysStdRolesActions2RolesTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_std_roles_actions2roles.
  \"\"\"
  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_std_roles_actions2roles...\", module: __MODULE__)
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_std_roles_actions2roles (
      role_id INTEGER NOT NULL, -- FK para sys_std_roles.id
      action_id INTEGER NOT NULL, -- FK para sys_std_roles_actions.id
      PRIMARY KEY (role_id, action_id)
      -- FOREIGN KEY (role_id) REFERENCES sys_std_roles(id) ON DELETE CASCADE,
      -- FOREIGN KEY (action_id) REFERENCES sys_std_roles_actions(id) ON DELETE CASCADE
    );
    \"\"\"
    case Repo.execute(sql) do
      {:ok, _} -> :ok
      err -> err
    end
  end

  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_std_roles_actions2roles...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_std_roles_actions2roles;\"
    case Repo.execute(sql) do
      {:ok, _} -> :ok
      err -> err
    end
  end
end
```