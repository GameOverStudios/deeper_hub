# Migração Elixir: Criar Tabela `sys_acl_levels`

Este módulo de migração Elixir cria a tabela `sys_acl_levels` no SQLite, que define os diferentes níveis de membresia (roles) no sistema.

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_acl_levels_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysAclLevelsTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_acl_levels.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_acl_levels...\", module: __MODULE__)
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_acl_levels (
      ID INTEGER PRIMARY KEY AUTOINCREMENT,
      Name TEXT NOT NULL UNIQUE,
      Icon TEXT NOT NULL DEFAULT '',
      Description TEXT NOT NULL DEFAULT '',
      Active TEXT NOT NULL DEFAULT 'no' CHECK(Active IN ('yes', 'no')),
      Purchasable TEXT NOT NULL DEFAULT 'yes' CHECK(Purchasable IN ('yes', 'no')),
      Removable TEXT NOT NULL DEFAULT 'yes' CHECK(Removable IN ('yes', 'no')),
      QuotaSize INTEGER NOT NULL DEFAULT 0, -- Em bytes
      QuotaNumber INTEGER NOT NULL DEFAULT 0, -- Número de arquivos
      QuotaMaxFileSize INTEGER NOT NULL DEFAULT 0, -- Em bytes
      \"Order\" INTEGER NOT NULL DEFAULT 0, -- Aspas para 'Order'
      PasswordExpired INTEGER NOT NULL DEFAULT 0, -- Dias para expirar
      PasswordExpiredNotify INTEGER NOT NULL DEFAULT 0 -- Dias antes para notificar
    );
    CREATE INDEX IF NOT EXISTS idx_sys_acl_levels_name ON sys_acl_levels(Name);
    CREATE INDEX IF NOT EXISTS idx_sys_acl_levels_active ON sys_acl_levels(Active);
    \"\"\"
    # O dump original tem um FULLTEXT KEY em Description, que será omitido para SQLite inicial.
    case Repo.execute(sql) do
      {:ok, _} -> :ok
      err -> err
    end
  end

  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_acl_levels...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_acl_levels;\"
    case Repo.execute(sql) do
      {:ok, _} -> :ok
      err -> err
    end
  end
end
```