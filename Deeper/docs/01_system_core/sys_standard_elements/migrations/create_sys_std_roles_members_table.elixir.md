# Migração Elixir: Criar Tabela `sys_std_roles_members`

Este módulo de migração Elixir cria a tabela `sys_std_roles_members` no SQLite, que associa contas de usuário (`sys_accounts`) a papéis padrão (`sys_std_roles`).

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_std_roles_members_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysStdRolesMembersTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_std_roles_members.
  \"\"\"
  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_std_roles_members...\", module: __MODULE__)
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_std_roles_members (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      account_id INTEGER NOT NULL UNIQUE, -- FK para sys_accounts.id
      role INTEGER NOT NULL -- FK para sys_std_roles.id (ou o valor do ID do papel)
      -- FOREIGN KEY (account_id) REFERENCES sys_accounts(id) ON DELETE CASCADE,
      -- FOREIGN KEY (role) REFERENCES sys_std_roles(id) ON DELETE SET NULL -- Ou SET DEFAULT
    );
    CREATE INDEX IF NOT EXISTS idx_sys_std_roles_members_role ON sys_std_roles_members(role);
    \"\"\"
    # A constraint UNIQUE em account_id garante que uma conta só tenha um papel padrão atribuído.
    case Repo.execute(sql) do
      {:ok, _} -> :ok
      err -> err
    end
  end

  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_std_roles_members...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_std_roles_members;\"
    case Repo.execute(sql) do
      {:ok, _} -> :ok
      err -> err
    end
  end
end
```