# Migração Elixir: Criar Tabela `sys_std_roles_members`

Este módulo de migração Elixir é responsável por criar a tabela `sys_std_roles_members` no banco de dados SQLite. Esta tabela associa contas de usuário (`sys_accounts`) a papéis padrão (`sys_std_roles`).

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_std_roles_members_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysStdRolesMembersTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_std_roles_members.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela sys_std_roles_members.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_std_roles_members...\", module: __MODULE__)

    # PRAGMA foreign_keys = ON;

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_std_roles_members (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      account_id INTEGER NOT NULL UNIQUE, -- FK para sys_accounts.id
      role INTEGER NOT NULL, -- FK para sys_std_roles.id (no UNA o nome da coluna é `role`)
      FOREIGN KEY (account_id) REFERENCES sys_accounts(id) ON DELETE CASCADE ON UPDATE CASCADE,
      FOREIGN KEY (role) REFERENCES sys_std_roles(id) ON DELETE CASCADE ON UPDATE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_sys_std_roles_members_role ON sys_std_roles_members(role);
    -- O índice UNIQUE em account_id já é criado pela constraint UNIQUE na coluna.
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_std_roles_members criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela sys_std_roles_members: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela sys_std_roles_members.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_std_roles_members...\", module: __MODULE__)

    sql = \"DROP TABLE IF EXISTS sys_std_roles_members;\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_std_roles_members removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela sys_std_roles_members: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas de Adaptação SQLite:

*   `id`: `INT(11) UNSIGNED AUTO_INCREMENT` (MySQL) -> `INTEGER PRIMARY KEY AUTOINCREMENT` (SQLite).
*   `account_id`: `INT(11) UNSIGNED` com `UNIQUE KEY` (MySQL) -> `INTEGER NOT NULL UNIQUE` (SQLite). Chave estrangeira para `sys_accounts.id`.
*   `role`: `INT(11) UNSIGNED` (MySQL) -> `INTEGER NOT NULL` (SQLite). Chave estrangeira para `sys_std_roles.id`.
*   **Chaves Estrangeiras:** Definidas para `account_id` e `role`.