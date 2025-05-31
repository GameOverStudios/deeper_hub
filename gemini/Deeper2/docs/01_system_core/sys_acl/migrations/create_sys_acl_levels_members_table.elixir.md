# Migração Elixir: Criar Tabela `sys_acl_levels_members`

Este módulo de migração Elixir é responsável por criar a tabela `sys_acl_levels_members` no banco de dados SQLite. Esta tabela associa membros (contas de usuário) a níveis de ACL específicos, registrando também a validade dessa associação.

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_acl_levels_members_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysAclLevelsMembersTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_acl_levels_members.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela sys_acl_levels_members.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_acl_levels_members...\", module: __MODULE__)

    # PRAGMA foreign_keys = ON; -- Idealmente configurado na conexão do Repo

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_acl_levels_members (
      IDMember INTEGER NOT NULL, -- No UNA é INT(10) UNSIGNED, refere-se a sys_accounts.id
      IDLevel INTEGER NOT NULL, -- No UNA é INT(10) UNSIGNED, refere-se a sys_acl_levels.ID
      DateStarts TEXT NOT NULL, -- No UNA é DATETIME, armazenar como ISO8601
      DateExpires TEXT, -- No UNA é DATETIME DEFAULT NULL, armazenar como ISO8601
      State TEXT, -- No UNA é VARCHAR(16) NOT NULL DEFAULT ''
      TransactionID TEXT, -- No UNA é VARCHAR(16) NOT NULL DEFAULT ''
      PRIMARY KEY (IDMember, IDLevel, DateStarts),
      FOREIGN KEY (IDMember) REFERENCES sys_accounts(id) ON DELETE CASCADE ON UPDATE CASCADE,
      FOREIGN KEY (IDLevel) REFERENCES sys_acl_levels(ID) ON DELETE CASCADE ON UPDATE CASCADE
    );
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_acl_levels_members criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela sys_acl_levels_members: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela sys_acl_levels_members.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_acl_levels_members...\", module: __MODULE__)

    sql = \"DROP TABLE IF EXISTS sys_acl_levels_members;\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_acl_levels_members removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela sys_acl_levels_members: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas de Adaptação SQLite:

*   `IDMember`: `INT(10) UNSIGNED` (MySQL) -> `INTEGER` (SQLite). Refere-se a `sys_accounts.id`.
*   `IDLevel`: `INT(10) UNSIGNED` (MySQL) -> `INTEGER` (SQLite). Refere-se a `sys_acl_levels.ID`.
*   `DateStarts`, `DateExpires`: `DATETIME` (MySQL) -> `TEXT` (SQLite), armazenando datas/horas no formato ISO 8601 (`YYYY-MM-DD HH:MM:SS`). `DateExpires` pode ser `NULL`.
*   `State`, `TransactionID`: `VARCHAR(16)` (MySQL) -> `TEXT` (SQLite).
*   **Chave Primária Composta:** `PRIMARY KEY (IDMember, IDLevel, DateStarts)` foi mantida. Isso permite que um membro possa ter o mesmo nível múltiplas vezes, desde que as datas de início sejam diferentes (ex: renovações ou períodos distintos de acesso).
*   **Chaves Estrangeiras:** Definidas para `IDMember` e `IDLevel` com `ON DELETE CASCADE` e `ON UPDATE CASCADE` para manter a integridade referencial.
    *   Lembrete: `PRAGMA foreign_keys = ON;` deve estar ativo na conexão para que as FKs sejam impostas.