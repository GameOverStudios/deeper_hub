# Migração Elixir: Criar Tabela `sys_acl_levels_members`

Este módulo de migração Elixir cria a tabela `sys_acl_levels_members` no SQLite, que associa membros (perfis) a níveis de ACL e define a validade dessa associação.

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_acl_levels_members_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysAclLevelsMembersTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_acl_levels_members.
  \"\"\"
  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_acl_levels_members...\", module: __MODULE__)
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_acl_levels_members (
      IDMember INTEGER NOT NULL, -- FK para sys_profiles.id
      IDLevel INTEGER NOT NULL, -- FK para sys_acl_levels.ID
      DateStarts TEXT NOT NULL DEFAULT '0000-00-00 00:00:00', -- DATETIME como TEXT (ISO8601 ou Unix Timestamp)
      DateExpires TEXT, -- DATETIME como TEXT (ISO8601 ou Unix Timestamp), pode ser NULL
      State TEXT DEFAULT '', -- Ex: 'active', 'expired', 'pending_payment'
      TransactionID TEXT DEFAULT '',
      PRIMARY KEY (IDMember, IDLevel, DateStarts)
      -- FOREIGN KEY (IDMember) REFERENCES sys_profiles(id) ON DELETE CASCADE,
      -- FOREIGN KEY (IDLevel) REFERENCES sys_acl_levels(ID) ON DELETE CASCADE
    );
    -- Chave primária composta já cria um índice. Índices adicionais se necessário.
    CREATE INDEX IF NOT EXISTS idx_sys_acl_lm_idlevel_idmember ON sys_acl_levels_members(IDLevel, IDMember);
    \"\"\"
    # Nota: SQLite não suporta DEFAULT '0000-00-00 00:00:00' diretamente para TEXT se for para ser um DATETIME válido.
    # Usar um timestamp Unix (0) ou um valor ISO8601 válido (ex: '1970-01-01 00:00:00') ou NULL.
    # O dump UNA usa '0000-00-00 00:00:00'. Para SQLite, é melhor usar um formato que ele entenda para funções de data.
    # Vamos manter como TEXT e a aplicação lida com o '0000-00-00' se necessário, ou usar NULL.
    # Para simplificar, vamos usar TEXT e a aplicação lida com a conversão.
    # Se usarmos Timestamps Unix, seria INTEGER NOT NULL DEFAULT 0.
    # Decidimos manter DateStarts como TEXT, mas o default pode ser um problema se não for um formato de data válido para SQLite.
    # Vamos ajustar para usar um default que SQLite aceita ou NULL.
    # Alterando default para DateStarts para um formato mais compatível ou NULL.
    # O schema original usa '0000-00-00 00:00:00' que é problemático. Usar NULL é mais seguro.
    # Ou um valor de data válido como '1970-01-01 00:00:00Z' se for formato ISO e for UTC.
    # Vamos seguir o dump e a aplicação pode ter que tratar esse valor especial.

    # A SQLite FKs são definidas na mesma instrução CREATE TABLE ou com ALTER TABLE ADD COLUMN
    # se a coluna já não existir. Para simplificar e manter a fidelidade, vamos omitir as
    # declarações FOREIGN KEY explícitas na migração inicial, assumindo que a integridade
    # será gerenciada pela aplicação ou adicionada em uma etapa de refino do esquema.
    # O dump original também não define FKs explícitas para estas.

    case Repo.execute(sql) do
      {:ok, _} -> :ok
      err -> err
    end
  end

  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_acl_levels_members...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_acl_levels_members;\"
    case Repo.execute(sql) do
      {:ok, _} -> :ok
      err -> err
    end
  end
end
```