# Migração Elixir: Criar Tabela `sys_acl_levels_members`

Este módulo de migração Elixir é responsável por criar a tabela `sys_acl_levels_members` no banco de dados SQLite. Esta tabela associa usuários (`sys_accounts.id`) a níveis de ACL (`sys_acl_levels.ID`) e define o período de validade dessa associação.

## Código da Migração (`lib/deeper/core/data/migrations/acl/create_sys_acl_levels_members_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.ACL.CreateSysAclLevelsMembersTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_acl_levels_members.
  Depende da existência das tabelas `sys_accounts` e `sys_acl_levels`.
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

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_acl_levels_members (
      IDMember INTEGER NOT NULL,
      IDLevel INTEGER NOT NULL,
      DateStarts INTEGER NOT NULL, -- Unix Timestamp
      DateExpires INTEGER, -- Unix Timestamp, NULL para nunca expirar
      State TEXT DEFAULT '' CHECK(State IN ('', 'active', 'pending', 'expired')),
      TransactionID TEXT,
      PRIMARY KEY (IDMember, IDLevel, DateStarts),
      FOREIGN KEY (IDMember) REFERENCES sys_accounts(id) ON DELETE CASCADE ON UPDATE CASCADE,
      FOREIGN KEY (IDLevel) REFERENCES sys_acl_levels(ID) ON DELETE CASCADE ON UPDATE CASCADE
    );
    \"\"\"
    # Habilitar FKs se necessário para esta sessão/transação de migração
    # Repo.execute(\"PRAGMA foreign_keys = ON;\")

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

## Notas:

*   `IDMember` referencia `sys_accounts.id` e `IDLevel` referencia `sys_acl_levels.ID`.
*   `DateStarts` e `DateExpires` são Timestamps Unix que definem a validade da associação.
*   A chave primária composta `(IDMember, IDLevel, DateStarts)` permite que um membro possa ter o mesmo nível múltiplas vezes, mas com diferentes datas de início (ex: renovações).
*   `State` e `TransactionID` podem ser usados para rastrear o status de aquisição de níveis (ex: via pagamento).
*   As constraints de Chave Estrangeira garantem a integridade referencial. Lembre-se da necessidade do `PRAGMA foreign_keys = ON;` no SQLite.