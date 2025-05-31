# Migração Elixir: Criar Tabela `sys_acl_levels`

Este módulo de migração Elixir é responsável por criar a tabela `sys_acl_levels` no banco de dados SQLite. Esta tabela define os diferentes níveis de membresia do sistema.

## Código da Migração (`lib/deeper/core/data/migrations/acl/create_sys_acl_levels_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.ACL.CreateSysAclLevelsTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_acl_levels.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela sys_acl_levels.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_acl_levels...\", module: __MODULE__)

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_acl_levels (
      ID INTEGER PRIMARY KEY AUTOINCREMENT,
      Name TEXT NOT NULL UNIQUE,
      Icon TEXT,
      Description TEXT,
      Active TEXT NOT NULL DEFAULT 'no' CHECK(Active IN ('yes', 'no')),
      Purchasable TEXT NOT NULL DEFAULT 'yes' CHECK(Purchasable IN ('yes', 'no')),
      Removable TEXT NOT NULL DEFAULT 'yes' CHECK(Removable IN ('yes', 'no')),
      QuotaSize INTEGER NOT NULL DEFAULT 0,
      QuotaNumber INTEGER NOT NULL DEFAULT 0,
      QuotaMaxFileSize INTEGER NOT NULL DEFAULT 0,
      \"Order\" INTEGER NOT NULL DEFAULT 0,
      PasswordExpired INTEGER NOT NULL DEFAULT 0,
      PasswordExpiredNotify INTEGER NOT NULL DEFAULT 0
    );
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_acl_levels criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela sys_acl_levels: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela sys_acl_levels.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_acl_levels...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_acl_levels;\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_acl_levels removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela sys_acl_levels: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas:

*   As colunas `Active`, `Purchasable`, `Removable` usam `TEXT` com `CHECK` constraints para simular ENUMs.
*   `\"Order\"` está entre aspas para evitar conflito com a palavra-chave SQL.
*   As colunas `Quota...` e `PasswordExpired...` armazenam valores numéricos para as respectivas configurações do nível.